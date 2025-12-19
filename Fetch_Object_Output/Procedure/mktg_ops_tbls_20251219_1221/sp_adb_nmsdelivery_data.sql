CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_nmsdelivery_data()
 LANGUAGE plpgsql
AS $$
	
	
	
	DECLARE inserted_count INT;

BEGIN
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
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmsdelivery stg
    LEFT OUTER JOIN mktg_ops_tbls.adb_nmsdelivery tgt
    ON stg.ideliveryid = tgt.ideliveryid;
    GET DIAGNOSTICS inserted_count = ROW_COUNT;


INSERT INTO mktg_ops_tbls.audit_log (
    proc_name, task_name, status, start_time, end_time, taskmessage
) VALUES (
    'sp_adb_nmsdelivery_data', 'execute_stored_procs',
    CASE WHEN inserted_count > 0 THEN 'success' ELSE 'no_data' END,
    GETDATE(), GETDATE(), -- Changed NOW() to GETDATE()
    'Inserted rows: ' || inserted_count
);

END;



$$
