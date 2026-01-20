CREATE OR REPLACE VIEW ufds_vws.gmpbz_dim_arcpg_comnictn_typ AS
SELECT
comnictn_typ_key,
comnictn_typ_cd,
comnictn_typ_dsc,
comnictn_ctg_cd,
comnictn_ctg_dsc,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.dim_arcpg_comnictn_typ
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;