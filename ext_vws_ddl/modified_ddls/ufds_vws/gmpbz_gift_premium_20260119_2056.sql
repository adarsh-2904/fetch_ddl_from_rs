CREATE OR REPLACE VIEW mods_bi.ufds_vws.gmpbz_gift_premium AS
SELECT
gift_premium_key,
premium_key,
giftran_key,
gift_cnst_grp_key,
nk_gift_premium_id,
gpp_premium_seq,
premium_cd,
premium_dsc,
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
FROM cdigms_rep.gms_tbls.gift_premium
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.ufds_vws.gmpbz_gift_premium TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.ufds_vws.gmpbz_gift_premium TO role ds_mods_reader_vt;
