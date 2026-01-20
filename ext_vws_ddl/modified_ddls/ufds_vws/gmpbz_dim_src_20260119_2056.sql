CREATE OR REPLACE VIEW mods_bi.ufds_vws.gmpbz_dim_src AS
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
appl_src_cd
FROM eda.ufds_vws.gmpbza_dim_src
WHERE bzd_curr_ind = 1
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.ufds_vws.gmpbz_dim_src TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.ufds_vws.gmpbz_dim_src TO role ds_mods_reader_vt;
