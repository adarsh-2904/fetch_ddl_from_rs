CREATE OR REPLACE VIEW mktg_ops_vws.bzf_cem_fr_cnst_loc_prefs AS

SELECT 
    a.cnst_mstr_id,
    a.bzd_pref_loc_all_email_loc_id,
    'CEM' AS cnst_data_src_cd,
    b.cnst_email_addr AS all_cnst_email_addr,
    ba.assessmnt_ctg AS all_em_assessmnt_ctg,
    a.bzd_pref_loc_fr_email_loc_id,
    c.cnst_email_addr AS fr_cnst_email_addr,
    ca.assessmnt_ctg AS fr_em_assessmnt_ctg,    
    a.bzd_pref_loc_all_mail_loc_id AS all_locator_addr_key,
    da.assessmnt_ctg AS all_cnst_addr_assessmnt_ctg,
    d.line1_addr AS all_cnst_line_1_addr,
    d.line2_addr AS all_cnst_line_2_addr,
    d.city AS all_cnst_city_nm,
    d.state AS all_cnst_st_cd,
    d.zip_5 AS all_cnst_zip_5_cd,
    d.zip_4 AS all_cnst_zip_4_cd,
    d.county AS all_cnst_addr_county_nm,
    a.bzd_pref_loc_fr_mail_loc_id AS fr_locator_addr_key,
    ea.assessmnt_ctg AS fr_cnst_addr_assessmnt_ctg,
    e.line1_addr AS fr_cnst_line_1_addr,
    e.line2_addr AS fr_cnst_line_2_addr,
    e.city AS fr_cnst_city_nm,
    e.state AS fr_cnst_st_cd,
    e.zip_5 AS frl_cnst_zip_5_cd,
    e.zip_4 AS fr_cnst_zip_4_cd,
    e.county AS fr_cnst_addr_county_nm,
    a.bzd_pref_loc_all_phone_loc_id AS all_locator_phone_key,
    fa.assessmnt_ctg AS all_phone_assessmnt,
    f.cnst_phn_num AS all_prim_cnst_phn,
    f.cnst_phn_extsn_num AS all_cnst_phn_extsn_num,
    a.bzd_pref_loc_fr_phone_loc_id AS fr_locator_phone_key,
    ga.assessmnt_ctg AS fr_phone_assessmnt,
    g.cnst_phn_num AS fr_prim_cnst_phn,
    g.cnst_phn_extsn_num AS fr_cnst_phn_extsn_num

FROM eda.arc_cmm_vws.bzf_cnst_pref_loc a
LEFT JOIN eda.arc_mdm_vws.bz_locator_email b ON b.email_key = a.bzd_pref_loc_all_email_loc_id
LEFT JOIN eda.arc_mdm_vws.bz_assessmnt ba ON b.assessmnt_key = ba.assessmnt_key
LEFT JOIN eda.arc_mdm_vws.bz_locator_email c ON c.email_key = a.bzd_pref_loc_fr_email_loc_id 
LEFT JOIN eda.arc_mdm_vws.bz_assessmnt ca ON c.assessmnt_key = ca.assessmnt_key

LEFT JOIN eda.arc_mdm_vws.bz_locator_addr d ON d.locator_addr_key = a.bzd_pref_loc_all_mail_loc_id
LEFT JOIN eda.arc_mdm_vws.bz_assessmnt da ON d.assessmnt_key = da.assessmnt_key
LEFT JOIN eda.arc_mdm_vws.bz_locator_addr e ON e.locator_addr_key = a.bzd_pref_loc_fr_mail_loc_id 
LEFT JOIN eda.arc_mdm_vws.bz_assessmnt ea ON e.assessmnt_key = ea.assessmnt_key

LEFT JOIN eda.arc_mdm_vws.bz_locator_phn f ON f.locator_phn_key = a.bzd_pref_loc_all_phone_loc_id
LEFT JOIN eda.arc_mdm_vws.bz_assessmnt fa ON f.assessmnt_key = fa.assessmnt_key
LEFT JOIN eda.arc_mdm_vws.bz_locator_phn g ON g.locator_phn_key = a.bzd_pref_loc_fr_phone_loc_id 
LEFT JOIN eda.arc_mdm_vws.bz_assessmnt ga ON g.assessmnt_key = ga.assessmnt_key

WHERE 
    a.bzd_pref_loc_all_email_loc_id IS NOT NULL OR 
    a.bzd_pref_loc_fr_email_loc_id IS NOT NULL OR
    a.bzd_pref_loc_all_mail_loc_id IS NOT NULL OR 
    a.bzd_pref_loc_fr_mail_loc_id IS NOT NULL OR 
    a.bzd_pref_loc_all_phone_loc_id IS NOT NULL OR 
    a.bzd_pref_loc_fr_phone_loc_id IS NOT NULL

WITH NO SCHEMA BINDING
;