CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_rgnrt_reason AS
SELECT
    rgnrt_reason_key,
    rgnrt_reason_cd,
    rgnrt_reason_dsc,
    active_ind,
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    load_id,
    appl_src_cd
FROM ufds_vws.gmpbz_dim_rgnrt_reason
with no schema binding
;