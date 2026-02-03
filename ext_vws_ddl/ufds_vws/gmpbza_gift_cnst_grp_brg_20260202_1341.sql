CREATE OR REPLACE VIEW ufds_vws.gmpbza_gift_cnst_grp_brg AS
SELECT
gift_cnst_grp_key,
gmp_cnst_hst_key,
gmp_cnst_key,
row_eff_from_ts,
row_eff_to_ts,
cnst_role_cd,
cnst_role_dsc,
active_ind,
backed_out_ind,
back_out_reason_cd,
vendor_src_cd,
srcsys_create_ts ,
srcsys_update_ts ,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd,
CASE WHEN row_eff_to_ts = TIMESTAMP '9999-12-31 00:00:00'THEN 1 ELSE 0 END AS bzd_curr_ind
FROM cdigms_rep.gms_tbls.gift_cnst_grp_brg
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;