CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_nmsaddress()
 LANGUAGE plpgsql
AS $$

/*
Created By: 	Adarsh Ram
Created Date:	11/05/2025
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
	    WHERE process_nm = 'sp_adb_nmsaddress'
	      AND LOWER(table_nm) = 'adb_nmsaddress';

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
	    VALUES ('sp_adb_nmsaddress', 'Stored Procedure', 'Inprogress', v_start_time);

		--step 3: select existing record
		create temp table existingrecord as
			SELECT 
	        stg.iaddressid, 
	        stg.iconsecutiveerror, 
	        stg.ideliveryid, 
	        stg.iquarantinereason, 
	        stg.istatus, 
	        stg.itype, 
	        stg.mquarantinetext, 
	        stg.saddress, 
	        stg.tscreated, 
	        stg.tslasterror, 
	        stg.tslastmodified,
			stg.dw_trans_ts,
			case when tgt.iaddressid is null then 'I' else 'C' end as row_stat_cd,
			stg.appl_src_cd,
			stg.load_id
		FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmsaddress stg
             LEFT OUTER JOIN mktg_ops_tbls.adb_nmsaddress tgt
    		ON stg.iaddressid = tgt.iaddressid;
        

			

		---Step 4: delete from tgt where src matches the conditions.

		delete from  mktg_ops_tbls.adb_nmsaddress
		where iaddressid in (select iaddressid from existingrecord where row_stat_cd='C'); 


--		DELETE select * from mktg_ops_tbls.adb_nmsaddress
--		USING  mods_bi_rep.mktg_stage_tbls.stg_adb_nmsaddress stg
--		WHERE stg.iaddressid = mktg_ops_tbls.adb_nmsaddres.iaddressid;

		-- Step 5: insert all stg records into tgt-ops table.
	    INSERT INTO mktg_ops_tbls.adb_nmsaddress (
	        iaddressid, iconsecutiveerror, ideliveryid, iquarantinereason, istatus, itype, 
	        mquarantinetext, saddress, tscreated, tslasterror, tslastmodified, dw_trans_ts, row_stat_cd, appl_src_cd, load_id
	    )
	    SELECT * from existingrecord;


		GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

		-- Step 6: Get latest timestamp for next run and Update load control	
	   	SELECT COALESCE(MAX(tslastmodified), '9999-01-01'::timestamp)
	    INTO v_next_extract_ts
	    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmsaddress stg;
		
		CALL etl_config.sp_upsert_load_control(
	        'sp_adb_nmsaddress', 'adb_nmsaddress',
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
           proc_name = 'sp_adb_nmsaddress' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;

		-- Step 8: Insert in audit to Error
	    EXCEPTION
	        WHEN OTHERS THEN
	            v_end_time := CURRENT_TIMESTAMP;
				RAISE NOTICE 'NOTICE: An exception occurred.';
				
	    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('sp_adb_nmsaddress', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


END;

$$
