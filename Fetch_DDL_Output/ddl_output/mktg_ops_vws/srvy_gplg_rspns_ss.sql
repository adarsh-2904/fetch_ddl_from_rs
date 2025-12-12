CREATE OR REPLACE VIEW mktg_ops_vws.srvy_gplg_rspns_ss
AS
/*
Created by: Michael Hall
Created On: 06/04/2020
Purpose: This view presents the FY20 Planned Giving Lead Generation (GPLG) Supporter Survey Response data.  
                The MODS team collaborated with the Planned Giving team to automate the GPLG survey process in FY19.  
				This survey was formerly run through Survey Monkey and managed by a third party vendor.  
				Response data may come from constituents that received an email and click on the survey link online or 
				constituents that received a direct mail piece and went online to the URL provided in the direct mail piece. 
				This view presents a consolidated final picture of the PG Supporter survey data, including Direct Mail and Email
				versions, as well as English and Spanish versions of each.  Each portion has been 'deduped' of mutiple survey 
				response rows, by using partitioning to enable one survey response row per constituent per fiscal year.

Modified by: Michael Hall
Modified On: 06/09/2020
Purpose: Added GMS ARC Fundraising Summary view to help align the duplicate constituents with the latest donation date.		

Modified by: Michael Hall
Modified On: 06/17/2020
Purpose: Remodeled the view as two separate SELECTs with a UNION ALL combining both direct mail and email versions of the PG survey.	

Modified by: Michael Hall
Modified On: 06/25/2020
Purpose: Refactored the view to segment the Direct Mail portion into two queries to separate resolved and unresolved master constituent ids.	
                This change allows better handling of potential duplicate survey rows.  Added back the iwebappid in WHERE clause to  more easily distinguish between Direct Mail and Email versions of the survey.
				The webappid's will likely change from year-to-year, thus requiring modification to the view.  
				However, the change facilitates better view performance, plus cleaner presentation and understanding.

Modified by: Michael Hall
Modified On: 02/18/2021
Purpose: Replaced the old FY20 web app id's with new FY21 web app id's. Changed 'FY20' to 'FY21' in the comments.
         Note that in the FY21 version there is only one language version for PG Direct Mail and it's English.
				 
Modified by: Michael Hall
Modified On: 01/24/2022
Purpose: Replaced the old FY20 web app id's with new FY22 version. Note that there is only one language version for PG Direct Mail and it's English.

Modified by: Michael Andrien
Modified On: 04/06/2022
Purpose: Added the gz subquery to both queries to derive the unit/chapter key and code based on the zip code provided on the reply address.  Updated the coalesce rankings
to make the gz unit_key and code the highest ranking and made the e.mktg_unit_key and e.mktg_unit_cd values a higher priority than e.unit_key and e.unit_cd
This change is linked to Teamwork ticket #8577053.

Modified by: Michael Andrien
Modified On: 08/18/2022
Purpose:  Changed the default value in the coalesce statements for the cnst_mstr_id and unit_key from NULL to 0

Modified by: Michael Hall
Modified On: 01/12/2023
Purpose:  Added new column containing responses for re-worded question 5d "Gift by Beneficiary Designation" (d5_gift_bnfcry_dsgntn_ind) 
          in the FY23 version 5.0 of the survey.

Modified by: Michael Hall
Modified On: 04/12/2023
Purpose:  Added new SELECT query to pull Direct Mail and Online (Email) rows for the FY20 version 2.0 of the survey, 
          which had been excluded from the view.

Modified by: Michael Hall
Modified On: 06/06/2023
Purpose:  Added two new webapp_ids in WHERE clauses to pull Direct Mail and Online (Email) rows for the FY23 version 5.1 of the survey,
          FY23 Direct/Online - Planned Giving Supporter Survey V5.1 Second Wave

Modified by: Michael Hall
Modified On: 06/08/2023
Purpose:  Changed view to set proper source code depending on the survey webappid.

Modified by: Michael Hall
Modified On: 06/15/2023
Purpose:  Changed view to set proper source code for email webappid 213387808 when snapshot date >= '2023-06-08'

Modified by: Michael Hall
Modified On: 01/05/2024
Purpose:  Added a total of three new webapp_ids in the WHERE clause to pull Direct Mail and Online (Email) rows for the FY24 version 6.0 of the survey,
          FY24 Direct/Online - Planned Giving Supporter Survey V6.0
		  
Modified by: Michael Hall
Modified On: 01/18/2024
Purpose:  Fixed 2023 rows to reflect source code 2024 instead of 2023.

Modified by: Michael Andrien
Modified On: 05/28/2024
Purpose:  Added the COALESCE statement to the src_cd attribute to pull in the source code when it is not null.

Modified by: Michael Hall
Modified On: 01/19/2025
Purpose:  Added new webapp_ids in the WHERE clause to pull Direct Mail and Online/Email rows for the FY25 version 7.0 of the survey,
          FY25 Direct - Planned Giving Supporter Survey V7.0 URL [webpappid = 230148501]
		  FY25 Online - Planned Giving Supporter Survey V7.0 [webpappid = 230991571]
		  Columns added:
		  1. g8_cntct_prfrnc AS cntct_prfrnc
		  2. f1_frnd_fmly_mbr_suprtr_ind
		  3. d5_gift_ira_chrtbl_dstrbtn_ind

Modified by: Michael Andrien
Modified On: 01/30/2025
Purpose:    Added g8_cntct_prfrnc_phone_ind, g8_cntct_prfrnc_email_ind, g8_cntct_prfrnc_text_ind attributes to the view.

Modified by: Michael Andrien
Modified On: 02/17/2025
Purpose:    Added logic to set the src_cd for the FY25 supporter survey - WHEN iwebappid = 230991571 THEN 'APP25024E000'

Modified by: Michael Hall
Modified On: 04/24/2025
Purpose:    Added logic to set the src_cd for the FY25 Supporter survey based on deployment date (i.e., snapshot_ts):
            WHEN iwebappid = 230991571 AND CAST(snapshot_ts AS DATE) < '2025-04-11'  THEN 'APP25024E000' [2025 February Supporter survey]
		    WHEN iwebappid = 230991571 AND CAST(snapshot_ts AS DATE) >= '2025-04-11' THEN 'APP25044E000' [2025 April Supporter survey]

*/

SELECT
	snapshot_ts, 
	history_record_ts, 
	 srvy_respns_dt,
	history_record_id, 
	iwebappid,
	src_cd,
	adnc_mbr_id,
	survey_nm, 
	 cnst_mstr_id_xlob,
	orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone,
	 phone_typ,
	cntct_prfrnc,
	g8_cntct_prfrnc_phone_ind,
	g8_cntct_prfrnc_email_ind,
	 g8_cntct_prfrnc_text_ind,
	age_band,
	marital_status, 
	unit_key, 
	 nk_ecode, 
	suprt_imprtnc, /* 'How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status,
	a1_there_for_me_suprt_ind , /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind, /* 'I support to provide general support for the ARC programs AND services' */
	c1_dstr_suprt_ind, /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind, /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind , /* 'I support because I believe in the ARC mission' */
	f1_frnd_fmly_mbr_suprtr_ind, /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind , /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind, /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind, /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind, /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind, /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind, /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
		 /* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind, /* Very Important */
	c4_somewhat_imprtnt_ind, /* Somewhat Important */
	d4_not_imprtnt_ind, /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind , /* Volunteering */
	c5_suprt_gift_in_will_ind , /* Gift in your will */
	d5_suprt_fmly_mbr_ind, /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind, /* Gift by beneficiary designation */
	d5_gift_ira_chrtbl_dstrbtn_ind, /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind, /* Blood Donation */
	f5_suprt_gift_incm_life_ind, /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance)' */
	b8_children_ind , /* Do you have Children? */
	c8_grand_children_ind , /* Do you have Grandchildren? */
	g8_arc_story , /* Do you have a story about how the Red Cross has touched your life? Tell us about it here.' */
	survey_vrsn, /* Version of survey (English or Spanish) */
	dw_create_ts, 
	dw_updt_ts, 
	row_stat_cd, 
	appl_src_cd,
	load_id
	
	from (
	
			SELECT
	snapshot_ts, 
	history_record_ts, 
	CAST(history_record_ts AS DATE) AS srvy_respns_dt,
	history_record_id, 
	iwebappid,
	 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '054M000' AS src_cd,
	adnc_mbr_id,
	survey_nm, 
	COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, 0) AS cnst_mstr_id_xlob,
	COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, 0) AS orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone,
	CAST(NULL AS VARCHAR(10)) AS phone_typ,
	CAST(NULL AS VARCHAR(25)) AS cntct_prfrnc,
	CAST(NULL AS SMALLINT) AS g8_cntct_prfrnc_phone_ind,
	CAST(NULL AS SMALLINT) AS g8_cntct_prfrnc_email_ind,
	CAST(NULL AS SMALLINT) AS g8_cntct_prfrnc_text_ind,
	age_band,
	marital_status, 
	COALESCE(gz.unit_key, e.mktg_unit_key, e.unit_key, f.unit_key, f.mktg_unit_key, g.unit_key, g.mktg_unit_key, h.unit_key, h.mktg_unit_key, 0) AS unit_key, 
	COALESCE(gz.unit_cd::varchar(20), e.mktg_unit_key::varchar(20), e.unit_key::varchar(20), f.unit_cd::varchar(20), f.mktg_unit_cd::varchar(20), g.unit_cd::varchar(20), g.mktg_unit_cd::varchar(20), h.unit_cd::varchar(20), h.mktg_unit_cd::varchar(20), NULL) AS nk_ecode, 
	suprt_imprtnc, /* 'How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status,
	a1_there_for_me_suprt_ind , /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind, /* 'I support to provide general support for the ARC programs AND services' */
	c1_dstr_suprt_ind, /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind, /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind , /* 'I support because I believe in the ARC mission' */
	CAST(NULL AS SMALLINT) AS f1_frnd_fmly_mbr_suprtr_ind, /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind , /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind, /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind, /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind, /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind, /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind, /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
		 /* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind, /* Very Important */
	c4_somewhat_imprtnt_ind, /* Somewhat Important */
	d4_not_imprtnt_ind, /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind , /* Volunteering */
	c5_suprt_gift_in_will_ind , /* Gift in your will */
	d5_suprt_fmly_mbr_ind, /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind, /* Gift by beneficiary designation */
	CAST(NULL AS SMALLINT) AS d5_gift_ira_chrtbl_dstrbtn_ind, /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind, /* Blood Donation */
	f5_suprt_gift_incm_life_ind, /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance)' */
	b8_children_ind , /* Do you have Children? */
	c8_grand_children_ind , /* Do you have Grandchildren? */
	g8_arc_story , /* Do you have a story about how the Red Cross has touched your life? Tell us about it here.' */
	'EN'  AS survey_vrsn, /* Version of survey (English or Spanish) */
	a.dw_create_ts, 
	a.dw_updt_ts, 
	a.row_stat_cd, 
	a.appl_src_cd,
	a.load_id,
	Row_Number() Over (
PARTITION BY c.fiscal_yr, cnst_mstr_id_xlob
ORDER BY cnst_mstr_id_xlob, c.fiscal_yr, a.snapshot_ts ASC) as rn
	
	FROM mktg_ops_tbls.srvy_gplg_rspns_ss  a
LEFT JOIN 
(
	SELECT a.ZIP, a.ECODE AS unit_cd, b.unit_key
	FROM mktg_ops_vws.geo_zip_code_to_chapter a
	LEFT JOIN mktg_ops_vws.bz_dim_unit b ON a.ecode = b.nk_ecode
) gz (zip, unit_cd, unit_key) ON a.zip_cd = gz.ZIP /* Add subselect to get unit key and unit_cd */
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e 
     ON collate(a.first_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE') AND  collate(a.last_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE') 
				AND collate(a.state::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_st_cd::text,'CASE_INSENSITIVE') AND collate(SUBSTRING(a.zip_cd,1,5)::text,'CASE_INSENSITIVE') =  collate(e.dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_vws.gms_arc_fr_smry i  
     ON e.cnst_mstr_id = i.cnst_mstr_id	
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
     ON a.first_nm = f.dm_cnst_prsn_f_nm AND  a.last_nm = f.dm_cnst_prsn_l_nm 
				AND a.state = f.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  f.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
     ON a.first_nm = g.dm_cnst_prsn_f_nm AND  a.last_nm = g.dm_cnst_prsn_l_nm 
				AND a.state = g.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  g.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
     ON a.first_nm = h.dm_cnst_prsn_f_nm AND  a.last_nm = h.dm_cnst_prsn_l_nm 
				AND a.state = h.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  h.dm_cnst_zip_5_cd
LEFT JOIN eda.dw_common_vws.dim_calendar c /* join to calendar dimension to get FY for de-duping purposes */
    ON (CAST(a.snapshot_ts AS DATE) = c.calendar_dt)  /* each PG survey respondent should have only one entry per FY */
WHERE
    iwebappid = 180243985 /* FY20 Planned Giving Sponsor Survey v2.0, Direct Mail (English version only) */
and  history_record_ts >= TIMESTAMP '2020-05-22 10:54:40' /* filter out test rows */
	
	) as subqry

where cnst_mstr_id_xlob <> 0 and rn=1

union all

SELECT
	snapshot_ts, 
	history_record_ts, 
	srvy_respns_dt,
	history_record_id, 
	iwebappid,
	src_cd,
	-- 'APP' || SUBSTR(CAST(EXTRACT(YEAR FROM CAST(history_record_ts AS DATE FORMAT 'MM/DD/YYYY')) AS VARCHAR(4)),3,2) || '014M000'AS src_cd,
	adnc_mbr_id,
	survey_nm, 
	cnst_mstr_id_xlob,
	orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone,
	phone_typ,
	cntct_prfrnc,
    cntct_prfrnc_phone_ind, 
    cntct_prfrnc_email_ind,
    cntct_prfrnc_text_ind, 
    age_band,
	marital_status, 
	unit_key, 
	 nk_ecode, 
	suprt_imprtnc , /* 'How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status ,
	a1_there_for_me_suprt_ind , /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind , /* 'I support to provide general support for the ARC programs AND services', */
	c1_dstr_suprt_ind , /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind , /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind, /* 'I support because I believe in the ARC mission' */
    f1_frnd_fmly_mbr_suprtr_ind, /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind, /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind, /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind, /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind, /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind, /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind, /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
		 /* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind, /* Very Important */
	c4_somewhat_imprtnt_ind, /* Somewhat Important */
	d4_not_imprtnt_ind, /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind, /* Volunteering */
	c5_suprt_gift_in_will_ind, /* Gift in your will */
	d5_suprt_fmly_mbr_ind, /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind , /* Gift by beneficiary designation */
	d5_gift_ira_chrtbl_dstrbtn_ind, /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind, /* Blood Donation */
	f5_suprt_gift_incm_life_ind , /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance) */
	b8_children_ind, /* Do you have Children? */
	c8_grand_children_ind, /* Do you have Grandchildren? */
	g8_arc_story, /* Do you have a story about how the Red Cross has touched your life? Tell us about it here. */
	survey_vrsn, /* Version of survey (English or Spanish) */
	dw_create_ts, 
	dw_updt_ts, 
	row_stat_cd, 
	appl_src_cd,
	load_id
	
	from (
	SELECT
	snapshot_ts, 
	history_record_ts, 
	CAST(history_record_ts AS DATE) AS srvy_respns_dt,
	history_record_id, 
	iwebappid,
	COALESCE(src_cd,CASE
	  WHEN iwebappid IN (187581647, 201608500, 213490198) THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '014M000' 
	  WHEN iwebappid IN (217449515)            THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '054M000'
	  WHEN iwebappid IN (222949362, 222968470) AND CAST(snapshot_ts AS DATE) <= '2023-12-31' /* identify 2023 rows */ THEN 'APP' || '24014M000'
	  WHEN iwebappid IN (222949362, 222968470, 230148501) THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '014M000'
	  WHEN iwebappid IN (230148501) THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '014M000'
	END) AS src_cd,
	-- 'APP' || SUBSTR(CAST(EXTRACT(YEAR FROM CAST(history_record_ts AS DATE FORMAT 'MM/DD/YYYY')) AS VARCHAR(4)),3,2) || '014M000'AS src_cd,
	adnc_mbr_id,
	survey_nm, 
	COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, 0) AS cnst_mstr_id_xlob,
	COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, 0) AS orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone,
	e8_phone_typ AS phone_typ,
	CAST(NULL AS VARCHAR(25)) AS cntct_prfrnc,
    g8_cntct_prfrnc_phone_ind AS cntct_prfrnc_phone_ind, 
    g8_cntct_prfrnc_email_ind AS cntct_prfrnc_email_ind,
    g8_cntct_prfrnc_text_ind AS cntct_prfrnc_text_ind, 
    age_band,
	marital_status, 
	COALESCE(gz.unit_key, e.mktg_unit_key, e.unit_key, f.unit_key, f.mktg_unit_key, g.unit_key, g.mktg_unit_key, h.unit_key, h.mktg_unit_key, 0) AS unit_key, 
	COALESCE(gz.unit_cd::varchar(20), e.mktg_unit_key::varchar(20), e.unit_key::varchar(20), f.unit_cd::varchar(20), f.mktg_unit_cd::varchar(20), g.unit_cd::varchar(20), g.mktg_unit_cd::varchar(20), h.unit_cd::varchar(20), h.mktg_unit_cd::varchar(20), NULL) AS nk_ecode, 
	suprt_imprtnc , /* 'How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status ,
	a1_there_for_me_suprt_ind , /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind , /* 'I support to provide general support for the ARC programs AND services', */
	c1_dstr_suprt_ind , /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind , /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind, /* 'I support because I believe in the ARC mission' */
    f1_frnd_fmly_mbr_suprtr_ind, /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind, /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind, /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind, /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind, /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind, /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind, /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
		 /* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind, /* Very Important */
	c4_somewhat_imprtnt_ind, /* Somewhat Important */
	d4_not_imprtnt_ind, /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind, /* Volunteering */
	c5_suprt_gift_in_will_ind, /* Gift in your will */
	d5_suprt_fmly_mbr_ind, /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind , /* Gift by beneficiary designation */
	d5_gift_ira_chrtbl_dstrbtn_ind, /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind, /* Blood Donation */
	f5_suprt_gift_incm_life_ind , /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance) */
	b8_children_ind, /* Do you have Children? */
	c8_grand_children_ind, /* Do you have Grandchildren? */
	g8_arc_story, /* Do you have a story about how the Red Cross has touched your life? Tell us about it here. */
	'EN'  AS survey_vrsn, /* Version of survey (English or Spanish) */
	a.dw_create_ts, 
	a.dw_updt_ts, 
	a.row_stat_cd, 
	a.appl_src_cd,
	a.load_id,
	Row_Number() Over (
PARTITION BY c.fiscal_yr, cnst_mstr_id_xlob
ORDER BY cnst_mstr_id_xlob, c.fiscal_yr, a.snapshot_ts ASC) as rn
	FROM mktg_ops_tbls.srvy_gplg_rspns_ss  a
LEFT JOIN 
(
	SELECT a.ZIP, a.ECODE AS unit_cd, b.unit_key
	FROM mktg_ops_vws.geo_zip_code_to_chapter a
	LEFT JOIN mktg_ops_vws.bz_dim_unit b ON a.ecode = b.nk_ecode
) gz (zip, unit_cd, unit_key) ON a.zip_cd = gz.ZIP /* Add subselect to get unit key and unit_cd */
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e 
     ON collate(a.first_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE') AND  collate(a.last_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE') 
				AND collate(a.state::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_st_cd::text,'CASE_INSENSITIVE') AND collate(SUBSTRING(a.zip_cd,1,5)::text,'CASE_INSENSITIVE') =  collate(e.dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_vws.gms_arc_fr_smry i  
     ON e.cnst_mstr_id = i.cnst_mstr_id	
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
     ON a.first_nm = f.dm_cnst_prsn_f_nm AND  a.last_nm = f.dm_cnst_prsn_l_nm 
				AND a.state = f.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  f.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
     ON a.first_nm = g.dm_cnst_prsn_f_nm AND  a.last_nm = g.dm_cnst_prsn_l_nm 
				AND a.state = g.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  g.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
     ON a.first_nm = h.dm_cnst_prsn_f_nm AND  a.last_nm = h.dm_cnst_prsn_l_nm 
				AND a.state = h.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  h.dm_cnst_zip_5_cd
LEFT JOIN eda.dw_common_vws.dim_calendar c /* join to calendar dimension to get FY for de-duping purposes */
    ON (CAST(a.snapshot_ts AS DATE) = c.calendar_dt)   /* each PG survey respondent should have only one entry per FY  */
WHERE
                     iwebappid IN (187581647, /* FY21 Planned Giving Sponsor Survey v3.0, Direct Mail (English version only) */
				   201608500, /* FY22 Planned Giving Sponsor Survey v4.0, Direct Mail */
				   213490198, /* FY23 Planned Giving Sponsor Survey v5.0, Direct Mail */
				   217449515, /* FY23 Planned Giving Sponsor Survey v5.1, Direct Mail */
				   222949362, /* FY24 Direct - Planned Giving Supporter Survey V6.0 */
				   222968470, /* FY24 Direct - Planned Giving Supporter Survey V6.0 URL */
				   230148501) /* FY25 Direct - Planned Giving Supporter Survey V7.0 URL */
	 --AND history_record_ts >= TIMESTAMP '2021-01-11 23:59:59' /* filter out test rows */
  	
	
	) as subqry
	
	where cnst_mstr_id_xlob <> 0 and rn =1

	
union all

SELECT
	snapshot_ts, 
	history_record_ts, 
	srvy_respns_dt,
	history_record_id, 
	iwebappid,
	src_cd,
    -- 'APP' || SUBSTR(CAST(EXTRACT(YEAR FROM CAST(history_record_ts AS DATE FORMAT 'MM/DD/YYYY')) AS VARCHAR(4)),3,2) || '014M000'AS src_cd,
	adnc_mbr_id,
	survey_nm, 
	cnst_mstr_id_xlob,
	orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone, 
	phone_typ,
	cntct_prfrnc,
    cntct_prfrnc_phone_ind, 
    cntct_prfrnc_email_ind,
    cntct_prfrnc_text_ind, 
	age_band,
	marital_status, 
	unit_key, 
	nk_ecode,  
	suprt_imprtnc, /* How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status,
	a1_there_for_me_suprt_ind, /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind, /* 'I support to provide general support for the ARC programs AND services' */
	c1_dstr_suprt_ind, /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind, /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind, /* 'I support because I believe in the ARC mission' */
	f1_frnd_fmly_mbr_suprtr_ind, /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind, /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind, /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind, /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind, /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind, /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind, /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
		 /* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind, /* Very Important */
	c4_somewhat_imprtnt_ind, /* Somewhat Important */
	d4_not_imprtnt_ind, /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind, /* Volunteering */
	c5_suprt_gift_in_will_ind, /* Gift in your will */
	d5_suprt_fmly_mbr_ind, /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind, /* Gift by beneficiary designation */
	d5_gift_ira_chrtbl_dstrbtn_ind, /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind, /* Blood Donation */
	f5_suprt_gift_incm_life_ind, /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance) */
	b8_children_ind, /* Do you have Children? */
	c8_grand_children_ind, /* Do you have Grandchildren? */
	g8_arc_story, /* Do you have a story about how the Red Cross has touched your life? Tell us about it here. */
	survey_vrsn, /* Version of survey (English or Spanish) */
	dw_create_ts, 
	dw_updt_ts, 
	row_stat_cd, 
	appl_src_cd,
	load_id
	
	from (
	
				SELECT
	snapshot_ts, 
	history_record_ts, 
	CAST(history_record_ts AS DATE) AS srvy_respns_dt,
	history_record_id, 
	iwebappid,
	COALESCE(src_cd,CASE
	  WHEN iwebappid IN (187581647, 201608500, 213490198)  THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '014M000' 
	  WHEN iwebappid IN (217449515)            THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '054M000'
	  WHEN iwebappid IN (222949362, 222968470) AND CAST(snapshot_ts AS DATE) <= '2023-12-31' /* identify 2023 rows */ THEN 'APP' || '24014M000'
	  WHEN iwebappid IN (222949362, 222968470, 230148501) THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '014M000'
	END) AS src_cd,
    -- 'APP' || SUBSTR(CAST(EXTRACT(YEAR FROM CAST(history_record_ts AS DATE FORMAT 'MM/DD/YYYY')) AS VARCHAR(4)),3,2) || '014M000'AS src_cd,
	adnc_mbr_id,
	survey_nm, 
	COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, 0) AS cnst_mstr_id_xlob,
	COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, 0) AS orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone, 
	e8_phone_typ AS phone_typ,
	CAST(NULL AS VARCHAR(25)) AS cntct_prfrnc,
    g8_cntct_prfrnc_phone_ind AS cntct_prfrnc_phone_ind, 
    g8_cntct_prfrnc_email_ind AS cntct_prfrnc_email_ind,
    g8_cntct_prfrnc_text_ind AS cntct_prfrnc_text_ind, 
	age_band,
	marital_status, 
	COALESCE(gz.unit_key, e.mktg_unit_key, e.unit_key, f.unit_key, f.mktg_unit_key, g.unit_key, g.mktg_unit_key, h.unit_key, h.mktg_unit_key, 0) AS unit_key, 
	COALESCE(gz.unit_cd::varchar(20), e.mktg_unit_key::varchar(20), e.unit_key::varchar(20), f.unit_cd::varchar(20), f.mktg_unit_cd::varchar(20), g.unit_cd::varchar(20), g.mktg_unit_cd::varchar(20), h.unit_cd::varchar(20), h.mktg_unit_cd::varchar(20), NULL) AS nk_ecode,  
	suprt_imprtnc, /* How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status,
	a1_there_for_me_suprt_ind, /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind, /* 'I support to provide general support for the ARC programs AND services' */
	c1_dstr_suprt_ind, /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind, /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind, /* 'I support because I believe in the ARC mission' */
	f1_frnd_fmly_mbr_suprtr_ind, /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind, /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind, /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind, /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind, /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind, /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind, /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
		 /* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind, /* Very Important */
	c4_somewhat_imprtnt_ind, /* Somewhat Important */
	d4_not_imprtnt_ind, /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind, /* Volunteering */
	c5_suprt_gift_in_will_ind, /* Gift in your will */
	d5_suprt_fmly_mbr_ind, /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind, /* Gift by beneficiary designation */
	d5_gift_ira_chrtbl_dstrbtn_ind, /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind, /* Blood Donation */
	f5_suprt_gift_incm_life_ind, /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance) */
	b8_children_ind, /* Do you have Children? */
	c8_grand_children_ind, /* Do you have Grandchildren? */
	g8_arc_story, /* Do you have a story about how the Red Cross has touched your life? Tell us about it here. */
	'EN' AS survey_vrsn, /* Version of survey (English or Spanish) */
	a.dw_create_ts, 
	a.dw_updt_ts, 
	a.row_stat_cd, 
	a.appl_src_cd,
	a.load_id,
	Row_Number() Over (
   PARTITION BY Trim(last_nm) || Trim(first_nm) || Trim(state) || Trim(zip_cd)
   ORDER BY snapshot_ts ASC) as rn
	FROM mktg_ops_tbls.srvy_gplg_rspns_ss  a
LEFT JOIN 
(
	SELECT a.ZIP, a.ECODE AS unit_cd, b.unit_key
	FROM mktg_ops_vws.geo_zip_code_to_chapter a
	LEFT JOIN mktg_ops_vws.bz_dim_unit b ON a.ecode = b.nk_ecode
) gz (zip, unit_cd, unit_key) ON a.zip_cd = gz.ZIP /* Add subselect to get unit key and unit_cd */
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e 
     ON collate(a.first_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE') AND  collate(a.last_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE') 
				AND collate(a.state::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_st_cd::text,'CASE_INSENSITIVE') AND collate(SUBSTRING(a.zip_cd,1,5)::text,'CASE_INSENSITIVE') =  collate(e.dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_vws.gms_arc_fr_smry i  
     ON e.cnst_mstr_id = i.cnst_mstr_id	
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
     ON a.first_nm = f.dm_cnst_prsn_f_nm AND  a.last_nm = f.dm_cnst_prsn_l_nm 
				AND a.state = f.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  f.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
     ON a.first_nm = g.dm_cnst_prsn_f_nm AND  a.last_nm = g.dm_cnst_prsn_l_nm 
				AND a.state = g.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  g.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
     ON a.first_nm = h.dm_cnst_prsn_f_nm AND  a.last_nm = h.dm_cnst_prsn_l_nm 
				AND a.state = h.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  h.dm_cnst_zip_5_cd
LEFT JOIN eda.dw_common_vws.dim_calendar c /* join to calendar dimension to get FY for de-duping purposes */
    ON (CAST(a.snapshot_ts AS DATE) = c.calendar_dt)  /* each PG survey respondent should have only one entry per FY  */
WHERE 
      iwebappid IN (187581647, /* FY21 Planned Giving Sponsor Survey v3.0, Direct Mail (English version only) */
					201608500, /* FY22 Direct - Planned Giving Supporter Survey V4.0 Direct Mail */
					213490198, /* FY23 Direct - Planned Giving Supporter Survey V5.0 Direct Mail */
					217449515, /* FY23 Direct - Planned Giving Supporter Survey V5.1 Direct Mail */
					222949362, /* FY24 Direct - Planned Giving Supporter Survey V6.0 */
					222968470, /* FY24 Direct - Planned Giving Supporter Survey V6.0 URL */
					230148501) /* FY25 Direct - Planned Giving Supporter Survey V7.0 URL */
	
) as subqry

where cnst_mstr_id_xlob = 0 and rn =1

union all

SELECT	
	snapshot_ts, 
	history_record_ts, 
	srvy_respns_dt,
	history_record_id, 
	iwebappid,
	src_cd,
	adnc_mbr_id,
	survey_nm, 
	cnst_mstr_id_xlob,
	orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone, 
	phone_typ,
	cntct_prfrnc,
	g8_cntct_prfrnc_phone_ind,
	g8_cntct_prfrnc_email_ind,
	g8_cntct_prfrnc_text_ind,
	age_band,
	marital_status, 
	unit_key,
	nk_ecode,
	suprt_imprtnc, /* 'How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status ,
	a1_there_for_me_suprt_ind, /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind , /* 'I support to provide general support for the ARC programs AND services' */
	c1_dstr_suprt_ind , /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind , /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind , /* 'I support because I believe in the ARC mission' */
	f1_frnd_fmly_mbr_suprtr_ind, /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind , /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind , /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind , /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind , /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind , /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind , /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
	/* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind , /* Very Important */
	c4_somewhat_imprtnt_ind , /* Somewhat Important */
	d4_not_imprtnt_ind , /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind , /* Volunteering */
	c5_suprt_gift_in_will_ind , /* Gift in your will */
	d5_suprt_fmly_mbr_ind , /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind , /* Gift by beneficiary designation */
	d5_gift_ira_chrtbl_dstrbtn_ind, /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind , /* Blood Donation */
	f5_suprt_gift_incm_life_ind , /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance) */
	b8_children_ind , /* Do you have Children? */
	c8_grand_children_ind , /* Do you have Grandchildren? */
	g8_arc_story , /* Do you have a story about how the Red Cross has touched your life? Tell us about it here. */
	survey_vrsn, /* Version of survey (English or Spanish) */
	dw_create_ts, 
	dw_updt_ts, 
	row_stat_cd, 
	appl_src_cd,
	load_id
	
	from(
	
				SELECT	
	snapshot_ts, 
	history_record_ts, 
	CAST(history_record_ts AS DATE)  AS srvy_respns_dt,
	history_record_id, 
	iwebappid,
	'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '064E000' AS src_cd,
	adnc_mbr_id,
	survey_nm, 
	a.cnst_mstr_id AS cnst_mstr_id_xlob,
	a.orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone, 
	CAST(NULL AS VARCHAR(10)) AS phone_typ,
	CAST(NULL AS VARCHAR(25)) AS cntct_prfrnc,
	CAST(NULL AS SMALLINT) AS g8_cntct_prfrnc_phone_ind,
	CAST(NULL AS SMALLINT) AS g8_cntct_prfrnc_email_ind,
	CAST(NULL AS SMALLINT) AS g8_cntct_prfrnc_text_ind,
	age_band,
	marital_status, 
	COALESCE(e.unit_key, e.mktg_unit_key, f.unit_key, f.mktg_unit_key, g.unit_key, g.mktg_unit_key, h.unit_key, h.mktg_unit_key, 0) AS unit_key,
	COALESCE(e.unit_cd::varchar(20), e.mktg_unit_cd::varchar(20), f.unit_cd::varchar(20), f.mktg_unit_cd::varchar(20), g.unit_cd::varchar(20), g.mktg_unit_cd::varchar(20), h.unit_cd::varchar(20), h.mktg_unit_cd::varchar(20), NULL) AS nk_ecode,
	suprt_imprtnc, /* 'How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status ,
	a1_there_for_me_suprt_ind, /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind , /* 'I support to provide general support for the ARC programs AND services' */
	c1_dstr_suprt_ind , /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind , /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind , /* 'I support because I believe in the ARC mission' */
	CAST(NULL AS SMALLINT) AS f1_frnd_fmly_mbr_suprtr_ind, /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind , /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind , /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind , /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind , /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind , /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind , /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
	/* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind , /* Very Important */
	c4_somewhat_imprtnt_ind , /* Somewhat Important */
	d4_not_imprtnt_ind , /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind , /* Volunteering */
	c5_suprt_gift_in_will_ind , /* Gift in your will */
	d5_suprt_fmly_mbr_ind , /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind , /* Gift by beneficiary designation */
	CAST(NULL AS SMALLINT) AS d5_gift_ira_chrtbl_dstrbtn_ind, /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind , /* Blood Donation */
	f5_suprt_gift_incm_life_ind , /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance) */
	b8_children_ind , /* Do you have Children? */
	c8_grand_children_ind , /* Do you have Grandchildren? */
	g8_arc_story , /* Do you have a story about how the Red Cross has touched your life? Tell us about it here. */
	survey_vrsn, /* Version of survey (English or Spanish) */
	a.dw_create_ts, 
	a.dw_updt_ts, 
	a.row_stat_cd, 
	a.appl_src_cd,
	a.load_id,
	Row_Number() Over (
   PARTITION BY c.fiscal_yr, cnst_mstr_id_xlob
   ORDER BY cnst_mstr_id_xlob, c.fiscal_yr, a.snapshot_ts ASC) as rn
FROM mktg_ops_tbls.srvy_gplg_rspns_ss  a
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e 
     ON collate(a.first_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE') AND  collate(a.last_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE') 
				AND collate(a.state::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_st_cd::text,'CASE_INSENSITIVE') AND collate(SUBSTRING(a.zip_cd,1,5)::text,'CASE_INSENSITIVE') =  collate(e.dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_vws.gms_arc_fr_smry i  
     ON e.cnst_mstr_id = i.cnst_mstr_id	
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
     ON a.first_nm = f.dm_cnst_prsn_f_nm AND  a.last_nm = f.dm_cnst_prsn_l_nm 
				AND a.state = f.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  f.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
     ON a.first_nm = g.dm_cnst_prsn_f_nm AND  a.last_nm = g.dm_cnst_prsn_l_nm 
				AND a.state = g.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  g.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
     ON a.first_nm = h.dm_cnst_prsn_f_nm AND  a.last_nm = h.dm_cnst_prsn_l_nm 
				AND a.state = h.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  h.dm_cnst_zip_5_cd
LEFT JOIN eda.dw_common_vws.dim_calendar c /* join to calendar dimension to get FY for de-duping purposes */
     ON (CAST(a.snapshot_ts AS DATE) = c.calendar_dt)  /* each PG survey respondent should have only one entry per FY  */
WHERE 
     iwebappid IN (178861986,178863995)
	
) as subquery

where rn =1

union all

SELECT	
	snapshot_ts, 
	history_record_ts, 
	srvy_respns_dt,
	history_record_id, 
	iwebappid,
    src_cd,
	adnc_mbr_id,
	survey_nm, 
	cnst_mstr_id_xlob,
	orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone,
	phone_typ,
	cntct_prfrnc,
    cntct_prfrnc_phone_ind, 
    cntct_prfrnc_email_ind,
    cntct_prfrnc_text_ind, 
	age_band,
	marital_status, 
	unit_key,
	nk_ecode,
	suprt_imprtnc , /* 'How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status ,
	a1_there_for_me_suprt_ind , /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind , /* 'I support to provide general support for the ARC programs AND services' */
	c1_dstr_suprt_ind , /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind , /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind , /* 'I support because I believe in the ARC mission' */
	f1_frnd_fmly_mbr_suprtr_ind , /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind , /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind , /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind , /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind  , /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind , /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind , /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
	/* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind , /* Very Important */
	c4_somewhat_imprtnt_ind , /* Somewhat Important */
	d4_not_imprtnt_ind , /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind , /* Volunteering */
	c5_suprt_gift_in_will_ind , /* Gift in your will */
	d5_suprt_fmly_mbr_ind , /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind , /* Gift by beneficiary designation*/
	d5_gift_ira_chrtbl_dstrbtn_ind , /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind , /* Blood Donation */
	f5_suprt_gift_incm_life_ind , /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance) */
	b8_children_ind , /* Do you have Children? */
	c8_grand_children_ind , /* Do you have Grandchildren? */
	g8_arc_story , /* Do you have a story about how the Red Cross has touched your life? Tell us about it here. */
	survey_vrsn, /* Version of survey (English or Spanish) */
	dw_create_ts, 
	dw_updt_ts, 
	row_stat_cd, 
	appl_src_cd,
	load_id
	
	from (
			SELECT	
	snapshot_ts, 
	history_record_ts, 
	CAST(history_record_ts AS DATE) AS srvy_respns_dt,
	history_record_id, 
	iwebappid,
		COALESCE(src_cd,CASE
		WHEN iwebappid = 213387808 AND CAST(snapshot_ts AS DATE) >= '2023-06-08'  THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '064E000'
		WHEN iwebappid IN (186943876, 188167818, 202240030, 213387808, 222815562) THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '014E000'
		WHEN iwebappid = 217449006 AND CAST(snapshot_ts AS DATE) <= '2023-12-31' /* identify 2023 rows */ THEN 'APP' || '24064M000'
		WHEN iwebappid = 217449006 THEN 'APP' || SUBSTRING(CAST(EXTRACT(YEAR From CAST(history_record_ts AS DATE)) AS VARCHAR(4)),3,2) || '064M000'
		WHEN iwebappid = 230991571 AND CAST(snapshot_ts AS DATE) < '2025-04-11'  THEN 'APP25024E000'
		WHEN iwebappid = 230991571 AND CAST(snapshot_ts AS DATE) >= '2025-04-11' THEN 'APP25044E000'
		END) AS src_cd,
	adnc_mbr_id,
	survey_nm, 
	a.cnst_mstr_id AS cnst_mstr_id_xlob,
	a.orig_cnst_mstr_id,
	first_nm, 
	last_nm, 
	addr1, 
	city, 
	state, 
	zip_cd,
	email, 
	phone,
	e8_phone_typ AS phone_typ,
	CAST(NULL AS VARCHAR(25)) AS cntct_prfrnc,
    g8_cntct_prfrnc_phone_ind AS cntct_prfrnc_phone_ind, 
    g8_cntct_prfrnc_email_ind AS cntct_prfrnc_email_ind,
    g8_cntct_prfrnc_text_ind AS cntct_prfrnc_text_ind, 
	age_band,
	marital_status, 
	COALESCE(e.unit_key, e.mktg_unit_key, f.unit_key, f.mktg_unit_key, g.unit_key, g.mktg_unit_key, h.unit_key, h.mktg_unit_key, 0) AS unit_key,
	COALESCE(e.unit_cd::varchar(20), e.mktg_unit_cd::varchar(20), f.unit_cd::varchar(20), f.mktg_unit_cd::varchar(20), g.unit_cd::varchar(20), g.mktg_unit_cd::varchar(20), h.unit_cd::varchar(20), h.mktg_unit_cd::varchar(20), NULL) AS nk_ecode,
	suprt_imprtnc , /* 'How important is it to you to support ARC programs (Extremely, Somewhat, Very, Not Very, No Opinion) */
	gift_plan_status ,
	a1_there_for_me_suprt_ind , /* 'I support because the ARC was there for me or my loved ones' */
	b1_gen_suprt_ind , /* 'I support to provide general support for the ARC programs AND services' */
	c1_dstr_suprt_ind , /* 'I support  in reponse to local or national disaster or emergencies' */
	d1_tax_suprt_ind , /* 'I support for tax purposes (charitable tax deduction, reduce capital gains, decrease estate taxes' */
	e1_mission_suprt_ind , /* 'I support because I believe in the ARC mission' */
	f1_frnd_fmly_mbr_suprtr_ind , /* 'I have friends or family members who are/were Red Cross supporters or volunteers' */
	a2_inflncl_persn_ind , /* 'The was an influencial person in your life that inspired you to appreciate the lifesaving work of the ARC */
	a3_pgm_safety_ind , /* 'Health and Safety programs that provide individuals with the training, knowledge AND skill to take action to help other') */
	b3_pgm_afes_ind , /* 'I support programs for member of the Armed Forcess and their families' */
	c3_pgm_biomed_ind  , /* 'Blood donation and distribution programs that collect lifesaving blood in order to meet the ongoing need' */
	d3_pgm_domestic_dstr_ind , /* 'Domestic disaster relief programs that allow the ARC to respond to disasters everywhere at any time' */
	e3_pgm_intl_dstr_ind , /* 'International relief and development programs that strive to relieve human suffering throughout the world' */
	/* When thinking about the future, how important is it to you that the Red Cross is able to continue to provide the programs listed in the previous question? */
	b4_very_imprtnt_ind , /* Very Important */
	c4_somewhat_imprtnt_ind , /* Somewhat Important */
	d4_not_imprtnt_ind , /* Not Important */
	a5_suprt_cc_ind , /* Gift via check or credit card */
	b5_suprt_vlntr_ind , /* Volunteering */
	c5_suprt_gift_in_will_ind , /* Gift in your will */
	d5_suprt_fmly_mbr_ind , /* Honoring a family member with a memorial/tribute gift in your will */
	d5_gift_bnfcry_dsgntn_ind , /* Gift by beneficiary designation*/
	d5_gift_ira_chrtbl_dstrbtn_ind , /* Gift from IRA by Qualified Charitable Distribution (QCD) */
	e5_suprt_bld_dntn_ind , /* Blood Donation */
	f5_suprt_gift_incm_life_ind , /* Gift that pays you income for life */
	g5_suprt_othr_asset_ind , /* Gift of other assets (i.e. stock, real estate, retirement/bank account or life insurance) */
	b8_children_ind , /* Do you have Children? */
	c8_grand_children_ind , /* Do you have Grandchildren? */
	g8_arc_story , /* Do you have a story about how the Red Cross has touched your life? Tell us about it here. */
	survey_vrsn, /* Version of survey (English or Spanish) */
	a.dw_create_ts, 
	a.dw_updt_ts, 
	a.row_stat_cd, 
	a.appl_src_cd,
	a.load_id,
	ROW_NUMBER() OVER (
   PARTITION BY c.fiscal_yr, cnst_mstr_id_xlob
   ORDER BY cnst_mstr_id_xlob, c.fiscal_yr, a.snapshot_ts ASC) as rn
FROM mktg_ops_tbls.srvy_gplg_rspns_ss  a
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e 
     ON collate(a.first_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE') AND collate(a.last_nm::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE') 
				AND collate(a.state::text,'CASE_INSENSITIVE') = collate(e.dm_cnst_st_cd::text,'CASE_INSENSITIVE') AND collate(SUBSTRING(a.zip_cd,1,5),'CASE_INSENSITIVE') =  collate(e.dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_vws.gms_arc_fr_smry i  
     ON e.cnst_mstr_id = i.cnst_mstr_id	
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
     ON a.first_nm = f.dm_cnst_prsn_f_nm AND a.last_nm = f.dm_cnst_prsn_l_nm 
				AND a.state = f.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  f.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
     ON a.first_nm = g.dm_cnst_prsn_f_nm AND a.last_nm = g.dm_cnst_prsn_l_nm 
				AND a.state = g.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  g.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
     ON a.first_nm = h.dm_cnst_prsn_f_nm AND a.last_nm = h.dm_cnst_prsn_l_nm 
				AND a.state = h.dm_cnst_st_cd AND SUBSTRING(a.zip_cd,1,5) =  h.dm_cnst_zip_5_cd
LEFT JOIN eda.dw_common_vws.dim_calendar c /* join to calendar dimension to get FY for de-duping purposes */
     ON (CAST(a.snapshot_ts AS DATE) = c.calendar_dt)  /* each PG survey respondent should have only one entry per FY */
WHERE 
     iwebappid IN (186943876, 188167818, 202240030, 213387808, 217449006, 222815562, 230991571) 
	 								/* FY21 Planned Giving Sponsor Survey v3.0, Email (English + Spanish versions) */
	                               	/* FY22 Planned Giving Sponsor Survey v4.0, Email */
	                               	/* FY23 Planned Giving Sponsor Survey v5.0, Email */
								   	/* FY23 Planned Giving Sponsor Survey v5.1, Email */
								   	/* FY24 Online - Planned Giving Supporter Survey V6.0 */ 
								   	/* FY25 Online - Planned Giving Supporter Survey V7.0 */
       --AND history_record_ts >= TIMESTAMP '2021-01-11 23:59:59' /* filter out test rows */

	
	
	) as subqry
	
 
	where rn =1
	with no schema binding;