CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_gl_fcc AS 
-- mktg_ops_vws.gmpbz_dim_gl_fcc source

--------------------------------------------------------------------------------

 
CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_gl_fcc 

AS
SELECT
gl_fcc_key,
gl_fcc_cd,
gl_fcc_dsc,
active_ind,
TO_TIMESTAMP(srcsys_create_ts, 'MM/DD/YYYY"b"HH:MI:SS')  AS srcsys_create_ts,
TO_TIMESTAMP(srcsys_update_ts, 'MM/DD/YYYY"b"HH:MI:SS') AS srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
TO_TIMESTAMP(dw_trans_ts ,'MM/DD/YYYY"b"HH:MI:SS')  AS dw_trans_ts,
load_id,
appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_gl_fcc
WHERE row_status_cd <> 'L'
with no schema binding;