CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_prog AS
SELECT
    prog_key,
    prog_cd,
    prog_dsc,
    rev_credit_cd,
    rev_credit_nm,
    gl_fcc_cd,
    gl_fcc_dsc,
    gl_ntrl_acct_cd,
    gl_ntrl_acct_dsc,
    fund_cd,
    fund_dsc,
    evnt_benefit_ind,
    TO_DATE(evnt_strt_dt, 'MM/DD/YYYY') as evnt_strt_dt,
    TO_DATE(expected_dt, 'MM/DD/YYYY') as expected_dt,
    expected_rev_amt,
    active_ind,
    TO_TIMESTAMP(srcsys_create_ts, 'MM/DD/YYYY HH24:MI:SS') as srcsys_create_ts,
    TO_TIMESTAMP(srcsys_update_ts, 'MM/DD/YYYY HH24:MI:SS') as srcsys_update_ts,
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    TO_TIMESTAMP(dw_trans_ts, 'MM/DD/YYYY HH24:MI:SS') as dw_trans_ts,
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_prog
WHERE row_status_cd <> 'L'
WITH NO SCHEMA BINDING;