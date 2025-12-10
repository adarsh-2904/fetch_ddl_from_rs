CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_arcpg_comnictn_typ AS
SELECT
    comnictn_typ_key AS communication_type_key,
    comnictn_typ_cd AS communication_type_code,
    comnictn_typ_dsc AS communication_type_description,
    comnictn_ctg_cd AS communication_category_code,
    comnictn_ctg_dsc AS communication_category_description,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    row_status_cd AS row_status_code,
    appl_src_cd AS application_source_code,
    load_id AS load_identifier,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
FROM eda.ufds_vws.gmpbz_dim_arcpg_comnictn_typ
with no schema binding
;