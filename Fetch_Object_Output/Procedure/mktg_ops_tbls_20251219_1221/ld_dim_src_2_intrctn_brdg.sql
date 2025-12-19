CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dim_src_2_intrctn_brdg()
 LANGUAGE plpgsql
AS $$
/* 
---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 04/01/2020
Purpose: This macro was created to load the campaign source code to campaign interaction bridge table (dim_src_2_intrctn_brdg).
The table is referenced by the ld_bzfc_fact_response_all macro and used to set the campaign interaction date on the PG response rows.
The macro derives the dates from the 3 interactions fact tables that contain all the email and dmail interaction records from our old Aprimo Campaign automation tool (bzfc_fact_interaction_all)
and from the current Adobe Campaign tool (bzfc_fact_dmail_interaction and bzfc_fact_email_interaction).

Modified By: Michael Andrien
Modified Date: 05/06/2020
Purpose: Changed the references to comnictn_src_key to src_key to align GMS source keys in the brdg table.

Modified By: Michael Andrien
Modified Date: 06/30/2020
Purpose:  Replaced the NOT IN part of SQL using Left Outer Join and c.src_key is null. 
				Updated the logic for the load_id to use max(load_id) in the column SQL. 
				
Modified By: Majeed Mohammad
Modified Date: 07/06/2020
Purpose:  Added the left join to bz_dim_delivery and the where condition to the email insert query.  The two join and where details are listed below:
	--Join Added -- left outer join mktg_ops_vws.bz_dim_delivery d on a.delivery_key = d.delivery_key 
	--Where Condition added -  and substr(d.delivery_nm,1,3) <> 'FCP' and d.exclude_rptng_ind = 0 and a.intrctn_status_key = 1
------------------------------------------------------------------------------------------------------------------------------------ 
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dim_src_2_intrctn_brdg', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		-- Truncate staging table
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.dim_src_2_intrctn_brdg_stg;
		
		/* Now Apply the Adobe Email Source Code Inserts */
		INSERT INTO mktg_stage_tbls.dim_src_2_intrctn_brdg_stg
		WITH email_interactions AS (
			SELECT  
				a.src_key,  
				a.src_cd,  
				src.pg_src_cd, 
				NULL::date AS mail_dt, 
				a.intrctn_dt AS email_launch_dt, 
				a.intrctn_dt, 
				'I'::VARCHAR(1) AS row_status_cd, 
				GETDATE() AS dw_trans_ts, 
				(SELECT MAX(load_id) + 1 FROM mktg_ops_tbls.dim_src_2_intrctn_brdg) AS load_id, 
				'MODS'::VARCHAR(4) AS appl_src_cd,
				ROW_NUMBER() OVER (PARTITION BY a.src_key ORDER BY a.intrctn_dt) AS rn
			FROM mktg_ops_vws.bzfc_fact_email_interaction a 
			LEFT OUTER JOIN mktg_ops_vws.gmpbzal_dim_src src ON a.src_key = src.src_key 
			LEFT OUTER JOIN mktg_ops_tbls.dim_src_2_intrctn_brdg c ON a.src_key = c.src_key  
			LEFT OUTER JOIN mktg_ops_vws.bz_dim_delivery d ON a.delivery_key = d.delivery_key 
			WHERE a.intrctn_dt IS NOT NULL 
			  AND a.src_key IS NOT NULL 
			  AND c.src_key IS NULL  
			  AND SUBSTRING(d.delivery_nm,1,3) <> 'FCP' 
			  AND d.exclude_rptng_ind = 0 
			  AND a.intrctn_status_key = 1
		)
		SELECT 
			src_key, src_cd, pg_src_cd, mail_dt, email_launch_dt, intrctn_dt,
			row_status_cd, dw_trans_ts, load_id, appl_src_cd
		FROM email_interactions
		WHERE rn = 1;

		/* Now Apply the Adobe Dmail Source Code Inserts */
		INSERT INTO mktg_stage_tbls.dim_src_2_intrctn_brdg_stg
		WITH dmail_interactions AS (
			SELECT 
				a.src_key, 
				a.src_cd, 
				src.pg_src_cd,
				a.intrctn_dt AS mail_dt,
				NULL::date AS email_launch_dt,
				a.intrctn_dt,
				'I'::VARCHAR(1) AS row_status_cd,
				GETDATE() AS dw_trans_ts,
				(SELECT MAX(load_id) + 1 FROM mktg_ops_tbls.dim_src_2_intrctn_brdg) AS load_id,
				'MODS'::VARCHAR(4) AS appl_src_cd,
				ROW_NUMBER() OVER (PARTITION BY a.src_key ORDER BY a.intrctn_dt) AS rn
			FROM mktg_ops_vws.bzfc_fact_dmail_interaction a
			LEFT OUTER JOIN mktg_ops_vws.gmpbzal_dim_src src ON a.src_key = src.src_key
			LEFT OUTER JOIN mktg_ops_tbls.dim_src_2_intrctn_brdg c ON a.src_key = c.src_key 
			WHERE mailed_ind = 1 
			  AND a.intrctn_dt IS NOT NULL 
			  AND a.src_key IS NOT NULL 
			  AND c.src_key IS NULL
		)
		SELECT 
			src_key, src_cd, pg_src_cd, mail_dt, email_launch_dt, intrctn_dt,
			row_status_cd, dw_trans_ts, load_id, appl_src_cd
		FROM dmail_interactions
		WHERE rn = 1;

		/* Now Apply the Aprimo email and dmail interaction source code inserts (fact_interaction_all Source Code) */
		INSERT INTO mktg_stage_tbls.dim_src_2_intrctn_brdg_stg
		WITH aprimo_interactions AS (
			SELECT 
				a.src_key AS src_key, 
				a.cell_src_cd AS src_cd, 
				src.pg_src_cd,
				CASE WHEN drop_dt IS NOT NULL THEN drop_dt ELSE NULL::date END AS mail_dt,
				CASE WHEN email_sent_dt IS NOT NULL THEN interaction_dt ELSE NULL::date END AS email_launch_dt,
				interaction_dt AS intrctn_dt,
				'I'::VARCHAR(1) AS row_status_cd,
				GETDATE() AS dw_trans_ts,
				(SELECT MAX(load_id) + 1 FROM mktg_ops_tbls.dim_src_2_intrctn_brdg) AS load_id,
				'MODS'::VARCHAR(4) AS appl_src_cd,
				ROW_NUMBER() OVER (PARTITION BY a.src_key ORDER BY a.interaction_dt) AS rn
			FROM mktg_ops_vws.bzfc_fact_interaction_all a
			LEFT OUTER JOIN mktg_ops_vws.gmpbzal_dim_src src ON a.src_key = src.src_key
			LEFT OUTER JOIN mktg_ops_tbls.dim_src_2_intrctn_brdg c ON a.src_key = c.src_key 
			WHERE 
				mailed_ind = CASE WHEN drop_dt IS NOT NULL THEN 1 ELSE 0 END
				AND interaction_dt IS NOT NULL 
				AND a.src_key IS NOT NULL
				AND c.src_key IS NULL
		)
		SELECT 
			src_key, src_cd, pg_src_cd, mail_dt, email_launch_dt, intrctn_dt,
			row_status_cd, dw_trans_ts, load_id, appl_src_cd
		FROM aprimo_interactions
		WHERE rn = 1;
        
        -- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.dim_src_2_intrctn_brdg
        SELECT * FROM mods_bi.mktg_stage_tbls.dim_src_2_intrctn_brdg_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_stage_tbls.dim_src_2_intrctn_brdg_stg) as INTEGER)
        WHERE proc_name = 'ld_dim_src_2_intrctn_brdg' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_dim_src_2_intrctn_brdg: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_dim_src_2_intrctn_brdg', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
