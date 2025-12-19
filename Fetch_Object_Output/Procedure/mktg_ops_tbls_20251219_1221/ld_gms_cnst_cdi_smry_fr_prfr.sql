CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_cnst_cdi_smry_fr_prfr()
 LANGUAGE plpgsql
AS $$
	
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_cnst_cdi_smry_fr_prfr', 'Stored Procedure', 'Inprogress', v_start_time);

begin


TRUNCATE TABLE mktg_stage_tbls.stg_gms_cnst_cdi_smry_fr_prfr_src ;
TRUNCATE TABLE mktg_stage_tbls.bzf_cem_fr_cnst_loc_prefs_tmp ;
 
COMMIT;

INSERT INTO mktg_stage_tbls.stg_gms_cnst_cdi_smry_fr_prfr_src
SELECT
    M.cnst_mstr_id AS const_mstr_id,
    M.cnst_hsld_id AS const_household_id,
    M.cnst_arc_deceased_cd AS const_deceased_code,
    
    CASE 
        WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.arc_srcsys_cd, 'CASE_INSENSITIVE')  
        ELSE collate(DM.cnst_data_src_cd, 'CASE_INSENSITIVE')  
    END AS dm_prsn_nm_src_cd,
    
    DM.cnst_data_src_cd AS dm_cnst_data_src_cd,
    
CAST(
    CASE 
        WHEN DM.cnst_prsn_l_nm IS NULL 
            THEN nm_rnk.locator_prsn_nm_key
        ELSE DM.locator_prsn_nm_key
    END 
AS BIGINT) AS dm_locator_prsn_nm_key,

    
CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.assessmnt_ctg::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_prsn_nm_assessmnt_ctg::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_prsn_nm_assessmnt_ctg,

CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_nm_prefix::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_prsn_prfx_nm::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_prsn_prfx_nm,

CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_first_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_prsn_f_nm::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_prsn_f_nm,

CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_middle_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_prsn_m_nm::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_prsn_m_nm,

CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_last_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_prsn_l_nm::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_prsn_l_nm,

CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_nm_suffix::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_prsn_sfx_nm::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_prsn_sfx_nm,

CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.cnst_prsn_full_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_prsn_full_nm::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_prsn_full_nm,

CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.bz_cnst_alias_in_saltn_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_alias_in_saltn_nm::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_alias_in_saltn_nm,

CASE 
    WHEN DM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.bz_cnst_alias_out_saltn_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_alias_out_saltn_nm::text, 'CASE_INSENSITIVE')  
END AS dm_cnst_alias_out_saltn_nm,


    DM.locator_addr_key AS dm_locator_addr_key,
    DM.cnst_addr_assessmnt_ctg AS dm_addr_assessmnt_ctg,
    DM.dpv_cd AS dm_dpv_cd,
    DM.cnst_line_1_addr AS dm_line_1_addr,
    DM.cnst_line_2_addr AS dm_line_2_addr,
    DM.cnst_city_nm AS dm_city_nm,
    DM.cnst_st_cd AS dm_st_cd,
    DM.cnst_zip_5_cd AS dm_zip_5_cd,
    DM.cnst_zip_4_cd AS dm_zip_4_cd,
    DM.cnst_addr_county_nm AS dm_county_nm,
    DM.cnst_email AS dm_email,
    DM.cnst_org_nm AS dm_org_nm,
    DM.cnst_typ_dsc AS dm_typ_dsc,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.arc_srcsys_cd::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_data_src_cd::text, 'CASE_INSENSITIVE')  
END AS em_prsn_nm_src_cd,

EM.cnst_data_src_cd AS em_cnst_data_src_cd,

CAST(
    CASE 
        WHEN EM.cnst_prsn_l_nm IS NULL 
            THEN nm_rnk.locator_prsn_nm_key
        ELSE EM.locator_prsn_nm_key
    END 
AS BIGINT) AS em_locator_prsn_nm_key,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.assessmnt_ctg::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_prsn_nm_assessmnt_ctg::text, 'CASE_INSENSITIVE')  
END AS em_cnst_prsn_nm_assessmnt_ctg,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_nm_prefix::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_prsn_prfx_nm::text, 'CASE_INSENSITIVE')  
END AS em_cnst_prsn_prfx_nm,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_first_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_prsn_f_nm::text, 'CASE_INSENSITIVE')  
END AS em_cnst_prsn_f_nm,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_middle_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_prsn_m_nm::text, 'CASE_INSENSITIVE')  
END AS em_cnst_prsn_m_nm,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_last_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_prsn_l_nm::text, 'CASE_INSENSITIVE')  
END AS em_cnst_prsn_l_nm,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.locator_prsn_nm_suffix::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_prsn_sfx_nm::text, 'CASE_INSENSITIVE')  
END AS em_cnst_prsn_sfx_nm,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.cnst_prsn_full_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_prsn_full_nm::text, 'CASE_INSENSITIVE')  
END AS em_cnst_prsn_full_nm,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.bz_cnst_alias_in_saltn_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(EM.cnst_alias_in_saltn_nm::text, 'CASE_INSENSITIVE')  
END AS em_cnst_alias_in_saltn_nm,

CASE 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN collate(nm_rnk.bz_cnst_alias_out_saltn_nm::text, 'CASE_INSENSITIVE')  
    ELSE collate(DM.cnst_alias_out_saltn_nm::text, 'CASE_INSENSITIVE')  
END AS em_cnst_alias_out_saltn_nm,


    EM.locator_addr_key AS em_locator_addr_key,
    EM.cnst_line_1_addr AS em_line_1_addr,
    EM.cnst_line_2_addr AS em_line_2_addr,
    EM.cnst_city_nm AS em_city_nm,
    EM.cnst_st_cd AS em_st_cd,
    EM.cnst_zip_5_cd AS em_zip_5_cd,
    EM.cnst_zip_4_cd AS em_zip_4_cd,
    EM.cnst_addr_county_nm AS em_county_nm,
    EM.cnst_email AS em_email,
    EM.cnst_email_key AS em_email_key,
    EM.cnst_email_assessmnt_ctg AS em_email_assessmnt_ctg,
    EM.cnst_org_nm AS em_org_nm,
    EM.cnst_typ_dsc AS em_typ_dsc,

    0 AS email_deliverable_ind,

    hphone.prim_cnst_phn AS primary_phone,
    hphone.prim_cnst_phn_source AS primary_phone_source,
    hphone.prim_cnst_phn_typ_dsc AS primary_phone_type,

    wphone.cnst_work_phone AS work_phone,
    wphone.cnst_work_phone_source AS work_phone_source,
    wphone.cnst_work_phone_type_cd AS work_phone_type,

    mphone.cnst_mbl_phn AS mobile_phone,
    mphone.cnst_mbl_phn_source AS mobile_phone_source,
    mphone.cnst_mbl_phn_typ_dsc AS mobile_phone_type,

CASE 
    WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 
    ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_hm_phn_ind, 0) 
END AS do_not_call_hm_phn_ind,

CASE 
    WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 
    ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_mbl_phn_ind, 0) 
END AS do_not_call_mbl_phn_ind,

CASE 
    WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 
    ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_work_phn_ind, 0) 
END AS do_not_call_work_phn_ind,

CASE 
    WHEN em.cnst_email LIKE '%@philips.com' THEN 1 
    WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 
    ELSE COALESCE(cnst_cntct_pref.fr_do_not_email_ind, 0) 
END AS fr_do_not_email_ind,

CASE 
    WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 
    ELSE COALESCE(cnst_cntct_pref.fr_do_not_mail_ind, 0) 
END AS do_not_mail_ind,

CASE 
    WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 
    ELSE COALESCE(cnst_cntct_pref.fr_do_not_txt_ind, 0) 
END AS do_not_txt_ind,

NULL AS third_party_segment_group,

CASE 
    WHEN DU.unit_key IS NULL THEN prim_chpt.prim_affl_unit_key 
    ELSE DU.unit_key 
END AS unit_key,


    COALESCE(prim_chpt.acct_affl_lock_ind, 0) AS affl_lock_ind

    , COALESCE(mngd_dnr.frf_cur_mngd_dnr_ind, 0) AS sf_acct_fmd_ind
    , mngd_dnr.frf_status_cd AS sf_managed_portfolio_status
    , mngd_dnr.frf_cur_portfolio_ctg AS portfolio_category
    , mngd_dnr.rlshp_mgr_ownr_key AS relationship_manager_cnst_fsa_key
    , mngd_dnr.rlshp_mgr_nm AS relationship_manager_name
    , mngd_dnr.rlshp_mgr_prefd_email_addr AS relationship_manager_preferred_email_address
    , M.cnst_typ_cd AS constituent_type_code
   , CASE 
       WHEN M.cnst_typ_cd = 'IN' THEN 'IN' 
       ELSE org_typ.org_typ_cd 
    END AS org_typ_cd
    , sf_acct.frf_acct_id AS sf_account_id
    , sf_cntct.frf_cntct_id AS sf_contact_id
    , mult_sf_cnst_ind AS sf_multi_account_ind

FROM 
(
SELECT DISTINCT a.cnst_mstr_id
FROM 
(
SELECT  brid.cnst_mstr_id 
FROM eda.arc_mdm_vws.bz_cnst_mstr_bridge brid 
LEFT JOIN 
	(
		SELECT cnst_mstr_id, arc_srcsys_cd
		FROM mktg_ops_vws.bz_grp_mbrshp a 
		LEFT JOIN eda. arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
		WHERE grp_typ NOT IN ('Vol NHQ LOB',  'Bio NHQ LOB', 'PHSS NHQ LOB') 
	) fr_list (cnst_mstr_id, arc_srcsys_cd) ON brid.cnst_mstr_id = fr_list.cnst_mstr_id AND brid.cnst_mstr_subj_area_cd = fr_list.arc_srcsys_cd

WHERE 
(
	cnst_mstr_subj_area_cd IN   ('RCO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'MDON')
	OR (cnst_mstr_subj_area_cd IN (SELECT arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='FR'))
	OR 	( brid.cnst_mstr_id = fr_list.cnst_mstr_id AND brid.cnst_mstr_subj_area_cd = fr_list.arc_srcsys_cd) 
	OR (brid.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM  mktg_ops_vws.atg_order_registrants WHERE atg_gift_cnt > 0) AND brid.cnst_mstr_subj_area_cd = 'ATGO')
	OR (brid.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM  mktg_ops_vws.atg_registrants WHERE atg_gift_cnt > 0) AND brid.cnst_mstr_subj_area_cd =  'ATG')
)

UNION ALL

SELECT email.cnst_mstr_id
FROM eda.arc_mdm_vws.bz_cnst_email email
LEFT JOIN 
	(
		SELECT cnst_mstr_id, arc_srcsys_cd
		FROM mktg_ops_vws.bz_grp_mbrshp a 
		LEFT JOIN eda. arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
		WHERE grp_typ NOT IN ('Vol NHQ LOB',  'Bio NHQ LOB', 'PHSS NHQ LOB') 
	) fr_list (cnst_mstr_id, arc_srcsys_cd) ON email.cnst_mstr_id = fr_list.cnst_mstr_id AND email.arc_srcsys_cd = fr_list.arc_srcsys_cd

WHERE 
(
	email.arc_srcsys_cd IN    ('RCO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'MDON')
	OR (email.arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='FR'))
	OR 	( email.cnst_mstr_id = fr_list.cnst_mstr_id AND email.arc_srcsys_cd = fr_list.arc_srcsys_cd) 
	OR (email.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM  mktg_ops_vws.atg_order_registrants WHERE atg_gift_cnt > 0) AND email.arc_srcsys_cd = 'ATGO')
	OR (email.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM  mktg_ops_vws.atg_registrants WHERE atg_gift_cnt > 0) AND email.arc_srcsys_cd =  'ATG')
)
) a ) FR_CNST 

JOIN eda.arc_mdm_vws.bz_cnst_mstr AS M
    ON FR_CNST.cnst_mstr_id = M.cnst_mstr_id
    
LEFT OUTER JOIN 
 mktg_ops_tbls.cnst_cdi_s_f_p_fr_dmail  DM
  ON M.cnst_mstr_id = DM.cnst_mstr_id
                  
LEFT OUTER JOIN
 mktg_ops_tbls.cnst_cdi_s_f_p_fr_email  EM
  ON M.cnst_mstr_id = EM.cnst_mstr_id
  
LEFT OUTER JOIN 

(
 SELECT 
 		a.cnst_mstr_id,
		a.affl_lock_ind,
		b.unit_key AS prim_affl_unit_key 
 FROM eda.ufds_vws.bzfc_cnst_fr_prfl a
 LEFT JOIN mktg_ops_vws.dim_unit_merged b ON a.rev_credit_key = orig_unit_key
 ) prim_chpt (cnst_mstr_id, acct_affl_lock_ind , prim_affl_unit_key) ON M.cnst_mstr_id = prim_chpt.cnst_mstr_id

LEFT JOIN (
    SELECT
        mngd_dnr.frf_acct_id, 
        mngd_dnr.cnst_mstr_id, 
        mngd_dnr.unf_fr_cnst_key, 
        mngd_dnr.frf_cur_mngd_dnr_ind, 
        mngd_dnr.rlshp_mgr_nm, 
        mngd_dnr.rlshp_mgr_prefd_email_addr, 
        mngd_dnr.rlshp_mgr_ownr_key, 
        mngd_dnr.frf_status_cd, 
        mngd_dnr.frf_cur_portfolio_ctg,
        CASE 
            WHEN mstr_sf_cnst.sf_cnst_cnt > 1 THEN 1 
            ELSE 0 
        END AS mult_sf_cnst_ind
    FROM (
        SELECT  
            a.frf_acct_id, 
            d.cnst_mstr_id, 
            a.unf_fr_cnst_key, 
            a.frf_cur_mngd_dnr_ind, 
            b.nm_line AS rlshp_mgr_nm, 
            b.prefd_email_addr AS rlshp_mgr_prefd_email_addr, 
            a.ownr_key AS rlshp_mgr_ownr_key, 
            a.frf_status_cd, 
            a.frf_cur_portfolio_ctg
        FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst AS a
        LEFT JOIN eda.ufds_vws.bzfc_dim_unf_fr_owner AS b 
            ON a.acct_ownr_key = b.unf_fr_cnst_key
        LEFT JOIN eda.ufds_vws.bzl_cnst_mstr_fsa_acct AS d 
            ON a.unf_fr_cnst_key = d.cnst_key
        WHERE a.cnst_typ_cd IN ('AG', 'OR') 
          AND a.appl_src_cd = 'SFFS' 
          AND d.cnst_mstr_id IS NOT NULL
    ) AS mngd_dnr
    INNER JOIN (
        SELECT *
        FROM (
            SELECT 
                b.cnst_mstr_id, 
                a.unf_fr_cnst_key, 
                COUNT(*) OVER (PARTITION BY b.cnst_mstr_id) AS sf_cnst_cnt,
                ROW_NUMBER() OVER (
                    PARTITION BY b.cnst_mstr_id 
                    ORDER BY 
                        a.frf_cur_mngd_dnr_ind DESC, 
                        a.active_ind DESC, 
                        a.unf_fr_cnst_key DESC
                ) AS rn
            FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst AS a
            LEFT JOIN eda.ufds_vws.bzl_cnst_mstr_fsa_acct AS b 
                ON a.unf_fr_cnst_key = b.cnst_key
            WHERE a.cnst_typ_cd IN ('AG', 'OR') 
              AND a.appl_src_cd = 'SFFS' 
              AND b.cnst_mstr_id IS NOT NULL
        ) sub
        WHERE rn = 1
    ) AS mstr_sf_cnst
    ON mngd_dnr.cnst_mstr_id = mstr_sf_cnst.cnst_mstr_id 
       AND mngd_dnr.unf_fr_cnst_key = mstr_sf_cnst.unf_fr_cnst_key
) AS mngd_dnr
ON M.cnst_mstr_id = mngd_dnr.cnst_mstr_id

LEFT OUTER JOIN mktg_ops_vws.bzfc_dim_unit_merged DU ON prim_chpt.prim_affl_unit_key = DU.orig_unit_key 

LEFT OUTER JOIN (
    SELECT *
    FROM (
        SELECT
            bz_cnst_phn.cnst_mstr_id,
            bz_cnst_phn.cnst_phn_num AS prim_cnst_phn,
            bz_cnst_phn.arc_srcsys_cd AS prim_cnst_phn_source,
            CAST(CASE 
                WHEN bz_cnst_phn.phn_typ_cd = 'H' THEN 'Home'
                ELSE 'Other'
            END AS VARCHAR(20)) AS prim_cnst_phn_typ_dsc,
            CASE 
                WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd
            END AS fr_arc_srcsys_cd,
            CASE 
                WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='SFFS' THEN 1
                WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='GMFS' THEN 2
                WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='TAFS' THEN 2.1
                WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
                WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='RCO' THEN 4.1
                WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='ATG' THEN 4.2
                WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='CNVO' THEN 5
                WHEN bz_cnst_phn.arc_srcsys_cd='CDIM' AND bz_cnst_phn.phn_typ_cd='LN' THEN 6
                ELSE 999
            END AS hnum,
            ROW_NUMBER() OVER (
                PARTITION BY bz_cnst_phn.cnst_mstr_id
                ORDER BY 
                    CASE 
                        WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='SFFS' THEN 1
                        WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='GMFS' THEN 2
                        WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='TAFS' THEN 2.1
                        WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
                        WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='RCO' THEN 4.1
                        WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='ATG' THEN 4.2
                        WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='CNVO' THEN 5
                        WHEN bz_cnst_phn.arc_srcsys_cd='CDIM' AND bz_cnst_phn.phn_typ_cd='LN' THEN 6
                        ELSE 999
                    END ASC,
                    bz_cnst_phn.dw_srcsys_trans_ts DESC
            ) AS rownum
        FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
        LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys
            ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
            AND bz_arc_srcsys.line_of_service_cd = 'FR'
        WHERE bz_cnst_phn.phn_typ_cd IN ('H', 'LN')
          AND bz_cnst_phn.assessmnt_ctg = 'Usable'
          AND bz_cnst_phn.cnst_phn_end_dt = '9999-12-31'
    ) AS ranked_phns
    WHERE ranked_phns.hnum < 999 AND ranked_phns.rownum = 1
) AS hphone
ON M.cnst_mstr_id = hphone.cnst_mstr_id


LEFT OUTER JOIN (
    SELECT *
    FROM (
        SELECT *
        FROM (
            SELECT
                bz_cnst_phn.cnst_mstr_id,
                bz_cnst_phn.cnst_phn_num AS cnst_work_phone,
                bz_cnst_phn.arc_srcsys_cd AS cnst_work_phone_source,
                CAST('Work' AS VARCHAR(20)) AS cnst_work_phone_type_cd,
                CASE 
                    WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd 
                END AS fr_arc_srcsys_cd,
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' THEN 1
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'GMFS' THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' THEN 2.1
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'RCO' THEN 4.1
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' THEN 4.2
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'CNVO' THEN 5
                    ELSE 999
                END AS wnum,
                ROW_NUMBER() OVER (
                    PARTITION BY bz_cnst_phn.cnst_mstr_id
                    ORDER BY 
                        CASE 
                            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' THEN 1
                            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'GMFS' THEN 2
                            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' THEN 2.1
                            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
                            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'RCO' THEN 4.1
                            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' THEN 4.2
                            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'CNVO' THEN 5
                            ELSE 999
                        END ASC,
                        bz_cnst_phn.dw_srcsys_trans_ts DESC
                ) AS rownum
            FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
            LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys
                ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
                AND bz_arc_srcsys.line_of_service_cd = 'FR'
            WHERE 
                bz_cnst_phn.phn_typ_cd = 'W'
                AND bz_cnst_phn.assessmnt_ctg = 'Usable'
                AND bz_cnst_phn.cnst_phn_end_dt = '9999-12-31'
        ) AS ranked_work_phns
        WHERE rownum = 1 AND wnum < 999
    ) AS filtered_work_phns
) AS wphone
ON M.cnst_mstr_id = wphone.cnst_mstr_id


LEFT OUTER JOIN (
    SELECT *
    FROM (
        SELECT *
        FROM (
            SELECT
                bz_cnst_phn.cnst_mstr_id,
                bz_cnst_phn.cnst_phn_num AS cnst_mbl_phn,
                bz_cnst_phn.arc_srcsys_cd AS cnst_mbl_phn_source,
                CAST('Mobile' AS VARCHAR(20)) AS cnst_mbl_phn_typ_dsc,
                CASE 
                    WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd 
                END AS fr_arc_srcsys_cd,
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' THEN 1
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'GMFS' THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' THEN 2.1
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'RCO' THEN 4.1
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' THEN 4.2
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'CNVO' THEN 5
                    WHEN bz_cnst_phn.arc_srcsys_cd = 'MDON' THEN 6
                    ELSE 999
                END AS mnum,
                ROW_NUMBER() OVER (
                    PARTITION BY bz_cnst_phn.cnst_mstr_id
                    ORDER BY 
                        CASE 
                            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' THEN 1
                            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'GMFS' THEN 2
                            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' THEN 2.1
                            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
                            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'RCO' THEN 4.1
                            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' THEN 4.2
                            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'CNVO' THEN 5
                            WHEN bz_cnst_phn.arc_srcsys_cd = 'MDON' THEN 6
                            ELSE 999
                        END ASC,
                        bz_cnst_phn.dw_srcsys_trans_ts DESC
                ) AS rownum
            FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
            LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys
                ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
                AND bz_arc_srcsys.line_of_service_cd IN ('FR', 'MDON')
            WHERE 
                (bz_cnst_phn.phn_typ_cd = 'M' OR bz_cnst_phn.arc_srcsys_cd = 'MDON')
                AND bz_cnst_phn.assessmnt_ctg = 'Usable'
                AND bz_cnst_phn.cnst_phn_end_dt = '9999-12-31'
        ) AS ranked_mbl_phns
        WHERE rownum = 1 AND mnum < 999
    ) AS filtered_mbl_phns
) AS mphone
ON M.cnst_mstr_id = mphone.cnst_mstr_id


LEFT JOIN (
    SELECT *
    FROM (
        SELECT 
            a.cnst_mstr_id,
            b.locator_prsn_nm_key,
            a.cnst_typ_cd,
            b.locator_prsn_first_nm,
            b.locator_prsn_middle_nm,
            b.locator_prsn_last_nm,
            b.locator_prsn_nm_prefix,
            b.locator_prsn_nm_suffix,
            b.cnst_prsn_full_nm,
            b.bz_cnst_alias_out_saltn_nm,
            b.bz_cnst_alias_in_saltn_nm,
            b.assessmnt_ctg,
            b.arc_srcsys_cd,
            b.cnst_nm_strt_dt,
            b.dw_srcsys_trans_ts,
            ROW_NUMBER() OVER (
                PARTITION BY a.cnst_mstr_id
                ORDER BY 
                    CASE 
                        WHEN b.arc_srcsys_cd = 'STRX' THEN 1
                        WHEN b.arc_srcsys_cd = 'CDIM' THEN 2
                        WHEN b.arc_srcsys_cd = 'SFFS' THEN 3
                        WHEN b.arc_srcsys_cd = 'GMFS' THEN 4
                        WHEN b.arc_srcsys_cd = 'RCO'  THEN 5
                        ELSE 6
                    END,
                    b.cnst_nm_strt_dt DESC,
                    b.dw_srcsys_trans_ts DESC
            ) AS row_num
        FROM eda.arc_mdm_vws.bz_cnst_mstr a
        LEFT JOIN (
            SELECT 
                a.cnst_mstr_id,
                a.locator_prsn_nm_key,
                a.locator_prsn_first_nm,
                a.locator_prsn_middle_nm,
                a.locator_prsn_last_nm,
                a.locator_prsn_nm_prefix,
                a.locator_prsn_nm_suffix,
                a.cnst_prsn_full_nm,
                a.bz_cnst_alias_out_saltn_nm,
                a.bz_cnst_alias_in_saltn_nm,
                a.assessmnt_ctg,
                a.arc_srcsys_cd,
                a.cnst_nm_strt_dt,
                a.dw_srcsys_trans_ts
            FROM eda.arc_mdm_vws.bzfc_cnst_prsn_nm a
            LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys b
                ON a.arc_srcsys_cd = b.arc_srcsys_cd
            WHERE 
                (b.line_of_service_cd = 'FR' OR a.arc_srcsys_cd IN ('CDIM', 'STRX'))
                AND a.assessmnt_ctg = 'Usable'
                AND a.cnst_prsn_nm_end_dt = '9999-12-31'
        ) b ON a.cnst_mstr_id = b.cnst_mstr_id
    ) AS ranked_names
    WHERE ranked_names.row_num = 1
) AS nm_rnk 
ON nm_rnk.cnst_mstr_id = M.cnst_mstr_id


LEFT JOIN mktg_ops_tbls.bzf_cem_cnst_opt_outs_copy cnst_cntct_pref
    ON M.cnst_mstr_id = cnst_cntct_pref.cnst_mstr_id
    
 LEFT JOIN (
    SELECT *
    FROM (
        SELECT 
            clss.cnst_mstr_id,
            clss.org_typ_cd,
            clss.dw_srcsys_trans_ts,
            clss.arc_srcsys_cd,
            ROW_NUMBER() OVER (
                PARTITION BY clss.cnst_mstr_id
                ORDER BY 
                    CASE 
                        WHEN clss.arc_srcsys_cd = 'SFFS' AND clss.org_typ_cd <> 'U' THEN 1
                        WHEN clss.arc_srcsys_cd = 'GMFS' AND clss.org_typ_cd <> 'U' THEN 2
                        WHEN clss.arc_srcsys_cd = 'TAFS' AND clss.org_typ_cd <> 'U' THEN 2.1
                        WHEN clss.arc_srcsys_cd = 'SFFS' THEN 3
                        WHEN clss.arc_srcsys_cd = 'GMFS' THEN 4
                        WHEN clss.arc_srcsys_cd = 'TAFS' THEN 4.1
                        ELSE 5 
                    END,
                    clss.dw_srcsys_trans_ts DESC
            ) AS row_num
        FROM eda.arc_mdm_vws.bz_cnst_org_clssfctn clss
        INNER JOIN eda.arc_mdm_vws.bz_arc_srcsys src
            ON src.arc_srcsys_cd = clss.arc_srcsys_cd
        WHERE src.line_of_service_cd = 'FR'
    ) ranked_org
    WHERE row_num = 1
) org_typ ON M.cnst_mstr_id = org_typ.cnst_mstr_id

LEFT JOIN (
    SELECT *
    FROM (
        SELECT 
            cnst_mstr_id,
            frf_cntct_id,
            ROW_NUMBER() OVER (
                PARTITION BY cnst_mstr_id 
                ORDER BY active_ind DESC, frf_cntct_id DESC
            ) AS row_num
        FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
        WHERE appl_src_cd = 'SFFS' 
            AND cnst_typ_cd IN ('IN')
    ) ranked_cntct
    WHERE row_num = 1
) sf_cntct ON M.cnst_mstr_id = sf_cntct.cnst_mstr_id

LEFT JOIN (
    SELECT *
    FROM (
        SELECT 
            cnst_mstr_id,
            frf_acct_id,
            ROW_NUMBER() OVER (
                PARTITION BY cnst_mstr_id 
                ORDER BY frf_acct_id DESC
            ) AS row_num
        FROM eda.ufds_vws.bzl_cnst_mstr_fsa_acct
        WHERE appl_src_cd = 'SFFS'
            AND cnst_typ_cd IN ('OR', 'AG')
    ) ranked_acct
    WHERE row_num = 1
) sf_acct ON M.cnst_mstr_id = sf_acct.cnst_mstr_id
   
LEFT JOIN (
    SELECT *
    FROM (
        SELECT 
            cnst_mstr_id, 
            benevity_suprsn_ind,
            ROW_NUMBER() OVER (
                PARTITION BY cnst_mstr_id 
                ORDER BY cnst_mstr_id 
            ) AS row_num
        FROM mktg_ops_vws.gms_arc_fr_smry
    ) ranked_fr_smry
    WHERE row_num = 1
) fr_smry ON M.cnst_mstr_id = fr_smry.cnst_mstr_id ;



COMMIT;


insert into mktg_stage_tbls.bzf_cem_fr_cnst_loc_prefs_tmp 
select * from mktg_ops_vws.bzf_cem_fr_cnst_loc_prefs; 


COMMIT;


TRUNCATE TABLE  mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg ; 

insert into mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg  
(	
cnst_mstr_id, cnst_hsld_id, cnst_arc_deceased_cd, dm_prsn_nm_src_cd, dm_cnst_data_src_cd,
		dm_locator_prsn_nm_key, dm_cnst_prsn_nm_assessmnt_ctg, dm_cnst_prsn_prfx_nm,
		dm_cnst_prsn_f_nm, dm_cnst_prsn_m_nm, dm_cnst_prsn_l_nm, dm_cnst_prsn_sfx_nm,
		dm_cnst_prsn_full_nm, dm_cnst_alias_in_saltn_nm, dm_cnst_alias_out_saltn_nm,
		dm_locator_addr_key, dm_cnst_addr_assessmnt_ctg, dpv_cd, dm_cnst_line_1_addr,
		dm_cnst_line_2_addr, dm_cnst_city_nm, dm_cnst_st_cd, dm_cnst_zip_5_cd,
		dm_cnst_zip_4_cd, dm_cnst_addr_county_nm, 
		cem_all_mail_override_flg,
		cem_fr_mail_override_flg, 
		cem_all_mail_override_ind, 
		cem_fr_mail_override_ind,
		ncoa_mail_override_flg, ncoa_mail_override_ind, 
		dm_cnst_email, dm_cnst_org_nm, dm_cnst_typ_dsc, 
		em_prsn_nm_src_cd, em_cnst_data_src_cd,
		em_locator_prsn_nm_key, em_cnst_prsn_nm_assessmnt_ctg, em_cnst_prsn_prfx_nm,
		em_cnst_prsn_f_nm, em_cnst_prsn_m_nm, em_cnst_prsn_l_nm, em_cnst_prsn_sfx_nm,
		em_cnst_prsn_full_nm, em_cnst_alias_in_saltn_nm, em_cnst_alias_out_saltn_nm,
		em_locator_addr_key, em_cnst_line_1_addr, em_cnst_line_2_addr,
		em_cnst_city_nm, em_cnst_st_cd, em_cnst_zip_5_cd, em_cnst_zip_4_cd,
		em_cnst_addr_county_nm, em_cnst_email, em_email_key, em_cnst_email_assessmnt_ctg,
		em_cnst_org_nm, em_cnst_typ_dsc, email_dlvrbl_ind, prim_cnst_phn,
		prim_cnst_phn_source, prim_cnst_phn_typ_dsc, cnst_work_phn, cnst_work_phn_source,
		cnst_work_phn_typ_dsc, cnst_mbl_phn, cnst_mbl_phn_source, cnst_mbl_phn_typ_dsc,
		do_not_call_hm_phn_ind, do_not_call_mbl_phn_ind, do_not_call_work_phn_ind,
		do_not_email_ind, do_not_mail_ind, do_not_txt_ind, cnst_3rd_prty_segmtn_group_nm,
		unit_key, 
		affl_lock_ind, 
		sf_acct_fmd_ind, 
		frf_status_cd,
		portfolio_category, 
		rlshp_mgr_ownr_key, 
		rlshp_mgr_nm, 
		rlshp_mgr_prefd_email_addr,
		acct_in_salutn_nm, 
		acct_out_salutn_nm, 
		dm_pa_addr_check, 
		unit_key_src,
		mktg_unit_key,
		cnst_typ_cd, 
		org_typ_cd, 
		inactvn_unf_fr_cnst_key,
		inactvtn_reason_cd,  
		inactvtn_reason_dsc, 
		inactvtn_dt ,
		inactvtn_reason_txt,
		ag_bzd_sfid, 
		cntct_bzd_sfid,
		mult_sf_cnst_ind) 

SELECT
src.cnst_mstr_id, cnst_hsld_id, cnst_arc_deceased_cd, dm_prsn_nm_src_cd, dm_cnst_data_src_cd, dm_locator_prsn_nm_key, 
dm_cnst_prsn_nm_assessmnt_ctg, dm_cnst_prsn_prfx_nm, dm_cnst_prsn_f_nm, dm_cnst_prsn_m_nm, dm_cnst_prsn_l_nm,
dm_cnst_prsn_sfx_nm, dm_cnst_prsn_full_nm, dm_cnst_alias_in_saltn_nm,
dm_cnst_alias_out_saltn_nm, 

CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_locator_addr_key
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.fr_locator_addr_key
ELSE src.dm_locator_addr_key 
END AS dm_locator_addr_key,

CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_cnst_addr_assessmnt_ctg
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.fr_cnst_addr_assessmnt_ctg
ELSE src.dm_cnst_addr_assessmnt_ctg 
END AS dm_cnst_addr_assessmnt_ctg,

src.dpv_cd,

-- Address fields
CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_cnst_line_1_addr
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.fr_cnst_line_1_addr
ELSE src.dm_cnst_line_1_addr 
END AS dm_cnst_line_1_addr,

CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_cnst_line_2_addr
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.fr_cnst_line_2_addr
ELSE src.dm_cnst_line_2_addr 
END AS dm_cnst_line_2_addr,

CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_cnst_city_nm
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.fr_cnst_city_nm
ELSE src.dm_cnst_city_nm 
END AS dm_cnst_city_nm,

CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_cnst_st_cd
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.fr_cnst_st_cd
ELSE src.dm_cnst_st_cd 
END AS dm_cnst_st_cd,

CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_cnst_zip_5_cd
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.frl_cnst_zip_5_cd
ELSE src.dm_cnst_zip_5_cd 
END AS dm_cnst_zip_5_cd,

CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_cnst_zip_4_cd
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.fr_cnst_zip_4_cd
ELSE src.dm_cnst_zip_4_cd 
END AS dm_cnst_zip_4_cd,

CASE 
WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.all_cnst_addr_county_nm
WHEN pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN pref.fr_cnst_addr_county_nm
ELSE src.dm_cnst_addr_county_nm 
END AS dm_cnst_addr_county_nm,

-- Flags
CASE WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN 'Y' ELSE 'N' END AS cem_all_mail_override_flg,
CASE WHEN pref.all_locator_addr_key IS NULL AND pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN 'Y' ELSE 'N' END AS cem_fr_mail_override_flg,
CASE WHEN pref.all_locator_addr_key IS NOT NULL AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN 1 ELSE 0 END AS cem_all_mail_override_ind,
CASE WHEN pref.all_locator_addr_key IS NULL AND pref.fr_locator_addr_key IS NOT NULL AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable' THEN 1 ELSE 0 END AS cem_fr_mail_override_ind,

'N' AS ncoa_mail_override_flg,
0 AS ncoa_mail_override_ind,

-- Remaining fields
dm_cnst_email, dm_cnst_org_nm, dm_cnst_typ_dsc, 
em_prsn_nm_src_cd, em_cnst_data_src_cd, em_locator_prsn_nm_key, 
em_cnst_prsn_nm_assessmnt_ctg, em_cnst_prsn_prfx_nm, em_cnst_prsn_f_nm, em_cnst_prsn_m_nm, em_cnst_prsn_l_nm, em_cnst_prsn_sfx_nm,
em_cnst_prsn_full_nm, em_cnst_alias_in_saltn_nm, em_cnst_alias_out_saltn_nm,
em_locator_addr_key, em_cnst_line_1_addr, em_cnst_line_2_addr,
em_cnst_city_nm, em_cnst_st_cd, em_cnst_zip_5_cd, em_cnst_zip_4_cd,
em_cnst_addr_county_nm, em_cnst_email, em_email_key, em_cnst_email_assessmnt_ctg,
em_cnst_org_nm, em_cnst_typ_dsc, email_dlvrbl_ind, prim_cnst_phn,
prim_cnst_phn_source, prim_cnst_phn_typ_dsc, cnst_work_phn, cnst_work_phn_source,
cnst_work_phn_typ_dsc, cnst_mbl_phn, cnst_mbl_phn_source, cnst_mbl_phn_typ_dsc,
do_not_call_hm_phn_ind, do_not_call_mbl_phn_ind, do_not_call_work_phn_ind,
do_not_email_ind, do_not_mail_ind, do_not_txt_ind, cnst_3rd_prty_segmtn_group_nm,
unit_key, affl_lock_ind, sf_acct_fmd_ind, frf_status_cd, portfolio_category, 
rlshp_mgr_ownr_key, rlshp_mgr_nm, rlshp_mgr_prefd_email_addr,
salutn.acct_in_salutn_nm, salutn.acct_out_salutn_nm,
'DM Address' AS dm_pa_addr_check,
'PA Unit Key' AS unit_key_src,
NULL::INTEGER AS mktg_unit_key,
src.cnst_typ_cd, org_typ_cd,
inactive_attrb.inactvn_unf_fr_cnst_key, inactive_attrb.inactvtn_reason_cd, 
inactive_attrb.inactvtn_reason_dsc, inactive_attrb.inactvtn_dt, inactive_attrb.inactvtn_reason_txt, 
ag_bzd_sfid, cntct_bzd_sfid, COALESCE(mult_sf_cnst_ind, 0) AS mult_sf_cnst_ind
FROM mktg_stage_tbls.stg_gms_cnst_cdi_smry_fr_prfr_src src
LEFT JOIN mktg_stage_tbls.bzf_cem_fr_cnst_loc_prefs_tmp pref 
ON src.cnst_mstr_id = pref.cnst_mstr_id 
LEFT JOIN (
SELECT lnk.cnst_mstr_id, fsa.frf_acct_id, fsa.salutn AS acct_in_salutn_nm, fsa.addressee AS acct_out_salutn_nm, fsa.cnst_typ_cd
FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst fsa
INNER JOIN eda.ufds_vws.bzl_cnst_mstr_fsa_acct lnk ON fsa.unf_fr_cnst_key = lnk.cnst_key
WHERE fsa.appl_src_cd = 'SFFS' AND lnk.cnst_typ_cd IN ('AG', 'OR') AND (fsa.salutn IS NOT NULL OR fsa.addressee IS NOT NULL) AND lnk.cnst_mstr_id IS NOT NULL
) salutn ON salutn.cnst_mstr_id = src.cnst_mstr_id
LEFT JOIN (
    SELECT *
    FROM (
        SELECT 
            cnst_mstr_id, 
            unf_fr_cnst_key AS inactvn_unf_fr_cnst_key, 
            active_ind, 
            frf_active_ind, 
            inactvtn_reason_cd, 
            inactvtn_reason_dsc, 
            inactvtn_dt, 
            inactvtn_reason_txt,
            ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY active_ind DESC, unf_fr_cnst_key DESC) AS rn
        FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
        WHERE inactvtn_dt IS NOT NULL
    ) sub
    WHERE rn = 1
) inactive_attrb ON inactive_attrb.cnst_mstr_id = src.cnst_mstr_id ;  --- 3m20s -- 40938630





TRUNCATE TABLE  mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm ; 

COMMIT;
 
INSERT INTO mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm 
    (cnst_mstr_id, 
     pa_unit_key, 
     dm_cnst_line_1_addr, 
     dm_cnst_line_2_addr,
     dm_cnst_city_nm, 
     dm_cnst_st_cd, 
     dm_cnst_zip_5_cd,
     dm_cnst_zip_4_cd, 
     dm_cnst_addr_county_nm,
     affl_lock_ind, 
     cnst_line_1_addr, 
     cnst_line_2_addr, 
     cnst_city_nm,
     cnst_st_cd, 
     cnst_zip_5_cd, 
     cnst_zip_4_cd, 
     cnst_addr_county_nm,
     pa_locator_addr_key, 
     dm_locator_addr_key, 
     pa_addr_assessmnt_ctg,
     dm_addr_assessmnt_ctg, 
     dm_unit_key)
SELECT
     cnst_mstr_id, 
     pa_unit_key, 
     dm_cnst_line_1_addr, 
     dm_cnst_line_2_addr,
     dm_cnst_city_nm, 
     dm_cnst_st_cd, 
     dm_cnst_zip_5_cd,
     dm_cnst_zip_4_cd, 
     dm_cnst_addr_county_nm,
     affl_lock_ind, 
     cnst_line_1_addr, 
     cnst_line_2_addr, 
     cnst_city_nm,
     cnst_st_cd, 
     cnst_zip_5_cd, 
     cnst_zip_4_cd, 
     cnst_addr_county_nm,
     pa_locator_addr_key, 
     dm_locator_addr_key, 
     pa_addr_assessmnt_ctg,
     dm_addr_assessmnt_ctg, 
     dm_unit_key
FROM  mktg_ops_vws.gms_cnst_cdi_smry_fr_pa_dm;
 

COMMIT;

UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
SET 
    unit_key_src = 'DM Unit key',
    unit_key = src.dm_unit_key
FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm AS src
WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
  AND COALESCE(src.dm_unit_key, 0) <> COALESCE(src.pa_unit_key, 0)
  AND COALESCE(src.pa_addr_assessmnt_ctg, '') <> 'Deliverable'
  AND COALESCE(src.affl_lock_ind, 0) <> 1;  


COMMIT;

UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
SET 
    unit_key_src = 'DM Unit key',
    unit_key = src.dm_unit_key
FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm AS src
WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
  AND COALESCE(tgt.unit_key, 0) = 0
  AND COALESCE(src.dm_addr_assessmnt_ctg, '') = 'Deliverable'; 
  
COMMIT;

UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
SET 
    unit_key_src = 'Stuart Unit key',
    unit_key = src.unit_key
FROM mktg_ops_vws.cnst_sturt_lst_affl AS src
WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
  AND COALESCE(tgt.unit_key, 0) = 0; ---13433 --54s


COMMIT;

UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
SET 
    unit_key_src = 'Grp Mbrshp Unit key',
    unit_key = src.unit_key
FROM (
    SELECT DISTINCT cnst_mstr_id, unit_key
    FROM (
        SELECT 
            a.cnst_mstr_id,
            a.unit_key,
            ROW_NUMBER() OVER (PARTITION BY a.cnst_mstr_id ORDER BY a.srcsys_trans_ts DESC) AS rn
        FROM mktg_ops_vws.bz_grp_mbrshp a
        LEFT JOIN eda.arc_cmm_vws.grp_ref b 
            ON a.grp_key = b.grp_key
        WHERE grp_typ <> 'Vol NHQ LOB'
          AND COALESCE(unit_key, 0) > 0
    ) sub
    WHERE rn = 1
) AS src
WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
  AND COALESCE(tgt.unit_key, 0) = 0; --- 232218, 54s


COMMIT;

UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
SET cnst_arc_deceased_cd = 'D'
FROM eda.arc_mdm_vws.bz_cnst_mstr AS mstr
WHERE tgt.cnst_mstr_id = mstr.cnst_mstr_id
  AND mstr.cnst_arc_death_dt IS NOT NULL; 
  
  
COMMIT;


UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
SET
    dm_locator_addr_key = src.new_locator_addr_key,
    dm_cnst_addr_assessmnt_ctg = src.assessmnt_ctg,
    dm_cnst_line_1_addr = src.cnst_addr_new_addr1,
    dm_cnst_line_2_addr = src.cnst_addr_new_addr2,
    dm_cnst_city_nm = src.cnst_addr_new_city_nm,
    dm_cnst_st_cd = src.cnst_addr_new_state_cd,
    dm_cnst_zip_5_cd = src.cnst_addr_new_zip_5_cd,
    dm_cnst_zip_4_cd = src.cnst_addr_new_zip_4_cd,
    dm_cnst_addr_county_nm = src.bz_cnst_addr_county_nm,
    ncoa_mail_override_flg = 'Y',
    ncoa_mail_override_ind = 1
FROM mktg_ops_vws.cnst_addr_ncoa_log AS src
WHERE tgt.cnst_mstr_id = src.new_cnst_mstr_id
  AND tgt.dm_cnst_line_1_addr = src.cnst_addr_old_addr1
  AND tgt.dm_cnst_city_nm = src.cnst_addr_old_city_nm
  AND tgt.dm_cnst_st_cd = src.cnst_addr_old_state_cd
  AND (
        src.old_locator_addr_key IS NULL AND src.cnst_addr_new_addr1 IS NOT NULL
        OR src.old_locator_addr_key <> src.new_locator_addr_key
      );
 
COMMIT;
 
TRUNCATE TABLE  mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr ; 
 
COMMIT;

insert into mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr
 (cnst_mstr_id, cnst_hsld_id, cnst_arc_deceased_cd, dm_prsn_nm_src_cd, dm_cnst_data_src_cd,
		dm_locator_prsn_nm_key, dm_cnst_prsn_nm_assessmnt_ctg, dm_cnst_prsn_prfx_nm,
		dm_cnst_prsn_f_nm, dm_cnst_prsn_m_nm, dm_cnst_prsn_l_nm, dm_cnst_prsn_sfx_nm,
		dm_cnst_prsn_full_nm, dm_cnst_alias_in_saltn_nm, dm_cnst_alias_out_saltn_nm,
		dm_pa_addr_check, dm_locator_addr_key, dm_cnst_addr_assessmnt_ctg,
		dpv_cd, dm_cnst_line_1_addr, dm_cnst_line_2_addr, dm_cnst_city_nm,
		dm_cnst_st_cd, dm_cnst_zip_5_cd, dm_cnst_zip_4_cd, dm_cnst_addr_county_nm,
		cem_all_mail_override_flg, cem_fr_mail_override_flg, cem_all_mail_override_ind, cem_fr_mail_override_ind, ncoa_mail_override_flg, ncoa_mail_override_ind,
		dm_cnst_email, dm_cnst_org_nm, dm_cnst_typ_dsc, dm_cnst_prsn_prfx_nm2,
		dm_cnst_prsn_f_nm2, dm_cnst_prsn_m_nm2, dm_cnst_prsn_l_nm2, dm_cnst_prsn_sfx_nm2,
		dm_cnst_prsn_full_nm2, 
		em_prsn_nm_src_cd, em_cnst_data_src_cd, em_locator_prsn_nm_key,
		em_cnst_prsn_nm_assessmnt_ctg, em_cnst_prsn_prfx_nm, em_cnst_prsn_f_nm,
		em_cnst_prsn_m_nm, em_cnst_prsn_l_nm, em_cnst_prsn_sfx_nm, em_cnst_prsn_full_nm,
		em_cnst_alias_in_saltn_nm, em_cnst_alias_out_saltn_nm, em_locator_addr_key,
		em_cnst_line_1_addr, em_cnst_line_2_addr, em_cnst_city_nm, em_cnst_st_cd,
		em_cnst_zip_5_cd, em_cnst_zip_4_cd, em_cnst_addr_county_nm, em_cnst_email,
		em_email_key, em_cnst_email_assessmnt_ctg, em_cnst_org_nm, em_cnst_typ_dsc,
		em_cnst_prsn_prfx_nm2, em_cnst_prsn_f_nm2, em_cnst_prsn_m_nm2,
		em_cnst_prsn_l_nm2, em_cnst_prsn_sfx_nm2, em_cnst_prsn_full_nm2,
		email_dlvrbl_ind, prim_cnst_phn, prim_cnst_phn_source, prim_cnst_phn_typ_dsc,
		cnst_work_phn, cnst_work_phn_source, cnst_work_phn_typ_dsc, cnst_mbl_phn,
		cnst_mbl_phn_source, cnst_mbl_phn_typ_dsc, do_not_call_hm_phn_ind,
		do_not_call_mbl_phn_ind, do_not_call_work_phn_ind, do_not_email_ind,
		do_not_mail_ind, do_not_txt_ind, cnst_3rd_prty_segmtn_group_nm,
		unit_key_src, unit_key, affl_lock_ind, sf_acct_fmd_ind, frf_status_cd,
		portfolio_category, rlshp_mgr_ownr_key, rlshp_mgr_nm, rlshp_mgr_prefd_email_addr,
		acct_in_salutn_nm, acct_out_salutn_nm, 
		mktg_unit_key, cnst_typ_cd, org_typ_cd, has_smry_profile_ind,
		inactvn_unf_fr_cnst_key, inactvtn_reason_cd, inactvtn_reason_dsc, inactvtn_dt, inactvtn_reason_txt, ag_bzd_sfid, cntct_bzd_sfid, mult_sf_cnst_ind, active_cnst_ind, active_email_cnst_ind,
		last_email_open_dt, last_email_intrctn_dt, last_dmail_intrctn_dt)
select  
a.cnst_mstr_id as cnst_mstr_id, 
a.cnst_hsld_id as cnst_hsld_id , 
a.cnst_arc_deceased_cd as cnst_arc_deceased_cd, 
a.dm_prsn_nm_src_cd as dm_prsn_nm_src_cd, 
a.dm_cnst_data_src_cd as dm_cnst_data_src_cd,
a.dm_locator_prsn_nm_key as dm_locator_prsn_nm_key , 
a.dm_cnst_prsn_nm_assessmnt_ctg as dm_cnst_prsn_nm_assessmnt_ctg,
a.dm_cnst_prsn_prfx_nm as dm_cnst_prsn_prfx_nm , 
a.dm_cnst_prsn_f_nm as dm_cnst_prsn_f_nm, 
a.dm_cnst_prsn_m_nm as dm_cnst_prsn_m_nm, 
CAST(
    CASE 
        WHEN a.dm_cnst_typ_dsc = 'Organization' AND a.dm_cnst_prsn_l_nm IS NULL 
        THEN a.dm_cnst_org_nm 
        ELSE a.dm_cnst_prsn_l_nm 
    END AS VARCHAR(50)
) AS dm_cnst_prsn_l_nm ,
a.dm_cnst_prsn_sfx_nm as dm_cnst_prsn_sfx_nm ,
a.dm_cnst_prsn_full_nm as dm_cnst_prsn_full_nm, 
a.dm_cnst_alias_in_saltn_nm as dm_cnst_alias_in_saltn_nm,
a.dm_cnst_alias_out_saltn_nm as dm_cnst_alias_out_saltn_nm, 
a.dm_pa_addr_check, 
a.dm_locator_addr_key as dm_locator_addr_key,
a.dm_cnst_addr_assessmnt_ctg as dm_cnst_addr_assessmnt_ctg,
a.dpv_cd as dpv_cd,
a.dm_cnst_line_1_addr as dm_cnst_line_1_addr, 
a.dm_cnst_line_2_addr as dm_cnst_line_2_addr,
a.dm_cnst_city_nm as dm_cnst_city_nm, 
a.dm_cnst_st_cd as dm_cnst_st_cd, 
a.dm_cnst_zip_5_cd as dm_cnst_zip_5_cd, 
a.dm_cnst_zip_4_cd as dm_cnst_zip_4_cd,
a.dm_cnst_addr_county_nm as dm_cnst_addr_county_nm,
a.cem_all_mail_override_flg, 
a.cem_fr_mail_override_flg, 
a.cem_all_mail_override_ind, 
a.cem_fr_mail_override_ind, 
a.ncoa_mail_override_flg, 
a.ncoa_mail_override_ind,
a.dm_cnst_email as dm_cnst_email, 
a.dm_cnst_org_nm as dm_cnst_org_nm, 
a.dm_cnst_typ_dsc as dm_cnst_typ_dsc, 
c.dm_cnst_prsn_prfx_nm AS dm_cnst_prsn_prfx_nm2,
c.dm_cnst_prsn_f_nm AS dm_cnst_prsn_f_nm2,
c.dm_cnst_prsn_m_nm AS dm_cnst_prsn_m_nm2,
c.dm_cnst_prsn_l_nm AS dm_cnst_prsn_l_nm2,
c.dm_cnst_prsn_sfx_nm AS dm_cnst_prsn_sfx_nm2,
c.dm_cnst_prsn_full_nm AS dm_cnst_prsn_full_nm2,
a.em_prsn_nm_src_cd, 
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_data_src_cd 
    ELSE a.em_cnst_data_src_cd 
END AS em_cnst_data_src_cd ,  
a.em_locator_prsn_nm_key as em_locator_prsn_nm_key , 
a.em_cnst_prsn_nm_assessmnt_ctg as em_cnst_prsn_nm_assessmnt_ctg,
a.em_cnst_prsn_prfx_nm as em_cnst_prsn_prfx_nm, 
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_prsn_f_nm 
    ELSE a.em_cnst_prsn_f_nm 
END AS em_cnst_prsn_f_nm,
a.em_cnst_prsn_m_nm AS em_cnst_prsn_m_nm,
CAST(
    CASE 
        WHEN (a.dm_cnst_typ_dsc = 'Organization' AND a.em_cnst_prsn_l_nm IS NULL) THEN a.em_cnst_org_nm
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_prsn_l_nm
        ELSE a.em_cnst_prsn_l_nm 
    END AS VARCHAR(50)
) AS em_cnst_prsn_l_nm,
a.em_cnst_prsn_sfx_nm AS em_cnst_prsn_sfx_nm,
a.em_cnst_prsn_full_nm AS em_cnst_prsn_full_nm,
a.em_cnst_alias_in_saltn_nm AS em_cnst_alias_in_saltn_nm,
a.em_cnst_alias_out_saltn_nm AS em_cnst_alias_out_saltn_nm,
a.em_locator_addr_key,  
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_line_1_addr 
    ELSE a.em_cnst_line_1_addr 
END AS em_cnst_line_1_addr,
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_line_2_addr 
    ELSE a.em_cnst_line_2_addr 
END AS em_cnst_line_2_addr,
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_city_nm 
    ELSE a.em_cnst_city_nm 
END AS em_cnst_city_nm,
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_st_cd 
    ELSE a.em_cnst_st_cd 
END AS em_cnst_st_cd,
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_zip_5_cd 
    ELSE a.em_cnst_zip_5_cd 
END AS em_cnst_zip_5_cd,
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN NULL 
    ELSE a.em_cnst_zip_4_cd 
END AS em_cnst_zip_4_cd,
a.em_cnst_addr_county_nm AS em_cnst_addr_county_nm,
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_email 
    ELSE a.em_cnst_email 
END AS em_cnst_email, 
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN COALESCE(faem.em_email_key, 0)
    ELSE COALESCE(a.em_email_key, 0)
END AS em_email_key,  
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_email_assessmnt_ctg 
    ELSE a.em_cnst_email_assessmnt_ctg 
END AS em_cnst_email_assessmnt_ctg,  
a.em_cnst_org_nm AS em_cnst_org_nm,
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN 'IN' 
    ELSE a.em_cnst_typ_dsc 
END AS em_cnst_typ_dsc,
c.em_cnst_prsn_prfx_nm AS em_cnst_prsn_prfx_nm2,  
c.em_cnst_prsn_f_nm AS em_cnst_prsn_f_nm2,
c.em_cnst_prsn_m_nm AS em_cnst_prsn_m_nm2,
c.em_cnst_prsn_l_nm AS em_cnst_prsn_l_nm2,
c.em_cnst_prsn_sfx_nm AS em_cnst_prsn_sfx_nm2,
c.em_cnst_prsn_full_nm AS em_cnst_prsn_full_nm2,
a.email_dlvrbl_ind as email_dlvrbl_ind, 
a.prim_cnst_phn as prim_cnst_phn,
a.prim_cnst_phn_source as prim_cnst_phn_source,
a.prim_cnst_phn_typ_dsc as prim_cnst_phn_typ_dsc,
a.cnst_work_phn as cnst_work_phn, 
a.cnst_work_phn_source as cnst_work_phn_source, 
a.cnst_work_phn_typ_dsc as cnst_work_phn_typ_dsc, 
a.cnst_mbl_phn as cnst_mbl_phn, 
a.cnst_mbl_phn_source as cnst_mbl_phn_source, 
a.cnst_mbl_phn_typ_dsc as cnst_mbl_phn_typ_dsc,
a.do_not_call_hm_phn_ind as do_not_call_hm_phn_ind, 
a.do_not_call_mbl_phn_ind as do_not_call_mbl_phn_ind, 
a.do_not_call_work_phn_ind as do_not_call_work_phn_ind,
a.do_not_email_ind as do_not_email_ind, 
a.do_not_mail_ind as do_not_mail_ind, 
a.do_not_txt_ind as do_not_txt_ind, 
a.cnst_3rd_prty_segmtn_group_nm as cnst_3rd_prty_segmtn_group_nm,
a.unit_key_src as unit_key_src, 
a.unit_key as unit_key, 
COALESCE(a.affl_lock_ind, 0) AS affl_lock_ind,
a.sf_acct_fmd_ind as sf_acct_fmd_ind, 
a.frf_status_cd,
a.portfolio_category,
a.rlshp_mgr_ownr_key,
a.rlshp_mgr_nm AS rlshp_mgr_nm,  
a.rlshp_mgr_prefd_email_addr AS bzd_prefd_email_addr,
a.acct_in_salutn_nm AS acct_in_salutn_nm,
a.acct_out_salutn_nm AS acct_out_salutn_nm,
e.unit_key AS mktg_unit_key,
a.cnst_typ_cd,
a.org_typ_cd,
CASE 
    WHEN f.cnst_mstr_id IS NULL THEN 0 
    ELSE 1 
END AS has_smry_profile_ind,  
a.inactvn_unf_fr_cnst_key,
a.inactvtn_reason_cd,
a.inactvtn_reason_dsc,
a.inactvtn_dt,
a.inactvtn_reason_txt,
a.ag_bzd_sfid,
a.cntct_bzd_sfid,
a.mult_sf_cnst_ind,
CASE 
    WHEN active.cnst_mstr_id IS NOT NULL THEN 1 
    ELSE 0 
END AS active_cnst_ind,
CASE 
    WHEN (
        a.em_cnst_email_assessmnt_ctg IN ('Validated', 'Use With Caution')
        AND a.do_not_email_ind = 0
        AND (actem.ok_to_email_flg = 'Y' OR actem.ok_to_email_flg IS NULL)
        AND (
            active.fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE)
            OR actem.last_email_open_dt >= DATEADD(month, -24, CURRENT_DATE)
            OR actem.last_email_link_click_dt >= DATEADD(month, -24, CURRENT_DATE)
        )
    )
    OR (
        active_cnst_ind = 1
        AND faem.cnst_mstr_id IS NOT NULL
        AND a.do_not_email_ind = 0
        AND (actem.ok_to_email_flg = 'Y' OR actem.ok_to_email_flg IS NULL)
    )
    THEN 1 ELSE 0 
END AS active_email_cnst_ind,
actem.last_email_open_dt,
emi.last_email_intrctn_dt,
dmin.last_dmail_intrctn_dt

FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg a
LEFT JOIN mktg_ops_tbls.bzf_cnst_cdi_sltn_id b 
    ON a.cnst_mstr_id = b.pn_cnst_mstr_id  
LEFT JOIN mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg c 
    ON c.cnst_mstr_id = b.sn_cnst_mstr_id 
LEFT JOIN mktg_ops_vws.geo_zip_code_to_chapter d 
    ON d.zip = a.dm_cnst_zip_5_cd
LEFT JOIN mktg_ops_vws.dim_unit e 
    ON d.ECODE = e.nk_ecode
LEFT JOIN mktg_ops_vws.gms_arc_fr_smry f 
    ON a.cnst_mstr_id = f.cnst_mstr_id
LEFT JOIN (
    SELECT *
    FROM (
        SELECT 
            cnst_mstr_id, 
            cnst_prsn_f_nm, 
            cnst_prsn_l_nm, 
            cnst_line_1_addr, 
            cnst_line_2_addr, 
            cnst_city_nm, 
            cnst_st_cd, 
            cnst_zip_5_cd, 
            cnst_email, 
            list_source_nm, 
            em_cnst_data_src_cd, 
            em_email_key, 
            em_cnst_email_assessmnt_ctg, 
            ok_to_email_flg, 
            list_upload_ts,
            ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY list_upload_ts DESC) AS rn
        FROM (
            SELECT 
                a.cnst_mstr_id, 
                a.cnst_prsn_f_nm, 
                a.cnst_prsn_l_nm, 
                a.cnst_line_1_addr, 
                a.cnst_line_2_addr, 
                a.cnst_city_nm, 
                a.cnst_st_cd, 
                a.cnst_zip_5_cd, 
                a.cnst_email, 
                a.list_source_nm, 
                'PEEM' AS em_cnst_data_src_cd,
                b.email_key AS em_email_key,
                COALESCE(c.assessmnt_ctg, 'Validated') AS em_cnst_email_assessmnt_ctg,
                d.ok_to_email_flg,
                a.list_upload_ts
            FROM mktg_ops_tbls.pacific_east_email_append a
            LEFT JOIN eda.arc_mdm_vws.bz_locator_email b ON b.cnst_email_addr = a.cnst_email
            LEFT JOIN eda.arc_mdm_vws.bz_assessmnt c ON b.assessmnt_key = c.assessmnt_key
            LEFT JOIN mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile d ON a.cnst_email = d.email_addr
            WHERE a.row_stat_cd <> 'L'
            
            UNION ALL
            
            SELECT 
                a.cnst_mstr_id, 
                a.cnst_prsn_f_nm, 
                a.cnst_prsn_l_nm, 
                a.cnst_line_1_addr, 
                a.cnst_line_2_addr, 
                a.cnst_city_nm, 
                a.cnst_st_cd, 
                a.cnst_zip_5_cd, 
                a.cnst_email, 
                a.list_nm AS list_source_nm, 
                'FAEM' AS em_cnst_data_src_cd,
                b.email_key AS em_email_key,
                COALESCE(c.assessmnt_ctg, 'Validated') AS em_cnst_email_assessmnt_ctg,
                d.ok_to_email_flg,
                a.list_upload_ts
            FROM mktg_ops_tbls.fresh_address_email_append a
            LEFT JOIN eda.arc_mdm_vws.bz_locator_email b ON b.cnst_email_addr = a.cnst_email
            LEFT JOIN eda.arc_mdm_vws.bz_assessmnt c ON b.assessmnt_key = c.assessmnt_key
            LEFT JOIN mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile d ON a.cnst_email = d.email_addr
            WHERE a.row_stat_cd <> 'L'
        ) combined
    ) ranked
    WHERE rn = 1
) faem (cnst_mstr_id, em_cnst_prsn_f_nm, em_cnst_prsn_l_nm, em_cnst_line_1_addr, em_cnst_line_2_addr, em_cnst_city_nm, em_cnst_st_cd, em_cnst_zip_5_cd, em_cnst_email, em_list_source_nm, em_cnst_data_src_cd, em_email_key, em_cnst_email_assessmnt_ctg, ok_to_email_flg, list_upload_ts)
ON a.cnst_mstr_id = faem.cnst_mstr_id

LEFT JOIN (
    SELECT 
        cnst_mstr_id, 
        fr_last_dntn_dt
    FROM mktg_ops_vws.gms_arc_fr_smry
    WHERE fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE)
) AS active ON a.cnst_mstr_id = active.cnst_mstr_id


LEFT JOIN (
    SELECT 
        cnst_mstr_id, 
        ok_to_email_flg, 
        MAX(last_em_open_dt) AS last_email_open_dt, 
        MAX(last_em_link_click_dt) AS last_email_link_click_dt
    FROM mktg_ops_vws.gms_bzfc_cnst_cdi_fr_prfr_em_prfl
    WHERE last_em_open_dt IS NOT NULL OR last_em_link_click_dt IS NOT NULL
    GROUP BY cnst_mstr_id, ok_to_email_flg
) AS actem ON a.cnst_mstr_id = actem.cnst_mstr_id

LEFT JOIN (
    SELECT 
        cnst_mstr_id, 
        MAX(intrctn_dt) AS last_email_intrctn_dt
    FROM mktg_ops_vws.bzfc_fact_email_interaction
    WHERE intrctn_status_key = 1
    GROUP BY cnst_mstr_id
) AS emi ON a.cnst_mstr_id = emi.cnst_mstr_id

LEFT JOIN (
    SELECT 
        cnst_mstr_id, 
        MAX(intrctn_dt) AS last_dmail_intrctn_dt
    FROM mktg_ops_vws.bzfc_fact_dmail_intrctn_norm
    GROUP BY cnst_mstr_id
) AS dmin ON a.cnst_mstr_id = dmin.cnst_mstr_id ; --2m57s -- 40938630
    

COMMIT;


UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr AS tgt
SET 
    em_prsn_nm_src_cd = 'STRX',
    em_cnst_alias_in_saltn_nm = src.bz_cnst_alias_in_saltn_nm,
    em_cnst_alias_out_saltn_nm = src.bz_cnst_alias_out_saltn_nm,
    dm_prsn_nm_src_cd = 'STRX',
    dm_cnst_alias_in_saltn_nm = src.bz_cnst_alias_in_saltn_nm,
    dm_cnst_alias_out_saltn_nm = src.bz_cnst_alias_out_saltn_nm
FROM (
    SELECT 
        cnst_mstr_id, 
        bz_cnst_alias_out_saltn_nm, 
        bz_cnst_alias_in_saltn_nm
    FROM (
        SELECT 
            cnst_mstr_id, 
            bz_cnst_alias_out_saltn_nm, 
            bz_cnst_alias_in_saltn_nm,
            ROW_NUMBER() OVER (
                PARTITION BY cnst_mstr_id 
                ORDER BY 
                    CASE 
                        WHEN cnst_prsn_nm_typ_cd = 'ARC' THEN 1
                        WHEN cnst_prsn_nm_typ_cd = 'PN' THEN 2
                        WHEN cnst_prsn_nm_typ_cd = 'LN' THEN 3
                        ELSE 4
                    END
            ) AS rn
        FROM eda.arc_mdm_vws.bz_cnst_prsn_nm
        WHERE arc_srcsys_cd = 'STRX'
          AND TRIM(bz_cnst_alias_out_saltn_nm) <> TRIM(cnst_prsn_full_nm)
    ) sub
    WHERE rn = 1
) AS src
WHERE tgt.cnst_mstr_id = src.cnst_mstr_id;
    
COMMIT;

TRUNCATE TABLE mktg_stage_tbls.stg_gms_cnst_cdi_smry_fr_prfr_src;
TRUNCATE TABLE mktg_stage_tbls.bzf_cem_fr_cnst_loc_prefs_tmp;
TRUNCATE TABLE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg;



--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr) as nvarchar)+ ' Records inserted.';
        UPDATE mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_gms_cnst_cdi_smry_fr_prfr' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_gms_cnst_cdi_smry_fr_prfr', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;





$$
