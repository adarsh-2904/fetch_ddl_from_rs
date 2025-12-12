create or REPLACE VIEW mktg_ops_vws.bz_grp_mbrshp as 
SELECT
    grp_key,
    cnst_mstr_id,
    arc_srcsys_cd,
    line_of_service_cd,
    b.unit_key,
    assgnmnt_mthd,
    NULL AS created_dt,
    NULL AS created_by,
    TO_CHAR(grp_mbrshp_eff_strt_dt, 'MM/DD/YYYY') as grp_mbrshp_eff_strt_dt,
    TO_CHAR(grp_mbrshp_eff_end_dt, 'MM/DD/YYYY') as grp_mbrshp_eff_end_dt,
    TO_CHAR(grp_mbrshp_strt_ts, 'MM/DD/YYYY HH24:MI:SS') as grp_mbrshp_strt_ts,
    TO_CHAR(grp_mbrshp_end_dt, 'MM/DD/YYYY') as grp_mbrshp_end_dt,
    trans_key ,
    user_id,
    notes,
    TO_CHAR(srcsys_trans_ts, 'MM/DD/YYYY HH24:MI:SS') as srcsys_trans_ts,
    TO_CHAR(dw_srcsys_trans_ts, 'MM/DD/YYYY HH24:MI:SS') as dw_srcsys_trans_ts,
    a.row_stat_cd,
    a.appl_src_cd,
    a.load_id
FROM eda.arc_cmm_vws.bza_grp_mbrshp a
LEFT JOIN mktg_ops_vws.dim_unit_merged b ON a.unit_key = b.orig_unit_key
WHERE bzd_curr_ind = 1
with no schema binding;