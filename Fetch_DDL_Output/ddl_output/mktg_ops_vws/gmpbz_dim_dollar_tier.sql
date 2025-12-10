CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_dollar_tier AS
SELECT
    dollar_tier_key,
    dollar_tier_cd,
    dollar_tier_dsc,
    high_val,
    low_val,
    active_ind,
    srcsys_created_by,
    srcsys_modified_by,
    CAST(srcsys_create_ts AS TIMESTAMP),
    CAST(srcsys_update_ts AS TIMESTAMP),
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP),
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_dollar_tier
WHERE row_status_cd <> 'L'
WITH NO SCHEMA BINDING;