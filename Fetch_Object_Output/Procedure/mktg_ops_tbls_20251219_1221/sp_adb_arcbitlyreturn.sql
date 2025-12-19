CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_arcbitlyreturn()
 LANGUAGE plpgsql
AS $$


/*
Created By: 	Hitansu Sahoo
Created Date:	10/31/2025
Purpose: Creating a stored procedure from Informatica existing code. */
	
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
    WHERE process_nm = 'sp_adb_arcbitlyreturn'
      AND LOWER(table_nm) = 'adb_accistbl_contacts';

    -- Step 2: Set default values if null
    IF v_appl_src_cd IS NULL THEN
        v_appl_src_cd := 'ADBE';
    END IF;
    IF v_dw_load_id IS NULL THEN
        v_dw_load_id := 101;
    END IF;
	
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('sp_adb_arcbitlyreturn', 'Stored Procedure', 'Inprogress', v_start_time);	
	
	--step 3: Prep temp data to bulk insert
--drop table if exists existingrecord;
	create temp table existingrecord as
   SELECT
        stg.iBitlyReturnId,
        stg.iCreatedById,
        stg.iDelProduct,
        stg.iDonorClickCount,
        stg.iDonorCount,
        stg.iModifiedById,
        stg.iOptOutCount,
        stg.iRepliesCount,
        stg.sCampaignLabel,
        stg.sCampaignName,
        stg.sDelNature,
        stg.sDeliveryLabel,
        stg.sDeliveryName,
        stg.tsCreated,
        stg.tsLastModified,
        stg.tsLaunch,
        case when tgt.iBitlyReturnId is null then 'I' else 'C' end as row_stat_cd,
        v_appl_src_cd as appl_src_cd,
        v_dw_load_id as load_id,
        CURRENT_DATE
    FROM
        mods_bi_rep.mktg_stage_tbls.stg_adb_ArcBitlyReturn stg
		 LEFT OUTER JOIN mktg_ops_tbls.adb_arcbitlyreturn tgt
		ON stg.iBitlyReturnId = tgt.iBitlyReturnId;
	
    ---New step: delete from tgt where src matches the conditions.
	DELETE FROM mktg_ops_tbls.adb_arcbitlyreturn
	USING mods_bi_rep.mktg_stage_tbls.stg_adb_ArcBitlyReturn
	WHERE mods_bi_rep.mktg_stage_tbls.stg_adb_ArcBitlyReturn.iBitlyReturnId = mktg_ops_tbls.adb_arcbitlyreturn.ibitlyreturnid;

	-- Step 3: insert all stg records into tgt-ops table.
    INSERT INTO mktg_ops_tbls.adb_arcbitlyreturn (
        ibitlyreturnid,
        icreatedbyid,
        idelproduct,
        idonorclickcount,
        idonorcount,
        imodifiedbyid,
        ioptoutcount,
        irepliescount,
        scampaignlabel,
        scampaignname,
        sdelnature,
        sdeliverylabel,
        sdeliveryname,
        tscreated,
        tslastmodified,
        tslaunch,
        row_stat_cd,
        appl_src_cd,
        load_id,
        dw_trans_ts
    )
    SELECT
        stg.iBitlyReturnId,
        stg.iCreatedById,
        stg.iDelProduct,
        stg.iDonorClickCount,
        stg.iDonorCount,
        stg.iModifiedById,
        stg.iOptOutCount,
        stg.iRepliesCount,
        stg.sCampaignLabel,
        stg.sCampaignName,
        stg.sDelNature,
        stg.sDeliveryLabel,
        stg.sDeliveryName,
        stg.tsCreated,
        stg.tsLastModified,
        stg.tsLaunch,
        stg.row_stat_cd,
        stg.appl_src_cd,
        stg.load_id,
        CURRENT_DATE
    FROM
        existingrecord stg;
		
		
	GET DIAGNOSTICS v_inserted_count = ROW_COUNT;	
	
	    -- Step 6: Get latest timestamp for next run and Update load control	
    SELECT MAX(tslastmodified)--modified to dw_trans_ts from tslastmodified
    INTO v_next_extract_ts
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_ArcBitlyReturn;

    	
    CALL etl_config.sp_upsert_load_control(
        'sp_adb_arcbitlyreturn', 'adb_arcbitlyreturn',--this will be updated in every stored proc
        v_next_extract_ts, v_appl_src_cd, v_dw_load_id
		);
		
	--audit update	
			v_end_time := GETDATE();
            v_ok_message := '';
			
		UPDATE mods_bi.etl_config.audit_log
       	SET 
           status = 'Complete',
           end_time = v_end_time,
           TaskMessage = v_ok_message,
           recs_processed = v_inserted_count
       WHERE 
           proc_name = 'sp_adb_arcbitlyreturn' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;
	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('sp_adb_arcbitlyreturn', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
END;


$$
