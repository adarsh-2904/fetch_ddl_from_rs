CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fsa_cnst_indv_chrctrs2 AS 
-- mktg_ops_vws.bzfc_fsa_cnst_indv_chrctrs2 source

create or REPLACE VIEW 
/* **************************mktg_ops_vws.bzfc_fsa_cnst_indv_chrctrs2 sql************************** */
/* ---------------------------------------------------------------------------------------------------------------------------

Created by; Majeed Mohammad
Created date; 01/08/2016
Purpose; This view replaces the view aprimo_wrk_tbls.bzfc_fsa_cnst_indv_chrctrstc2. The name is shortened to 27 characters. 
The sync tables add additional 3 characters for _bk and _cl suffices. 
 
 Modified By:  Mike Andrien
 Modified Date:  01/11/2017
 Purpose: Changed to logic for setting the bzd_sustainer_cdrp_ind column.  If the acitve_ind = 1 but the end_dt value is not null 
 				then the indicator should be set to 0

------------------------------------------------------------------------------------------------------------------------------------ */
mktg_ops_vws.bzfc_fsa_cnst_indv_chrctrs2 AS 

SELECT 
 a.cnst_mstr_id,
 a.bzd_cnst_fsa_key ,
 a.bzd_acct_fsa_key,
 a.bzd_ntrl_key,
 a.bzd_chpt_import_id,
 a.nk_ta_acct_id,
 a.nk_ta_nm_id,
 a.nk_sf_acct_id ,
 a.nk_sf_cntct_id,
 a.bzd_SFID,
-- a.cnst_typ_cd (TITLE 'Constituent Type Code'),
-- a.appl_src_cd (TITLE 'Application Source Code'),
  b.cnst_fsa_key,
  b.cnst_typ_cd,
  b.org_typ_cd,
  b.org_typ_dsc,
  b.act_ind,
  bzd_03008_feb_ind ,
  bzd_03008_mail_ind,
  bzd_03008_zip_ind,
  bzd_03_resp_ind,
  bzd_13056_mail_ind ,
  bzd_25040_mail_ind,
  bzd_25152_add_ind,
  bzd_2gp_prospect_ind,
  bzd_30040_ind ,
  bzd_911b_ind ,
  bzd_age_range ,
  bzd_anon_anon_ind ,
  bzd_anon_undel_ind,
  bzd_appeal_exp_sup_ind,
  bzd_appeal_noval_ind,
  bzd_appeal_only_ind,
  bzd_atg_p_donation_ind,
  bzd_atg_sustainer_ind,
  bzd_auto_renew_ind ,
  bzd_bad_data_ind ,
  bzd_bloodreg_midatl_ind ,
  bzd_bloodreg_norcen_ind,
  bzd_board_chapter_ind ,
  bzd_board_national_ind,
  bzd_cbarton_ind ,
  bzd_ch_disaster_ind,
  bzd_cinfo_coa_ind,
  bzd_cinfo_corradd_ind ,
  bzd_cinfo_incompadd_ind,
  bzd_cinfo_moved_ind ,
  bzd_cinfo_outsidechpt_ind,
   bzd_cinfo_re7conv_ind,
  bzd_cinfo_returned_ind,
  bzd_cinfo_s_coa_ind,
  bzd_cinfo_s_corradd_ind,
  bzd_cinfo_s_incompadd_ind,
  bzd_cinfo_s_moved_ind,
  bzd_cinfo_s_outsidechpt_ind,
  bzd_cinfo_s_returned_ind,
  bzd_cleanup_constituent_ind,
  bzd_cleanup_hierarchy_ind,
  bzd_cofgov_ind,
  bzd_cofgpresappt_ind,
  bzd_cogp_ind,
  bzd_confirmed_ind,
  bzd_constit_boardofgov_ind,
  bzd_constit_celeb_cabmem_ind,
  bzd_constit_cofgov_ind,
  bzd_constit_cofgpresappt_ind,
  bzd_constit_foreigngov_ind,
  bzd_constit_former_bog_ind,
  bzd_constit_museumadvbrd_ind,
  bzd_constit_primcorp_ind,
  bzd_contact_no_email_ind,
  bzd_contact_no_mail_ind,
  bzd_contact_no_phone_ind,
  bzd_convio_prosp_ind,
  bzd_convio_p_donataion_ind,
  bzd_convio_p_donation_ind,
  bzd_convio_sept_2007_ind,
  bzd_convio_team_raiser_ind,
  bzd_convio_ticket_event_ind,
  bzd_corp_ben_emp_ind,
  bzd_corp_ben_public_ind,
  bzd_co_record_ind,
  bzd_cp_agrmt_3rd_pty_fund_ind,
  bzd_cp_agreement_adgp_ind,
  bzd_cp_agreement_cdp_ind,
  bzd_cp_agreement_c_mkt_ind,
  bzd_cp_agreement_domore_ind,
  bzd_cp_agreement_ikd_ind,
  bzd_cp_agreement_lic_ind,
  bzd_cp_agreement_me_ind,
  bzd_cp_agreement_mp_ind,
  bzd_cp_agreement_other_ind,
  bzd_cp_agrmt_phss_prod_ind,
  bzd_cp_agrmt_phss_train_ind,
  bzd_cp_agreement_spons_ind,
  bzd_cp_agreement_vis_ind,
  bzd_cp_agreement_vol_ind,
  bzd_cp_agreement_wpg_ind,
  bzd_cv_origin_arc_ind,
  bzd_cv_origin_arc2_ind,
  bzd_cv_origin_cdm_ind,
  bzd_cv_origin_nhq_ind,
  bzd_deceased_ind,
  bzd_dupl_dw_ind,
  bzd_employee_ind,
  bzd_exclude_fy07_ind,
  bzd_exclude_fy08_ind,
  bzd_fndattr_commfnd_ind,
  bzd_fndattr_corpfnd_ind,
  bzd_fndattr_donadv_ind,
  bzd_fndattr_prvtfnd_ind,
  bzd_foundation_ind,
  bzd_fy03_file_ind,
  bzd_fy03_prospec_ind,
  bzd_fy04_file_ind,
  bzd_fy04_prospec_ind,
  bzd_fy05_file_ind,
  bzd_fy05_prospec_ind,
  bzd_fy06_file_ind,
  bzd_fy07_file_ind,
  bzd_fy08_file_ind,
  bzd_fy09_file_cdr_ind,
  bzd_fy09_file_supplmntl_ind,
  bzd_gender,
  bzd_gpattr_2gp_ind,
  bzd_gpattr_benchp_ind,
  bzd_gpattr_bennhq_ind,
  bzd_gpattr_bensplit_ind,
  bzd_industry_ind,
  bzd_language_english_ind,
  bzd_language_spanish_ind,
  bzd_lapsed_resp_ind,
  bzd_leadership_pp_ind,
  bzd_major_donor_chapter_ind,
  bzd_major_donor_national_ind,
  bzd_manageddonor_managed_ind,
  bzd_march_ncoa_ind,
  bzd_mar_ncoa_add_ind,
  bzd_merged_inactive_ind,
  bzd_natlcampaign_donor_ind,
  bzd_natlcmpgn_ldrshpvlntr_ind,
  bzd_natlcampaign_prospect_ind,
  bzd_ncoa_bad_add_ind,
  bzd_ncoa_new_add_ind,
  bzd_news_resp_ind,
  bzd_new_resp_ind,
  bzd_nhqdmsts_prpred_ind,
  bzd_nhqdmsts_prpstrt_ind,
  bzd_nhqdmsts_supred_ind,
  bzd_nhqdmsts_supstrt_ind,
  bzd_num_emp_ind,
  bzd_past_board_chapter_ind,
  bzd_pg_confirm_ind,
  bzd_pg_info_ind,
  bzd_pg_prev_resp_ind,
  bzd_princpgift_donor_ind,
  bzd_princpgift_ldrshpvlntr_ind,
  bzd_princpgift_prospect_ind,
  bzd_r3bmk_supr_ind,
  bzd_r3hmk_resp_ind,
  bzd_redcross_blood_region_ind,
  bzd_redcross_redcrnatsoc_ind,
  bzd_red_online_katrina2_ind,
  bzd_red_online_tsunami2_ind,
  bzd_removed_ncoa_ind,
  bzd_responder_ind,
  bzd_rs_profile_abrev_rep_ind,
  bzd_rs_profile_abrev_rep_u_ind,
  bzd_rs_profile_rsrch_rep_ind,
  bzd_rs_profile_rsrch_rep_u_ind,
  bzd_rs_profile_sol_plan_ind,
  bzd_rs_profile_sol_plan_u_ind,
  bzd_sa9_59800_ind,
  bzd_sa9_59801_ind,
  bzd_sa9_59802_ind,
  bzd_sa9_59804_ind,
  bzd_sa9_59807_ind,
  bzd_sa9_59808_ind,
  bzd_sa9_59809_ind,
  bzd_sa9_59810_ind,
  bzd_sa9_59814_ind,
  bzd_sa9_59816_ind,
  bzd_sa9_59819_ind,
  bzd_sa9_59823_ind,
  bzd_sa9_59824_ind,
  bzd_sa9_59825_ind,
  bzd_sa9_59828_ind,
  bzd_sa9_59830_ind,
  bzd_sa9_59831_ind,
  bzd_sa9_59832_ind,
  bzd_sa9_59838_ind,
  bzd_sa9_59851_ind,
  bzd_sa9_59852_ind,
  bzd_sa9_59859_ind,
  bzd_sa9_59860_ind,
  bzd_sa9_59861_ind,
  bzd_sa9_59862_ind,
  bzd_sa9_59864_ind,
  bzd_sa9_59865_ind,
  bzd_sa9_59876_ind,
  bzd_sa9_59880_ind,
  bzd_sa9_69800_ind,
  bzd_sa9_69801_ind,
  bzd_sa9_69803_ind,
  bzd_sa9_69804_ind,
  bzd_sa9_69805_ind,
  bzd_sa9_69807_ind,
  bzd_sa9_69808_ind,
  bzd_sa9_69809_ind,
  bzd_sa9_69810_ind,
  bzd_sa9_69811_ind,
  bzd_sa9_69814_ind,
  bzd_sa9_69815_ind,
  bzd_sa9_69816_ind,
  bzd_sa9_69817_ind,
  bzd_sa9_69818_ind,
  bzd_sa9_69829_ind,
  bzd_sa9_69833_ind,
  bzd_sa9_69835_ind,
  bzd_sa9_77777_ind,
  bzd_seed_ind,
  bzd_servarea_afes_ind,
  bzd_servarea_gl5_ind,
  bzd_servarea_intnl_ind,
  bzd_servarea_ma_ind,
  bzd_servarea_ma7_ind,
  bzd_servarea_mtw_ind,
  bzd_servarea_mw3_ind,
  bzd_servarea_nc_ind,
  bzd_servarea_ne_ind,
  bzd_servarea_ne6_ind,
  bzd_servarea_nw_ind,
  bzd_servarea_pf_ind,
  bzd_servarea_pf1_ind,
  bzd_servarea_se_ind,
  bzd_servarea_se8_ind,
  bzd_servarea_sw4_ind,
  bzd_servarea_sw8_ind,
  bzd_servarea_ws2_ind,
  bzd_staart_gifts_jan2008_ind,
  bzd_staart_prosp_feb2008_ind,
  bzd_staart_prosp_jan2008_ind,
  bzd_subject_ind,
  bzd_suppression_archq_ind,
  bzd_supprsn_chapter_sent_ind,
  bzd_supprsn_ch_sent_25plus_ind,
  bzd_suppression_hqcdm_ind,
  bzd_suppression_hqmdcp_ind,
  bzd_suppression_hqstaart_ind,
  bzd_supress_ind,
  case when c.cnst_fsa_key is null then b.bzd_sustainer_cdrp_ind else 0 end as bzd_sustainer_cdrp_ind,
  bzd_sustainer_convio_ind,
  bzd_sustainer_gh_ind,
  bzd_test_a_ind,
  bzd_topusfnd_current_ind,
  bzd_topusfnd_former_ind,
  bzd_vip_celebrity_ind,
  bzd_vip_congress_ind,
  bzd_vip_governor_ind,
  bzd_vip_mayor_ind,
  bzd_vip_senate_ind,
  bzd_volunteer_ind,
  bzd_vskill_ind,
  b.appl_src_cd
FROM 
eda.arc_mdm_vws.bzl_cnst_mstr_fsa a 
JOIN ddcoe_vws.bzf_cnst_fsa_chrctrstc2 b ON a.bzd_cnst_fsa_key = b.cnst_fsa_key
LEFT JOIN (select distinct cnst_fsa_key
from ddcoe_vws.cnst_fsa_chrctrstc2
where chrctrstc_typ_cd = 'SUSTAINER' and chrctrstc_val = 'CDRP'
and act_ind=1 and end_dt is not null) c ON a.bzd_cnst_fsa_key = c.cnst_fsa_key
where  a.cnst_typ_cd = 'IN'
with no schema binding;