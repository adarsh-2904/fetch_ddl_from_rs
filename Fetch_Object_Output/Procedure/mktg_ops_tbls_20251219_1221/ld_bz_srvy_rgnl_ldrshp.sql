CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_srvy_rgnl_ldrshp()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Hall
Created On: 12/14/2020
Purpose: This view presents the Regional Leadership Survey data in the table mktg_ops_tbls.srvy_new_vlntr_rspns for dashboard visualization purposes. 
               There should be one record per survey respondent per calendar quarter.
				
Updated by: Robert Shoemake (view deployed by Michael Andrien)
Updated On: 3/18/2021
Purpose: This updated view UNIONS the results from the FY21 Q1 surveys. The scale of questions were all aligned to Almost Always to Almost Never for all questions. Notated in SQL below.

Updated by: Robert Shoemake (view deployed by Michael Andrien)
Updated On: 3/22/2021
Purpose: Added the final WHERE condition to excluded test rows from the view

Updated by:	Michael Andrien
Update Date:	04/28/2023
Purpose:	Added the join to the bz_dim_edrtl_response_period and added the edrtl_respns_period_key and edrtl_respns_period attributes from the dimension.

Updated by:	Michael Hall
Update Date: 	11/06/2023
Purpose: 	View turned into a macro.  This macro will truncate-and-load the target table for current FY survey responses.  
         	Prior view (mktg_ops_vws.srvy_rgnl_ldrshp) is now a simple UNION ALL query to extract both current and past (historical) FY rows.
         
Updated by:	Michael Hall
Update Date:	12/07/2023
Purpose: 	Updated rating descriptions to align with rating scale for FY24 survey version.
         	CASE 
		   WHEN rtng = 5 THEN 'Almost Always'
		   WHEN rtng = 4 THEN 'Usually'
		   WHEN rtng = 3 THEN 'Sometimes'
		   WHEN rtng = 2 THEN 'Rarely'
		   WHEN rtng = 1 THEN 'Almost Never'
		   ELSE
     		      NULL
        	  END AS rtng_dsc

*/
	
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_srvy_rgnl_ldrshp', 'Stored Procedure', 'Inprogress', v_start_time);


begin

INSERT INTO mktg_ops_tbls.srvy_rgnl_ldrshp

--create table mktg_ops_tbls.srvy_rgnl_ldrshp as 

SELECT 
rcp.tslog AS snapshot_ts, 	
rcp.tslog AS history_record_ts,
rcp.iwebapplogrcpid AS history_record_id,
nr.irecipientid AS adnc_mbr_id, 
0 AS cnst_mstr_id,
0 AS orig_cnst_mstr_id,
CAST(NULL AS VARCHAR(30)) AS last_nm,
CAST(NULL AS VARCHAR(30)) AS email,
wa.slabel AS survey_nm, 
SUBSTRING(wa.slabel,1,4) AS survey_period,
COALESCE(rp.edrtl_respns_period_key, 0) AS edrtl_respns_period_key,
CASE 
   WHEN rp.edrtl_respns_period IS NULL THEN 'Unknown' 
   ELSE rp.edrtl_respns_period 
END AS edrtl_respns_period,
du.division_cd,
du.division_dsc,
CASE 
    WHEN SUBSTRING(du.division_dsc, 1, LEN(du.division_dsc) - 8) = 'Southeast and Caribbean' THEN 'SEC'
    WHEN SUBSTRING(du.division_dsc, 1, LEN(du.division_dsc) - 8) = 'Southwest and Rocky Mountain' THEN 'SWaRM'
    ELSE SUBSTRING(du.division_dsc, 1, LEN(du.division_dsc) - 8)
END AS division_dsc_abbr,
r1.string0 AS nk_ecode,
cs_region_nm,
SUBSTRING(cs_region_nm,1,LEN(cs_region_nm)-7) AS cs_region_nm_abbr, 
UPPER(r1.string4) AS vol_position,
CASE 
   WHEN UPPER(r1.string4) = 'ED' THEN 'ED'
   WHEN UPPER(r1.string4) = 'RLT' THEN 'RLT' 
   ELSE 'Other' 
END AS position_category,
r1.byte4 AS tmwrk_lvl_rtng1, /*a2_tmwrk_lvl_rtng*/
CASE 
   WHEN r1.tmwrk_lvl_rtng = 5 THEN 'Excellent'
   WHEN r1.tmwrk_lvl_rtng = 4 THEN 'Good'
   WHEN r1.tmwrk_lvl_rtng = 3 THEN 'Average'
   WHEN r1.tmwrk_lvl_rtng = 2 THEN 'Poor'
   WHEN r1.tmwrk_lvl_rtng = 1 THEN 'Very Poor'
   ELSE
     NULL
END AS tmwrk_lvl_rtng_dsc, /* a2_tmwrk_lvl_rtng_dsc */
r1.byte5 AS embrcd_ldr_rtng_composite, /* a4_ed_embrcd_ldr_rtng (ED embraced leader removed from non-ED survey) */
CASE 
   WHEN r1.embrcd_ldr_rtng_composite = 5 THEN 'Almost Always'
   WHEN r1.embrcd_ldr_rtng_composite = 4 THEN 'Usually'
   WHEN r1.embrcd_ldr_rtng_composite = 3 THEN 'Sometimes'
   WHEN r1.embrcd_ldr_rtng_composite = 2 THEN 'Rarely'
   WHEN r1.embrcd_ldr_rtng_composite = 1 THEN 'Almost Never'
   ELSE
     NULL
END AS embrcd_ldr_rtng_composite_dsc, /* ED embraced leader removed from non-ED survey */
r1.byte10 AS ed_focus_five_key_rsp_rtng /* a8_ed_focus_five_key_rsp_rtng  */, 
CASE 
   WHEN r1.ed_focus_five_key_rsp_rtng = 5 THEN 'Almost Always'
   WHEN r1.ed_focus_five_key_rsp_rtng = 4 THEN 'Usually'
   WHEN r1.ed_focus_five_key_rsp_rtng = 3 THEN 'Sometimes'
   WHEN r1.ed_focus_five_key_rsp_rtng = 2 THEN 'Rarely'
   WHEN r1.ed_focus_five_key_rsp_rtng = 1 THEN 'Almost Never'
   ELSE
     NULL
END AS ed_focus_five_key_rsp_rtng_dsc, /* a8_ed_focus_five_key_rsp_rtng_dsc (new question for FY21) */
r1.byte11 AS ed_have_sprt_rtng, /* a7_ed_have_sprt_rtng */
CASE 
   WHEN r1.ed_have_sprt_rtng = 5 THEN 'Almost Always'
   WHEN r1.ed_have_sprt_rtng = 4 THEN 'Usually'
   WHEN r1.ed_have_sprt_rtng = 3 THEN 'Sometimes'
   WHEN r1.ed_have_sprt_rtng = 2 THEN 'Rarely'
   WHEN r1.ed_have_sprt_rtng = 1 THEN 'Almost Never'
   ELSE
     NULL
END AS ed_have_sprt_rtng_dsc, /* a7_ed_have_sprt_rtng_dsc */
byte0 AS mutual_rspct_rtng, /*a1_mutual_rspct_rtng */
CASE 
   WHEN r1.mutual_rspct_rtng = 5 THEN 'Almost Always'
   WHEN r1.mutual_rspct_rtng = 4 THEN 'Usually'
   WHEN r1.mutual_rspct_rtng = 3 THEN 'Sometimes'
   WHEN r1.mutual_rspct_rtng = 2 THEN 'Rarely'
   WHEN r1.mutual_rspct_rtng = 1 THEN 'Almost Never'
   ELSE
     NULL
END AS mutual_rspct_rtng_dsc, /* a1_mutual_rspct_rtng_dsc */

r1.byte1 AS team_cmtmnt_rtng, /* b1_team_cmtmnt_rtng */ 
CASE 
   WHEN r1.team_cmtmnt_rtng = 5 THEN 'Almost Always'
   WHEN r1.team_cmtmnt_rtng = 4 THEN 'Usually'
   WHEN r1.team_cmtmnt_rtng = 3 THEN 'Sometimes'
   WHEN r1.team_cmtmnt_rtng = 2 THEN 'Rarely'
   WHEN r1.team_cmtmnt_rtng = 1 THEN 'Almost Never'
   ELSE
     NULL 
END AS team_cmtmnt_rtng_dsc, /* b1_team_cmtmnt_rtng_dsc */
r1.byte3 AS held_accntbl_rtng, /* c1_held_accntbl_rtng */ 
CASE 
   WHEN r1.held_accntbl_rtng = 5 THEN 'Almost Always'
   WHEN r1.held_accntbl_rtng = 4 THEN 'Usually'
   WHEN r1.held_accntbl_rtng = 3 THEN 'Sometimes'
   WHEN r1.held_accntbl_rtng = 2 THEN 'Rarely'
   WHEN r1.held_accntbl_rtng = 1 THEN 'Almost Never'
   ELSE
     NULL
END AS held_accntbl_rtng_dsc, /* c1_held_accntbl_rtng_dsc */
r1.byte2 AS lead_by_exmpl_lob_rtng, /* d1_lead_by_exmpl_lob_rtng */ 
CASE 
   WHEN r1.lead_by_exmpl_lob_rtng = 5 THEN 'Almost Always'
   WHEN r1.lead_by_exmpl_lob_rtng = 4 THEN 'Usually'
   WHEN r1.lead_by_exmpl_lob_rtng = 3 THEN 'Sometimes'
   WHEN r1.lead_by_exmpl_lob_rtng = 2 THEN 'Rarely'
   WHEN r1.lead_by_exmpl_lob_rtng = 1 THEN 'Almost Never'
   ELSE
     NULL
END AS lead_by_exmpl_lob_rtng_dsc,

/* Question 5:  I am aware of the five key responsibilities for Executive Directors (applies only to 'ED' choice) */
r1.ed_aware_ind,

--Question logic as follows: if the survey taker is an ED THEN check dynamic question of Is Aware of 5 Keys/Is NOT Aware of 5 Keys. 
--It is same question, but asked in response to if the ED is aware of 5 Keys
--Same question, different ordering due to the way the survey was created. 
--If not ED, THEN use the RLT version.
--Serving as the Face of the Red Cross
r1.arc_face_srvg_composite,

--FY21 Descriptions changed - Same 1-5 Values - Different Descriptions
CASE  r1.arc_face_srvg_composite
   WHEN 6 THEN 'Dont Know' 
   WHEN 5 THEN 'Almost Always' 
   WHEN 4 THEN 'Usually' 
   WHEN 3 THEN 'Sometimes' 
   WHEN 2 THEN 'Rarely'  
   WHEN 1 THEN 'Almost Never' 
END AS arc_face_srvg_composite_dsc,

--Developing and leveraging relationships to build
r1.rltnshp_bldg_cpcty_composite,
CASE r1.rltnshp_bldg_cpcty_composite 
   WHEN 6 THEN 'Dont Know' 
   WHEN 5 THEN 'Almost Always' 
   WHEN 4 THEN 'Usually' 
   WHEN 3 THEN 'Sometimes' 
   WHEN 2 THEN 'Rarely'  
   WHEN 1 THEN 'Almost Never' 
END AS rltnshp_bldg_cpcty_composite_dsc,

--Developing and managing the chapter board 
r1.chptr_board_dvlpmnt_composite,
CASE r1.chptr_board_dvlpmnt_composite 
   WHEN 6 THEN 'Dont Know' 
   WHEN 5 THEN 'Almost Always' 
   WHEN 4 THEN 'Usually' 
   WHEN 3 THEN 'Sometimes' 
   WHEN 2 THEN 'Rarely'  
   WHEN 1 THEN 'Almost Never' 
END AS chptr_board_dvlpmnt_composite_dsc,

--Developing, leading and managing community volunteer leaders
r1.cmmnty_ldr_dvlpmnt_composite,
CASE r1.cmmnty_ldr_dvlpmnt_composite 
   WHEN 6 THEN 'Dont Know' 
   WHEN 5 THEN 'Almost Always' 
   WHEN 4 THEN 'Usually' 
   WHEN 3 THEN 'Sometimes' 
   WHEN 2 THEN 'Rarely'  
   WHEN 1 THEN 'Almost Never' 
END AS cmmnty_ldr_dvlpmnt_composite_dsc,

--Influencing to create an environment of teamwork and inclusion
r1.tmwrk_inclsn_envrnmnt_composite,
CASE r1.tmwrk_inclsn_envrnmnt_composite 
   WHEN 6 THEN 'Dont Know' 
   WHEN 5 THEN 'Almost Always' 
   WHEN 4 THEN 'Usually' 
   WHEN 3 THEN 'Sometimes' 
   WHEN 2 THEN 'Rarely'  
   WHEN 1 THEN 'Almost Never' 
END AS tmwrk_inclsn_envrnmnt_composite_dsc,

--If applicable, please select the areas outside of the five key responsibilities that still require your focus (select all that apply)
r1.boolean7 AS ed_mng_evnt_ind, 		/* a9_ed_mng_evnt_ind */
r1.boolean6 AS ed_lcl_bldg_mntnc_ind, 	/* b9_ed_lcl_bldg_mntnc_ind */
r1.boolean5 AS ed_frnt_dsk_ind, 		/* c9_ed_frnt_dsk_ind */
r1.boolean4 AS ed_offc_mngmnt_ind, 	    /* d9_ed_offc_mngmnt_ind */
r1.boolean3 AS ed_vlntr_cmplnt_ind, 	/* e9_ed_vlntr_cmplnt_ind */
r1.boolean2 AS ed_clnt_srvc_dlvry_ind,  /* f9_ed_clnt_srvc_dlvry_ind */
r1.boolean1 AS ed_other_ind, 			/* g9_ed_other_ind */
r1.string6  AS ed_other_txt_dsc,        /* g9_ed_other_txt_dsc */
(r1.boolean7 + r1.boolean6 + r1.boolean5 + r1.boolean4 + r1.boolean3 + r1.boolean2 + r1.boolean1) AS ed_focus_area_total,
/* (a9_ed_mng_evnt_ind + b9_ed_lcl_bldg_mntnc_ind + c9_ed_frnt_dsk_ind + d9_ed_offc_mngmnt_ind + e9_ed_vlntr_cmplnt_ind + f9_ed_clnt_srvc_dlvry_ind + g9_ed_other_ind) AS ed_focus_area_total */
CASE 
   WHEN (r1.boolean7 + r1.boolean6 + r1.boolean5 + r1.boolean4 + r1.boolean3 + r1.boolean2 + r1.boolean1) > 0 THEN 1 
   ELSE 0 
END AS ed_focus_outside_top5_ind,
/* comment fields */
/* ED additional comment no longer used in >= FY23 versions, so logic will move it there from RLT additional comment field */
CASE
   WHEN UPPER(r1.string4) = 'RLT' THEN REGEXP_SUBSTR(r1.mdata,'[^<>]+',1,5,'i')   
   
/*SELECT REGEXP_SUBSTR(--Redshift Tested code for syntax
  '<?xml version=''1.0''?>
  <webAppLogRcpData><rltAdditionalComments>We have a newly combined RLT and the team is working extremely well together.</rltAdditionalComments></webAppLogRcpData>',
  '[^<>]+',
  1,
  5,'i'
) AS extracted_text;*/
   
	--WHEN UPPER(r1.string4) = 'RLT' THEN REGEXP_SUBSTRING(r1.mdata,'[^<>]+',1,5,'i') /* RLT Additional comment is the 5th string occurrence that is not <>, case insensitive */
   ELSE NULL
END AS rlt_addtnl_cmt,
CASE
   WHEN UPPER(r1.string4) = 'ED' THEN REGEXP_SUBSTR(r1.mdata,'[^<>]+',1,5,'i') /* ED Additional comment is the 5th string occurrence that is not <>, case insensitive */
   ELSE NULL
END AS ed_addtnl_cmt, 
REGEXP_SUBSTR(r1.mdata,'[^<>]+',1,8,'i') AS ed_addtnl_sprt_cmt,
--REGEXP_SUBSTRING(r1.mdata,'[^<>]+',1,8,'i') AS ed_addtnl_sprt_cmt, /* ED Additional Support Comment is the 8th string occurrence that is not <>, case insensitive */
/* audit columns */
CAST(CAST(rcp.tslog AS VARCHAR(19)) AS TIMESTAMP) AS srcsys_trans_ts, 
CURRENT_TIMESTAMP(0) AS dw_trans_ts,
'I' AS row_stat_cd, 
'ADBE' AS appl_src_cd, 
1 AS load_id

FROM (select byte4 AS tmwrk_lvl_rtng,
	byte5 AS embrcd_ldr_rtng_composite,
	byte10 AS ed_focus_five_key_rsp_rtng,
	byte11 AS ed_have_sprt_rtng,
	byte0 AS mutual_rspct_rtng,
	byte1 AS team_cmtmnt_rtng,
	byte3 AS held_accntbl_rtng,
byte2 AS lead_by_exmpl_lob_rtng,
CASE 
   WHEN UPPER(string4) = 'ED' THEN boolean0  /* a5_ed_aware_ind */
   ELSE 99 
END AS ed_aware_ind,
CASE 
   WHEN UPPER(string4) = 'ED' THEN 
      CASE 
         WHEN byte17 = 0 THEN byte22 /* a6_edna_arc_face_srvg_rtng , a6_eda_arc_face_srvg_rtng */
         ELSE byte17    /* a6_edna_arc_face_srvg_rtng */
	  END 
ELSE 0  /* a4_arc_face_srvg_rtng (MISSING FROM FY24 SOURCE DATA) */
END AS arc_face_srvg_composite,
CASE 
   WHEN UPPER(string4) = 'ED' THEN 
      CASE 
	     WHEN byte16 = 0 THEN byte21  
         ELSE byte16 
	  END 
   ELSE 0   /* b4_rltnshp_bldg_cpcty_rtng (MISSING FROM FY24 SOURCE DATA) */
END AS rltnshp_bldg_cpcty_composite,
CASE 
   WHEN UPPER(string4) = 'ED' THEN 
      CASE 
      WHEN byte15 = 0 THEN byte20 
      ELSE byte15 
	  END 
   ELSE 0  /* c4_chptr_board_dvlpmnt_rtng (MISSING FROM FY24 SOURCE DATA) */
END AS chptr_board_dvlpmnt_composite,
CASE 
   WHEN UPPER(string4) = 'ED' THEN 
      CASE 
      WHEN byte14 = 0 THEN byte19
      ELSE byte14 
   END 
   ELSE 0  /* d4_cmmnty_ldr_dvlpmnt_rtng (MISSING FROM FY24 SOURCE DATA) */
END AS cmmnty_ldr_dvlpmnt_composite,
CASE 
   WHEN UPPER(string4) = 'ED' THEN 
      CASE 
         WHEN byte12 = 0 THEN byte18 
         ELSE byte12 
      END 
   ELSE 0 /* e4_tmwrk_inclsn_envrnmnt_rtng (MISSING FROM FY24 SOURCE DATA) */
END AS tmwrk_inclsn_envrnmnt_composite,
	* from mktg_ops_tbls.adb_nmswebapplogrcpdata )r1     /* web app survey response table */	
LEFT JOIN mktg_ops_tbls.adb_nmswebapplogrcp rcp   /* web app log recipient table */	
   ON rcp.iwebapplogrcpid = r1.iwebapplogid	
LEFT JOIN mktg_ops_tbls.adb_nmswebapp wa  /* web app table */	
   ON wa.iwebappid = rcp.iwebappid	
LEFT JOIN mktg_ops_tbls.adb_nmsrecipient nr /* recipient  table */	
   ON rcp.irecipientid = nr.irecipientid
LEFT JOIN mktg_ops_vws.dim_unit_merged du /* unit dimension (merged) */
   ON collate(du.nk_ecode,'case_insensitive') = collate(r1.string0,'case_insensitive')
LEFT JOIN mktg_ops_vws.bz_dim_edrtl_response_period rp  /* ED-RLT period view */
ON EXTRACT(YEAR FROM rcp.tslog) = rp.edrtl_respns_yr 
AND EXTRACT(MONTH FROM rcp.tslog) = rp.edrtl_respns_mth
 WHERE  wa.snature = 'survey'	
    AND rcp.iwebappid = 221630596 /* FY24 RLT Survey v4 - Anonymous */;


	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.srvy_rgnl_ldrshp) as integer)
        WHERE proc_name = 'ld_bz_srvy_rgnl_ldrshp' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bz_srvy_rgnl_ldrshp', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;


$$
