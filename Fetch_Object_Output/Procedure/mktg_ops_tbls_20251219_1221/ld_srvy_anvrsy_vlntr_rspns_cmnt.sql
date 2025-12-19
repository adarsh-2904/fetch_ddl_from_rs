CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_anvrsy_vlntr_rspns_cmnt()
 LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_anvrsy_vlntr_rspns_cmnt', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN
		/* First, truncate data from the table then insert the new data */
		Truncate table mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_stg;

		/* Now reload the table with the current data */
		--1st insert
		INSERT INTO mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_stg
		WITH anvrsy_cte AS (
			SELECT
				snapshot_ts,
				history_record_ts,
				history_record_id,
				adnc_mbr_id,
				cnst_mstr_id,
				orig_cnst_mstr_id,
				last_nm,
				email,
				survey_nm,
				other_srvc_cmt,
				why_scr_cmt,
				why_scr_tmwrk_cmt,
				vlntr_exp_cmt,
				ROW_NUMBER() OVER (PARTITION BY fiscal_yr, cnst_mstr_id ORDER BY cnst_mstr_id, fiscal_yr, snapshot_ts ASC) AS rn
			FROM (
				SELECT
					snapshot_ts,
					history_record_ts,
					history_record_id,
					adnc_mbr_id,
					COALESCE(x.new_cnst_mstr_id, nvsr.cnst_mstr_id) AS cnst_mstr_id,
					nvsr.orig_cnst_mstr_id,
					last_nm,
					email,
					survey_nm,
				/*	vlntr_length,
					a5_acctg_fnc_ind,
					b5_blood_svc_ind,
					c5_gen_admin_sprt_srvc_ind,
					d5_saf_srvc_ind,
					e5_comnty_srvc_ind,
					f5_trng_srvc_ind,
					g5_vlntr_srvc_ind,
					h5_dstr_srvc_ind,
					i5_intl_srvc_ind,
					j5_youth_prgrm_srvc_ind,
					k5_fr_srvc_ind,
					l5_ldrshp_ind,
					m5_mrktg_ind,
					n5_other_ind AS l2_other_srvc_ind,
					CAST(NULL AS VARCHAR(3)) AS vol_area_no_answer, */
					CAST(n5_other_dsc AS VARCHAR(50)) AS other_srvc_cmt,
				/*	a5_exp_rtng_num,
					a5_exp_rtng_dsc,
					b5_exp_rtng_num,
					b5_exp_rtng_dsc,
					c5_exp_rtng_num,
					c5_exp_rtng_dsc,
					d5_exp_rtng_num,
					d5_exp_rtng_dsc,
					e5_exp_rtng_num,
					e5_exp_rtng_dsc,
					f5_exp_rtng_num,
					f5_exp_rtng_dsc,
					g5_exp_rtng_num,
					g5_exp_rtng_dsc,
					h5_exp_rtng_num,
					h5_exp_rtng_dsc,
					h5_in_rgn_dro_dplymnt_ind,
					h5_out_rgn_dro_dplymnt_ind,
					h5_both_rgn_dro_dplymnt_ind,
					h5_no_rgn_dro_dplymnt_ind,
					i5_exp_rtng_num,
					i5_exp_rtng_dsc,
					j5_exp_rtng_num,
					j5_exp_rtng_dsc,
					k5_exp_rtng_num,
					k5_exp_rtng_dsc,
					l5_exp_rtng_num,
					l5_exp_rtng_dsc,
					m5_exp_rtng_num,
					m5_exp_rtng_dsc,
					vlntr_xprnc_rtng,
					vlntr_xprnc_rtng_dsc,
					rcmnd_frnd_vlntr_rtng,
					rcmnd_frnd_vlntr_rtng_dsc, */
					why_scr_cmt,
					why_scr_tmwrk_cmt,
				/*	CAST(a6_vlntr_sprt_rtng AS SMALLINT) AS a6_vlntr_sprt_rtng,
					CAST(a6_vlntr_sprt_rtng_dsc AS VARCHAR(25)) AS a6_vlntr_sprt_rtng_dsc,
					CAST(b6_expctn_rtng AS SMALLINT) AS b6_expctn_rtng,
					CAST(b6_expctn_rtng_dsc AS VARCHAR(25)) AS b6_expctn_rtng_dsc,
					CAST(c6_trng_mtrl_rtng AS SMALLINT) AS c6_trng_mtrl_rtng,
					CAST(c6_trng_mtrl_rtng_dsc AS VARCHAR(25)) AS c6_trng_mtrl_rtng_dsc,
					CAST(tmwrk_good_rtng AS SMALLINT) AS tmwrk_good_rtng,
					CAST(tmwrk_good_rtng_dsc AS VARCHAR(25)) AS tmwrk_good_rtng_dsc,
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
					CAST(NULL AS SMALLINT) AS j6_bkgrnd_rspctd_rtng,
					CAST(NULL AS VARCHAR(25)) AS j6_bkgrnd_rspctd_rtng_dsc, */
					vlntr_exp_cmt,
				/*	vlntr_hrs_value,
					vlntr_hrs_dsc,
					a9_dntd_bld_ind,
					b9_dntd_mny_ind,
					c9_prprdns_app_ind,
					d9_hs_crs_ind,
					e9_ref_fmly_ind,
					f9_none_ind,
					CAST(NULL AS SMALLINT) AS l12mo_have_you_no_answer,
					a10_vlntr_exprnc_easy_rtng,
					a10_vlntr_exprnc_easy_rtng_dsc,
					b10_vlntr_cnctn_usfl_rtng,
					b10_vlntr_cnctn_usfl_rtng_dsc,
					c10_vlntr_cnctn_easy_rtng,
					c10_vlntr_cnctn_easy_rtng_dsc,
					CAST(NULL AS SMALLINT) AS a11_arc_cmptr_rtng,
					CAST(NULL AS VARCHAR(25)) AS a11_arc_cmptr_rtng_dsc,
					CAST(NULL AS SMALLINT) AS b11_arc_email_rtng,
					CAST(NULL AS VARCHAR(25)) AS b11_arc_email_rtng_dsc,
					CAST(NULL AS SMALLINT) AS c11_arc_xchng_rtng,
					CAST(NULL AS VARCHAR(25)) AS c11_arc_xchng_rtng_dsc,
					CAST(NULL AS SMALLINT) AS d11_arc_edge_rtng,
					CAST(NULL AS VARCHAR(25)) AS d11_arc_edge_rtng_dsc,
					CAST(NULL AS SMALLINT) AS arc_edctn_lvl_value,
					CAST(NULL AS VARCHAR(25)) AS arc_edctn_lvl_dsc,
					CAST(NULL AS SMALLINT) AS vlntr_dscrptn_value,
					CAST(NULL AS VARCHAR(25)) AS vlntr_dscrptn_dsc,
					nvsr.dw_create_ts,
					nvsr.dw_updt_ts,
					nvsr.row_stat_cd,
					nvsr.appl_src_cd,
					nvsr.load_id,
					svp.dm_cnst_zip_5_cd,
					CASE
						WHEN msz.zip_cd IS NOT NULL THEN msz.zip_cd
						WHEN msz_mktg.zip_cd IS NOT NULL THEN msz_mktg.zip_cd
						ELSE svp.dm_cnst_zip_5_cd
					END AS attribtn_zip_5_cd,
					svp.unit_key,
					svp.mktg_unit_key,
					svp.mktg_unit_cd,
					um.unit_nm,
					um.cs_region_cd,
					um.cs_region_nm AS region_nm,
					um.division_cd,
					um.division_dsc,
					dz.district_cd,
					dz.district_name AS district_nm,
					dz.zip AS unit_zip,
					dz.orc_division_id,
					dz.orc_division_name,
					dz.ds_region_id,
					dz.ds_region_name,
					dz.geo_lat_lon_ID,
					dz.geo_centriod_lat,
					dz.geo_centriod_lon,
					reg.region_nm AS bio_region_nm,
					reg.division_dsc AS bio_division_dsc,
					reg.ldrshp_nm, */
					cal.fiscal_yr
				FROM mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy22 nvsr
				LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON nvsr.cnst_mstr_id = x.cnst_mstr_id
			/*	LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON COALESCE(x.new_cnst_mstr_id, nvsr.cnst_mstr_id) = svp.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_unit_merged um ON svp.unit_key = um.orig_unit_key
				LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter geo ON svp.dm_cnst_zip_5_cd = geo.zip
				LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = um.unit_zip
				LEFT JOIN eda.dw_common_vws.dim_region reg ON SUBSTRING(dz.region_code, 1, 3) = reg.nk_region_id */
				LEFT JOIN eda.dw_common_vws.dim_calendar cal ON (CAST(nvsr.snapshot_ts AS DATE) = cal.calendar_dt)
			/*	LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz ON um.nk_ecode = msz.nk_ecode
				LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg ON svp.mktg_unit_cd = msz_mktg.nk_ecode */
				WHERE snapshot_ts >= DATE '2021-07-11'
			)
		)
		SELECT
			snapshot_ts,
			history_record_ts,
			history_record_id,
			adnc_mbr_id,
			cnst_mstr_id,
			orig_cnst_mstr_id,
			last_nm,
			email,
			survey_nm,
			other_srvc_cmt,
			why_scr_cmt,
			why_scr_tmwrk_cmt,
			vlntr_exp_cmt
		FROM anvrsy_cte
		WHERE rn = 1;
		
		--2nd insert
		INSERT INTO mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_stg
		WITH anvrsy_cte AS (
			SELECT
				snapshot_ts,
				history_record_ts,
				history_record_id,
				adnc_mbr_id,
				cnst_mstr_id,
				orig_cnst_mstr_id,
				last_nm,
				email,
				survey_nm,
				other_srvc_cmt,
				why_scr_cmt,
				why_scr_tmwrk_cmt,
				vlntr_exp_cmt,
				ROW_NUMBER() OVER (PARTITION BY fiscal_yr, cnst_mstr_id ORDER BY cnst_mstr_id, fiscal_yr, snapshot_ts ASC) AS rn
			FROM (
				SELECT
					snapshot_ts,
					history_record_ts,
					history_record_id,
					adnc_mbr_id,
					COALESCE(x.new_cnst_mstr_id, nvsr.cnst_mstr_id) AS cnst_mstr_id,
					nvsr.orig_cnst_mstr_id,
					last_nm,
					email,
					survey_nm,
				/*	vlntr_length,
					a5_acctg_fnc_ind,
					b5_blood_svc_ind,
					c5_gen_admin_sprt_srvc_ind,
					d5_saf_srvc_ind,
					e5_comnty_srvc_ind,
					f5_trng_srvc_ind,
					g5_vlntr_srvc_ind,
					h5_dstr_srvc_ind,
					i5_intl_srvc_ind,
					j5_youth_prgrm_srvc_ind,
					k5_fr_srvc_ind,
					l5_ldrshp_ind,
					m5_mrktg_ind,
					n5_other_ind AS l2_other_srvc_ind,
					CAST(NULL AS VARCHAR(3)) AS vol_area_no_answer,	*/
					CAST(n5_other_dsc AS VARCHAR(50)) AS other_srvc_cmt,
				/*	a5_exp_rtng_num,
					a5_exp_rtng_dsc,
					b5_exp_rtng_num,
					b5_exp_rtng_dsc,
					c5_exp_rtng_num,
					c5_exp_rtng_dsc,
					d5_exp_rtng_num,
					d5_exp_rtng_dsc,
					e5_exp_rtng_num,
					e5_exp_rtng_dsc,
					f5_exp_rtng_num,
					f5_exp_rtng_dsc,
					g5_exp_rtng_num,
					g5_exp_rtng_dsc,
					h5_exp_rtng_num,
					h5_exp_rtng_dsc,
					h5_in_rgn_dro_dplymnt_ind,
					h5_out_rgn_dro_dplymnt_ind,
					h5_both_rgn_dro_dplymnt_ind,
					h5_no_rgn_dro_dplymnt_ind,
					i5_exp_rtng_num,
					i5_exp_rtng_dsc,
					j5_exp_rtng_num,
					j5_exp_rtng_dsc,
					k5_exp_rtng_num,
					k5_exp_rtng_dsc,
					l5_exp_rtng_num,
					l5_exp_rtng_dsc,
					m5_exp_rtng_num,
					m5_exp_rtng_dsc,
					vlntr_xprnc_rtng,
					vlntr_xprnc_rtng_dsc,
					rcmnd_frnd_vlntr_rtng,
					rcmnd_frnd_vlntr_rtng_dsc, */
					why_scr_cmt,
					why_scr_tmwrk_cmt,
				/*	CAST(a6_vlntr_sprt_rtng AS SMALLINT) AS a6_vlntr_sprt_rtng,
					CAST(a6_vlntr_sprt_rtng_dsc AS VARCHAR(25)) AS a6_vlntr_sprt_rtng_dsc,
					CAST(b6_expctn_rtng AS SMALLINT) AS b6_expctn_rtng,
					CAST(b6_expctn_rtng_dsc AS VARCHAR(25)) AS b6_expctn_rtng_dsc,
					CAST(c6_trng_mtrl_rtng AS SMALLINT) AS c6_trng_mtrl_rtng,
					CAST(c6_trng_mtrl_rtng_dsc AS VARCHAR(25)) AS c6_trng_mtrl_rtng_dsc,
					CAST(tmwrk_good_rtng AS SMALLINT) AS tmwrk_good_rtng,
					CAST(tmwrk_good_rtng_dsc AS VARCHAR(25)) AS tmwrk_good_rtng_dsc,
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
					CAST(j6_bkgrnd_rspctd_rtng AS SMALLINT) AS j6_bkgrnd_rspctd_rtng,
					CAST(j6_bkgrnd_rspctd_rtng_dsc AS VARCHAR(25)) AS j6_bkgrnd_rspctd_rtng_dsc, */
					vlntr_exp_cmt,
				/*	vlntr_hrs_value,
					vlntr_hrs_dsc,
					a9_dntd_bld_ind,
					b9_dntd_mny_ind,
					c9_prprdns_app_ind,
					d9_hs_crs_ind,
					e9_ref_fmly_ind,
					f9_none_ind,
					CAST(NULL AS SMALLINT) AS l12mo_have_you_no_answer,
					a10_vlntr_exprnc_easy_rtng,
					a10_vlntr_exprnc_easy_rtng_dsc,
					b10_vlntr_cnctn_usfl_rtng,
					b10_vlntr_cnctn_usfl_rtng_dsc,
					c10_vlntr_cnctn_easy_rtng,
					c10_vlntr_cnctn_easy_rtng_dsc,
					CAST(NULL AS SMALLINT) AS a11_arc_cmptr_rtng,
					CAST(NULL AS VARCHAR(25)) AS a11_arc_cmptr_rtng_dsc,
					CAST(NULL AS SMALLINT) AS b11_arc_email_rtng,
					CAST(NULL AS VARCHAR(25)) AS b11_arc_email_rtng_dsc,
					CAST(NULL AS SMALLINT) AS c11_arc_xchng_rtng,
					CAST(NULL AS VARCHAR(25)) AS c11_arc_xchng_rtng_dsc,
					CAST(NULL AS SMALLINT) AS d11_arc_edge_rtng,
					CAST(NULL AS VARCHAR(25)) AS d11_arc_edge_rtng_dsc,
					CAST(NULL AS SMALLINT) AS arc_edctn_lvl_value,
					CAST(NULL AS VARCHAR(25)) AS arc_edctn_lvl_dsc,
					CAST(NULL AS SMALLINT) AS vlntr_dscrptn_value,
					CAST(NULL AS VARCHAR(25)) AS vlntr_dscrptn_dsc,
					nvsr.dw_create_ts,
					nvsr.dw_updt_ts,
					nvsr.row_stat_cd,
					nvsr.appl_src_cd,
					nvsr.load_id,
					svp.dm_cnst_zip_5_cd,
					CASE
						WHEN msz.zip_cd IS NOT NULL THEN msz.zip_cd
						WHEN msz_mktg.zip_cd IS NOT NULL THEN msz_mktg.zip_cd
						ELSE svp.dm_cnst_zip_5_cd
					END AS attribtn_zip_5_cd,
					svp.unit_key,
					svp.mktg_unit_key,
					svp.mktg_unit_cd,
					um.unit_nm,
					um.cs_region_cd,
					um.cs_region_nm AS region_nm,
					um.division_cd,
					um.division_dsc,
					dz.district_cd,
					dz.district_name AS district_nm,
					dz.zip AS unit_zip,
					dz.orc_division_id,
					dz.orc_division_name,
					dz.ds_region_id,
					dz.ds_region_name,
					dz.geo_lat_lon_ID,
					dz.geo_centriod_lat,
					dz.geo_centriod_lon,
					reg.region_nm AS bio_region_nm,
					reg.division_dsc AS bio_division_dsc,
					reg.ldrshp_nm,	*/
					cal.fiscal_yr
				FROM mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy22 nvsr
				LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON nvsr.cnst_mstr_id = x.cnst_mstr_id
			/*	LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON COALESCE(x.new_cnst_mstr_id, nvsr.cnst_mstr_id) = svp.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_unit_merged um ON svp.unit_key = um.orig_unit_key
				LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter geo ON svp.dm_cnst_zip_5_cd = geo.zip
				LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = um.unit_zip
				LEFT JOIN eda.dw_common_vws.dim_region reg ON SUBSTRING(dz.region_code, 1, 3) = reg.nk_region_id	*/
				LEFT JOIN eda.dw_common_vws.dim_calendar cal ON (CAST(nvsr.snapshot_ts AS DATE) = cal.calendar_dt)
			/*	LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz ON um.nk_ecode = msz.nk_ecode
				LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg ON svp.mktg_unit_cd = msz_mktg.nk_ecode	*/
				WHERE survey_nm = 'FY23 New Volunteer Survey'
			)
		)
		SELECT
			snapshot_ts,
			history_record_ts,
			history_record_id,
			adnc_mbr_id,
			cnst_mstr_id,
			orig_cnst_mstr_id,
			last_nm,
			email,
			survey_nm,
			other_srvc_cmt,
			why_scr_cmt,
			why_scr_tmwrk_cmt,
			vlntr_exp_cmt
		FROM anvrsy_cte
		WHERE rn = 1;
		
		--3rd insert
		INSERT INTO mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_stg
		WITH anvrsy_cte AS (
			SELECT
				snapshot_ts,
				history_record_ts,
				history_record_id,
				adnc_mbr_id,
				cnst_mstr_id,
				orig_cnst_mstr_id,
				last_nm,
				email,
				survey_nm,
				other_srvc_cmt,
				why_scr_cmt,
				why_scr_tmwrk_cmt,
				vlntr_exp_cmt,
				ROW_NUMBER() OVER (PARTITION BY fiscal_yr, cnst_mstr_id ORDER BY cnst_mstr_id, fiscal_yr, snapshot_ts ASC) AS rn
			FROM (
				SELECT
					snapshot_ts, 
					history_record_ts, 
					history_record_id, 
					adnc_mbr_id,
					COALESCE(x.new_cnst_mstr_id, nvsr.cnst_mstr_id) AS cnst_mstr_id, 
					nvsr.orig_cnst_mstr_id,
					last_nm,
					email,
					survey_nm,
				/*	vlntr_length,
					a5_acctg_fnc_ind, 
					b5_blood_svc_ind,
					c5_gen_admin_sprt_srvc_ind,
					d5_saf_srvc_ind,
					e5_comnty_srvc_ind,
					f5_trng_srvc_ind,
					g5_vlntr_srvc_ind,
					h5_dstr_srvc_ind,
					i5_intl_srvc_ind,
					j5_youth_prgrm_srvc_ind,
					k5_fr_srvc_ind,
					l5_ldrshp_ind,
					CAST(NULL AS SMALLINT) AS m5_mrktg_ind,
					NULL AS l2_other_srvc_ind,
					CAST(NULL AS VARCHAR(3)) AS vol_area_no_answer,    */
					CAST(NULL AS VARCHAR(50)) AS other_srvc_cmt,
				/*	CAST(NULL AS SMALLINT) AS a5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS a5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS b5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS b5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS c5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS c5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS d5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS d5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS e5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS e5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS f5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS f5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS g5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS g5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS h5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS h5_exp_rtng_dsc,
					0 AS h5_in_rgn_dro_dplymnt_ind,
					0 AS h5_out_rgn_dro_dplymnt_ind,
					0 AS h5_both_rgn_dro_dplymnt_ind,
					0 AS h5_no_rgn_dro_dplymnt_ind,
					CAST(NULL AS SMALLINT) AS i5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS i5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS j5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS j5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS k5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS k5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS l5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS l5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS m5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS m5_exp_rtng_dsc,
					vlntr_xprnc_rtng,
					vlntr_xprnc_rtng_dsc,
					rcmnd_frnd_vlntr_rtng, 
					rcmnd_frnd_vlntr_rtng_dsc,	*/
					why_scr_cmt,
					CAST(NULL AS VARCHAR(255)) AS why_scr_tmwrk_cmt,
				/*	CAST(a6_vlntr_sprt_rtng AS SMALLINT) AS a6_vlntr_sprt_rtng,
					CAST(a6_vlntr_sprt_rtng_dsc AS VARCHAR(25)) AS a6_vlntr_sprt_rtng_dsc,
					CAST(b6_expctn_rtng AS SMALLINT) AS b6_expctn_rtng,
					CAST(b6_expctn_rtng_dsc AS VARCHAR(25)) AS b6_expctn_rtng_dsc,
					CAST(c6_trng_mtrl_rtng AS SMALLINT) AS c6_trng_mtrl_rtng,
					CAST(c6_trng_mtrl_rtng_dsc AS VARCHAR(25)) AS c6_trng_mtrl_rtng_dsc,
					CAST(NULL AS SMALLINT) AS tmwrk_good_rtng,
					CAST(NULL AS VARCHAR(25)) AS tmwrk_good_rtng_dsc,
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
					CAST(NULL AS SMALLINT) AS j6_bkgrnd_rspctd_rtng,
					CAST(NULL AS VARCHAR(25)) AS j6_bkgrnd_rspctd_rtng_dsc,    */
					vlntr_exp_cmt,
				/*	vlntr_hrs_value,
					vlntr_hrs_dsc,
					a9_dntd_bld_ind,
					b9_dntd_mny_ind,
					c9_prprdns_app_ind,
					d9_hs_crs_ind,
					e9_ref_fmly_ind,
					f9_none_ind,
					CAST(NULL AS SMALLINT) AS l12mo_have_you_no_answer,
					CAST(NULL AS SMALLINT) AS a10_vlntr_exprnc_easy_rtng,
					CAST(NULL AS VARCHAR(25)) AS a10_vlntr_exprnc_easy_rtng_dsc,
					CAST(NULL AS SMALLINT) AS b10_vlntr_cnctn_usfl_rtng,
					CAST(NULL AS VARCHAR(25)) AS b10_vlntr_cnctn_usfl_rtng_dsc,
					CAST(NULL AS SMALLINT) AS c10_vlntr_cnctn_easy_rtng,
					CAST(NULL AS VARCHAR(25)) AS c10_vlntr_cnctn_easy_rtng_dsc,
					CAST(NULL AS SMALLINT) AS a11_arc_cmptr_rtng,
					CAST(NULL AS VARCHAR(25)) AS a11_arc_cmptr_rtng_dsc,
					CAST(NULL AS SMALLINT) AS b11_arc_email_rtng,
					CAST(NULL AS VARCHAR(25)) AS b11_arc_email_rtng_dsc,
					CAST(NULL AS SMALLINT) AS c11_arc_xchng_rtng,
					CAST(NULL AS VARCHAR(25)) AS c11_arc_xchng_rtng_dsc,
					CAST(NULL AS SMALLINT) AS d11_arc_edge_rtng,
					CAST(NULL AS VARCHAR(25)) AS d11_arc_edge_rtng_dsc,
					CAST(NULL AS SMALLINT) AS arc_edctn_lvl_value,
					CAST(NULL AS VARCHAR(25)) AS arc_edctn_lvl_dsc,
					CAST(NULL AS SMALLINT) AS vlntr_dscrptn_value,
					CAST(NULL AS VARCHAR(25)) AS vlntr_dscrptn_dsc,
					nvsr.dw_create_ts,
					nvsr.dw_updt_ts,
					nvsr.row_stat_cd,
					nvsr.appl_src_cd,
					nvsr.load_id,
					svp.dm_cnst_zip_5_cd, 
					CASE
						WHEN msz.zip_cd IS NOT NULL THEN msz.zip_cd 
						WHEN msz_mktg.zip_cd IS NOT NULL THEN msz_mktg.zip_cd
						ELSE svp.dm_cnst_zip_5_cd 
					END AS attribtn_zip_5_cd,
					svp.unit_key,
					svp.mktg_unit_key,
					svp.mktg_unit_cd,
					um.unit_nm,
					um.cs_region_cd,
					um.cs_region_nm AS region_nm,
					um.division_cd,
					um.division_dsc,
					dz.district_cd,
					dz.district_name AS district_nm,
					dz.zip AS unit_zip,
					dz.orc_division_id, 
					dz.orc_division_name, 
					dz.ds_region_id, 
					dz.ds_region_name,
					dz.geo_lat_lon_ID, 
					dz.geo_centriod_lat, 
					dz.geo_centriod_lon,
					reg.region_nm AS bio_region_nm, 
					reg.division_dsc AS bio_division_dsc, 
					reg.ldrshp_nm,   */
					cal.fiscal_yr 
				FROM mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_fy21 nvsr
				LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON nvsr.cnst_mstr_id = x.cnst_mstr_id
			/*	LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON COALESCE(x.new_cnst_mstr_id, nvsr.cnst_mstr_id) = svp.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_unit_merged um ON svp.unit_key = um.orig_unit_key
				LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter geo ON svp.dm_cnst_zip_5_cd = geo.zip
				LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = um.unit_zip
				LEFT JOIN eda.dw_common_vws.dim_region reg ON SUBSTRING(dz.region_code, 1, 3) = reg.nk_region_id    */
				LEFT JOIN eda.dw_common_vws.dim_calendar cal ON (CAST(nvsr.snapshot_ts AS DATE) = cal.calendar_dt)
			/*	LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz ON um.nk_ecode = msz.nk_ecode
				LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg ON svp.mktg_unit_cd = msz_mktg.nk_ecode    */
			)
		)
		SELECT
			snapshot_ts,
			history_record_ts,
			history_record_id,
			adnc_mbr_id,
			cnst_mstr_id,
			orig_cnst_mstr_id,
			last_nm,
			email,
			survey_nm,
			other_srvc_cmt,
			why_scr_cmt,
			why_scr_tmwrk_cmt,
			vlntr_exp_cmt
		FROM anvrsy_cte
		WHERE rn = 1;
		
		--4th insert
		INSERT INTO mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_stg
		WITH anvrsy_cte AS (
			SELECT
				snapshot_ts,
				history_record_ts,
				history_record_id,
				adnc_mbr_id,
				cnst_mstr_id,
				orig_cnst_mstr_id,
				last_nm,
				email,
				survey_nm,
				other_srvc_cmt,
				why_scr_cmt,
				why_scr_tmwrk_cmt,
				vlntr_exp_cmt,
				ROW_NUMBER() OVER (PARTITION BY fiscal_yr, cnst_mstr_id ORDER BY cnst_mstr_id, fiscal_yr, snapshot_ts ASC) AS rn
			FROM (
				--4th select
				SELECT
					snapshot_ts, 
					history_record_ts, 
					history_record_id, 
					adnc_mbr_id,
					COALESCE(x.new_cnst_mstr_id, nvsr.cnst_mstr_id) AS cnst_mstr_id,
					nvsr.orig_cnst_mstr_id,
					last_nm,
					email,
					survey_nm,
				/*	vlntr_length,
					CAST(NULL AS SMALLINT) AS a5_acctg_fnc_ind, 
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
					CAST(NULL AS SMALLINT) AS m5_mrktg_ind,
					CAST(NULL AS VARCHAR(3)) AS vol_area_no_answer,    */
					CAST(NULL AS VARCHAR(50)) AS other_srvc_cmt,
				/*	CAST(NULL AS SMALLINT) AS a5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS a5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS b5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS b5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS c5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS c5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS d5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS d5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS e5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS e5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS f5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS f5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS g5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS g5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS h5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS h5_exp_rtng_dsc,
					0 AS h5_in_rgn_dro_dplymnt_ind,
					0 AS h5_out_rgn_dro_dplymnt_ind,
					0 AS h5_both_rgn_dro_dplymnt_ind,
					0 AS h5_no_rgn_dro_dplymnt_ind,
					CAST(NULL AS SMALLINT) AS i5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS i5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS j5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS j5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS k5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS k5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS l5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS l5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS m5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS m5_exp_rtng_dsc,
					vlntr_xprnc_rtng,
					CAST(CASE 
						WHEN vlntr_xprnc_rtng_dsc = 'Very Satisfactory' THEN 'Excellent'
						WHEN vlntr_xprnc_rtng_dsc = 'Satisfactory' THEN 'Very Good' 
						WHEN vlntr_xprnc_rtng_dsc = 'Somewhat Satisfactory' THEN 'Above Average' 
						WHEN vlntr_xprnc_rtng_dsc = 'Somewhat Unsatisfactory' THEN 'Below Average'
						WHEN vlntr_xprnc_rtng_dsc = 'Unsatisfactory' THEN 'Poor' 
						WHEN vlntr_xprnc_rtng_dsc = 'Very Unsatisfactory' THEN 'Extremely Poor' 
						WHEN vlntr_xprnc_rtng_dsc IS NULL THEN 'No Response'
						ELSE vlntr_xprnc_rtng_dsc
					END AS VARCHAR(50)) AS vlntr_xprnc_rtng_dsc,    
					rcmnd_frnd_vlntr_rtng, 
					rcmnd_frnd_vlntr_rtng_dsc, */
					why_scr_cmt,
					CAST(NULL AS VARCHAR(255)) AS why_scr_tmwrk_cmt,
				/*	CAST(a6_vlntr_sprt_rtng AS SMALLINT) AS a6_vlntr_sprt_rtng,
					CAST(a6_vlntr_sprt_rtng_dsc AS VARCHAR(25)) AS a6_vlntr_sprt_rtng_dsc,
					CAST(b6_expctn_rtng AS SMALLINT) AS b6_expctn_rtng,
					CAST(b6_expctn_rtng_dsc AS VARCHAR(25)) AS b6_expctn_rtng_dsc,
					CAST(c6_trng_mtrl_rtng AS SMALLINT) AS c6_trng_mtrl_rtng,
					CAST(c6_trng_mtrl_rtng_dsc AS VARCHAR(25)) AS c6_trng_mtrl_rtng_dsc,
					CAST(NULL AS SMALLINT) AS tmwrk_good_rtng,
					CAST(NULL AS VARCHAR(25)) AS tmwrk_good_rtng_dsc,
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
					CAST(NULL AS SMALLINT) AS j6_bkgrnd_rspctd_rtng,
					CAST(NULL AS VARCHAR(25)) AS j6_bkgrnd_rspctd_rtng_dsc,   */
					vlntr_exp_cmt,
				/*	vlntr_hrs_value,
					vlntr_hrs_dsc,
					a9_dntd_bld_ind,
					b9_dntd_mny_ind,
					c9_prprdns_app_ind,
					d9_hs_crs_ind,
					e9_ref_fmly_ind,
					f9_none_ind,
					CAST(NULL AS SMALLINT) AS l12mo_have_you_no_answer,
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
					CASE
						WHEN msz.zip_cd IS NOT NULL THEN msz.zip_cd 
						WHEN msz_mktg.zip_cd IS NOT NULL THEN msz_mktg.zip_cd
						ELSE svp.dm_cnst_zip_5_cd 
					END AS attribtn_zip_5_cd,
					svp.unit_key,
					svp.mktg_unit_key,
					svp.mktg_unit_cd,
					um.unit_nm,
					um.cs_region_cd,
					um.cs_region_nm AS region_nm,
					um.division_cd,
					um.division_dsc,
					dz.district_cd,
					dz.district_name AS district_nm,
					dz.zip AS unit_zip,
					dz.orc_division_id, 
					dz.orc_division_name, 
					dz.ds_region_id, 
					dz.ds_region_name,
					dz.geo_lat_lon_ID, 
					dz.geo_centriod_lat, 
					dz.geo_centriod_lon,
					reg.region_nm AS bio_region_nm, 
					reg.division_dsc AS bio_division_dsc, 
					reg.ldrshp_nm, */
					cal.fiscal_yr
				FROM mktg_ops_tbls.srvy_anvrsy_vlntr_rspns nvsr 
				LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON nvsr.cnst_mstr_id = x.cnst_mstr_id
				LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON COALESCE(x.new_cnst_mstr_id, nvsr.cnst_mstr_id) = svp.cnst_mstr_id
			/*	LEFT JOIN eda.dw_common_vws.dim_unit_merged um ON svp.unit_key = um.orig_unit_key
				LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter geo ON svp.dm_cnst_zip_5_cd = geo.zip
				LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = um.unit_zip
				LEFT JOIN eda.dw_common_vws.dim_region reg ON SUBSTRING(dz.region_code, 1, 3) = reg.nk_region_id    */
				LEFT JOIN eda.dw_common_vws.dim_calendar cal ON (CAST(nvsr.snapshot_ts AS DATE) = cal.calendar_dt)
			/*	LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz ON um.nk_ecode = msz.nk_ecode
				LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg ON svp.mktg_unit_cd = msz_mktg.nk_ecode    */
			)
		)
		SELECT
			snapshot_ts,
			history_record_ts,
			history_record_id,
			adnc_mbr_id,
			cnst_mstr_id,
			orig_cnst_mstr_id,
			last_nm,
			email,
			survey_nm,
			other_srvc_cmt,
			why_scr_cmt,
			why_scr_tmwrk_cmt,
			vlntr_exp_cmt
		FROM anvrsy_cte
		WHERE rn = 1;
		
		--5th insert
		INSERT INTO mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_stg
		WITH anvrsy_cte AS (
			SELECT
				snapshot_ts,
				history_record_ts,
				history_record_id,
				adnc_mbr_id,
				cnst_mstr_id,
				orig_cnst_mstr_id,
				last_nm,
				email,
				survey_nm,
				other_srvc_cmt,
				why_scr_cmt,
				why_scr_tmwrk_cmt,
				vlntr_exp_cmt,
				ROW_NUMBER() OVER (PARTITION BY fiscal_yr, cnst_mstr_id ORDER BY cnst_mstr_id, fiscal_yr, snapshot_ts ASC) AS rn
			FROM (
				SELECT 
					CAST(nk_survey_start_ts AS TIMESTAMP) AS snapshot_ts,
					CAST(nk_survey_start_ts AS TIMESTAMP) AS history_record_ts,
					CAST(NULL AS INTEGER) AS history_record_id, 
					CAST(NULL AS INTEGER) AS adnc_mbr_id,
					CAST(COALESCE(x.new_cnst_mstr_id, fsr.cnst_mstr_id) AS BIGINT) AS cnst_mstr_id, 
					CAST(fsr.orig_cnst_mstr_id AS BIGINT) AS orig_cnst_mstr_id, 
					CAST(NULL AS VARCHAR(255)) AS last_nm,
					CAST(NULL AS VARCHAR(255)) AS email,
					CAST(NULL AS VARCHAR(255)) AS survey_nm,
				/*	CAST(volunteer_length AS VARCHAR(25)) AS vlntr_length, 
					CAST(NULL AS SMALLINT) AS a5_acctg_fnc_ind,  
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
					CAST(NULL AS SMALLINT) AS m5_mrktg_ind,
					vol_area_no_answer,    */
					CAST(NULL AS VARCHAR(50)) AS other_srvc_cmt,
				/*	CAST(NULL AS SMALLINT) AS a5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS a5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS b5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS b5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS c5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS c5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS d5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS d5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS e5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS e5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS f5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS f5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS g5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS g5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS h5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS h5_exp_rtng_dsc,
					0 AS h5_in_rgn_dro_dplymnt_ind,
					0 AS h5_out_rgn_dro_dplymnt_ind,
					0 AS h5_both_rgn_dro_dplymnt_ind,
					0 AS h5_no_rgn_dro_dplymnt_ind,
					CAST(NULL AS SMALLINT) AS i5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS i5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS j5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS j5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS k5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS k5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS l5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS l5_exp_rtng_dsc,
					CAST(NULL AS SMALLINT) AS m5_exp_rtng_num,
					CAST(NULL AS VARCHAR(25)) AS m5_exp_rtng_dsc,
					CAST(CASE 
						WHEN rc_vol_experience_overal = 'Excellent' THEN '1'
						WHEN rc_vol_experience_overal = 'Very Good' THEN '2'
						WHEN rc_vol_experience_overal = 'Above Average' THEN '3'
						WHEN rc_vol_experience_overal = 'Below Average' THEN '4'
						WHEN rc_vol_experience_overal = 'Poor' THEN '5'
						WHEN rc_vol_experience_overal = 'Extremely Poor' THEN '6'
					END AS SMALLINT) AS vlntr_xprnc_rtng,
					rc_vol_experience_overal AS vlntr_xprnc_rtng_dsc,
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
					END AS VARCHAR(50)) AS rcmnd_frnd_vlntr_dsc,    */
					CAST(NULL AS VARCHAR(4000)) AS why_scr_cmt,
					CAST(NULL AS VARCHAR(255)) AS why_scr_tmwrk_cmt,
				/*	CASE
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
					CAST(NULL AS SMALLINT) AS tmwrk_good_rtng,
					CAST(NULL AS VARCHAR(25)) AS tmwrk_good_rtng_dsc,
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
						WHEN e8_valued_member = 'Somewart Disagree' THEN 4
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
					CASE
						WHEN i8_cont_as_arc_volun = 'Strongly Agree' THEN 1
						WHEN i8_cont_as_arc_volun = 'Agree' THEN 2
						WHEN i8_cont_as_arc_volun = 'Somewhat Agree' THEN 3
						WHEN i8_cont_as_arc_volun = 'Somewhat Disagree' THEN 4
						WHEN i8_cont_as_arc_volun = 'Disagree' THEN 5
						WHEN i8_cont_as_arc_volun = 'Strongly Disagree' THEN 6
						WHEN i8_cont_as_arc_volun = 'Does Not Apply' THEN 99 
					END AS j6_bkgrnd_rspctd_rtng,     
					i8_cont_as_arc_volun AS j6_bkgrnd_rspctd_rtng_dsc,     */   
					CAST(NULL AS VARCHAR(4000)) AS vlntr_exp_cmt,
				/*	CAST(CASE 
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
					0 AS e9_ref_fmly_ind,
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
					CAST(usefulness_of_volunteer_connec2 AS VARCHAR(25)) AS b10_vlntr_cnctn_usfl_rtng_dsc,
					CAST(CASE
								WHEN usefulness_of_volunteer_connec3 = 'Strongly Agree' THEN 1
								WHEN usefulness_of_volunteer_connec3 = 'Agree' THEN 2
								WHEN usefulness_of_volunteer_connec3 = 'Somewhat Agree' THEN 3
								WHEN usefulness_of_volunteer_connec3 = 'Somewhat Disagree' THEN 4
								WHEN usefulness_of_volunteer_connec3 = 'Disagree' THEN 5
								WHEN usefulness_of_volunteer_connec3 = 'Strongly Disagree' THEN 6
								WHEN usefulness_of_volunteer_connec3 = 'Does Not Apply' THEN 99
					END AS SMALLINT) AS c10_vlntr_cnctn_easy_rtng,
					CAST(usefulness_of_volunteer_connec3 AS VARCHAR(25)) AS c10_vlntr_cnctn_easy_rtng_dsc,
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
					CASE
						WHEN msz.zip_cd IS NOT NULL THEN msz.zip_cd 
						WHEN msz_mktg.zip_cd IS NOT NULL THEN msz_mktg.zip_cd
						ELSE svp.dm_cnst_zip_5_cd 
					END AS attribtn_zip_5_cd,
					svp.unit_key,
					svp.mktg_unit_key,
					svp.mktg_unit_cd,
					um.unit_nm,
					um.cs_region_cd,
					um.cs_region_nm AS region_nm,
					um.division_cd,
					um.division_dsc,
					dz.district_cd AS unit_district_cd,
					dz.district_name AS unit_district_nm,
					dz.zip AS unit_zip,
					dz.orc_division_id, 
					dz.orc_division_name, 
					dz.ds_region_id, 
					dz.ds_region_name,
					dz.geo_lat_lon_ID, 
					dz.geo_centriod_lat, 
					dz.geo_centriod_lon,
					reg.region_nm AS bio_region_nm, 
					reg.division_dsc AS bio_division_dsc, 
					reg.ldrshp_nm,    */
					cal.fiscal_yr
				FROM mktg_ops_tbls.bzfc_fact_surv_resp fsr
				LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON fsr.cnst_mstr_id = x.cnst_mstr_id
				LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON COALESCE(x.new_cnst_mstr_id, fsr.cnst_mstr_id) = svp.cnst_mstr_id
			/*	LEFT JOIN eda.dw_common_vws.dim_unit_merged um ON svp.unit_key = um.orig_unit_key
				LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter geo ON svp.dm_cnst_zip_5_cd = geo.zip
				LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = um.unit_zip
				LEFT JOIN eda.dw_common_vws.dim_region reg ON SUBSTRING(dz.region_code, 1, 3) = reg.nk_region_id    */
				LEFT JOIN eda.dw_common_vws.dim_calendar cal ON (CAST(nk_survey_start_ts AS DATE) = cal.calendar_dt)
			/*	LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz ON um.nk_ecode = msz.nk_ecode
				LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg ON svp.mktg_unit_cd = msz_mktg.nk_ecode    */
			)
		)
		SELECT
			snapshot_ts,
			history_record_ts,
			history_record_id,
			adnc_mbr_id,
			cnst_mstr_id,
			orig_cnst_mstr_id,
			last_nm,
			email,
			survey_nm,
			other_srvc_cmt,
			why_scr_cmt,
			why_scr_tmwrk_cmt,
			vlntr_exp_cmt
		FROM anvrsy_cte
		WHERE rn = 1;
		
		Truncate table mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt;
		
		-- Insert data from staging to target
        INSERT INTO mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt
        SELECT * FROM mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_stg;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_stg) as INTEGER)
        WHERE proc_name = 'ld_srvy_anvrsy_vlntr_rspns_cmnt' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_srvy_anvrsy_vlntr_rspns_cmnt: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_srvy_anvrsy_vlntr_rspns_cmnt', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
