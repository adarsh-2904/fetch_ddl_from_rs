CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_accistbl_contacts()
 LANGUAGE plpgsql
AS $$
/*
Created By: 	Hitansu Sahoo
Created Date:	10/30/2025
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
    WHERE process_nm = 'sp_adb_accistbl_contacts'
      AND LOWER(table_nm) = 'adb_accistbl_contacts';

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
    VALUES ('sp_adb_accistbl_contacts', 'Stored Procedure', 'Inprogress', v_start_time);	
	
		--step 3: Prep temp data to bulk insert
--drop table if exists existingrecord;
	create temp table existingrecord as
    SELECT
        stg.icreatedbyid, stg.imodifiedbyid, stg.iorgentityid, stg.irecipientid,
        stg.tscreated, stg.tslastmodified, case when tgt.irecipientid is null then 'I' else 'C' end as row_stat_cd,
		v_appl_src_cd as appl_src_cd,
        v_dw_load_id as dw_load_id, CURRENT_TIMESTAMP as dw_trans_ts
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_accistbl_contacts stg
		 LEFT OUTER JOIN mktg_ops_tbls.adb_accistbl_contacts tgt
		ON stg.irecipientid = tgt.irecipientid;
		
    ---Step 3: delete from tgt where src matches the conditions.
	DELETE FROM mktg_ops_tbls.adb_accistbl_contacts
	USING mods_bi_rep.mktg_stage_tbls.stg_adb_accistbl_contacts stg
	WHERE stg.iorgentityid = mktg_ops_tbls.adb_accistbl_contacts.iorgentityid
	AND stg.irecipientid = mktg_ops_tbls.adb_accistbl_contacts.irecipientid;

    -- Step 4: insert all stg records into tgt-ops table.
    INSERT INTO mktg_ops_tbls.adb_accistbl_contacts (
        icreatedbyid, imodifiedbyid, iorgentityid, irecipientid,
        tscreated, tslastmodified, row_stat_cd, appl_src_cd,
        load_id, dw_trans_ts
    )
    SELECT
        stg.icreatedbyid, stg.imodifiedbyid, stg.iorgentityid, stg.irecipientid,
        stg.tscreated, stg.tslastmodified, stg.row_stat_cd, stg.appl_src_cd,
        stg.dw_load_id, stg.dw_trans_ts
    FROM existingrecord stg;


    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

    -- Step 5: Get latest timestamp for next run and Update load control	
    SELECT MAX(tslastmodified)
    INTO v_next_extract_ts
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_accistbl_contacts;

    drop table existingrecord;	
    CALL etl_config.sp_upsert_load_control(
        'sp_adb_accistbl_contacts', 'adb_accistbl_contacts',--this will be updated in every stored proc
        v_next_extract_ts, v_appl_src_cd, v_dw_load_id
    );


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
           proc_name = 'sp_adb_accistbl_contacts' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;
	-- Step 7: Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('sp_adb_accistbl_contacts', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

END;

$$
