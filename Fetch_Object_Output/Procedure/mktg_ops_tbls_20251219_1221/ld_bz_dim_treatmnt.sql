CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_dim_treatmnt()
 LANGUAGE plpgsql
AS $$
/*
Created By: Michael Andrien
Created Date: 5/30/2017
Purpose: 	This macro combines the Aprimo and Adobe treatment reference tables and loads the data into mktg_ops_tbls.bz_dim_treatmnt, which is
				the source for the mktg_ops_vws.bz_dim_treatmnt view referenced in the Campaign Effectiveness universe.

*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_dim_treatmnt', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN

		TRUNCATE TABLE mktg_stage_tbls.bz_dim_treatmnt_stg;
		
		--Now insert the new rows
		INSERT INTO mktg_stage_tbls.bz_dim_treatmnt_stg
		WITH aprimo_treatments AS (
			SELECT
				trmt_id + 1000000 as treatmnt_key, -- Manufacturing the key for Aprimo treatments by adding 1,000,000 to the treatment id to make sure we have no conflicts with Adobe keys.
				trmt_id as nk_treatmnt_id,
				COLLATE(CAST(trmt_cd AS VARCHAR(75)), 'CASE_INSENSITIVE') as treatmnt_cd,
				COLLATE(CAST(ttl AS VARCHAR(75)), 'CASE_INSENSITIVE') as treatmnt_dsc, -- Changed the column name from ttl to treatmnt_dsc 5/17/2017 to match Adobe
				COLLATE(CAST(typ AS VARCHAR(255)), 'CASE_INSENSITIVE') as treatmnt_typ,
				COLLATE(CAST(status AS VARCHAR(765)), 'CASE_INSENSITIVE') as treatmnt_status,
				CAST(CASE WHEN status = 'Active' THEN 1 ELSE 0 END AS SMALLINT) as active_ind,
				COLLATE(CAST(channel AS VARCHAR(255)), 'CASE_INSENSITIVE') as channel,
				COLLATE(CAST(actvty_specific AS VARCHAR(765)), 'CASE_INSENSITIVE') as actvty_specific,
				snapshot_ts,
				srcsys_ts,
				dw_updt_ts,
				COLLATE(CAST(row_stat_cd AS VARCHAR(50)), 'CASE_INSENSITIVE') as row_stat_cd,
				COLLATE(CAST('APRM' AS VARCHAR(10)), 'CASE_INSENSITIVE') as appl_src_cd,
				load_id,
				ROW_NUMBER() OVER (PARTITION BY trmt_id ORDER BY snapshot_ts DESC) as rn
			FROM mktg_ops_tbls.aprm_wb_apnd_treatmnts
		)
		SELECT
			treatmnt_key,
			nk_treatmnt_id,
			treatmnt_cd,
			treatmnt_dsc,
			treatmnt_typ,
			treatmnt_status,
			active_ind,
			channel,
			actvty_specific,
			snapshot_ts,
			srcsys_ts,
			dw_updt_ts,
			row_stat_cd,
			appl_src_cd,
			load_id
		FROM aprimo_treatments
		WHERE rn = 1
		
		UNION ALL
		
		-- Added Adobe dim_treatmnt data 5/17/2017
		SELECT
			CAST(treatmnt_key AS INTEGER) as treatmnt_key,
			CAST(nk_treatmnt_id AS INTEGER) as nk_treatmnt_id,
			COLLATE(CAST(treatmnt_cd AS VARCHAR(75)), 'CASE_INSENSITIVE') as treatmnt_cd,
			COLLATE(CAST(treatmnt_dsc AS VARCHAR(75)), 'CASE_INSENSITIVE') as treatmnt_dsc,
			COLLATE(CAST(NULL AS VARCHAR(255)), 'CASE_INSENSITIVE') as treatmnt_typ, -- used in Aprimo, but not Adobe
			COLLATE(CAST(CASE WHEN active_ind = 1 THEN 'Active' ELSE 'Inactive' END AS VARCHAR(765)), 'CASE_INSENSITIVE') as treatmnt_status,
			CAST(active_ind AS SMALLINT) as actve_ind,
			COLLATE(CAST('Direct Mail' AS VARCHAR(255)), 'CASE_INSENSITIVE') as channel,
			COLLATE(CAST('NA' AS VARCHAR(765)), 'CASE_INSENSITIVE') as actvty_specific, -- This was an Aprimo attribute and is set to NA for Adobe treatments
			srcsys_trans_ts as snapshot_ts, -- including this to match Aprimo layout above
			srcsys_trans_ts,
			dw_trans_ts,
			COLLATE(CAST(row_stat_cd AS VARCHAR(50)), 'CASE_INSENSITIVE') as row_stat_cd,
			COLLATE(CAST('ADBE' AS VARCHAR(10)), 'CASE_INSENSITIVE') as appl_src_cd,
			load_id
		FROM mktg_ops_tbls.dim_treatmnt;
		
		TRUNCATE TABLE mktg_ops_tbls.bz_dim_treatmnt;
		
        INSERT INTO mktg_ops_tbls.bz_dim_treatmnt
        SELECT * FROM mktg_stage_tbls.bz_dim_treatmnt_stg;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_ops_tbls.bz_dim_treatmnt) as INTEGER)
        WHERE proc_name = 'ld_bz_dim_treatmnt' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bz_dim_treatmnt: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bz_dim_treatmnt', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
