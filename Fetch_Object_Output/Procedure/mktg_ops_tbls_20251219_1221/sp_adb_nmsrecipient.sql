CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_nmsrecipient()
 LANGUAGE plpgsql
AS $$
/*
Created By: 	Adarsh Ram
Created Date:	11/10/2025
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
	    WHERE process_nm = 'sp_adb_nmsrecipient'
	      AND LOWER(table_nm) = 'adb_nmsrecipient';



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
	    VALUES ('sp_adb_nmsrecipient', 'Stored Procedure', 'Inprogress', v_start_time);


	--step 3: select existing record
		create temp table existingrecord as
		SELECT
	        stg.iaddrerrorcount, stg.iaddrquality, stg.iblacklist, stg.iblacklistemail, stg.iblacklistfax, stg.iblacklistmobile,
	        stg.iblacklistphone, stg.iblacklistpostalmail, stg.iboolean1, stg.iboolean2, stg.iboolean3, stg.iemailformat,
	        stg.ifolderid, stg.igender, stg.irecipientid, stg.istatus, stg.mdata, stg.saccount, stg.saddress1, stg.saddress2,
	        stg.saddress3, stg.saddress4, stg.scity, stg.scompany, stg.scountrycode, stg.semail, stg.sfax, stg.sfirstname,
	        stg.slanguage, stg.slastname, stg.smiddlename, stg.smobilephone, stg.sorigin, stg.sphone, stg.ssalutation,
	        stg.sstatecode, stg.stext1, stg.stext2, stg.stext3, stg.stext4, stg.stext5, stg.szipcode, stg.tsaddrlastcheck,
	        stg.tsbirth, stg.tscreated, stg.tslastmodified, stg.bicnst_mstr_id, stg.birecipientid, stg.dlastdonationamt,
	        stg.iblacklistemail_bio, stg.iblacklistemail_fr, stg.iblacklistemail_phss, stg.iblacklistemail_vms,
	        stg.iblacklistmobile_bio, stg.iblacklistmobile_fr, stg.iblacklistmobile_phss, stg.iblacklistmobile_vms,
	        stg.iblacklistphone_bio, stg.iblacklistphone_fr, stg.iblacklistphone_phss, stg.iblacklistphone_vms,
	        stg.iblacklistpostalmail_bio, stg.iblacklistpostalmail_fr, stg.iblacklistpostalmail_phss, stg.iblacklistpostalmail_vms,
	        stg.iblacklist_bio, stg.iblacklist_fr, stg.iblacklist_phss, stg.iblacklist_vms,
	        stg.ifr_field_unit_dimension_id, stg.ifr_mkt_field_unit_dimension_id, stg.iisbio, stg.iisfr, stg.iisphss, stg.iisvms,
	        stg.saddress1_bio, stg.saddress1_fr, stg.saddress1_phss, stg.saddress1_vms,
	        stg.saddress2_bio, stg.saddress2_fr, stg.saddress2_phss, stg.saddress2_vms,
	        stg.saddress3_bio, stg.saddress3_fr, stg.saddress3_phss, stg.saddress3_vms,
	        stg.saddress4_bio, stg.saddress4_fr, stg.saddress4_phss, stg.saddress4_vms,
	        stg.sbioaddrquality, stg.sbio_em_email, stg.scity_bio, stg.scity_fr, stg.scity_phss, stg.scity_vms,
	        stg.scountrycode_bio, stg.scountrycode_fr, stg.scountrycode_phss, stg.scountrycode_vms,
	        stg.sfraddrquality, stg.sfr_em_email, stg.sline6, stg.smobilephone_bio, stg.smobilephone_fr, stg.smobilephone_phss, stg.smobilephone_vms,
	        stg.sofferorigin, stg.sphone_bio, stg.sphone_fr, stg.sphone_phss, stg.sphone_vms,
	        stg.sphssaddrquality, stg.sphss_em_email, stg.sprofilepicture, stg.srolename,
	        stg.sstatecode_bio, stg.sstatecode_fr, stg.sstatecode_phss, stg.sstatecode_vms,
	        stg.svmsaddrquality, stg.svms_em_email, stg.szipcode_bio, stg.szipcode_fr, stg.szipcode_phss, stg.szipcode_vms,
	        stg.tslastdonation,
	        case when tgt.irecipientid is null then 'I' else 'C' end as row_stat_cd, -- Value for row_stat_cd
	        v_appl_src_cd as appl_src_cd, -- Value for appl_src_cd
	        v_dw_load_id as load_id,     -- Value for load_id
	        CURRENT_DATE as dw_trans_ts    -- Value for dw_trans_ts
	    FROM
	        mods_bi_rep.mktg_stage_tbls.stg_adb_nmsrecipient stg
	    LEFT OUTER JOIN
	        mktg_ops_tbls.adb_nmsrecipient tgt
	    ON
	        stg.irecipientid = tgt.irecipientid;

		---Step 4: delete from tgt where src matches the conditions.

		delete from  mktg_ops_tbls.adb_nmsrecipient
		where irecipientid in (select irecipientid from existingrecord where row_stat_cd='C'); 


    -- Step 5: insert all stg records into tgt-ops table.
    INSERT INTO mktg_ops_tbls.adb_nmsrecipient (
        iaddrerrorcount, iaddrquality, iblacklist, iblacklistemail, iblacklistfax, iblacklistmobile,
        iblacklistphone, iblacklistpostalmail, iboolean1, iboolean2, iboolean3, iemailformat,
        ifolderid, igender, irecipientid, istatus, mdata, saccount, saddress1, saddress2,
        saddress3, saddress4, scity, scompany, scountrycode, semail, sfax, sfirstname,
        slanguage, slastname, smiddlename, smobilephone, sorigin, sphone, ssalutation,
        sstatecode, stext1, stext2, stext3, stext4, stext5, szipcode, tsaddrlastcheck,
        tsbirth, tscreated, tslastmodified, bicnst_mstr_id, birecipientid, dlastdonationamt,
        iblacklistemail_bio, iblacklistemail_fr, iblacklistemail_phss, iblacklistemail_vms,
        iblacklistmobile_bio, iblacklistmobile_fr, iblacklistmobile_phss, iblacklistmobile_vms,
        iblacklistphone_bio, iblacklistphone_fr, iblacklistphone_phss, iblacklistphone_vms,
        iblacklistpostalmail_bio, iblacklistpostalmail_fr, iblacklistpostalmail_phss, iblacklistpostalmail_vms,
        iblacklist_bio, iblacklist_fr, iblacklist_phss, iblacklist_vms,
        ifr_field_unit_dimension_id, ifr_mkt_field_unit_dimension_id, iisbio, iisfr, iisphss, iisvms,
        saddress1_bio, saddress1_fr, saddress1_phss, saddress1_vms,
        saddress2_bio, saddress2_fr, saddress2_phss, saddress2_vms,
        saddress3_bio, saddress3_fr, saddress3_phss, saddress3_vms,
        saddress4_bio, saddress4_fr, saddress4_phss, saddress4_vms,
        sbioaddrquality, sbio_em_email, scity_bio, scity_fr, scity_phss, scity_vms,
        scountrycode_bio, scountrycode_fr, scountrycode_phss, scountrycode_vms,
        sfraddrquality, sfr_em_email, sline6, smobilephone_bio, smobilephone_fr, smobilephone_phss, smobilephone_vms,
        sofferorigin, sphone_bio, sphone_fr, sphone_phss, sphone_vms,
        sphssaddrquality, sphss_em_email, sprofilepicture, srolename,
        sstatecode_bio, sstatecode_fr, sstatecode_phss, sstatecode_vms,
        svmsaddrquality, svms_em_email, szipcode_bio, szipcode_fr, szipcode_phss, szipcode_vms,
        tslastdonation,
        row_stat_cd, appl_src_cd, load_id, dw_trans_ts -- Added these columns
    )
    SELECT
        iaddrerrorcount, iaddrquality, iblacklist, iblacklistemail, iblacklistfax, iblacklistmobile,
        iblacklistphone, iblacklistpostalmail, iboolean1, iboolean2, iboolean3, iemailformat,
        ifolderid, igender, irecipientid, istatus, mdata, saccount, saddress1, saddress2,
        saddress3, saddress4, scity, scompany, scountrycode, semail, sfax, sfirstname,
        slanguage, slastname, smiddlename, smobilephone, sorigin, sphone, ssalutation,
        sstatecode, stext1, stext2, stext3, stext4, stext5, szipcode, tsaddrlastcheck,
        tsbirth, tscreated, tslastmodified, bicnst_mstr_id, birecipientid, dlastdonationamt,
        iblacklistemail_bio, iblacklistemail_fr, iblacklistemail_phss, iblacklistemail_vms,
        iblacklistmobile_bio, iblacklistmobile_fr, iblacklistmobile_phss, iblacklistmobile_vms,
        iblacklistphone_bio, iblacklistphone_fr, iblacklistphone_phss, iblacklistphone_vms,
        iblacklistpostalmail_bio, iblacklistpostalmail_fr, iblacklistpostalmail_phss, iblacklistpostalmail_vms,
        iblacklist_bio, iblacklist_fr, iblacklist_phss, iblacklist_vms,
        ifr_field_unit_dimension_id, ifr_mkt_field_unit_dimension_id, iisbio, iisfr, iisphss, iisvms,
        saddress1_bio, saddress1_fr, saddress1_phss, saddress1_vms,
        saddress2_bio, saddress2_fr, saddress2_phss, saddress2_vms,
        saddress3_bio, saddress3_fr, saddress3_phss, saddress3_vms,
        saddress4_bio, saddress4_fr, saddress4_phss, saddress4_vms,
        sbioaddrquality, sbio_em_email, scity_bio, scity_fr, scity_phss, scity_vms,
        scountrycode_bio, scountrycode_fr, scountrycode_phss, scountrycode_vms,
        sfraddrquality, sfr_em_email, sline6, smobilephone_bio, smobilephone_fr, smobilephone_phss, smobilephone_vms,
        sofferorigin, sphone_bio, sphone_fr, sphone_phss, sphone_vms,
        sphssaddrquality, sphss_em_email, sprofilepicture, srolename,
        sstatecode_bio, sstatecode_fr, sstatecode_phss, sstatecode_vms,
        svmsaddrquality, svms_em_email, szipcode_bio, szipcode_fr, szipcode_phss, szipcode_vms,
        tslastdonation,
        row_stat_cd, appl_src_cd, load_id, dw_trans_ts
    FROM  existingrecord;
    
	
    	GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

	-- Step 6: Get latest timestamp for next run and Update load control	
	   	SELECT COALESCE(MAX(tslastmodified), '9999-01-01'::timestamp)
	    INTO v_next_extract_ts
	    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmsrecipient stg;
		
		CALL etl_config.sp_upsert_load_control(
	        'sp_adb_nmsrecipient', 'adb_nmsrecipient',
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
           proc_name = 'sp_adb_nmsrecipient' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;

	-- Step 8: Insert in audit to Error
	    EXCEPTION
	        WHEN OTHERS THEN
	            v_end_time := CURRENT_TIMESTAMP;
				RAISE NOTICE 'NOTICE: An exception occurred.';
				
	    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('sp_adb_nmsrecipient', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


END;




$$
