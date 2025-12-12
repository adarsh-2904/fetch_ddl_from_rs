CREATE OR REPLACE VIEW mktg_ops_vws.gmpbzal_dim_src 
AS
SELECT
    a.src_key,
    CAST(a.row_eff_from_ts AS TIMESTAMP) AS row_eff_from_ts,
    CAST(a.row_eff_to_ts AS TIMESTAMP) AS row_eff_to_ts,
    a.src_cd,
    a.src_dsc,
    CASE WHEN b.new_src_cd IS NULL THEN a.src_cd ELSE b.new_src_cd END AS pg_src_cd, 
    CASE WHEN b.new_src_cd IS NULL THEN a.src_dsc ELSE b.new_src_dsc END AS pg_src_dsc,
    a.prog_cd,
    a.prog_dsc,
    a.rev_credit_cd,
    a.rev_credit_nm,
    a.dnr_specified_lctn_cd,
    a.dnr_specified_lctn_nm,
    a.gl_fcc_dsc,
    a.gl_fcc_cd,
    a.gl_ntrl_acct_cd,
    a.gl_ntrl_acct_dsc,
    a.fund_cd,
    a.fund_dsc,
    a.sub_src_cd,
    a.evnt_benefit_ind,
    a.active_ind,
    c.mail_dt, 
    c.email_launch_dt,
    c.intrctn_dt, 
    CAST(a.srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(a.srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    a.srcsys_created_by,
    a.srcsys_modified_by,
    a.row_status_cd,
    CAST(a.dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    a.load_id,
    a.appl_src_cd
FROM eda.ufds_vws.gmpbzal_dim_src a
LEFT JOIN mktg_ops_vws.bz_pg_src_convrsn b 
    ON b.orig_src_cd = a.src_cd
LEFT JOIN mktg_ops_vws.dim_src_2_intrctn_brdg c 
    ON a.src_key = c.src_key
with no schema binding;