CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_sustnr_typ AS
SELECT
    sustnr_typ_key AS "Sustainer Type Key",
    sustnr_typ_cd AS "Sustainer Type Code",
    sustnr_typ_dsc AS "Sustainer Type Description",
    active_ind AS "Active Indicator",
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    srcsys_created_by AS "Record Created By",
    srcsys_modified_by AS "Record Modified By",
    row_status_cd AS "Row Status Code",
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    load_id AS "Load Id",
    appl_src_cd AS "Appl Src Cd"
FROM eda.ufds_vws.gmpbz_dim_sustnr_typ
WHERE row_status_cd <> 'L'
with no schema binding
;