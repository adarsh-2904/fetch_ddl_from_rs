CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_arcpg_response_typ AS
SELECT
    response_typ_key AS response_type_key,
    response_typ_cd AS response_type_code,
    CASE 
        WHEN response_typ_key = 26 THEN 'Downloaded Electronic Wills Guide'
        WHEN response_typ_key = 44 THEN 'Forced into Cultivation – Wills'
        ELSE response_typ_dsc
    END AS response_typ_dsc,
    response_ctg_cd AS response_category_code,
    response_ctg_dsc AS response_category_description,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    row_status_cd AS row_status_code,
    appl_src_cd AS application_source_code,
    load_id AS load_identifier,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
FROM eda.ufds_vws.gmpbz_dim_arcpg_response_typ
with no schema binding
;