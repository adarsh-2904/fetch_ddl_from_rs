CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fsa_cnst_indv_cntct_prefc 
AS
/* ---------------------------------------------------------------------------------------------------------------------------

Created by: Michael Andrien  
Created date: 18-April-2014  
Purpose: This view selects links arc_mdm_vws.bzl_cnst_mstr_fsa to the flatted FSA Contact Preference for Individuals view in ddcoe_vws.

Modified by: Majeed Mohammad  
Modified date: 20-Aug-2014  
Purpose: The view was modified to bring in both the Individual and Org contact preferences. It filters the Account characteristics whose cnst_typ_cd='AG'

------------------------------------------------------------------------------------------------------------------------------------ */
SELECT
 a.cnst_mstr_id,
 a.bzd_cnst_fsa_key,
 a.bzd_acct_fsa_key,
 a.bzd_ntrl_key,
 a.bzd_chpt_import_id,
 a.nk_ta_acct_id,
 a.nk_ta_nm_id,
 a.nk_sf_acct_id,
 a.nk_sf_cntct_id,
 a.bzd_SFID,
 a.cnst_typ_cd,
 a.appl_src_cd,
 b.bzd_ack_s_special_ind,
 b.bzd_ack_special_ind,
 b.bzd_acknowledge_no_ind,
 b.bzd_acknwldg_no_valtim_ak_ind,
 b.bzd_acknwldg_one_summary_ind,
 b.bzd_acknowledge_special_ind,
 b.bzd_appeal_o_no_email_ind,
 b.bzd_appeal_s_1r_ind,
 b.bzd_appeal_s_disasteronly_ind,
 b.bzd_appeal_s_no_ind,
 b.bzd_appeal_s_no_add_ind,
 b.bzd_appeal_s_no_email_ind,
 b.bzd_appeal_s_no_exchange_ind,
 b.bzd_appeal_s_no_mail_ind,
 b.bzd_appeal_s_no_news_ind,
 b.bzd_appeal_s_no_phone_ind,
 b.bzd_appeal_s_no_renew_ind,
 b.bzd_appeal_s_nophone_ind,
 b.bzd_appeal_1r_ind,
 b.bzd_appeal_2r_ind,
 b.bzd_appeal_3r_ind,
 b.bzd_appeal_4r_ind,
 b.bzd_appeal_addrrestrict_ind,
 b.bzd_appeal_dis_news_ind,
 b.bzd_appeal_disasteronly_ind,
 b.bzd_appeal_gpstewardonly_ind,
 b.bzd_appeal_incompadd_ind,
 b.bzd_appeal_news_only_ind,
 b.bzd_appeal_no_ind,
 b.bzd_appeal_no_add_ind,
 b.bzd_appeal_no_address_ind,
 b.bzd_appeal_no_dm_ind,
 b.bzd_appeal_no_dm_labels_ind,
 b.bzd_appeal_no_email_ind,
 b.bzd_appeal_no_exchange_ind,
 b.bzd_appeal_no_gpcga_ind,
 b.bzd_appeal_no_gpsolicit_ind,
 b.bzd_appeal_no_gpsurvey_ind,
 b.bzd_appeal_no_mail_ind,
 b.bzd_appeal_no_mail_all_ind,
 b.bzd_appeal_no_news_ind,
 b.bzd_appeal_no_phone_ind,
 b.bzd_appeal_nophone_ind,
 b.bzd_appeal_okapr_ind,
 b.bzd_appeal_okaug_ind,
 b.bzd_appeal_okdec_ind,
 b.bzd_appeal_okfeb_ind,
 b.bzd_appeal_okgplg_ind,
 b.bzd_appeal_okjan_ind,
 b.bzd_appeal_okjul_ind,
 b.bzd_appeal_okjun_ind,
 b.bzd_appeal_okmar_ind,
 b.bzd_appeal_okmay_ind,
 b.bzd_appeal_oknov_ind,
 b.bzd_appeal_okoct_ind,
 b.bzd_appeal_oksep_ind,
 b.bzd_appeal_once_per_yr_ind,
 b.bzd_appeal_remove_ind,
 b.bzd_benefit_no_card_ind,
 b.bzd_benefit_no_premium_ind,
 b.bzd_constit_workplgiv_ind,
 b.bzd_email_alerts_ind,
 b.bzd_email_blooddnrmsgs_ind,
 b.bzd_email_crossnotes_ind,
 b.bzd_email_disasteronly_ind,
 b.bzd_email_donorsurveys_ind,
 b.bzd_email_giftcatalog_ind,
 b.bzd_email_giftsatwork_ind,
 b.bzd_email_holiday_ind,
 b.bzd_email_managed_donor_ind,
 b.bzd_email_redcrossstore_ind,
 b.bzd_email_safmessages_ind,
 b.bzd_email_volunteermsgs_ind,
 b.bzd_eventsonly_ind,
 b.bzd_mail_mar_onl_ind,
 b.bzd_ok_to_mail_ind,
 b.bzd_one_time_mai_ind,
 b.bzd_specialevent_no_ind
FROM 
 eda.arc_mdm_vws.bzl_cnst_mstr_fsa a
JOIN 
 ddcoe_vws.bzf_cnst_fsa_cntct_prefc b 
 ON a.bzd_cnst_fsa_key = b.cnst_fsa_key
WHERE 
 a.cnst_typ_cd = 'IN' with no schema binding;