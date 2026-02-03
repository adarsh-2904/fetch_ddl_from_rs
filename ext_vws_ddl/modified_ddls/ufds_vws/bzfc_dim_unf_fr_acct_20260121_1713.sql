CREATE OR REPLACE VIEW mods_bi.ufds_vws.bzfc_dim_unf_fr_acct AS
/*
created by: soumya p
created date:08/03/2019
purpose :to fetch org records

modified by:aman kumar
modifed date:7 jun-2019
Purpose: added prefd_county_cd and prefd_county_nm

modified by: aman kumar
modified date : 26 aug 2019
purpose: added new columns listed below:
1)grp_cnst_1_spouse_key
2)grp_cnst_2_spous
3)grp_cnst_1_spouse_ms
4)grp_cnst_2_spouse_mstr_id
5) related_org_1_key
6) related_org_2_key
7)related_org_
modified by: venkata siva
modified date ; 29-sept-2020
purpose: added new column 'frf_acct_rgn_key' to the view definition as part of ufds-23638

Updated By: GMS PBI Team
Updated On: May 28 2024
Purpose: Adding 3 new columns parent_id, parent_acct_cnst_key and parent_ind for GMS-37298
*/
SELECT
unf_fr_cnst_key,
nk_sf_acct_guid,
nk_ta_acct_id,
nk_chpt_sys_id,
frf_acct_id,
nk_hema_intrnl_acct_id,
cnst_typ_cd,
cnst_typ_dsc,
dnr_typ_cd,
dnr_typ_dsc,
nm_line,
prefd_addr_locator_key,
prefd_addr_typ,
prefd_addr_line_1,
prefd_addr_line_2,
prefd_city_nm,
prefd_state_cd,
prefd_state_dsc,
prefd_zip_cd,
prefd_country_cd,
prefd_country_nm,
prefd_county_cd,
prefd_county_nm,
prefd_phn_locator_key,
prefd_phn_typ,
prefd_phn_num,
prefd_email_locator_key,
prefd_email_typ,
prefd_email_addr,
prefd_lang_cd,
prefd_lang_dsc,
grp_active_cnst_cnt,
grp_cnst_1_key,
grp_cnst_2_key,
grp_cnst_1_spouse_key,
grp_cnst_2_spouse_key,
CASE WHEN cnst_typ_cd = 'OR' THEN unf_fr_cnst_key ELSE grp_org_cnst_key END AS grp_org_cnst_key,
grp_cnst_1_mstr_id,
grp_cnst_2_mstr_id,
grp_cnst_1_spouse_mstr_id,
grp_cnst_2_spouse_mstr_id,
CASE WHEN cnst_typ_cd = 'OR' THEN cnst_mstr_id ELSE grp_org_mstr_id END AS grp_org_mstr_id,
grp_cnst_rmng_mstr_id,
grp_cnst_rmng_cnst_nm,
related_org_1_key,
related_org_2_key,
related_org_3_key,
TO_DATE(strt_dt,'MM/DD/YYYY') AS strt_dt,
TO_DATE(frf_spotlighted_dt,'MM/DD/YYYY') AS frf_spotlighted_dt,
active_ind,
frf_active_ind,
anon_ind,
prvt_ind,
has_cdi_mstr_brg_ind,
frf_anon_ind,
frf_gift_mngd_dnr_ind,
frf_cur_mngd_dnr_ind,
frf_prvt_ind,
frf_visit_in_pairs_ind,
frf_spotlight_dnr_ind,
sustnr_ind,
plnd_gvng_confirm_ind,
plnd_gvng_info_rqst_ind,
inactvtn_reason_cd,
inactvtn_reason_dsc,
inactvtn_dt,
inactvtn_reason_txt,
ownr_key,
frf_acct_key,
frf_status_cd,
frf_spotlight_note_txt,
frf_ent_org_id,
frf_num_of_lctn,
frf_gift_portfolio_ctg,
frf_cur_portfolio_ctg,
frf_industry_nm,
frf_acct_ownr_asgnd_dt,
frf_acct_modified_key,
frf_prev_acct_ownr_key,
frf_acct_ownr_key,
rev_credit_key,
frf_rev_credit_key,
frf_dnr_intrst_othr_txt,
frf_dnr_intrst_txt,
frf_issue_risk_txt,
frf_leverage_point_txt,
frf_rlshp_fit_txt,
frf_rlshp_gap_txt,
frf_upld_txt,
frf_vsblty_thrshld_excd_ind,
frf_vsblty_thrshld_excd_cnt,
frf_vsblty_thrshld_excd_dt,
bio_acct_mngr_nm,
bio_acct_mngr_email,
bio_acct_mngr_phn,
bio_acct_ind,
bio_annual_collect_tgt,
bio_annual_drive_tgt,
bio_rgn_nm,
bio_cllctn_zipcode_dtl_key,
bio_maintain_strat_ind,
mmp_last_updated_dt,
mmp_status,
backed_out_ind,
back_out_reason_cd,
vendor_src_cd,
frf_acct_rgn_key,
gift_planning_ind,
honor_roll,
geographic_interests,
geographic_notes,
revenue_opportunity_min,
revenue_opportunity_max,
TO_CHAR(prospect_start_dt, 'MM/DD/YYYY') AS prospect_start_dt,
CASE WHEN prospect_start_dt IS NULL THEN 0 ELSE (CURRENT_DATE - prospect_start_dt) END AS prospect_age,
TO_CHAR(last_stage_change_dt, 'MM/DD/YYYY') AS last_stage_change_dt,
CASE WHEN last_stage_change_dt IS NULL THEN 0 ELSE (CURRENT_DATE - last_stage_change_dt) END AS current_stage_age,
parent_id, -- Added for GMS-37298
parent_acct_cnst_key, -- Added for GMS-37298
parent_ind -- Added for GMS-37298
FROM mods_bi.ufds_vws.bzfc_dim_unf_fr_cnst
WHERE (cnst_typ_cd IN('AG', 'OR', 'DW Unknown') AND appl_src_cd = 'SFFS')
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.ufds_vws.bzfc_dim_unf_fr_acct TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.ufds_vws.bzfc_dim_unf_fr_acct TO role ds_mods_reader_vt;
