CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_new_anvrsy_vlntr_rspns()
 LANGUAGE plpgsql
AS $$


	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_new_anvrsy_vlntr_rspns', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
insert into mktg_ops_tbls.srvy_new_anvrsy_vlntr_rspns 
Select        
		snapshot_ts, 
		history_record_ts, 
		history_record_id, 
		adnc_mbr_id,
		nvsr.cnst_mstr_id,
		nvsr.orig_cnst_mstr_id,
		last_nm,
		email,
		survey_nm,
		vlntr_length,
		a2_blood_svc_ind,
		b2_gen_admin_sprt_srvc_ind,
		c2_saf_srvc_ind,
		d2_comnty_srvc_ind,
		e2_health_safety_srvc_ind,
		f2_vlntr_srvc_ind,
		g2_dstr_srvc_ind,
		h2_intl_srvc_ind,
		i2_youth_prgrm_srvc_ind,
		j2_fr_srvc_ind,
		k2_ldrshp_ind,
		l2_other_srvc_ind,
		CAST(NULL AS VARCHAR(3)) AS vol_area_no_answer,   
		vlntr_area_cmt AS other_srvc_cmt,
		vlntr_xprnc_rtng,
	CAST(CASE 
		WHEN vlntr_xprnc_rtng_dsc = 'Very Satisfactory'  THEN 'Excellent'
		WHEN vlntr_xprnc_rtng_dsc =  'Satisfactory' THEN 'Very Good' 
		WHEN vlntr_xprnc_rtng_dsc =  'Somewhat Satisfactory' THEN 'Above Average' 
		WHEN vlntr_xprnc_rtng_dsc =  'Somewhat Unsatisfactory' THEN 'Below Average'
		WHEN vlntr_xprnc_rtng_dsc =  'Unsatisfactory' THEN 'Poor' 
		WHEN vlntr_xprnc_rtng_dsc = 'Very Unsatisfactory' THEN  'Extremely Poor' 
		WHEN vlntr_xprnc_rtng_dsc IS NULL THEN 'No Response'
		ELSE vlntr_xprnc_rtng_dsc
	END AS VARCHAR(50)) AS vlntr_xprnc_rtng_dsc,	
		rcmnd_frnd_vlntr_rtng, 
		rcmnd_frnd_vlntr_rtng_dsc,
		why_scr_cmt,
		CAST(a6_vlntr_sprt_rtng AS smallint) AS a6_vlntr_sprt_rtng,
		CAST(a6_vlntr_sprt_rtng_dsc AS VARCHAR(25)) AS a6_vlntr_sprt_rtng_dsc,
		CAST(b6_expctn_rtng AS smallint) AS b6_expctn_rtng,
		CAST(b6_expctn_rtng_dsc AS VARCHAR(25)) AS b6_expctn_rtng_dsc,
		CAST(c6_trng_mtrl_rtng AS smallint) AS c6_trng_mtrl_rtng,
		CAST(c6_trng_mtrl_rtng_dsc AS VARCHAR(25)) AS c6_trng_mtrl_rtng_dsc,
		CAST(d6_tmwrk_good_rtng AS smallint) AS d6_tmwrk_good_rtng,
		CAST(d6_tmwrk_good_rtng_dsc AS VARCHAR(25)) AS d6_tmwrk_good_rtng_dsc,
		CAST(e6_team_value_rtng AS smallint) AS e6_team_value_rtng,
		CAST(e6_team_value_rtng_dsc AS VARCHAR(25)) AS e6_team_value_rtng_dsc,
		CAST(f6_rspct_sprvsr_rtng AS smallint) AS f6_rspct_sprvsr_rtng,
		CAST(f6_rspct_sprvsr_rtng_dsc AS VARCHAR(25)) AS f6_rspct_sprvsr_rtng_dsc,
		CAST(g6_bhvr_cnstnt_rtng AS smallint) AS g6_bhvr_cnstnt_rtng,
		CAST(g6_bhvr_cnstnt_rtng_dsc AS VARCHAR(25)) AS g6_bhvr_cnstnt_rtng_dsc,
		CAST(h6_prspctv_value_rtng AS smallint) AS h6_prspctv_value_rtng,
		CAST(h6_prspctv_value_rtng_dsc AS VARCHAR(25)) AS h6_prspctv_value_rtng_dsc,
		CAST(i6_vlntr_cont_rtng AS smallint) AS i6_vlntr_cont_rtng,
		CAST(i6_vlntr_cont_rtng_dsc AS VARCHAR(25)) AS i6_vlntr_cont_rtng_dsc,
		vlntr_exp_cmt,
		vlntr_hrs_value,
        vlntr_hrs_dsc,
		a9_dntd_bld_ind,
		b9_dntd_mny_ind,
		c9_prprdns_app_ind,
		d9_hs_crs_ind,
		e9_ref_fmly_ind,
		f9_none_ind,
		CAST(NULL AS smallint) AS l12mo_have_you_no_answer, /* This was on the previous survey but not on current version*/ 
		a10_vlntr_exprnc_easy_rtng,
		a10_vlntr_exprnc_easy_rtng_dsc,
		b10_vlntr_cnctn_usfl_rtng,
		b10_vlntr_cnctn_usfl_rtng_dsc,
		c10_vlntr_cnctn_easy_rtng,
		c10_vlntr_cnctn_easy_rtng_dsc,
		a11_arc_cmptr_rtng,
		a11_arc_cmptr_rtng_dsc,
		b11_arc_email_rtng,
		b11_arc_email_rtng_dsc,
		c11_arc_xchng_rtng,
		c11_arc_xchng_rtng_dsc,
		d11_arc_edge_rtng,
		d11_arc_edge_rtng_dsc,
		arc_edctn_lvl_value,
		arc_edctn_lvl_dsc,
		vlntr_dscrptn_value,
		vlntr_dscrptn_dsc,
		nvsr.dw_create_ts,
		nvsr.dw_updt_ts,
		nvsr.row_stat_cd,
		nvsr.appl_src_cd,
		nvsr.load_id,
		svp.dm_cnst_zip_5_cd, 
		case when msz.zip_cd is not null then msz.zip_cd 
					when msz_mktg.zip_cd is not null then msz_mktg.zip_cd
					else svp.dm_cnst_zip_5_cd 
		end as attribtn_zip_5_cd,
		svp.unit_key,
		svp.mktg_unit_key,
		svp.mktg_unit_cd,
		um.unit_nm,
		um.cs_region_cd as cs_region_cd,
        um.cs_region_nm AS region_nm,
        um.division_cd,
		um.division_dsc,
		dz.district_cd district_cd, 
	    dz.district_name district_nm,
	    dz.zip unit_zip,
		dz.orc_division_id, 
		dz.orc_division_name, 
		dz.ds_region_id, 
		dz.ds_region_name,
	    dz.geo_lat_lon_ID, 
	    dz.geo_centriod_lat, 
	    dz.geo_centriod_lon,
	    reg.region_nm as bio_region_nm, 
	    reg.division_dsc as bio_division_dsc, 
	    reg.ldrshp_nm,
		cal.fiscal_yr
FROM	mktg_ops_tbls.srvy_anvrsy_vlntr_rspns nvsr
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON nvsr.cnst_mstr_id = svp.cnst_mstr_id
LEFT JOIN eda.dw_common_vws.dim_unit_merged um ON svp.unit_key = um.orig_unit_key
LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter geo ON svp.dm_cnst_zip_5_cd = geo.zip
LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = um.unit_zip
LEFT JOIN eda.dw_common_vws.dim_region reg ON SUBSTRING(dz.region_code,1,3) = reg.nk_region_id
LEFT JOIN eda.dw_common_vws.dim_calendar cal    ON (CAST(nvsr.snapshot_ts AS DATE) = cal.calendar_dt)
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz on um.nk_ecode= msz.nk_ecode /*10/30/2019 - MTA modifiied the join svp.unit_cd = msz.nk_ecode */
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg on svp.mktg_unit_cd = msz_mktg.nk_ecode;



insert into mktg_ops_tbls.srvy_new_anvrsy_vlntr_rspns 
SELECT 
	CAST(nk_survey_start_ts AS TIMESTAMP) AS snapshot_ts,
	CAST(nk_survey_start_ts AS TIMESTAMP) AS history_record_ts,
	CAST(NULL AS INTEGER) AS history_record_id, 
	CAST(NULL AS INTEGER) AS adnc_mbr_id,
	CAST(fsr.cnst_mstr_id AS BIGINT) AS cnst_mstr_id, 
	CAST(fsr.orig_cnst_mstr_id AS BIGINT) AS orig_cnst_mstr_id, 
	CAST(NULL AS VARCHAR(255)) AS last_nm,
	CAST(NULL AS VARCHAR(255)) AS email,
	CAST(NULL AS VARCHAR(255)) AS survey_nm,
	volunteer_length:: VARCHAR(75) AS vlntr_length, 
	vol_area_blood_services AS a2_blood_svc_ind,
	vol_area_general_admin AS b2_gen_admin_sprt_srvc_ind, 
	vol_area_armed_forces AS c2_saf_srvc_ind, 
	vol_area_community_services AS d2_comnty_srvc_ind, 
	vol_area_health_safety AS e2_health_safety_srvc_ind, 
	vol_area_volunteer AS f2_vlntr_srvc_ind,
	vol_area_disaster_services AS g2_dstr_srvc_ind, 
	vol_area_international AS h2_intl_srvc_ind,
	vol_area_youth AS i2_youth_prgrm_srvc_ind, 
	vol_area_fundraising_financial AS j2_fr_srvc_ind,
	vol_area_leadership AS k2_ldrshp_ind, 
	vol_area_other AS l2_other_srvc_ind, 
	vol_area_no_answer,
	CAST(NULL AS VARCHAR(4000)) AS other_srvc_cmt, /* this attribute did not exist on the original survey */
	CAST(CASE 
		WHEN rc_vol_experience_overal = 'Excellent' THEN '1'
		WHEN rc_vol_experience_overal = 'Very Good' THEN '2'
		WHEN rc_vol_experience_overal = 'Above Average' THEN '3'
		WHEN rc_vol_experience_overal = 'Below Average' THEN '4'
		WHEN rc_vol_experience_overal = 'Poor' THEN '5'
		WHEN rc_vol_experience_overal = 'Extremely Poor' THEN '6'
	END AS SMALLINT) AS vlntr_xprnc_rtng,
	rc_vol_experience_overal as vlntr_xprnc_rtng_dsc,
	CAST(CASE
		WHEN recomdn_arc_2_org_or_volutr = '0 - Not At All Likely' THEN '0'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=1' THEN '1'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=2' THEN '2'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=3' THEN '3'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=4' THEN '4'
		WHEN recomdn_arc_2_org_or_volutr = '5 - Neutral' THEN '5'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=6' THEN '6'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=7' THEN '7'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=8' THEN '8'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=9' THEN '9'
		WHEN recomdn_arc_2_org_or_volutr = '10 - Extremely Likely' THEN '10'
		WHEN recomdn_arc_2_org_or_volutr IS NULL THEN NULL
	END AS SMALLINT) AS rcmnd_frnd_vlntr_val,
	CAST(CASE
		WHEN recomdn_arc_2_org_or_volutr = '0 - Not At All Likely' THEN '0 - Not at all Likely'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=1' THEN '1'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=2' THEN '2'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=3' THEN '3'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=4' THEN '4'
		WHEN recomdn_arc_2_org_or_volutr = '5 - Neutral' THEN '5 - Neutral'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=6' THEN '6'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=7' THEN '7'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=8' THEN '8'
		WHEN recomdn_arc_2_org_or_volutr = 'Likely to Recommend=9' THEN '9'
		WHEN recomdn_arc_2_org_or_volutr = '10 - Extremely Likely' THEN '10 - Extremely Likely'
		WHEN recomdn_arc_2_org_or_volutr IS NULL THEN 'No Response Provided'
	END AS VARCHAR(50)) AS rcmnd_frnd_vlntr_dsc,
	CAST(NULL AS VARCHAR(4000)) AS why_scr_cmt, /* this attribute did not exist on the original survey */
	CASE
		WHEN a8_my_volun_2_arc_mission = 'Strongly Agree' THEN 1
		WHEN a8_my_volun_2_arc_mission = 'Agree' THEN 2
		WHEN a8_my_volun_2_arc_mission = 'Somewhat Agree' THEN 3
		WHEN a8_my_volun_2_arc_mission = 'Somewhat Disagree' THEN 4
		WHEN a8_my_volun_2_arc_mission = 'Disagree' THEN 5
		WHEN a8_my_volun_2_arc_mission = 'Strongly Disagree' THEN 6
		WHEN a8_my_volun_2_arc_mission = 'Does Not Apply' THEN 99 
	END AS a6_vlntr_sprt_rtng, 
	a8_my_volun_2_arc_mission AS a6_vlntr_sprt_rtng_dsc,
	CASE
		WHEN b8_expect_of_me = 'Strongly Agree' THEN 1
		WHEN b8_expect_of_me = 'Agree' THEN 2
		WHEN b8_expect_of_me = 'Somewhat Agree' THEN 3
		WHEN b8_expect_of_me = 'Somewhat Disagree' THEN 4
		WHEN b8_expect_of_me = 'Disagree' THEN 5
		WHEN b8_expect_of_me = 'Strongly Disagree' THEN 6
		WHEN b8_expect_of_me = 'Does Not Apply' THEN 99 
	END AS b6_expctn_rtng, 	
	b8_expect_of_me AS b6_expctn_rtng_dsc,
	CASE
		WHEN c8_arc_training_prepared_me = 'Strongly Agree' THEN 1
		WHEN c8_arc_training_prepared_me = 'Agree' THEN 2
		WHEN c8_arc_training_prepared_me = 'Somewhat Agree' THEN 3
		WHEN c8_arc_training_prepared_me = 'Somewhat Disagree' THEN 4
		WHEN c8_arc_training_prepared_me = 'Disagree' THEN 5
		WHEN c8_arc_training_prepared_me = 'Strongly Disagree' THEN 6
		WHEN c8_arc_training_prepared_me = 'Does Not Apply' THEN 99
	END AS c6_trng_mtrl_rtng, 	
	c8_arc_training_prepared_me AS c6_trng_mtrl_rtng_dsc, 
	CASE
		WHEN d8_empl_volun_teamwork = 'Strongly Agree' THEN 1
		WHEN d8_empl_volun_teamwork = 'Agree' THEN 2
		WHEN d8_empl_volun_teamwork = 'Somewhat Agree' THEN 3
		WHEN d8_empl_volun_teamwork = 'Somewhat Disagree' THEN 4
		WHEN d8_empl_volun_teamwork = 'Disagree' THEN 5
		WHEN d8_empl_volun_teamwork = 'Strongly Disagree' THEN 6
		WHEN d8_empl_volun_teamwork = 'Does Not Apply' THEN 99 
	END AS d6_tmwrk_good_rtng, 	
	d8_empl_volun_teamwork AS d6_tmwrk_good_rtng_dsc, 
	CASE
		WHEN e8_valued_member = 'Strongly Agree' THEN 1
		WHEN e8_valued_member = 'Agree' THEN 2
		WHEN e8_valued_member = 'Somewhat Agree' THEN 3
		WHEN e8_valued_member = 'Somewhat Disagree' THEN 4
		WHEN e8_valued_member = 'Disagree' THEN 5
		WHEN e8_valued_member = 'Strongly Disagree' THEN 6
		WHEN e8_valued_member = 'Does Not Apply' THEN 99
	END AS e6_team_value_rtng, 	
	e8_valued_member AS e6_team_value_rtng_dsc,
	CASE
		WHEN f8_sprvsr_mgr_respect = 'Strongly Agree' THEN 1
		WHEN f8_sprvsr_mgr_respect = 'Agree' THEN 2
		WHEN f8_sprvsr_mgr_respect = 'Somewhat Agree' THEN 3
		WHEN f8_sprvsr_mgr_respect = 'Somewhat Disagree' THEN 4
		WHEN f8_sprvsr_mgr_respect = 'Disagree' THEN 5
		WHEN f8_sprvsr_mgr_respect = 'Strongly Disagree' THEN 6
		WHEN f8_sprvsr_mgr_respect = 'Does Not Apply' THEN 99 
	END AS f6_rspct_sprvsr_rtng, 	
	f8_sprvsr_mgr_respect AS f6_rspct_sprvsr_rtng_dsc, 
	CASE
		WHEN g8_shared_vision_coworkers = 'Strongly Agree' THEN 1
		WHEN g8_shared_vision_coworkers = 'Agree' THEN 2
		WHEN g8_shared_vision_coworkers = 'Somewhat Agree' THEN 3
		WHEN g8_shared_vision_coworkers = 'Somewhat Disagree' THEN 4
		WHEN g8_shared_vision_coworkers = 'Disagree' THEN 5
		WHEN g8_shared_vision_coworkers = 'Strongly Disagree' THEN 6
		WHEN g8_shared_vision_coworkers = 'Does Not Apply' THEN 99 
	END AS g6_bhvr_cnstnt_rtng, 	
	g8_shared_vision_coworkers AS g6_bhvr_cnstnt_rtng_dsc, 
	CASE
		WHEN h8_diverse_ideas_valued = 'Strongly Agree' THEN 1
		WHEN h8_diverse_ideas_valued = 'Agree' THEN 2
		WHEN h8_diverse_ideas_valued = 'Somewhat Agree' THEN 3
		WHEN h8_diverse_ideas_valued = 'Somewhat Disagree' THEN 4
		WHEN h8_diverse_ideas_valued = 'Disagree' THEN 5
		WHEN h8_diverse_ideas_valued = 'Strongly Disagree' THEN 6
		WHEN h8_diverse_ideas_valued = 'Does Not Apply' THEN 99 
	END AS h6_prspctv_value_rtng, 	
	h8_diverse_ideas_valued AS h6_prspctv_value_rtng_dsc,
	CASE
		WHEN i8_cont_as_arc_volun = 'Strongly Agree' THEN 1
		WHEN i8_cont_as_arc_volun = 'Agree' THEN 2
		WHEN i8_cont_as_arc_volun = 'Somewhat Agree' THEN 3
		WHEN i8_cont_as_arc_volun = 'Somewhat Disagree' THEN 4
		WHEN i8_cont_as_arc_volun = 'Disagree' THEN 5
		WHEN i8_cont_as_arc_volun = 'Strongly Disagree' THEN 6
		WHEN i8_cont_as_arc_volun = 'Does Not Apply' THEN 99 
	END AS i6_vlntr_cont_rtng, 	
	i8_cont_as_arc_volun AS i6_vlntr_cont_rtng_dsc,
	CAST(NULL AS VARCHAR(4000)) AS vlntr_exp_cmt, /* this attribute did not exist on the original survey */
	CAST(CASE 
			WHEN l12mo_hrs_each_mo_volun = '10 hours or less per month' THEN 1
			WHEN l12mo_hrs_each_mo_volun = '11 to 20 hours per month' THEN 2
			WHEN l12mo_hrs_each_mo_volun = '21 to 80 hours per month' THEN 3
			WHEN l12mo_hrs_each_mo_volun = 'More than 80 hours per month' THEN 4
			WHEN l12mo_hrs_each_mo_volun = 'Did not volunteer in past 12 months' THEN 5
			WHEN l12mo_hrs_each_mo_volun IS NULL THEN NULL
			ELSE NULL
	END AS SMALLINT) AS vlntr_hrs_val,
	CAST(CASE 
		WHEN l12mo_hrs_each_mo_volun IS NULL THEN 'Did not Answer'
		ELSE l12mo_hrs_each_mo_volun
	END AS VARCHAR(50)) AS vlntr_hrs_dsc, 
	l12mo_have_you_donated_blood AS a9_dntd_bld_ind,
	l12mo_have_you_donated_money AS b9_dntd_mny_ind, 
	l12mo_have_you_downloaded AS c9_prprdns_app_ind, 
	l12mo_have_you_hlth_sfty_crse AS d9_hs_crs_ind,
	0 as e9_ref_fmly_ind, -- NOTE: This an option on the new survey version that was not on the original.
	l12mo_have_you_none AS f9_none_ind, 
	l12mo_have_you_no_answer,
	CAST(CASE
				WHEN usefulness_of_volunteer_connec = 'Strongly Agree' THEN 1
				WHEN usefulness_of_volunteer_connec = 'Agree' THEN 2
				WHEN usefulness_of_volunteer_connec = 'Somewhat Agree' THEN 3
				WHEN usefulness_of_volunteer_connec = 'Somewhat Disagree' THEN 4
				WHEN usefulness_of_volunteer_connec = 'Disagree' THEN 5
				WHEN usefulness_of_volunteer_connec = 'Strongly Disagree' THEN 6
				WHEN usefulness_of_volunteer_connec = 'Does Not Apply' THEN 99
	END AS SMALLINT) AS a10_vlntr_exprnc_easy_rtng,
	CAST(usefulness_of_volunteer_connec AS VARCHAR(25)) AS a10_vlntr_exprnc_easy_rtng_dsc,
	CAST(CASE
				WHEN usefulness_of_volunteer_connec2 = 'Strongly Agree' THEN 1
				WHEN usefulness_of_volunteer_connec2 = 'Agree' THEN 2
				WHEN usefulness_of_volunteer_connec2 = 'Somewhat Agree' THEN 3
				WHEN usefulness_of_volunteer_connec2 = 'Somewhat Disagree' THEN 4
				WHEN usefulness_of_volunteer_connec2 = 'Disagree' THEN 5
				WHEN usefulness_of_volunteer_connec2 = 'Strongly Disagree' THEN 6
				WHEN usefulness_of_volunteer_connec2 = 'Does Not Apply' THEN 99
	END AS SMALLINT) AS b10_vlntr_cnctn_usfl_rtng,
	CAST(usefulness_of_volunteer_connec2  AS VARCHAR(25)) AS b10_vlntr_cnctn_usfl_rtng_dsc,
	CAST(CASE
				WHEN usefulness_of_volunteer_connec3 = 'Strongly Agree' THEN 1
				WHEN usefulness_of_volunteer_connec3 = 'Agree' THEN 2
				WHEN usefulness_of_volunteer_connec3 = 'Somewhat Agree' THEN 3
				WHEN usefulness_of_volunteer_connec3 = 'Somewhat Disagree' THEN 4
				WHEN usefulness_of_volunteer_connec3 = 'Disagree' THEN 5
				WHEN usefulness_of_volunteer_connec3 = 'Strongly Disagree' THEN 6
				WHEN usefulness_of_volunteer_connec3 = 'Does Not Apply' THEN 99
	END AS SMALLINT) AS c10_vlntr_cnctn_easy_rtng,
	CAST(usefulness_of_volunteer_connec3  AS VARCHAR(25)) AS c10_vlntr_cnctn_easy_rtng_dsc,
	CAST(TECH_EXPERIENCE_COMPUTER AS SMALLINT) AS a11_arc_cmptr_rtng,
	CAST(CASE 
	  WHEN TECH_EXPERIENCE_COMPUTER = '6' THEN 'Very Satisfactory'
	  WHEN TECH_EXPERIENCE_COMPUTER = '5' THEN 'Satisfactory'
	  WHEN TECH_EXPERIENCE_COMPUTER = '4' THEN 'Somewhat Satisfactory'
	  WHEN TECH_EXPERIENCE_COMPUTER = '3' THEN 'Somewhat Unsatisfactory'
	  WHEN TECH_EXPERIENCE_COMPUTER = '2' THEN 'Unsatisfactory'
	  WHEN TECH_EXPERIENCE_COMPUTER = '1' THEN 'Very Unsatisfactory'
	  WHEN TECH_EXPERIENCE_COMPUTER = '0' THEN 'Does Not Apply'
	  ELSE NULL 
	END AS VARCHAR(25)) AS a11_arc_cmptr_rtng_dsc,
	CAST(TECH_EXPERIENCE_EMAIL AS SMALLINT) AS b11_arc_email_rtng,
	CAST(CASE 
	  WHEN TECH_EXPERIENCE_EMAIL = '6' THEN 'Very Satisfactory'
	  WHEN TECH_EXPERIENCE_EMAIL = '5' THEN 'Satisfactory'
	  WHEN TECH_EXPERIENCE_EMAIL = '4' THEN 'Somewhat Satisfactory'
	  WHEN TECH_EXPERIENCE_EMAIL = '3' THEN 'Somewhat Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EMAIL = '2' THEN 'Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EMAIL = '1' THEN 'Very Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EMAIL = '0' THEN 'Does Not Apply'
	  ELSE NULL 
	END AS VARCHAR(25)) AS b11_arc_email_rtng_dsc,
	CAST(TECH_EXPERIENCE_EXCHANGE AS SMALLINT) AS c11_arc_xchng_rtng,
	CAST(CASE 
	  WHEN TECH_EXPERIENCE_EXCHANGE = '6' THEN 'Very Satisfactory'
	  WHEN TECH_EXPERIENCE_EXCHANGE = '5' THEN 'Satisfactory'
	  WHEN TECH_EXPERIENCE_EXCHANGE = '4' THEN 'Somewhat Satisfactory'
	  WHEN TECH_EXPERIENCE_EXCHANGE = '3' THEN 'Somewhat Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EXCHANGE = '2' THEN 'Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EXCHANGE = '1' THEN 'Very Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EXCHANGE = '0' THEN 'Does Not Apply'
	  ELSE NULL 
	END AS VARCHAR(25)) AS c11_arc_xchng_rtng_dsc,
	CAST(TECH_EXPERIENCE_EDGE AS SMALLINT) AS d11_arc_edge_rtng,
	CAST(CASE 
	  WHEN TECH_EXPERIENCE_EDGE = '6' THEN 'Very Satisfactory'
	  WHEN TECH_EXPERIENCE_EDGE = '5' THEN 'Satisfactory'
	  WHEN TECH_EXPERIENCE_EDGE = '4' THEN 'Somewhat Satisfactory'
	  WHEN TECH_EXPERIENCE_EDGE = '3' THEN 'Somewhat Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EDGE = '2' THEN 'Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EDGE = '1' THEN 'Very Unsatisfactory'
	  WHEN TECH_EXPERIENCE_EDGE = '0' THEN 'Does Not Apply'
	  ELSE NULL 
	END AS VARCHAR(25)) AS d11_arc_edge_rtng_dsc, 
	CAST(NULL AS SMALLINT) AS arc_edctn_lvl_value,
	CAST(NULL AS VARCHAR(50)) AS arc_edctn_lvl_dsc,
	CAST(NULL AS SMALLINT) AS vlntr_dscrptn_value,
	CAST(NULL AS VARCHAR(50)) AS vlntr_dscrptn_dsc,
	CAST(NULL AS TIMESTAMP) AS dw_create_ts,
	CAST(NULL AS TIMESTAMP) AS dw_updt_ts,
	CAST(NULL AS CHAR(1)) AS row_stat_cd,
	CAST(NULL AS CHAR(4)) AS appl_src_cd,
	CAST(NULL AS INTEGER) AS load_id,
	svp.dm_cnst_zip_5_cd,  
	case when msz.zip_cd is not null then msz.zip_cd 
				when msz_mktg.zip_cd is not null then msz_mktg.zip_cd
				else svp.dm_cnst_zip_5_cd 
	end as attribtn_zip_5_cd,
	svp.unit_key,
	svp.mktg_unit_key,
	svp.mktg_unit_cd,
	um.unit_nm,
	um.cs_region_cd,
    um.cs_region_nm AS region_nm,
    um.division_cd,
	um.division_dsc,
    dz.district_cd unit_district_cd, 
    dz.district_name unit_district_nm,
    dz.zip unit_zip,
	dz.orc_division_id, 
	dz.orc_division_name, 
	dz.ds_region_id, 
	dz.ds_region_name,
    dz.geo_lat_lon_ID, 
    dz.geo_centriod_lat, 
    dz.geo_centriod_lon,
    reg.region_nm as bio_region_nm, 
    reg.division_dsc as bio_division_dsc, 
    reg.ldrshp_nm,
	cal.fiscal_yr
FROM mktg_ops_tbls.bzfc_fact_surv_resp fsr
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON fsr.cnst_mstr_id = svp.cnst_mstr_id
LEFT JOIN eda.dw_common_vws.dim_unit_merged um ON svp.unit_key = um.orig_unit_key
LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter geo ON svp.dm_cnst_zip_5_cd = geo.zip
LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = um.unit_zip
LEFT JOIN eda.dw_common_vws.dim_region reg ON SUBSTRING(dz.Region_Code,1,3) = reg.nk_region_id
LEFT JOIN eda.dw_common_vws.dim_calendar cal ON (CAST(nk_survey_start_ts AS DATE) = cal.calendar_dt)
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz on um.nk_ecode= msz.nk_ecode /*10/30/2019 - MTA modifiied the join svp.unit_cd = msz.nk_ecode */
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg on svp.mktg_unit_cd = msz_mktg.nk_ecode;

------------------------------------------626 to 743------------------------------------------------------------------------------------------------

insert into mktg_ops_tbls.srvy_new_anvrsy_vlntr_rspns 
SELECT	
        snapshot_ts, 
		history_record_ts, 
		history_record_id, 
		adnc_mbr_id,
		nvsr.cnst_mstr_id,
		nvsr.orig_cnst_mstr_id,
		last_nm,
		email,
		survey_nm,
		vlntr_length,
		b5_blood_svc_ind,-- a2_blood_svc_ind,
		c5_gen_admin_sprt_srvc_ind,
		d5_saf_srvc_ind, --c2_saf_srvc_ind,
		e5_comnty_srvc_ind,
		f5_trng_srvc_ind, -- e2_health_safety_srvc_ind,
		g5_vlntr_srvc_ind,
		h5_dstr_srvc_ind,
		i5_intl_srvc_ind,
		j5_youth_prgrm_srvc_ind,
		k5_fr_srvc_ind,
		l5_ldrshp_ind,
		null as l2_other_srvc_ind ,
		CAST(NULL AS VARCHAR(3)) AS vol_area_no_answer,
		CAST(NULL AS VARCHAR(3)) /*vlntr_area_cmt*/ AS other_srvc_cmt,
		vlntr_xprnc_rtng,
		vlntr_xprnc_rtng_dsc,
		rcmnd_frnd_vlntr_rtng, 
		rcmnd_frnd_vlntr_rtng_dsc,
		why_scr_cmt,
		CAST(a6_vlntr_sprt_rtng AS SMALLINT) AS a6_vlntr_sprt_rtng,
		CAST(a6_vlntr_sprt_rtng_dsc AS VARCHAR(25)) AS a6_vlntr_sprt_rtng_dsc,
		CAST(b6_expctn_rtng AS SMALLINT) AS b6_expctn_rtng,
		CAST(b6_expctn_rtng_dsc AS VARCHAR(25)) AS b6_expctn_rtng_dsc,
		CAST(c6_trng_mtrl_rtng AS SMALLINT) AS c6_trng_mtrl_rtng,
		CAST(c6_trng_mtrl_rtng_dsc AS VARCHAR(25)) AS c6_trng_mtrl_rtng_dsc,
		CAST(d6_tmwrk_good_rtng AS SMALLINT) AS d6_tmwrk_good_rtng,
		CAST(d6_tmwrk_good_rtng_dsc AS VARCHAR(25)) AS d6_tmwrk_good_rtng_dsc,
		CAST(e6_team_value_rtng AS SMALLINT) AS e6_team_value_rtng,
		CAST(e6_team_value_rtng_dsc AS VARCHAR(25)) AS e6_team_value_rtng_dsc,
		CAST(f6_rspct_sprvsr_rtng AS SMALLINT) AS f6_rspct_sprvsr_rtng,
		CAST(f6_rspct_sprvsr_rtng_dsc AS VARCHAR(25)) AS f6_rspct_sprvsr_rtng_dsc,
		CAST(g6_bhvr_cnstnt_rtng AS SMALLINT) AS g6_bhvr_cnstnt_rtng,
		CAST(g6_bhvr_cnstnt_rtng_dsc AS VARCHAR(25)) AS g6_bhvr_cnstnt_rtng_dsc,
		CAST(h6_prspctv_value_rtng AS SMALLINT) AS h6_prspctv_value_rtng,
		CAST(h6_prspctv_value_rtng_dsc AS VARCHAR(25)) AS h6_prspctv_value_rtng_dsc,
		CAST(i6_vlntr_cont_rtng AS SMALLINT) AS i6_vlntr_cont_rtng,
		CAST(i6_vlntr_cont_rtng_dsc AS VARCHAR(25)) AS i6_vlntr_cont_rtng_dsc,
		vlntr_exp_cmt,
		vlntr_hrs_value,
        vlntr_hrs_dsc,
		a9_dntd_bld_ind,
		b9_dntd_mny_ind,
		c9_prprdns_app_ind,
		d9_hs_crs_ind,
		e9_ref_fmly_ind,
		f9_none_ind,
		CAST(NULL AS SMALLINT) AS l12mo_have_you_no_answer, /* This was on the previous survey but not on current version*/ 
		--FY21 survey removed the below questions
		CAST(NULL AS SMALLINT) a10_vlntr_exprnc_easy_rtng,
		CAST(NULL AS VARCHAR(25)) a10_vlntr_exprnc_easy_rtng_dsc,
		CAST(NULL AS SMALLINT) b10_vlntr_cnctn_usfl_rtng,
		CAST(NULL AS VARCHAR(25)) b10_vlntr_cnctn_usfl_rtng_dsc,
		CAST(NULL AS SMALLINT) c10_vlntr_cnctn_easy_rtng,
		CAST(NULL AS VARCHAR(25)) c10_vlntr_cnctn_easy_rtng_dsc,
		CAST(NULL AS SMALLINT) a11_arc_cmptr_rtng,
		CAST(NULL AS VARCHAR(25)) a11_arc_cmptr_rtng_dsc,
		CAST(NULL AS SMALLINT) b11_arc_email_rtng,
		CAST(NULL AS VARCHAR(25)) b11_arc_email_rtng_dsc,
		CAST(NULL AS SMALLINT) c11_arc_xchng_rtng,
		CAST(NULL AS VARCHAR(25)) c11_arc_xchng_rtng_dsc,
		CAST(NULL AS SMALLINT) d11_arc_edge_rtng,
		CAST(NULL AS VARCHAR(25)) d11_arc_edge_rtng_dsc,
		CAST(NULL AS SMALLINT) arc_edctn_lvl_value,
		CAST(NULL AS VARCHAR(25)) arc_edctn_lvl_dsc,
		CAST(NULL AS SMALLINT) vlntr_dscrptn_value,
		CAST(NULL AS VARCHAR(25)) vlntr_dscrptn_dsc,
		nvsr.dw_create_ts,
		nvsr.dw_updt_ts,
		nvsr.row_stat_cd,
		nvsr.appl_src_cd,
		nvsr.load_id,
		svp.dm_cnst_zip_5_cd, 
		case when msz.zip_cd is not null then msz.zip_cd 
					when msz_mktg.zip_cd is not null then msz_mktg.zip_cd
					else svp.dm_cnst_zip_5_cd 
		end as attribtn_zip_5_cd,
		svp.unit_key,
		svp.mktg_unit_key,
		svp.mktg_unit_cd,
		um.unit_nm,
		um.cs_region_cd,
        um.cs_region_nm AS region_nm,
        um.division_cd,
		um.division_dsc,
		dz.district_cd district_cd, 
	    dz.district_name district_nm,
	    dz.zip unit_zip,
		dz.orc_division_id, 
		dz.orc_division_name, 
		dz.ds_region_id, 
		dz.ds_region_name,
	    dz.geo_lat_lon_ID, 
	    dz.geo_centriod_lat, 
	    dz.geo_centriod_lon,
	    reg.region_nm as bio_region_nm, 
	    reg.division_dsc as bio_division_dsc, 
	    reg.ldrshp_nm,
		cal.fiscal_yr 
		
FROM	mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy21 nvsr
LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON nvsr.cnst_mstr_id = svp.cnst_mstr_id
LEFT JOIN eda.dw_common_vws.dim_unit_merged um ON svp.unit_key = um.orig_unit_key
LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter geo ON svp.dm_cnst_zip_5_cd = geo.zip
LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = um.unit_zip
LEFT JOIN eda.dw_common_vws.dim_region reg ON SUBSTRING(dz.region_code,1,3) = reg.nk_region_id
LEFT JOIN eda.dw_common_vws.dim_calendar cal    ON (CAST(nvsr.snapshot_ts AS DATE) = cal.calendar_dt)
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz on um.nk_ecode= msz.nk_ecode /*10/30/2019 - MTA modifiied the join svp.unit_cd = msz.nk_ecode */
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg on svp.mktg_unit_cd = msz_mktg.nk_ecode;



		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.mktg_ops_tbls.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.srvy_new_anvrsy_vlntr_rspns) as INTEGER)
			WHERE proc_name = 'ld_srvy_new_anvrsy_vlntr_rspns' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_srvy_new_anvrsy_vlntr_rspns', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
