CREATE OR REPLACE VIEW ufds_vws.gmpbz_gift_sku AS
SELECT
gift_sku_key,
sku_key,
giftran_key,
gift_cnst_grp_key,
nk_gift_sku_id,
gpp_sku_seq,
sku_cd,
sku_dsc,
sku_qty,
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
FROM cdigms_rep.gms_tbls.gift_sku
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;