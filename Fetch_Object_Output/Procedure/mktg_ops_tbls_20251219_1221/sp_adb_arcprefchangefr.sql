CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_arcprefchangefr()
 LANGUAGE plpgsql
AS $$
/*
Created By: 	Hitansu Sahoo
Created Date:	11/05/2025
Purpose: Creating a stored procedure from Informatica existing code. 

Q: Do we have historical loads on the stg tables in adb or is it 
	delete all and fresh insert everytime in the stg tables?
A: Yes its a fresh insert everytime.	
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
    WHERE process_nm = 'sp_adb_arcprefchangefr'
      AND LOWER(table_nm) = 'adb_arcprefchangefr';

    -- Step 2: Set default values if null
    IF v_appl_src_cd IS NULL THEN
        v_appl_src_cd := 'ADBE';
    END IF;
    IF v_dw_load_id IS NULL THEN
        v_dw_load_id := 101;
    END IF;

	-- Step 2b: insert audit log InProgress status 
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('sp_adb_arcprefchangefr', 'Stored Procedure', 'Inprogress', v_start_time);	

	--step 3: Prep temp data to bulk insert
--drop table if exists existingrecord;
	create temp table existingrecord as
    SELECT
        stg.iBlackListEmail_fr, stg.iDeliveryId, stg.iPrefChangeFRId, stg.iRecipientId,
        stg.sFr_em_email, stg.tsLastModified, CURRENT_TIMESTAMP,
        case when tgt.iPrefChangeFRId is null then 'I' else 'C' end as row_stat_cd,
		v_appl_src_cd, v_dw_load_id as load_id
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_arcprefchangefr stg
		 LEFT OUTER JOIN mktg_ops_tbls.adb_arcprefchangefr tgt
		ON stg.iPrefChangeFRId = tgt.iPrefChangeFRId;
		
    ---Step 3: delete from tgt where src matches the conditions.
	DELETE FROM mktg_ops_tbls.adb_arcprefchangefr
	USING mods_bi_rep.mktg_stage_tbls.stg_adb_arcprefchangefr stg
	WHERE stg.iPrefChangeFRId = mktg_ops_tbls.adb_arcprefchangefr.iPrefChangeFRId;


    --Step 4: insert all stg records into tgt-ops table.
    INSERT INTO mktg_ops_tbls.adb_arcprefchangefr (
        iBlackListEmail_fr, iDeliveryId, iPrefChangeFRId, iRecipientId,
        sFr_em_email, tsLastModified, dw_trans_ts, row_stat_cd,
        appl_src_cd, load_id
    )
    SELECT
        stg.iBlackListEmail_fr, stg.iDeliveryId, stg.iPrefChangeFRId, stg.iRecipientId,
        stg.sFr_em_email, stg.tsLastModified, CURRENT_TIMESTAMP,
        stg.row_stat_cd, v_appl_src_cd, stg.load_id
    FROM existingrecord stg;
    
    -- Capture number of rows inserted
    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

    -- Step 5: Get latest timestamp for next run and Update load control	
    SELECT MAX(tsLastModified)
    INTO v_next_extract_ts
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_arcprefchangefr;

    --  Update load control
    CALL etl_config.sp_upsert_load_control(
        'sp_adb_arcprefchangefr', 'adb_arcprefchangefr',
        v_next_extract_ts, v_appl_src_cd, v_dw_load_id
    );
	drop table existingrecord;
-- Step 6: Audit update	
			v_end_time := GETDATE();
            v_ok_message := '';
			
		UPDATE mods_bi.etl_config.audit_log
       	SET 
           status = 'Complete',
           end_time = v_end_time,
           TaskMessage = v_ok_message,
           recs_processed = v_inserted_count
       WHERE 
           proc_name = 'sp_adb_arcprefchangefr' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;
	-- Step 7: Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('sp_adb_arcprefchangefr', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

END;


$$
