CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_src AS
SELECT
    src_key,
    CAST(row_eff_from_ts AS TIMESTAMP) AS row_eff_from_ts,
    CAST(row_eff_to_ts AS TIMESTAMP) AS row_eff_to_ts,
    src_cd,
    src_dsc,
    CASE 
        WHEN b.new_src_cd IS NULL THEN src_cd 
        ELSE b.new_src_cd 
    END AS pg_src_cd,
    CASE 
        WHEN b.new_src_cd IS NULL THEN src_dsc 
        ELSE b.new_src_dsc 
    END AS pg_src_dsc,
    prog_cd,
    prog_dsc,
    rev_credit_cd,
    rev_credit_nm,
    dnr_specified_lctn_cd,
    dnr_specified_lctn_nm,
    gl_fcc_dsc,
    gl_fcc_cd,
    gl_ntrl_acct_cd,
    gl_ntrl_acct_dsc,
    fund_cd,
    fund_dsc,
    sub_src_cd,
    evnt_benefit_ind,
    active_ind,
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_src a
LEFT JOIN mktg_ops_vws.bz_pg_src_convrsn b ON b.orig_src_cd = a.src_cd
with no schema binding
;