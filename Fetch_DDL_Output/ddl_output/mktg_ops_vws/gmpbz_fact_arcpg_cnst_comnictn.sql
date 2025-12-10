CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_fact_arcpg_cnst_comnictn AS
SELECT
    cnst_comnictn_key AS constituent_communication_key,
    cnst_mstr_id AS constituent_master_identifier,
    nk_tapg_acct_id AS nk_tapg_account_identifier,
    nk_tapg_comnictn_dt AS nk_tapg_communication_date,
    nk_tapg_comnictn_seq AS nk_tapg_communication_sequence,
    nk_tapg_comnictn_seq_page AS nk_tapg_communication_sequence_page,
    comnictn_dsc AS communication_description,
    src_key AS communication_source_key,
    comnictn_typ_key AS communication_type_key,
    response_typ_key AS response_type_key,
    chan_typ_key AS channel_type_key,
    lctn_key AS unit_key,
    amt_typ_key AS amount_type_key,
    amt AS amount,
    comnictn_note_txt AS note_txt,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_trans_ts,
    row_status_cd AS row_stat_cd,
    appl_src_cd AS application_source_code,
    load_id AS load_identifier,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
FROM eda.ufds_vws.gmpbz_fact_arcpg_cnst_comnictn
with no schema binding
;