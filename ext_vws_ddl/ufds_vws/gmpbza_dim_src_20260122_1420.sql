CREATE OR REPLACE VIEW ufds_vws.gmpbza_dim_src AS
SELECT
src_key,
row_eff_from_ts,
row_eff_to_ts,
src_cd,
src_dsc,
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
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd,
CASE WHEN row_eff_to_ts = TIMESTAMP '9999-12-31 00:00:00' OR row_eff_to_ts = TIMESTAMP '9999-12-31 00:00:00' THEN 1 ELSE 0 END AS bzd_curr_ind
FROM cdigms_rep.gms_tbls.dim_src
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;