CREATE or replace VIEW mktg_ops_vws.gmpbz_dim_giftran_typ AS
SELECT
    giftran_typ_key,
    giftran_typ_cd,
    giftran_typ_dsc,
    active_ind,
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_giftran_typ
WHERE row_status_cd <> 'L'
WITH NO SCHEMA BINDING;