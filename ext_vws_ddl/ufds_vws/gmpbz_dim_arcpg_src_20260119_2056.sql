CREATE OR REPLACE VIEW ufds_vws.gmpbz_dim_arcpg_src AS
SELECT
src_key,
src_cd,
src_dsc,
activity_cd,
activity_dsc,
prog_cd,
prog_dsc,
initiative_cd,
initiative_dsc,
effort,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.dim_arcpg_src
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;