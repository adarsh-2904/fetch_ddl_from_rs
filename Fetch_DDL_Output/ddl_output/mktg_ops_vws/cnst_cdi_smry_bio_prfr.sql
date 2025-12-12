CREATE OR REPLACE VIEW mktg_ops_vws.cnst_cdi_smry_bio_prfr AS
SELECT 
   cnst_mstr_id,
   cnst_hsld_id,
   cnst_arc_deceased_cd,
   dm_cnst_data_src_cd,
   last_ep_donor_key,
   last_dr_contact_key,
   last_race_cd,
   last_race_dsc,
   dm_cnst_prsn_prfx_nm,
   dm_cnst_prsn_f_nm,
   dm_cnst_prsn_m_nm,
   dm_cnst_prsn_l_nm,
   dm_cnst_prsn_sfx_nm,
   dm_cnst_prsn_full_nm,
   dm_cnst_alias_in_saltn_nm,
   dm_cnst_alias_out_saltn_nm,
   dm_locator_addr_key,
   dm_cnst_addr_assessmnt_ctg,
   a.dpv_cd,
   dm_cnst_line_1_addr,
   dm_cnst_line_2_addr,
   dm_cnst_city_nm,
   dm_cnst_st_cd,
   dm_cnst_zip_5_cd,
   dm_cnst_zip_4_cd,
   dm_cnst_addr_county_nm,
   dm_cnst_email,
   dm_cnst_org_nm,
   dm_cnst_typ_dsc,
   em_cnst_data_src_cd,
   em_cnst_prsn_prfx_nm,
   em_cnst_prsn_f_nm,
   em_cnst_prsn_m_nm,
   em_cnst_prsn_l_nm,
   em_cnst_prsn_sfx_nm,
   em_cnst_prsn_full_nm,
   em_cnst_alias_in_saltn_nm,
   em_cnst_alias_out_saltn_nm,
   em_locator_addr_key,
   em_cnst_line_1_addr,
   em_cnst_line_2_addr,
   em_cnst_city_nm,
   em_cnst_st_cd,
   em_cnst_zip_5_cd,
   em_cnst_zip_4_cd,
   em_cnst_addr_county_nm,
   em_cnst_email,
   em_email_key,
   em_cnst_email_assessmnt_ctg,
   em_cnst_org_nm,
   em_cnst_typ_dsc,
   email_dlvrbl_ind,
   prim_cnst_phn,
   prim_cnst_phn_source,
   prim_cnst_phn_typ_dsc,
   cnst_work_phone,
   cnst_work_phone_source,
   cnst_work_phone_type_cd as cnst_work_phone_typ_dsc,
   cnst_mbl_phn,
   cnst_mbl_phn_source,
   cnst_mbl_phn_typ_dsc,
   do_not_call_hm_phn_ind,
   do_not_call_mbl_phn_ind,
   do_not_call_work_phn_ind,
   do_not_email_ind,
   do_not_mail_ind,
   do_not_txt_ind,
   cnst_3rd_prty_segmtn_group_nm,
   COALESCE(a.unit_key, 0) AS unit_key,
   d.nk_ecode AS unit_cd,
   affl_lock_ind,
   nxt_leukoph_rec_dt,
   nxt_pls_rec_dt,
   nxt_plt_rec_dt,
   nxt_wb_rec_dt,
   CASE 
     WHEN COALESCE(c.unit_key, 0) = 0 THEN COALESCE(a.unit_key, 0) 
     ELSE COALESCE(c.unit_key, 0) 
   END AS mktg_unit_key,
   CASE 
     WHEN b.ecode IS NULL THEN d.nk_ecode 
     ELSE b.ecode 
   END AS mktg_unit_cd
FROM mktg_ops_tbls.cnst_cdi_smry_bio_prfr a
LEFT JOIN mods_bi.mktg_ops_vws.bz_geo_zip_code_to_chapter b 
  ON a.dm_cnst_zip_5_cd = b.ZIP
LEFT JOIN mods_bi.mktg_ops_vws.bz_dim_unit c 
  ON b.ecode = c.nk_ecode
LEFT JOIN mods_bi.mktg_ops_vws.bz_dim_unit d 
  ON a.unit_key = d.unit_key
with no schema binding;