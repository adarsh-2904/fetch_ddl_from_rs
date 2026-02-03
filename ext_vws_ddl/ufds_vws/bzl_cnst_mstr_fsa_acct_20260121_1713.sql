CREATE OR REPLACE VIEW ufds_vws.bzl_cnst_mstr_fsa_acct AS
SELECT
cnst_mstr_id,
acct_key,
cnst_key,
cnst_typ_cd,
nk_gmp_cnst_id,
nk_sf_acct_guid,
nk_sf_cntct_guid,
frf_acct_id,
frf_cntct_id,
nk_ta_acct_id,
nk_ta_nm_id,
nk_chpt_sys_id,
appl_src_cd,
dw_trans_ts
FROM ufds_vws.bzl_cnst_mstr_fsa
WHERE cnst_typ_cd IN ('OR', 'AG', 'IG', 'OG')
WITH NO SCHEMA BINDING;