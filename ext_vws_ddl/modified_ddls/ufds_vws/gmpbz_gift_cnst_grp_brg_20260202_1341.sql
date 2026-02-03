CREATE OR REPLACE VIEW mods_bi.ufds_vws.gmpbz_gift_cnst_grp_brg AS
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
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM mods_bi.ufds_vws.gmpbza_gift_cnst_grp_brg
WHERE bzd_curr_ind = 1
WITH NO SCHEMA BINDING;
GRANT ALL ON mods_bi.ufds_vws.gmpbz_gift_cnst_grp_brg TO role mods_bi_writer;
GRANT SELECT ON mods_bi.ufds_vws.gmpbz_gift_cnst_grp_brg TO role mods_bi_reader_vt;
