CREATE OR REPLACE VIEW ufds_vws.gmpbz_gmp_cnst_cdi_bridge AS
SELECT
gmp_cnst_cdi_bridge_key,
gmp_cnst_cdi_key,
gmp_cnst_key,
nk_gmp_cnst_id,
nk_gmp_cnst_cdi_id,
active_ind,
vendor_src_cd,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.gmp_cnst_cdi_bridge
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;