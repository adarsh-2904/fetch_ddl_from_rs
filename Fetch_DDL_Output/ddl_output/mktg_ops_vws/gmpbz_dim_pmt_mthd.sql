CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_pmt_mthd AS
SELECT
    pmt_mthd_key AS payment_method_key,
    pmt_mthd_cd AS payment_method_code,
    pmt_mthd_dsc AS payment_method_description,
    charge_card_ind AS charge_card_indicator,
    active_ind AS active_indicator,
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    srcsys_created_by AS record_created_by,
    srcsys_modified_by AS record_modified_by,
    row_status_cd AS row_status_code,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    load_id AS load_id,
    appl_src_cd AS appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_pmt_mthd
WHERE row_status_cd <> 'L'
with no schema binding
;