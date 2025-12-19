CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_merchant AS
SELECT
    merchant_key,
    merchant_cd,
    merchant_dsc,
    active_ind,
    CAST(srcsys_create_ts AS TIMESTAMP),
    CAST(srcsys_update_ts AS TIMESTAMP),
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP),
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gms_tbls.dim_merchant
WHERE row_status_cd <> 'L'
WITH NO SCHEMA BINDING;