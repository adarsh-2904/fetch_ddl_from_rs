CREATE OR REPLACE VIEW mods_bi.ufds_vws.gmpbz_dim_gift_stg AS
SELECT
gift_stg_key,
gift_stg_cd,
gift_stg_dsc,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.dim_gift_stg
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.ufds_vws.gmpbz_dim_gift_stg TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.ufds_vws.gmpbz_dim_gift_stg TO role ds_mods_reader_vt;
