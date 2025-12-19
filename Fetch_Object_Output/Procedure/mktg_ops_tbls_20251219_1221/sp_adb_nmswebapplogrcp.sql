CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_nmswebapplogrcp()
 LANGUAGE plpgsql
AS $$
/*
Created By: 	Adarsh Ram
Created Date:	11/11/2025
Purpose: Creating a stored procedure from Informatica existing code. 

	
*/	
	
	
DECLARE
    v_increment_ts TIMESTAMP;
    v_appl_src_cd VARCHAR(4);
    v_dw_load_id INT;
    v_next_extract_ts TIMESTAMP;
    v_start_time TIMESTAMP := CURRENT_TIMESTAMP;
	v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
    v_inserted_count INT := 0;


BEGIN

	-- Step 1: Fetch parameters from control table
	    SELECT next_begin_dt, appl_src_cd, load_id + 1
	    INTO v_increment_ts, v_appl_src_cd, v_dw_load_id
	    FROM etl_config.load_cntl_tbl
	    WHERE process_nm = 'sp_adb_nmswebapplogrcp'
	      AND LOWER(table_nm) = 'adb_nmswebapplogrcp';

	-- Step 2a: Set default values if null
	    IF v_appl_src_cd IS NULL THEN
	        v_appl_src_cd := 'ADBE';
	    END IF;
	    IF v_dw_load_id IS NULL THEN
	        v_dw_load_id := 101;
	    END IF;

	-- Step 2b: insert audit log InProgress status 
		v_start_time := CURRENT_TIMESTAMP;
		INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
	    VALUES ('sp_adb_nmswebapplogrcp', 'Stored Procedure', 'Inprogress', v_start_time);

	--step 3: select existing record
		create temp table existingrecord as
		SELECT
	        stg.dscore, stg.icreation, stg.ideliveryid, stg.irecipientid, 
	        stg.iwebappid, stg.iwebapplogrcpid, stg.slanguage, stg.sorigin, 
	        stg.tslog, CURRENT_DATE as dw_trans_ts, 
			case when tgt.iwebapplogrcpid is null then 'I' else 'C' end as row_stat_cd,
			v_appl_src_cd as appl_src_cd, v_dw_load_id as load_id
	    FROM
	        mods_bi_rep.mktg_stage_tbls.stg_adb_nmswebapplogrcp stg
	    LEFT OUTER JOIN
	        mktg_ops_tbls.adb_nmswebapplogrcp tgt
	        ON stg.iwebapplogrcpid = tgt.iwebapplogrcpid;

	---Step 4: delete from tgt where src matches the conditions.

		delete from  mktg_ops_tbls.adb_nmswebapplogrcp
		where iwebapplogrcpid in (select iwebapplogrcpid from existingrecord where row_stat_cd='C');

    -- Step 5: insert all stg records into tgt-ops table.
	    INSERT INTO mktg_ops_tbls.adb_nmswebapplogrcp (
	        dscore, icreation, ideliveryid, irecipientid, 
	        iwebappid, iwebapplogrcpid, slanguage, sorigin, 
	        tslog, dw_trans_ts, row_stat_cd, appl_src_cd, load_id
	    )
	    SELECT
	        dscore, icreation, ideliveryid, irecipientid, 
	        iwebappid, iwebapplogrcpid, slanguage, sorigin, 
	        tslog, dw_trans_ts, row_stat_cd, appl_src_cd, load_id
	    FROM existingrecord;

		GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

	-- Step 6: Get latest timestamp for next run and Update load control	
	   	SELECT COALESCE(MAX(dw_trans_ts), '9999-01-01'::timestamp)
	    INTO v_next_extract_ts
	    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmswebapplogrcp stg;
		
		CALL etl_config.sp_upsert_load_control(
	        'sp_adb_nmswebapplogrcp', 'adb_nmswebapplogrcp',
	        v_next_extract_ts, v_appl_src_cd, v_dw_load_id
	    );
        drop table existingrecord;

    -- Step 7: Audit update	
			v_end_time := GETDATE();
            v_ok_message := '';
			
		UPDATE mods_bi.etl_config.audit_log
       	SET 
           status = 'Complete',
           end_time = v_end_time,
           TaskMessage = v_ok_message,
           recs_processed = v_inserted_count
       WHERE 
           proc_name = 'sp_adb_nmswebapplogrcp' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;

	-- Step 8: Insert in audit to Error
	    EXCEPTION
	        WHEN OTHERS THEN
	            v_end_time := CURRENT_TIMESTAMP;
				RAISE NOTICE 'NOTICE: An exception occurred.';
				
	    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('sp_adb_nmswebapplogrcp', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

END;



$$
