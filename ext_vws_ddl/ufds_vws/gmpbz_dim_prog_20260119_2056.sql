CREATE OR REPLACE VIEW ufds_vws.gmpbz_dim_prog AS
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
evnt_strt_dt,
expected_dt,
expected_rev_amt,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.dim_prog
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;