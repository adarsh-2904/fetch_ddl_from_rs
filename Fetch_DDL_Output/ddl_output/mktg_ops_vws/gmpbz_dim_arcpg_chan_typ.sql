CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_arcpg_chan_typ AS
SELECT
    chan_typ_key AS channel_type_key,
    chan_typ_cd AS channel_type_code,
    chan_typ_dsc AS channel_type_description,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    row_status_cd AS row_status_code,
    appl_src_cd AS application_source_code,
    load_id AS load_identifier,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
FROM eda.ufds_vws.gmpbz_dim_arcpg_chan_typ
with no schema binding
;