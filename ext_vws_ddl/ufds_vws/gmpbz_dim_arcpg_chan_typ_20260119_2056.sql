CREATE OR REPLACE VIEW ufds_vws.gmpbz_dim_arcpg_chan_typ AS
SELECT
chan_typ_key,
chan_typ_cd,
chan_typ_dsc,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.dim_arcpg_chan_typ
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;