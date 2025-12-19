CREATE OR REPLACE VIEW mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr_src AS
WITH fr_cnst AS (
    SELECT DISTINCT a.cnst_mstr_id
    FROM (
        SELECT brid.cnst_mstr_id 
        FROM eda.arc_mdm_vws.bz_cnst_mstr_bridge brid 
        LEFT JOIN (
            SELECT cnst_mstr_id, arc_srcsys_cd
            FROM mktg_ops_vws.bz_grp_mbrshp a 
            LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
            WHERE grp_typ NOT IN ('Vol NHQ LOB', 'Bio NHQ LOB', 'PHSS NHQ LOB') 
        ) fr_list ON brid.cnst_mstr_id = fr_list.cnst_mstr_id AND brid.cnst_mstr_subj_area_cd = fr_list.arc_srcsys_cd
        WHERE (
            cnst_mstr_subj_area_cd IN ('RCO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'MDON')
            OR (cnst_mstr_subj_area_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='FR'))
            OR (brid.cnst_mstr_id = fr_list.cnst_mstr_id AND brid.cnst_mstr_subj_area_cd = fr_list.arc_srcsys_cd) 
            OR (brid.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM mktg_ops_vws.atg_order_registrants WHERE atg_gift_cnt > 0) AND brid.cnst_mstr_subj_area_cd = 'ATGO')
            OR (brid.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM mktg_ops_vws.atg_registrants WHERE atg_gift_cnt > 0) AND brid.cnst_mstr_subj_area_cd = 'ATG')
        )
        
        UNION ALL
        
        SELECT email.cnst_mstr_id
        FROM eda.arc_mdm_vws.bz_cnst_email email
        LEFT JOIN (
            SELECT cnst_mstr_id, arc_srcsys_cd
            FROM mktg_ops_vws.bz_grp_mbrshp a 
            LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
            WHERE grp_typ NOT IN ('Vol NHQ LOB', 'Bio NHQ LOB', 'PHSS NHQ LOB') 
        ) fr_list ON email.cnst_mstr_id = fr_list.cnst_mstr_id AND email.arc_srcsys_cd = fr_list.arc_srcsys_cd
        WHERE (
            email.arc_srcsys_cd IN ('RCO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'MDON')
            OR (email.arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='FR'))
            OR (email.cnst_mstr_id = fr_list.cnst_mstr_id AND email.arc_srcsys_cd = fr_list.arc_srcsys_cd) 
            OR (email.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM mktg_ops_vws.atg_order_registrants WHERE atg_gift_cnt > 0) AND email.arc_srcsys_cd = 'ATGO')
            OR (email.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM mktg_ops_vws.atg_registrants WHERE atg_gift_cnt > 0) AND email.arc_srcsys_cd = 'ATG')
        )
    ) a
),

mngd_dnr_ranked AS (
    SELECT 
        cmfa.frf_acct_id,
        cmfa.cnst_mstr_id,
        cnst.unf_fr_cnst_key,
        cnst.frf_cur_mngd_dnr_ind,
        ownr.nm_line AS rlshp_mgr_nm,
        ownr.prefd_email_addr AS rlshp_mgr_prefd_email_addr,
        cnst.acct_ownr_key AS rlshp_mgr_ownr_key,
        cnst.frf_status_cd,
        cnst.frf_cur_portfolio_ctg,
        CASE WHEN frf_cnt.acct_cnt > 1 THEN 1 ELSE 0 END AS mult_sf_cnst_ind,
        ROW_NUMBER() OVER (
            PARTITION BY cmfa.cnst_mstr_id 
            ORDER BY 
                CASE WHEN cmfa.appl_src_cd = 'SFFS' THEN 1
                    WHEN cmfa.appl_src_cd = 'GMFS' THEN 2
                    ELSE 3 END,
                CASE WHEN cmfa.cnst_typ_cd IN ('AG','OR') THEN 1
                    ELSE 2 END,
                cnst.frf_cur_mngd_dnr_ind DESC,
                cnst.active_ind DESC,
                cnst.frf_active_ind DESC,
                cnst.frf_acct_key DESC,
                cmfa.cnst_key DESC
        ) AS rn
    FROM eda.ufds_vws.bzl_cnst_mstr_fsa_acct cmfa
    LEFT JOIN eda.ufds_vws.bzfc_dim_unf_fr_cnst cnst ON cmfa.cnst_key = cnst.unf_fr_cnst_key
    LEFT JOIN eda.ufds_vws.bzfc_dim_unf_fr_owner ownr ON cnst.acct_ownr_key = ownr.unf_fr_cnst_key
    LEFT JOIN (
        SELECT
            cnst_mstr_id,
            COUNT(DISTINCT frf_acct_id) AS acct_cnt
        FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
        WHERE cnst_mstr_id > 0
            AND COALESCE(TRIM(frf_acct_id), '') <> ''
        GROUP BY 1
    ) frf_cnt ON cmfa.cnst_mstr_id = frf_cnt.cnst_mstr_id
    WHERE cmfa.cnst_mstr_id > 0
        AND COALESCE(TRIM(cmfa.frf_acct_id), '') <> ''
),

hphone_ranked AS (
    SELECT
        bz_cnst_phn.cnst_mstr_id,
        bz_cnst_phn.cnst_phn_num AS prim_cnst_phn,
        bz_cnst_phn.arc_srcsys_cd AS prim_cnst_phn_source,
        CAST(CASE WHEN bz_cnst_phn.phn_typ_cd='H' THEN 'Home' ELSE 'Other' END AS VARCHAR(20)) AS prim_cnst_phn_typ_dsc,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='SFFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 1
            WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='GMFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2
            WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='TAFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2.1
            WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 3
            WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='RCO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.1
            WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='ATG' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.2
            WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='CNVO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 5
            WHEN bz_cnst_phn.arc_srcsys_cd='CDIM' AND bz_cnst_phn.phn_typ_cd='LN' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 6
            ELSE 999
        END AS hnum,
        ROW_NUMBER() OVER (
            PARTITION BY cnst_mstr_id 
            ORDER BY 
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='SFFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 1
                    WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='GMFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='TAFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2.1
                    WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='RCO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.1
                    WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='ATG' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.2
                    WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='CNVO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 5
                    WHEN bz_cnst_phn.arc_srcsys_cd='CDIM' AND bz_cnst_phn.phn_typ_cd='LN' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 6
                    ELSE 999
                END ASC,
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum
    FROM eda.arc_mdm_vws.bzfc_cnst_phn bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys bz_arc_srcsys
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
        AND bz_arc_srcsys.line_of_service_cd = 'FR'
    WHERE bz_cnst_phn.phn_typ_cd IN ('H','LN') 
    AND hnum < 999
    AND assessmnt_ctg = 'Usable' 
    AND cnst_phn_end_dt = '9999-12-31'
),

wphone_ranked AS (
    SELECT
        bz_cnst_phn.cnst_mstr_id,
        bz_cnst_phn.cnst_phn_num AS cnst_work_phone,
        bz_cnst_phn.arc_srcsys_cd AS cnst_work_phone_source,
        CAST('Work' AS VARCHAR(20)) AS cnst_work_phone_type_cd,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='SFFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 1
            WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='GMFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2
            WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='TAFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2.1
            WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 3
            WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='RCO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.1
            WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='ATG' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.2
            WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='CNVO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 5
            ELSE 999
        END AS wnum,
        ROW_NUMBER() OVER (
            PARTITION BY cnst_mstr_id 
            ORDER BY 
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='SFFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 1
                    WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='GMFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='TAFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2.1
                    WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='RCO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.1
                    WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='ATG' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.2
                    WHEN bz_cnst_phn.phn_typ_cd='W' AND bz_cnst_phn.arc_srcsys_cd='CNVO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 5
                    ELSE 999
                END ASC,
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum
    FROM eda.arc_mdm_vws.bzfc_cnst_phn bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys bz_arc_srcsys
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
        AND bz_arc_srcsys.line_of_service_cd = 'FR'
    WHERE bz_cnst_phn.phn_typ_cd = 'W' 
        AND wnum < 999
        AND assessmnt_ctg = 'Usable' 
        AND cnst_phn_end_dt = '9999-12-31'
),

mphone_ranked AS (
    SELECT
        bz_cnst_phn.cnst_mstr_id,
        bz_cnst_phn.cnst_phn_num AS cnst_mbl_phn,
        bz_cnst_phn.arc_srcsys_cd AS cnst_mbl_phn_source,
        CAST('Mobile' AS VARCHAR(20)) AS cnst_mbl_phn_typ_dsc,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='SFFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 1
            WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='GMFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2
            WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='TAFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2.1
            WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 3
            WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='RCO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.1
            WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='ATG' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.2
            WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='CNVO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 5
            WHEN bz_cnst_phn.arc_srcsys_cd='MDON' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 6
            ELSE 999
        END AS mnum,
        ROW_NUMBER() OVER (
            PARTITION BY cnst_mstr_id 
            ORDER BY 
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='SFFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 1
                    WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='GMFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='TAFS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2.1
                    WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='RCO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.1
                    WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='ATG' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 4.2
                    WHEN bz_cnst_phn.phn_typ_cd='M' AND bz_cnst_phn.arc_srcsys_cd='CNVO' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 5
                    WHEN bz_cnst_phn.arc_srcsys_cd='MDON' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 6
                    ELSE 999
                END ASC, 
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum
    FROM eda.arc_mdm_vws.bzfc_cnst_phn bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys bz_arc_srcsys
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
        AND bz_arc_srcsys.line_of_service_cd IN ('FR', 'MDON')
    WHERE (bz_cnst_phn.phn_typ_cd = 'M' OR bz_cnst_phn.arc_srcsys_cd = 'MDON') 
        AND mnum < 999
        AND assessmnt_ctg = 'Usable' 
        AND cnst_phn_end_dt = '9999-12-31'
),

nm_rnk_ranked AS (
    SELECT 
        a.cnst_mstr_id, 
        locator_prsn_nm_key, 
        a.cnst_typ_cd, 
        locator_prsn_first_nm, 
        locator_prsn_middle_nm, 
        locator_prsn_last_nm, 
        locator_prsn_nm_prefix, 
        locator_prsn_nm_suffix, 
        cnst_prsn_full_nm,
        bz_cnst_alias_out_saltn_nm,
        bz_cnst_alias_in_saltn_nm, 
        assessmnt_ctg, 
        b.arc_srcsys_cd,
        ROW_NUMBER() OVER (
            PARTITION BY a.cnst_mstr_id 
            ORDER BY 
                CASE 
                    WHEN b.arc_srcsys_cd = 'STRX' THEN 1
                    WHEN b.arc_srcsys_cd = 'CDIM' THEN 2
                    WHEN b.arc_srcsys_cd = 'SFFS' THEN 3
                    WHEN b.arc_srcsys_cd = 'GMFS' THEN 4
                    WHEN b.arc_srcsys_cd = 'RCO' THEN 5
                    ELSE 6
                END, 
                b.cnst_nm_strt_dt DESC,
                b.dw_srcsys_trans_ts DESC
        ) AS rn
    FROM eda.arc_mdm_vws.bz_cnst_mstr a
    LEFT JOIN (
        SELECT 
            cnst_mstr_id, 
            locator_prsn_nm_key,
            locator_prsn_first_nm, 
            locator_prsn_middle_nm, 
            locator_prsn_last_nm, 
            locator_prsn_nm_prefix, 
            locator_prsn_nm_suffix,
            cnst_prsn_full_nm,
            bz_cnst_alias_out_saltn_nm,
            bz_cnst_alias_in_saltn_nm, 
            assessmnt_ctg,
            a.arc_srcsys_cd, 
            a.cnst_nm_strt_dt, 
            a.dw_srcsys_trans_ts
        FROM eda.arc_mdm_vws.bzfc_cnst_prsn_nm a
        LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys b ON b.arc_srcsys_cd = a.arc_srcsys_cd
        WHERE 
            (b.line_of_service_cd = 'FR' OR a.arc_srcsys_cd IN ('CDIM', 'STRX'))
            AND assessmnt_ctg = 'Usable' 
            AND cnst_prsn_nm_end_dt = '9999-12-31'
    ) b ON a.cnst_mstr_id = b.cnst_mstr_id
),

org_typ_ranked AS (
    SELECT 
        cnst_mstr_id, 
        org_typ_cd,
        ROW_NUMBER() OVER (
            PARTITION BY cnst_mstr_id 
            ORDER BY 
                CASE 
                    WHEN clss.arc_srcsys_cd IN ('SFFS') AND org_typ_cd <> 'U' THEN 1
                    WHEN clss.arc_srcsys_cd IN ('GMFS') AND org_typ_cd <> 'U' THEN 2
                    WHEN clss.arc_srcsys_cd IN ('TAFS') AND org_typ_cd <> 'U' THEN 2.1
                    WHEN clss.arc_srcsys_cd IN ('SFFS') THEN 3 
                    WHEN clss.arc_srcsys_cd IN ('GMFS') THEN 4 
                    WHEN clss.arc_srcsys_cd IN ('TAFS') THEN 4.1 
                    ELSE 5 
                END, 
                clss.dw_srcsys_trans_ts DESC
        ) AS rn
    FROM eda.arc_mdm_vws.bz_cnst_org_clssfctn clss 
    INNER JOIN eda.arc_mdm_vws.bz_arc_srcsys src ON src.arc_srcsys_cd = clss.arc_srcsys_cd
    WHERE src.line_of_service_cd = 'FR'
),

sf_cntct_ranked AS (
    SELECT 
        cnst_mstr_id, 
        frf_cntct_id,
        ROW_NUMBER() OVER (
            PARTITION BY cnst_mstr_id 
            ORDER BY active_ind DESC, frf_cntct_id DESC
        ) AS rn
    FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
    WHERE appl_src_cd = 'SFFS' 
        AND cnst_typ_cd IN ('IN')
),

final_ranked AS (
    SELECT
        M.cnst_mstr_id,
        M.cnst_hsld_id,
        M.cnst_arc_deceased_cd,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.arc_srcsys_cd ELSE DM.cnst_data_src_cd END AS dm_prsn_nm_src_cd,
        DM.cnst_data_src_cd AS dm_cnst_data_src_cd,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_nm_key ELSE DM.locator_prsn_nm_key END AS dm_locator_prsn_nm_key,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.assessmnt_ctg ELSE DM.cnst_prsn_nm_assessmnt_ctg END AS dm_cnst_prsn_nm_assessmnt_ctg,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_nm_prefix ELSE DM.cnst_prsn_prfx_nm END AS dm_cnst_prsn_prfx_nm,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_first_nm ELSE DM.cnst_prsn_f_nm END AS dm_cnst_prsn_f_nm,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_middle_nm ELSE DM.cnst_prsn_m_nm END AS dm_cnst_prsn_m_nm,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_last_nm ELSE DM.cnst_prsn_l_nm END AS dm_cnst_prsn_l_nm,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_nm_suffix ELSE DM.cnst_prsn_sfx_nm END AS dm_cnst_prsn_sfx_nm,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.cnst_prsn_full_nm ELSE DM.cnst_prsn_full_nm END AS dm_cnst_prsn_full_nm,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.bz_cnst_alias_in_saltn_nm ELSE DM.cnst_alias_in_saltn_nm END AS dm_cnst_alias_in_saltn_nm,
        CASE WHEN DM.cnst_prsn_l_nm IS NULL THEN nm_rnk.bz_cnst_alias_out_saltn_nm ELSE DM.cnst_alias_out_saltn_nm END AS dm_cnst_alias_out_saltn_nm,
        DM.locator_addr_key AS dm_locator_addr_key,
        DM.cnst_addr_assessmnt_ctg AS dm_cnst_addr_assessmnt_ctg,
        DM.dpv_cd,
        DM.cnst_line_1_addr AS dm_cnst_line_1_addr,
        DM.cnst_line_2_addr AS dm_cnst_line_2_addr,
        DM.cnst_city_nm AS dm_cnst_city_nm,
        DM.cnst_st_cd AS dm_cnst_st_cd,
        DM.cnst_zip_5_cd AS dm_cnst_zip_5_cd,
        DM.cnst_zip_4_cd AS dm_cnst_zip_4_cd,
        DM.cnst_addr_county_nm AS dm_cnst_addr_county_nm,
        DM.cnst_email AS dm_cnst_email,
        DM.cnst_org_nm AS dm_cnst_org_nm,
        DM.cnst_typ_dsc AS dm_cnst_typ_dsc,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.arc_srcsys_cd ELSE EM.cnst_data_src_cd END AS em_prsn_nm_src_cd,
        EM.cnst_data_src_cd AS em_cnst_data_src_cd,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_nm_key ELSE EM.locator_prsn_nm_key END AS em_locator_prsn_nm_key,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.assessmnt_ctg ELSE EM.cnst_prsn_nm_assessmnt_ctg END AS em_cnst_prsn_nm_assessmnt_ctg,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_nm_prefix ELSE EM.cnst_prsn_prfx_nm END AS em_cnst_prsn_prfx_nm,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_first_nm ELSE EM.cnst_prsn_f_nm END AS em_cnst_prsn_f_nm,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_middle_nm ELSE EM.cnst_prsn_m_nm END AS em_cnst_prsn_m_nm,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_last_nm ELSE EM.cnst_prsn_l_nm END AS em_cnst_prsn_l_nm,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.locator_prsn_nm_suffix ELSE EM.cnst_prsn_sfx_nm END AS em_cnst_prsn_sfx_nm,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.cnst_prsn_full_nm ELSE EM.cnst_prsn_full_nm END AS em_cnst_prsn_full_nm,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.bz_cnst_alias_in_saltn_nm ELSE EM.cnst_alias_in_saltn_nm END AS em_cnst_alias_in_saltn_nm,
        CASE WHEN EM.cnst_prsn_l_nm IS NULL THEN nm_rnk.bz_cnst_alias_out_saltn_nm ELSE DM.cnst_alias_out_saltn_nm END AS em_cnst_alias_out_saltn_nm,
        EM.locator_addr_key AS em_locator_addr_key,
        EM.cnst_line_1_addr AS em_cnst_line_1_addr,
        EM.cnst_line_2_addr AS em_cnst_line_2_addr,
        EM.cnst_city_nm AS em_cnst_city_nm,
        EM.cnst_st_cd AS em_cnst_st_cd,
        EM.cnst_zip_5_cd AS em_cnst_zip_5_cd,
        EM.cnst_zip_4_cd AS em_cnst_zip_4_cd,
        EM.cnst_addr_county_nm AS em_cnst_addr_county_nm,
        EM.cnst_email AS em_cnst_email,
        EM.cnst_email_key AS em_email_key,
        EM.cnst_email_assessmnt_ctg AS em_cnst_email_assessmnt_ctg,
        EM.cnst_org_nm AS em_cnst_org_nm,
        EM.cnst_typ_dsc AS em_cnst_typ_dsc,
        0 AS email_dlvrbl_ind,
        hphone.prim_cnst_phn,
        hphone.prim_cnst_phn_source,
        hphone.prim_cnst_phn_typ_dsc,
        wphone.cnst_work_phone AS cnst_work_phn,
        wphone.cnst_work_phone_source AS cnst_work_phn_source,
        wphone.cnst_work_phone_type_cd AS cnst_work_phn_typ_dsc,
        mphone.cnst_mbl_phn,
        mphone.cnst_mbl_phn_source,
        mphone.cnst_mbl_phn_typ_dsc,
        CASE WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_hm_phn_ind, 0) END AS do_not_call_hm_phn_ind,
        CASE WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_mbl_phn_ind, 0) END AS do_not_call_mbl_phn_ind,
        CASE WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_work_phn_ind, 0) END AS do_not_call_work_phn_ind,
        CASE 
            WHEN em.cnst_email LIKE '%@philips.com' THEN 1 
            WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 
            ELSE COALESCE(cnst_cntct_pref.fr_do_not_email_ind, 0) 
        END AS do_not_email_ind,
        CASE WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 ELSE COALESCE(cnst_cntct_pref.fr_do_not_mail_ind, 0) END AS do_not_mail_ind,
        CASE WHEN fr_smry.benevity_suprsn_ind = 1 THEN 1 ELSE COALESCE(cnst_cntct_pref.fr_do_not_txt_ind, 0) END AS do_not_txt_ind,
        'NULL' AS cnst_3rd_prty_segmtn_group_nm,
        CASE WHEN DU.unit_key IS NULL THEN prim_chpt.prim_affl_unit_key ELSE DU.unit_key END AS unit_key,
        COALESCE(prim_chpt.acct_affl_lock_ind, 0) AS affl_lock_ind,
        COALESCE(mngd_dnr.frf_cur_mngd_dnr_ind, 0) AS sf_acct_fmd_ind,
        mngd_dnr.frf_status_cd,
        mngd_dnr.frf_cur_portfolio_ctg AS portfolio_category,
        mngd_dnr.rlshp_mgr_ownr_key,
        mngd_dnr.rlshp_mgr_nm,
        mngd_dnr.rlshp_mgr_prefd_email_addr,
        M.cnst_typ_cd,
        CASE WHEN M.cnst_typ_cd = 'IN' THEN 'IN' ELSE org_typ.org_typ_cd END AS org_typ_cd,
        mngd_dnr.frf_acct_id,
        sf_cntct.frf_cntct_id,
        mngd_dnr.mult_sf_cnst_ind,
        ROW_NUMBER() OVER (
            PARTITION BY M.cnst_mstr_id 
            ORDER BY mngd_dnr.frf_acct_id DESC NULLS LAST, sf_cntct.frf_cntct_id DESC
        ) AS rn
    FROM fr_cnst
    JOIN eda.arc_mdm_vws.bz_cnst_mstr M ON fr_cnst.cnst_mstr_id = M.cnst_mstr_id
    LEFT OUTER JOIN mktg_ops_tbls.cnst_cdi_s_f_p_fr_dmail DM ON M.cnst_mstr_id = DM.cnst_mstr_id
    LEFT OUTER JOIN mktg_ops_tbls.cnst_cdi_s_f_p_fr_email EM ON M.cnst_mstr_id = EM.cnst_mstr_id
    LEFT OUTER JOIN (
        SELECT 
            a.cnst_mstr_id,
            a.affl_lock_ind AS acct_affl_lock_ind,
            b.unit_key AS prim_affl_unit_key
        FROM eda.ufds_vws.bzfc_cnst_fr_prfl a
        LEFT JOIN mktg_ops_vws.dim_unit_merged b ON a.rev_credit_key = orig_unit_key
    ) prim_chpt ON M.cnst_mstr_id = prim_chpt.cnst_mstr_id
    LEFT OUTER JOIN mngd_dnr_ranked mngd_dnr ON M.cnst_mstr_id = mngd_dnr.cnst_mstr_id AND mngd_dnr.rn = 1
    LEFT OUTER JOIN mktg_ops_vws.bzfc_dim_unit_merged DU ON prim_chpt.prim_affl_unit_key = DU.orig_unit_key
    LEFT OUTER JOIN hphone_ranked hphone ON M.cnst_mstr_id = hphone.cnst_mstr_id AND hphone.rownum = 1
    LEFT OUTER JOIN wphone_ranked wphone ON M.cnst_mstr_id = wphone.cnst_mstr_id AND wphone.rownum = 1
    LEFT OUTER JOIN mphone_ranked mphone ON M.cnst_mstr_id = mphone.cnst_mstr_id AND mphone.rownum = 1
    LEFT OUTER JOIN nm_rnk_ranked nm_rnk ON nm_rnk.cnst_mstr_id = M.cnst_mstr_id AND nm_rnk.rn = 1
    LEFT OUTER JOIN mktg_ops_vws.bzf_cem_cnst_opt_outs cnst_cntct_pref ON M.cnst_mstr_id = cnst_cntct_pref.cnst_mstr_id
    LEFT OUTER JOIN org_typ_ranked org_typ ON M.cnst_mstr_id = org_typ.cnst_mstr_id AND org_typ.rn = 1
    LEFT OUTER JOIN sf_cntct_ranked sf_cntct ON M.cnst_mstr_id = sf_cntct.cnst_mstr_id AND sf_cntct.rn = 1
    LEFT OUTER JOIN (
        SELECT cnst_mstr_id, benevity_suprsn_ind
        FROM mktg_ops_vws.gms_arc_fr_smry
    ) fr_smry ON M.cnst_mstr_id = fr_smry.cnst_mstr_id
)

SELECT
    cnst_mstr_id,
    cnst_hsld_id,
    cnst_arc_deceased_cd,
    dm_prsn_nm_src_cd,
    dm_cnst_data_src_cd,
    dm_locator_prsn_nm_key,
    dm_cnst_prsn_nm_assessmnt_ctg,
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
    dpv_cd,
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
    em_prsn_nm_src_cd,
    em_cnst_data_src_cd,
    em_locator_prsn_nm_key,
    em_cnst_prsn_nm_assessmnt_ctg,
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
    cnst_work_phn,
    cnst_work_phn_source,
    cnst_work_phn_typ_dsc,
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
    unit_key,
    affl_lock_ind,
    sf_acct_fmd_ind,
    frf_status_cd,
    portfolio_category,
    rlshp_mgr_ownr_key,
    rlshp_mgr_nm,
    rlshp_mgr_prefd_email_addr,
    cnst_typ_cd,
    org_typ_cd,
    frf_acct_id,
    frf_cntct_id,
    mult_sf_cnst_ind
FROM final_ranked
WHERE rn = 1
with no schema BINDING;