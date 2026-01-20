CREATE OR REPLACE VIEW mods_bi.ufds_vws.gmpbz_dim_arcpg_amt_typ AS
SELECT
amt_typ_key,
amt_typ_cd,
amt_typ_dsc,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.dim_arcpg_amt_typ
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.ufds_vws.gmpbz_dim_arcpg_amt_typ TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.ufds_vws.gmpbz_dim_arcpg_amt_typ TO role ds_mods_reader_vt;
