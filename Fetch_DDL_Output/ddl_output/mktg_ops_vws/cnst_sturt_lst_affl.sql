CREATE OR REPLACE VIEW mktg_ops_vws.cnst_sturt_lst_affl AS
WITH combined AS (
    SELECT 
        a.cnst_mstr_id, 
        a.assgnmnt_mthd, 
        b.grp_cd, 
        b.grp_nm, 
        e.line_of_service_cd,
        c.cnst_mstr_subj_area_id, 
        d.arc_srcsys_cd,
        e.nk_ecode, 
        e.unit_key,
        e.grp_mbrshp_eff_strt_dt,
        e.grp_mbrshp_eff_end_dt,
        e.dw_srcsys_trans_ts,
        ROW_NUMBER() OVER (PARTITION BY a.cnst_mstr_id ORDER BY e.dw_srcsys_trans_ts DESC) AS rn
    FROM eda.arc_cmm_vws.bz_grp_mbrshp a
    INNER JOIN eda.arc_cmm_vws.grp_ref b 
        ON a.grp_key = b.grp_key
    INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge c 
        ON a.cnst_mstr_id = c.cnst_mstr_id 
    INNER JOIN eda.arc_mdm_vws.bz_arc_srcsys d  
        ON c.cnst_mstr_subj_area_cd = d.arc_srcsys_cd  
        AND d.line_of_service_dtl = 'FRUPLOAD'
    INNER JOIN eda.DW_STUART_VWS.cnst_grp_mbrshp e 
        ON e.seq_key = c.cnst_mstr_subj_area_id
    WHERE a.assgnmnt_mthd = 'Group Membership Upload' AND e.unit_key <> 0

    UNION ALL

    SELECT 
        a.cnst_mstr_id, 
        a.assgnmnt_mthd, 
        b.grp_cd, 
        b.grp_nm, 
        NULL AS line_of_service_cd,
        CAST(c.cnst_srcsys_id AS BIGINT) AS cnst_mstr_subj_area_id, 
        c.arc_srcsys_cd, 
        d.nk_ecode, 
        d.unit_key, 
        d.created_dt AS grp_mbrshp_eff_strt_dt,
        CAST('9999-12-31' AS DATE) AS grp_mbrshp_eff_end_dt,
        d.dw_srcsys_trans_ts,
        ROW_NUMBER() OVER (PARTITION BY a.cnst_mstr_id ORDER BY d.dw_srcsys_trans_ts DESC) AS rn
    FROM eda.arc_cmm_vws.bz_grp_mbrshp a
    INNER JOIN eda.arc_cmm_vws.grp_ref b 
        ON a.grp_key = b.grp_key
    INNER JOIN eda.arc_mdm_vws.bz_cnst_email c 
        ON a.cnst_mstr_id = c.cnst_mstr_id
    INNER JOIN eda.DW_STUART_VWS.cnst_grp_mbrshp_email d 
        ON CAST(c.cnst_srcsys_id AS BIGINT) = d.seq_key
    WHERE a.assgnmnt_mthd = 'Email-only Upload' 
      AND d.unit_key <> 0
      AND c.arc_srcsys_cd = 'EMLT'
)
SELECT 
    cnst_mstr_id, 
    assgnmnt_mthd, 
    grp_cd, 
    grp_nm, 
    line_of_service_cd,
    cnst_mstr_subj_area_id, 
    arc_srcsys_cd,
    nk_ecode, 
    unit_key,
    grp_mbrshp_eff_strt_dt,
    grp_mbrshp_eff_end_dt,
    dw_srcsys_trans_ts
FROM combined
WHERE rn = 1
with no schema binding 
;