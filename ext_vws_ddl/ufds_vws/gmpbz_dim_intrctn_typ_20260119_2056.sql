CREATE OR REPLACE VIEW ufds_vws.gmpbz_dim_intrctn_typ AS
SELECT
intrctn_typ_key,
intrctn_typ_cd,
intrctn_typ_dsc,
intrctn_ctg_cd,
intrctn_ctg_dsc,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.dim_intrctn_typ
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;