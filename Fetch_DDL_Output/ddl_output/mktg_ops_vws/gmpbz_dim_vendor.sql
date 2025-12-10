CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.gmpbz_dim_vendor
AS
SELECT
    vendor_key,
    vendor_cd,
    vendor_dsc,
    gl_debit_acct_string,
    active_ind,
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_vendor
WHERE row_status_cd <> 'L'
with no schema BINDING;