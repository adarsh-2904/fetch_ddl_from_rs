CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_nmswebapplogrcpdata()
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
	    WHERE process_nm = 'sp_adb_nmswebapplogrcpdata'
	      AND LOWER(table_nm) = 'adb_nmswebapplogrcpdata';

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
	    VALUES ('sp_adb_nmswebapplogrcpdata', 'Stored Procedure', 'Inprogress', v_start_time);
	
	--step 3: select existing record
		create temp table existingrecord as
		SELECT
	        stg.boolean0, stg.byte0, stg.byte1, stg.byte2, stg.byte3, stg.byte4, stg.byte5, stg.byte6,
	        stg.iwebapplogid,
	        TRIM(REPLACE(stg.mdata, CHR(26), '''')) AS mdata,
	        stg.string0, stg.byte7, stg.byte8, stg.byte9, stg.byte10, stg.byte11, stg.byte12, stg.byte13,
	        stg.byte14, stg.byte15, stg.byte16, stg.byte17, stg.byte18, stg.byte19, stg.byte20, stg.byte21,
	        stg.byte22, stg.byte23, stg.boolean1, stg.boolean10, stg.boolean11, stg.boolean12, stg.boolean13,
	        stg.boolean14, stg.boolean15, stg.boolean16, stg.boolean17, stg.boolean18, stg.boolean19,
	        stg.boolean20, stg.boolean21, stg.boolean22, stg.boolean23, stg.boolean24, stg.boolean25,
	        stg.boolean26, stg.boolean27, stg.boolean28, stg.boolean29, stg.boolean30, stg.boolean31,
	        stg.boolean32, stg.boolean33, stg.boolean2, stg.boolean3, stg.boolean4, stg.boolean5,
	        stg.boolean6, stg.boolean7, stg.boolean8, stg.boolean9, stg.string1, stg.string10,
	        stg.string11, stg.string12, stg.string13, stg.string14, stg.string15, stg.string16,
	        stg.string2, stg.string3, stg.string4, stg.string5, stg.string6, stg.string7, stg.string8,
	        stg.string9, stg.string17, stg.string18, stg.string19, stg.string20, stg.string21,
	        stg.string22, stg.string23, stg.string24, stg.string25, stg.string26, stg.string27,
	        stg.string28, stg.string29, stg.string30, stg.string31, stg.string32, stg.string33,
	        stg.string34, stg.string35, stg.string36, stg.string37, stg.string38, stg.string39,
	        stg.string40, stg.string41, stg.string42, stg.string43, stg.string44, stg.string45,
	        stg.string46, stg.string47, stg.string48, stg.int641, stg.long0, stg.string50,
	        stg.string51, stg.string52, stg.datetime0, stg.string49, stg.string53, stg.string54,
	        stg.string55, stg.string56, stg.string57, stg.string58, stg.string59, stg.string60,
	        stg.string61, stg.string62, stg.string63, stg.string64, stg.string65, stg.string71,
	        stg.string72, stg.string73, stg.string74, stg.string76, stg.string66,
	        case when tgt.iwebapplogid is null then 'I' else 'C' end as row_stat_cd, 
			v_appl_src_cd as appl_src_cd, v_dw_load_id as load_id, 
			CURRENT_DATE as dw_trans_ts
	    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmswebapplogrcpdata stg
	    LEFT OUTER JOIN mktg_ops_tbls.adb_nmswebapplogrcpdata tgt
	        ON stg.iwebapplogid = tgt.iwebapplogid;

	---Step 4: delete from tgt where src matches the conditions.

		delete from  mktg_ops_tbls.adb_nmswebapplogrcpdata
		where iwebapplogid in (select iwebapplogid from existingrecord where row_stat_cd='C'); 


	-- Step 5: insert all stg records into tgt-ops table.
	    INSERT INTO mktg_ops_tbls.adb_nmswebapplogrcpdata (
	        boolean0, byte0, byte1, byte2, byte3, byte4, byte5, byte6,
	        iwebapplogid, mdata,
	        string0, byte7, byte8, byte9, byte10, byte11, byte12, byte13, byte14, byte15,
	        byte16, byte17, byte18, byte19, byte20, byte21, byte22, byte23,
	        boolean1, boolean10, boolean11, boolean12, boolean13, boolean14, boolean15,
	        boolean16, boolean17, boolean18, boolean19, boolean20, boolean21, boolean22,
	        boolean23, boolean24, boolean25, boolean26, boolean27, boolean28, boolean29,
	        boolean30, boolean31, boolean32, boolean33, boolean2, boolean3, boolean4,
	        boolean5, boolean6, boolean7, boolean8, boolean9,
	        string1, string10, string11, string12, string13, string14, string15, string16,
	        string2, string3, string4, string5, string6, string7, string8, string9,
	        string17, string18, string19, string20, string21, string22, string23, string24,
	        string25, string26, string27, string28, string29, string30, string31, string32,
	        string33, string34, string35, string36, string37, string38, string39, string40,
	        string41, string42, string43, string44, string45, string46, string47, string48,
	        int641, long0, string50, string51, string52, datetime0, string49, string53,
	        string54, string55, string56, string57, string58, string59, string60, string61,
	        string62, string63, string64, string65, string71, string72, string73, string74,
	        string76, string66,
	        row_stat_cd, appl_src_cd, load_id, dw_trans_ts
	    )
	    SELECT
	         boolean0, byte0, byte1, byte2, byte3, byte4, byte5, byte6,
	        iwebapplogid, mdata,
	        string0, byte7, byte8, byte9, byte10, byte11, byte12, byte13, byte14, byte15,
	        byte16, byte17, byte18, byte19, byte20, byte21, byte22, byte23,
	        boolean1, boolean10, boolean11, boolean12, boolean13, boolean14, boolean15,
	        boolean16, boolean17, boolean18, boolean19, boolean20, boolean21, boolean22,
	        boolean23, boolean24, boolean25, boolean26, boolean27, boolean28, boolean29,
	        boolean30, boolean31, boolean32, boolean33, boolean2, boolean3, boolean4,
	        boolean5, boolean6, boolean7, boolean8, boolean9,
	        string1, string10, string11, string12, string13, string14, string15, string16,
	        string2, string3, string4, string5, string6, string7, string8, string9,
	        string17, string18, string19, string20, string21, string22, string23, string24,
	        string25, string26, string27, string28, string29, string30, string31, string32,
	        string33, string34, string35, string36, string37, string38, string39, string40,
	        string41, string42, string43, string44, string45, string46, string47, string48,
	        int641, long0, string50, string51, string52, datetime0, string49, string53,
	        string54, string55, string56, string57, string58, string59, string60, string61,
	        string62, string63, string64, string65, string71, string72, string73, string74,
	        string76, string66,
	        row_stat_cd, appl_src_cd, load_id, dw_trans_ts
	    FROM existingrecord;

    	GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
	
	-- Step 6: Get latest timestamp for next run and Update load control	
	   	SELECT COALESCE(MAX(dw_trans_ts), '9999-01-01'::timestamp)
	    INTO v_next_extract_ts
	    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmswebapplogrcpdata stg;
		
		CALL etl_config.sp_upsert_load_control(
	        'sp_adb_nmswebapplogrcpdata', 'sp_adb_nmswebapplogrcpdata',
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
           proc_name = 'sp_adb_nmswebapplogrcpdata' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;

	-- Step 8: Insert in audit to Error
	    EXCEPTION
	        WHEN OTHERS THEN
	            v_end_time := CURRENT_TIMESTAMP;
				RAISE NOTICE 'NOTICE: An exception occurred.';
				
	    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('sp_adb_nmswebapplogrcpdata', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
END;




$$
