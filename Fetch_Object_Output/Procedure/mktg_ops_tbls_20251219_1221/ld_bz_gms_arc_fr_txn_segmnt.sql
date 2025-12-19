CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_gms_arc_fr_txn_segmnt()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 2014-10-13
Purpose: This macro derives the email segment description and key for each gift transaction record and writes the results
				to the bz_arc_fr_txn table.  We need to do a self join on FR TXN table to derive the email segment value.  To avoid spool issues,
				the macro eliminates gift transaction associated with Org contituent types and master ids that have 300 or more gifts.  The macro
				uses UNION queries to assign default email segment values for the Corporate and Chapter/Generic gifts (these are the gifts associated
				with master ids that have 300 or more gifts and are not Org constituents).  This table is joined to the base arc_fr_txn in the mktg_ops_vws.gms_arc_fr_txn view definition.
				
				NOTE: This macro needs to run every morning after the ARC FR TXN table has been loaded.
				
Modified by: Michael Andrien
Modified Date: 02/10/2020
Purpose:	Created the GMS version to read from gms_arc_fr_txn. 
------------------------------------------------------------------------------------------------------------------------------------ */
-- The join below was add by Mike Andrien 1/30/17 to derive the email segment description and active email indicator 
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_bz_gms_arc_fr_txn_segmnt', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN
		-- Truncate the staging table before loading new data
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.bz_gms_arc_fr_txn_segmnt_stg;
		-- Load data into staging table
		INSERT INTO mktg_stage_tbls.bz_gms_arc_fr_txn_segmnt_stg
		
		WITH high_volume_constituents AS (
			SELECT cnst_mstr_id
			FROM mktg_ops_tbls.gms_arc_fr_txn
			GROUP BY cnst_mstr_id
			HAVING COUNT(*) >= 300
		),
		valid_constituents AS (
			SELECT DISTINCT c.cnst_mstr_id
			FROM mktg_ops_vws.bz_cnst_mstr c
			WHERE c.cnst_typ_cd = 'IN'
		),
		base_data AS (
			SELECT 
				a.cnst_mstr_id,
				a.giftran_key,
				a.dntn_gift_dt,
				a.fr_distr_dntn_ind
			FROM mktg_ops_tbls.gms_arc_fr_txn a
			WHERE a.cnst_mstr_id IN (SELECT cnst_mstr_id FROM valid_constituents)
			AND a.cnst_mstr_id NOT IN (SELECT cnst_mstr_id FROM high_volume_constituents)
		),
		calculated_data AS (
			SELECT 
				a.cnst_mstr_id,
				a.giftran_key,
				a.dntn_gift_dt,
				MAX(b.dntn_gift_dt) AS last_dntn_gift_dt,
				SUM(CASE WHEN a.dntn_gift_dt - b.dntn_gift_dt < 365 AND a.fr_distr_dntn_ind = 1 THEN 1 ELSE 0 END) AS fr_distr_dntn_cnt,
				SUM(CASE WHEN a.dntn_gift_dt - b.dntn_gift_dt < 365 AND a.fr_distr_dntn_ind = 0 THEN 1 ELSE 0 END) AS fr_mission_dntn_cnt
			FROM base_data a
			LEFT JOIN base_data b
				ON a.cnst_mstr_id = b.cnst_mstr_id 
				AND a.giftran_key > b.giftran_key 
				AND a.dntn_gift_dt > b.dntn_gift_dt
			GROUP BY a.cnst_mstr_id, a.giftran_key, a.dntn_gift_dt, a.fr_distr_dntn_ind
		),
		txn_data AS (
			SELECT 
				cnst_mstr_id,
				giftran_key,
				dntn_gift_dt,
				last_dntn_gift_dt,
				fr_distr_dntn_cnt,
				fr_mission_dntn_cnt,
				ROW_NUMBER() OVER (
					PARTITION BY cnst_mstr_id, giftran_key 
					ORDER BY dntn_gift_dt DESC
				) as rn
			FROM (
				SELECT 
					cnst_mstr_id,
					giftran_key,
					dntn_gift_dt,
					last_dntn_gift_dt::DATE,
					fr_distr_dntn_cnt::SMALLINT,
					fr_mission_dntn_cnt::SMALLINT
				FROM calculated_data
				
				UNION 
				
				-- This next query, which selects all cnsts then unions the set to the query above to eliminate duplicate master id records, identifies the donors that have no previous donations - 'New Donors'.	
				SELECT 
					a.cnst_mstr_id,
					a.giftran_key,
					a.dntn_gift_dt,
					NULL::DATE as last_dntn_gift_dt,
					0::SMALLINT as fr_distr_dntn_cnt,
					0::SMALLINT as fr_mission_dntn_cnt
				FROM mktg_ops_tbls.gms_arc_fr_txn a	
				LEFT JOIN mktg_ops_vws.bz_cnst_mstr b 
					ON a.cnst_mstr_id = b.cnst_mstr_id
				WHERE b.cnst_typ_cd = 'IN' 
					AND a.cnst_mstr_id <> 0 
					AND a.cnst_mstr_id NOT IN (
						SELECT cnst_mstr_id
						FROM mktg_ops_tbls.gms_arc_fr_txn
						GROUP BY cnst_mstr_id
						HAVING COUNT(*) >= 300
					)
				
				-- The third and UNION  identifies the chapter or mass generic/industrial donors and assigns a gift date of '12/31/9999' to identify them is generically processed chapter or phone campaign donors ids.
				UNION
				
				SELECT 
					a.cnst_mstr_id,
					a.giftran_key,
					a.dntn_gift_dt,
					'12/31/9999'::DATE as last_dntn_gift_dt,
					0::SMALLINT as fr_distr_dntn_cnt,
					0::SMALLINT as fr_mission_dntn_cnt
				FROM mktg_ops_vws.gms_arc_fr_txn a	
				LEFT JOIN mktg_ops_vws.bz_cnst_mstr b 
					ON a.cnst_mstr_id = b.cnst_mstr_id
				WHERE b.cnst_typ_cd = 'IN' 
					AND a.cnst_mstr_id IN (
						SELECT cnst_mstr_id
						FROM mktg_ops_tbls.gms_arc_fr_txn
						GROUP BY cnst_mstr_id
						HAVING COUNT(*) >= 300
					)
				
				-- The fourth UNION selects the Corporate donation and sets the email segment to Corporate.
				UNION
				
				SELECT 
					a.cnst_mstr_id,
					a.giftran_key,
					a.dntn_gift_dt,
					'12/31/3000'::DATE as last_dntn_gift_dt,
					0::SMALLINT as fr_distr_dntn_cnt,
					0::SMALLINT as fr_mission_dntn_cnt
				FROM mktg_ops_vws.gms_arc_fr_txn a	
				LEFT JOIN mktg_ops_vws.bz_cnst_mstr b 
					ON a.cnst_mstr_id = b.cnst_mstr_id
				WHERE b.cnst_typ_cd = 'OR'
			) txn
		)
		SELECT
			cnst_mstr_id,
			giftran_key,
			dntn_gift_dt,
			last_dntn_gift_dt,
			CASE 
				WHEN dntn_gift_dt - last_dntn_gift_dt >= 365 THEN 1 -- 'Lapsed Email'
				WHEN dntn_gift_dt - last_dntn_gift_dt < 365 AND fr_mission_dntn_cnt > 0 THEN 2 -- 'Active Email Mission'
				WHEN dntn_gift_dt - last_dntn_gift_dt < 365 AND fr_distr_dntn_cnt > 0 AND fr_mission_dntn_cnt = 0 THEN 3 -- 'Active Email Disaster'
				WHEN last_dntn_gift_dt = '12/31/9999' THEN 7 --'Generic Chapter Donor'
				WHEN last_dntn_gift_dt IS NULL THEN 5 -- 'New Donor'
				WHEN last_dntn_gift_dt = '12/31/3000' THEN 6 -- 'Corporate Donor'					
				ELSE 0 -- 'Unknown'
			END as email_segmnt_key,
			CASE 
				WHEN dntn_gift_dt - last_dntn_gift_dt < 365 AND last_dntn_gift_dt NOT IN ('12/31/3000','12/31/9999') THEN 1 
				ELSE 0 
			END as active_email_segmnt_ind
		FROM txn_data
		WHERE rn = 1;
		
        -- Only proceed to target table if staging was successful
        TRUNCATE TABLE mktg_ops_tbls.bz_gms_arc_fr_txn_segmnt;
        
        -- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.bz_gms_arc_fr_txn_segmnt
        SELECT * FROM mods_bi.mktg_stage_tbls.bz_gms_arc_fr_txn_segmnt_stg;

        v_end_time := GETDATE();
		v_ok_message = cast((select count(*) from mods_bi.mktg_ops_tbls.bz_gms_arc_fr_txn_segmnt) as nvarchar)+ ' Records inserted.';
        
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message
        WHERE proc_name = 'ld_bz_gms_arc_fr_txn_segmnt' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bz_gms_arc_fr_txn_segmnt: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bz_gms_arc_fr_txn_segmnt', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
