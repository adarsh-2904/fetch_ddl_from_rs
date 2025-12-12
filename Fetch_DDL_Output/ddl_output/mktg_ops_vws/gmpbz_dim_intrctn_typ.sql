CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_intrctn_typ AS
SELECT
    intrctn_typ_key,
    intrctn_typ_cd,
    intrctn_typ_dsc,
    intrctn_ctg_cd,
    intrctn_ctg_dsc,
    active_ind,
    CAST(srcsys_create_ts AS TIMESTAMP),
    CAST(srcsys_update_ts AS TIMESTAMP),
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP),
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_intrctn_typ
WHERE row_status_cd <> 'L'
WITH NO SCHEMA BINDING;