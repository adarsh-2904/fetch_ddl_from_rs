CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_adb_nmsoperation()
 LANGUAGE plpgsql
AS $$
/*
Created By: 	Hitansu Sahoo
Created Date:	11/04/2025
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
    WHERE process_nm = 'sp_adb_nmsoperation'
      AND LOWER(table_nm) = 'adb_nmsoperation';

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
    VALUES ('sp_adb_nmsoperation', 'Stored Procedure', 'Inprogress', v_start_time);	
	
	
		--step 3: Prep temp data to bulk insert
--drop table if exists existingrecord;
	create temp table existingrecord as
		SELECT
        stg.dcomputedcost,
        stg.dduration,
        stg.destimatedcost,
        stg.dfixedcost,
        stg.dperiodcovered,
        stg.drealcost,
        stg.iassignedition,
        stg.ibudgetid,
        stg.ibudgetstatus,
        stg.ibuiltin,
        stg.icancelstate,
        stg.icentrallocaltype,
        stg.icommitmentlevel,
        stg.icomputationstate,
        stg.icreatedbyid,
        stg.idisablenotification,
        stg.iexternalvalidation,
        stg.ifcpgroupid,
        stg.iforecasted,
        stg.iismodel,
        stg.ilinkedoperationid,
        stg.ilocalorgunitid,
        stg.imessagetype,
        stg.imodifiedbyid,
        stg.inbdocument,
        stg.inbvalidation,
        stg.ioperationid,
        stg.iownerid,
        stg.ipriority,
        stg.iprogramid,
        stg.iprogramprocessid,
        stg.isandboxmode,
        stg.isharedmode,
        stg.itype,
        stg.iusebudget,
        stg.iusebudgetvalidation,
        stg.iusecentrallocal,
        stg.iusecontentvalidation,
        stg.iuseextractionvalidation,
        stg.iusefcpvalidation,
        stg.iuselinkeddeliveryvalidation,
        stg.iusetargetvalidation,
        stg.ivalidationmode,
        stg.iwebapptype,
        stg.mdata,
        stg.sinternalname,
        stg.slabel,
        stg.slogin,
        stg.snature,
        stg.tscreated,
        stg.tsend,
        stg.tslastcomputed,
        stg.tslastmodified,
        stg.tsstart,
        stg.davg_investment_per_cust,
        stg.dcommission_per_cust,
        stg.destprovcost,
        stg.dmargin_benefit_per_cust,
        stg.dperc_hi_sales,
        stg.dperc_reviews_attended,
        stg.dperc_reviews_booked,
        stg.dperc_fp_sales,
        stg.dperc_sav_sales,
        stg.dperc_sfs_referrals,
        stg.dperc_sfs_sales,
        stg.dperc_will_sales,
        stg.droi,
        stg.idropfilerequired,
        stg.iexpected_volume,
        stg.ifk_actions,
        stg.ifk_incometypes,
        stg.ifk_reactions,
        stg.ifk_cmp_hierarchies,
        stg.iusetask,
        stg.iusetaskcreation,
        stg.iwebanalyticsaccountid,
        stg.scmp_deliverycode,
        stg.scmp_lettercode,
        stg.scmp_letternotes,
        stg.scmp_nature,
        stg.iistriggeredcampaign,
        case when tgt.ioperationid is null then 'I' else 'C' end as row_stat_cd,
        v_appl_src_cd as appl_src_cd,
        v_dw_load_id as load_id,
        CURRENT_DATE
    FROM
        mods_bi_rep.mktg_stage_tbls.stg_adb_nmsoperation stg
		 LEFT OUTER JOIN mktg_ops_tbls.adb_nmsoperation tgt
		ON stg.ioperationid = tgt.ioperationid;
		
		
    ---Step 3: delete from tgt where src matches the conditions.
	DELETE FROM mktg_ops_tbls.adb_nmsoperation
	USING mods_bi_rep.mktg_stage_tbls.stg_adb_nmsoperation stg
	WHERE stg.ioperationid = mktg_ops_tbls.adb_nmsoperation.ioperationid;	
	
	
	
	-- Step 4: insert all stg records into tgt-ops table.
    INSERT INTO mktg_ops_tbls.adb_nmsoperation (
        dcomputedcost,
        dduration,
        destimatedcost,
        dfixedcost,
        dperiodcovered,
        drealcost,
        iassignedition,
        ibudgetid,
        ibudgetstatus,
        ibuiltin,
        icancelstate,
        icentrallocaltype,
        icommitmentlevel,
        icomputationstate,
        icreatedbyid,
        idisablenotification,
        iexternalvalidation,
        ifcpgroupid,
        iforecasted,
        iismodel,
        ilinkedoperationid,
        ilocalorgunitid,
        imessagetype,
        imodifiedbyid,
        inbdocument,
        inbvalidation,
        ioperationid,
        iownerid,
        ipriority,
        iprogramid,
        iprogramprocessid,
        isandboxmode,
        isharedmode,
        itype,
        iusebudget,
        iusebudgetvalidation,
        iusecentrallocal,
        iusecontentvalidation,
        iuseextractionvalidation,
        iusefcpvalidation,
        iuselinkeddeliveryvalidation,
        iusetargetvalidation,
        ivalidationmode,
        iwebapptype,
        mdata,
        sinternalname,
        slabel,
        slogin,
        snature,
        tscreated,
        tsend,
        tslastcomputed,
        tslastmodified,
        tsstart,
        davg_investment_per_cust,
        dcommission_per_cust,
        destprovcost,
        dmargin_benefit_per_cust,
        dperc_hi_sales,
        dperc_reviews_attended,
        dperc_reviews_booked,
        dperc_fp_sales,
        dperc_sav_sales,
        dperc_sfs_referrals,
        dperc_sfs_sales,
        dperc_will_sales,
        droi,
        idropfilerequired,
        iexpected_volume,
        ifk_actions,
        ifk_incometypes,
        ifk_reactions,
        ifk_cmp_hierarchies,
        iusetask,
        iusetaskcreation,
        iwebanalyticsaccountid,
        scmp_deliverycode,
        scmp_lettercode,
        scmp_letternotes,
        scmp_nature,
        iistriggeredcampaign,
        row_stat_cd,
        appl_src_cd,
        load_id,
        dw_trans_ts
    )
    SELECT
        stg.dcomputedcost,
        stg.dduration,
        stg.destimatedcost,
        stg.dfixedcost,
        stg.dperiodcovered,
        stg.drealcost,
        stg.iassignedition,
        stg.ibudgetid,
        stg.ibudgetstatus,
        stg.ibuiltin,
        stg.icancelstate,
        stg.icentrallocaltype,
        stg.icommitmentlevel,
        stg.icomputationstate,
        stg.icreatedbyid,
        stg.idisablenotification,
        stg.iexternalvalidation,
        stg.ifcpgroupid,
        stg.iforecasted,
        stg.iismodel,
        stg.ilinkedoperationid,
        stg.ilocalorgunitid,
        stg.imessagetype,
        stg.imodifiedbyid,
        stg.inbdocument,
        stg.inbvalidation,
        stg.ioperationid,
        stg.iownerid,
        stg.ipriority,
        stg.iprogramid,
        stg.iprogramprocessid,
        stg.isandboxmode,
        stg.isharedmode,
        stg.itype,
        stg.iusebudget,
        stg.iusebudgetvalidation,
        stg.iusecentrallocal,
        stg.iusecontentvalidation,
        stg.iuseextractionvalidation,
        stg.iusefcpvalidation,
        stg.iuselinkeddeliveryvalidation,
        stg.iusetargetvalidation,
        stg.ivalidationmode,
        stg.iwebapptype,
        stg.mdata,
        stg.sinternalname,
        stg.slabel,
        stg.slogin,
        stg.snature,
        stg.tscreated,
        stg.tsend,
        stg.tslastcomputed,
        stg.tslastmodified,
        stg.tsstart,
        stg.davg_investment_per_cust,
        stg.dcommission_per_cust,
        stg.destprovcost,
        stg.dmargin_benefit_per_cust,
        stg.dperc_hi_sales,
        stg.dperc_reviews_attended,
        stg.dperc_reviews_booked,
        stg.dperc_fp_sales,
        stg.dperc_sav_sales,
        stg.dperc_sfs_referrals,
        stg.dperc_sfs_sales,
        stg.dperc_will_sales,
        stg.droi,
        stg.idropfilerequired,
        stg.iexpected_volume,
        stg.ifk_actions,
        stg.ifk_incometypes,
        stg.ifk_reactions,
        stg.ifk_cmp_hierarchies,
        stg.iusetask,
        stg.iusetaskcreation,
        stg.iwebanalyticsaccountid,
        stg.scmp_deliverycode,
        stg.scmp_lettercode,
        stg.scmp_letternotes,
        stg.scmp_nature,
        stg.iistriggeredcampaign,
        stg.row_stat_cd,
        stg.appl_src_cd,
        stg.load_id,
        CURRENT_DATE
    FROM
        existingrecord stg;
		
-- Capture number of rows inserted
    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

    -- Step 5: Get latest timestamp for next run and Update load control	
    SELECT MAX(dw_trans_ts)--modified to dw_trans_ts from tslastmodified
    INTO v_next_extract_ts
    FROM mods_bi_rep.mktg_stage_tbls.stg_adb_nmsoperation;

    drop table existingrecord;
	
    CALL etl_config.sp_upsert_load_control(
        'sp_adb_nmsoperation', 'adb_nmsoperation',--this will be updated in every stored proc
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
           proc_name = 'sp_adb_nmsoperation' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;
	-- Step 7: Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('sp_adb_nmsoperation', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

END;

$$
