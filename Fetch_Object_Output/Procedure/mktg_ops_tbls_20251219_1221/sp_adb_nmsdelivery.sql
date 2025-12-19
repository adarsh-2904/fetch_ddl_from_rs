CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_nmsdelivery()
 LANGUAGE plpgsql
AS $$
	
/*
Created By: 	Hitansu Sahoo
Created Date:	11/07/2025
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
    WHERE process_nm = 'sp_adb_nmsdelivery'
      AND LOWER(table_nm) = 'adb_nmsdelivery';

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
    VALUES ('sp_adb_nmsdelivery', 'Stored Procedure', 'Inprogress', v_start_time);	
	
	--step 3: Prep temp data to bulk insert
--drop table if exists existingrecord;
		create temp table existingrecord as
			SELECT 
 stg.damount, stg.dcomputedcost, stg.ddelayextraction, stg.dduration, stg.destimatedcost, stg.drate, stg.drealcost, stg.dretryperiod, stg.dtotalestimatedmargin, stg.dtotalestimatedrealized,
        stg.ianalysisstep, stg.iarticle, stg.iassignedition, stg.ibudgetid, stg.ibudgetstatus, stg.ibuiltin, stg.icommitmentlevel, stg.icomputationstate, stg.icontentstatus, stg.icreatedbyid,
        stg.ictrlgrpreject, stg.icurrentorderid, stg.idelayed, stg.ideletestatus, stg.ideliveryid, stg.ideliverymode, stg.ideliveryoutlineid, stg.ideliveryproviderid, stg.idirty,
        stg.idisablenotification, stg.idisabled, stg.ierror, stg.ierrorpending, stg.iexternalvalidation, stg.iextractionstatus, stg.ifcp, stg.ifcporseedcount, stg.ifolderid, stg.ifolderprocessid,
        stg.iforecasted, stg.iforward, stg.ihasattachments, stg.ihtml, stg.iimportreject, stg.iinsertmode, stg.iinvaliddomain, stg.iismodel, stg.ilinkeddeliveryid, stg.imailboxfull, stg.imappingid,
        stg.imaxretry, stg.imessagetype, stg.imidremoteid, stg.imidsourcing, stg.imirrorpage, stg.imodifiedbyid, stg.imsgpriority, stg.imultipart, stg.ineedmirrorpage, stg.inewquarantine,
        stg.inotconnected, stg.iofferanonymouscategoryid, stg.ioffercategoryid, stg.iofferspaceid, stg.ioperationid, stg.ioptout, stg.iowneroperationid, stg.ipersonclick, stg.ipriority,
        stg.iprocessed, stg.iproofeddeliveryid, stg.ipropositioncount, stg.irecipientclick, stg.irecipientopen, stg.irecurringdeliveryid, stg.irefused, stg.ireject, stg.iretry, stg.iroutingdeliveryid,
        stg.isandboxmode, stg.isandboxstatus, stg.iseedprocessed, stg.isent, stg.istate, stg.istatus, stg.isuccess, stg.isuccesswithoutseeds, stg.isuppliermodelid, stg.itargetstatus, stg.itext,
        stg.itodeliver, stg.itovalidate, stg.itotalrecipientclick, stg.itotalrecipientopen, stg.itotalwebpage, stg.itrackingpending, stg.itransaction, stg.itypologyid, stg.iunknownuser,
        stg.iunreachable, stg.iurl, stg.iusebudgetvalidation, stg.iusecontentvalidation, stg.iusedce, stg.iuseextractionvalidation, stg.iusefcpvalidation, stg.iuselinkeddeliveryvalidation,
        stg.iusetargetvalidation, stg.ivalidationmode, stg.iwebpage, stg.iwebrespurged, stg.iweight, stg.iweighttype, stg.iworkflowid, stg.mdata, stg.sdeliverycode, stg.sdesc, stg.sipaffinity,
        stg.sinternalname, stg.sjobtype, stg.slabel, stg.slogin, stg.snature, stg.svalidationmode, stg.sxtkschema, stg.tsbroadend, stg.tsbroadstart, stg.tscontact, stg.tscontentmodtime, stg.tscreated,
        stg.tsdelete, stg.tsend, stg.tsexpectedbudget, stg.tsexpectedcontent, stg.tsexpectededition, stg.tsexpectedexternal, stg.tsexpectedextraction, stg.tsexpectedfcp, stg.tsexpectedforecast,
        stg.tsexpectedtarget, stg.tsextracted, stg.tsextraction, stg.tslastcomputed, stg.tslasterrorcomputation, stg.tslastmodified, stg.tslasttrackingcomputation, stg.tsnextpass,
        stg.tspassstart, stg.tsreminderbudget, stg.tsremindercontent, stg.tsreminderedition, stg.tsreminderexternal, stg.tsreminderextraction, stg.tsreminderfcp, stg.tsreminderforecast,
        stg.tsremindertarget, stg.tsscenariomodtime, stg.tsstart, stg.tsvalidity, stg.tswebvalidity, stg.spublishingname, stg.spublishingnamespace, stg.ipublicationstatus, stg.seventtype,
        stg.dtotalmargin, stg.dtotalrealized, stg.icmsaccountid, stg.iusetaskcreation, stg.iwebanalyticsaccountid, stg.scampaignsourcecode, stg.streatmentsubsourcecode, stg.tsmaildrop,
        stg.ixpromoindicator, stg.ihidemessageflag, stg.iistriggeredmessageindicator, stg.scid, stg.sxpromofrom, stg.sxpromoto,
        case when tgt.ideliveryid is null then 'I' else 'C' end as row_stat_cd, v_appl_src_cd as appl_src_cd, v_dw_load_id as load_id, CURRENT_DATE

		FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmsdelivery stg
             LEFT OUTER JOIN mktg_ops_tbls.adb_nmsdelivery tgt
    		ON stg.ideliveryid = tgt.ideliveryid;
	
    ---Step 3: delete from tgt where src matches the conditions.
	DELETE FROM mktg_ops_tbls.adb_nmsdelivery
	USING mods_bi_rep.mktg_stage_tbls.stg_adb_nmsdelivery stg
	WHERE stg.ideliveryid = mktg_ops_tbls.adb_nmsdelivery.ideliveryid;	
	
	
	
	-- Step 4: insert all stg records into tgt-ops table.
    INSERT INTO mktg_ops_tbls.adb_nmsdelivery (
        damount, dcomputedcost, ddelayextraction, dduration, destimatedcost, drate, drealcost, dretryperiod, dtotalestimatedmargin, dtotalestimatedrealized,
        ianalysisstep, iarticle, iassignedition, ibudgetid, ibudgetstatus, ibuiltin, icommitmentlevel, icomputationstate, icontentstatus, icreatedbyid,
        ictrlgrpreject, icurrentorderid, idelayed, ideletestatus, ideliveryid, ideliverymode, ideliveryoutlineid, ideliveryproviderid, idirty,
        idisablenotification, idisabled, ierror, ierrorpending, iexternalvalidation, iextractionstatus, ifcp, ifcporseedcount, ifolderid, ifolderprocessid,
        iforecasted, iforward, ihasattachments, ihtml, iimportreject, iinsertmode, iinvaliddomain, iismodel, ilinkeddeliveryid, imailboxfull, imappingid,
        imaxretry, imessagetype, imidremoteid, imidsourcing, imirrorpage, imodifiedbyid, imsgpriority, imultipart, ineedmirrorpage, inewquarantine,
        inotconnected, iofferanonymouscategoryid, ioffercategoryid, iofferspaceid, ioperationid, ioptout, iowneroperationid, ipersonclick, ipriority,
        iprocessed, iproofeddeliveryid, ipropositioncount, irecipientclick, irecipientopen, irecurringdeliveryid, irefused, ireject, iretry, iroutingdeliveryid,
        isandboxmode, isandboxstatus, iseedprocessed, isent, istate, istatus, isuccess, isuccesswithoutseeds, isuppliermodelid, itargetstatus, itext,
        itodeliver, itovalidate, itotalrecipientclick, itotalrecipientopen, itotalwebpage, itrackingpending, itransaction, itypologyid, iunknownuser,
        iunreachable, iurl, iusebudgetvalidation, iusecontentvalidation, iusedce, iuseextractionvalidation, iusefcpvalidation, iuselinkeddeliveryvalidation,
        iusetargetvalidation, ivalidationmode, iwebpage, iwebrespurged, iweight, iweighttype, iworkflowid, mdata, sdeliverycode, sdesc, sipaffinity,
        sinternalname, sjobtype, slabel, slogin, snature, svalidationmode, sxtkschema, tsbroadend, tsbroadstart, tscontact, tscontentmodtime, tscreated,
        tsdelete, tsend, tsexpectedbudget, tsexpectedcontent, tsexpectededition, tsexpectedexternal, tsexpectedextraction, tsexpectedfcp, tsexpectedforecast,
        tsexpectedtarget, tsextracted, tsextraction, tslastcomputed, tslasterrorcomputation, tslastmodified, tslasttrackingcomputation, tsnextpass,
        tspassstart, tsreminderbudget, tsremindercontent, tsreminderedition, tsreminderexternal, tsreminderextraction, tsreminderfcp, tsreminderforecast,
        tsremindertarget, tsscenariomodtime, tsstart, tsvalidity, tswebvalidity, spublishingname, spublishingnamespace, ipublicationstatus, seventtype,
        dtotalmargin, dtotalrealized, icmsaccountid, iusetaskcreation, iwebanalyticsaccountid, scampaignsourcecode, streatmentsubsourcecode, tsmaildrop,
        ixpromoindicator, ihidemessageflag, iistriggeredmessageindicator, scid, sxpromofrom, sxpromoto,
        row_stat_cd, appl_src_cd, load_id, dw_trans_ts
    )
    SELECT
        stg.damount, stg.dcomputedcost, stg.ddelayextraction, stg.dduration, stg.destimatedcost, stg.drate, stg.drealcost, stg.dretryperiod, stg.dtotalestimatedmargin, stg.dtotalestimatedrealized,
        stg.ianalysisstep, stg.iarticle, stg.iassignedition, stg.ibudgetid, stg.ibudgetstatus, stg.ibuiltin, stg.icommitmentlevel, stg.icomputationstate, stg.icontentstatus, stg.icreatedbyid,
        stg.ictrlgrpreject, stg.icurrentorderid, stg.idelayed, stg.ideletestatus, stg.ideliveryid, stg.ideliverymode, stg.ideliveryoutlineid, stg.ideliveryproviderid, stg.idirty,
        stg.idisablenotification, stg.idisabled, stg.ierror, stg.ierrorpending, stg.iexternalvalidation, stg.iextractionstatus, stg.ifcp, stg.ifcporseedcount, stg.ifolderid, stg.ifolderprocessid,
        stg.iforecasted, stg.iforward, stg.ihasattachments, stg.ihtml, stg.iimportreject, stg.iinsertmode, stg.iinvaliddomain, stg.iismodel, stg.ilinkeddeliveryid, stg.imailboxfull, stg.imappingid,
        stg.imaxretry, stg.imessagetype, stg.imidremoteid, stg.imidsourcing, stg.imirrorpage, stg.imodifiedbyid, stg.imsgpriority, stg.imultipart, stg.ineedmirrorpage, stg.inewquarantine,
        stg.inotconnected, stg.iofferanonymouscategoryid, stg.ioffercategoryid, stg.iofferspaceid, stg.ioperationid, stg.ioptout, stg.iowneroperationid, stg.ipersonclick, stg.ipriority,
        stg.iprocessed, stg.iproofeddeliveryid, stg.ipropositioncount, stg.irecipientclick, stg.irecipientopen, stg.irecurringdeliveryid, stg.irefused, stg.ireject, stg.iretry, stg.iroutingdeliveryid,
        stg.isandboxmode, stg.isandboxstatus, stg.iseedprocessed, stg.isent, stg.istate, stg.istatus, stg.isuccess, stg.isuccesswithoutseeds, stg.isuppliermodelid, stg.itargetstatus, stg.itext,
        stg.itodeliver, stg.itovalidate, stg.itotalrecipientclick, stg.itotalrecipientopen, stg.itotalwebpage, stg.itrackingpending, stg.itransaction, stg.itypologyid, stg.iunknownuser,
        stg.iunreachable, stg.iurl, stg.iusebudgetvalidation, stg.iusecontentvalidation, stg.iusedce, stg.iuseextractionvalidation, stg.iusefcpvalidation, stg.iuselinkeddeliveryvalidation,
        stg.iusetargetvalidation, stg.ivalidationmode, stg.iwebpage, stg.iwebrespurged, stg.iweight, stg.iweighttype, stg.iworkflowid, stg.mdata, stg.sdeliverycode, stg.sdesc, stg.sipaffinity,
        stg.sinternalname, stg.sjobtype, stg.slabel, stg.slogin, stg.snature, stg.svalidationmode, stg.sxtkschema, stg.tsbroadend, stg.tsbroadstart, stg.tscontact, stg.tscontentmodtime, stg.tscreated,
        stg.tsdelete, stg.tsend, stg.tsexpectedbudget, stg.tsexpectedcontent, stg.tsexpectededition, stg.tsexpectedexternal, stg.tsexpectedextraction, stg.tsexpectedfcp, stg.tsexpectedforecast,
        stg.tsexpectedtarget, stg.tsextracted, stg.tsextraction, stg.tslastcomputed, stg.tslasterrorcomputation, stg.tslastmodified, stg.tslasttrackingcomputation, stg.tsnextpass,
        stg.tspassstart, stg.tsreminderbudget, stg.tsremindercontent, stg.tsreminderedition, stg.tsreminderexternal, stg.tsreminderextraction, stg.tsreminderfcp, stg.tsreminderforecast,
        stg.tsremindertarget, stg.tsscenariomodtime, stg.tsstart, stg.tsvalidity, stg.tswebvalidity, stg.spublishingname, stg.spublishingnamespace, stg.ipublicationstatus, stg.seventtype,
        stg.dtotalmargin, stg.dtotalrealized, stg.icmsaccountid, stg.iusetaskcreation, stg.iwebanalyticsaccountid, stg.scampaignsourcecode, stg.streatmentsubsourcecode, stg.tsmaildrop,
        stg.ixpromoindicator, stg.ihidemessageflag, stg.iistriggeredmessageindicator, stg.scid, stg.sxpromofrom, stg.sxpromoto,
        stg.row_stat_cd, stg.appl_src_cd, stg.load_id, CURRENT_DATE
    FROM existingrecord stg;
	
    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;


   -- Step 5: Get latest timestamp for next run and Update load control	
    SELECT MAX(dw_trans_ts)--modified to dw_trans_ts from tslastmodified
    INTO v_next_extract_ts
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmsdelivery;

    	
    CALL etl_config.sp_upsert_load_control(
        'sp_adb_nmsdelivery', 'adb_nmsdelivery',--this will be updated in every stored proc
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
           proc_name = 'sp_adb_nmsdelivery' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;
	-- Step 7: Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('sp_adb_nmsdelivery', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

END;

$$
