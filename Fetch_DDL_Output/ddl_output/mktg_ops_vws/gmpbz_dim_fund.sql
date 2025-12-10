CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_fund AS
SELECT
    fund_key,
    CAST(row_eff_from_ts AS TIMESTAMP) AS row_eff_from_ts,
    CAST(row_eff_to_ts AS TIMESTAMP) AS row_eff_to_ts,
    fund_cd,
    fund_dsc,
    gl_company_fund_cd,
    gl_company_fund_dsc,
    gl_action_prog_cd,
    gl_action_prog_dsc,
    gl_prog_srcv_cd,
    gl_prog_srcv_dsc,
    non_bdgt_rlvng_ind,
    active_ind,
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gmpbza_dim_fund
WHERE bzd_curr_ind = 1
with no schema binding
;