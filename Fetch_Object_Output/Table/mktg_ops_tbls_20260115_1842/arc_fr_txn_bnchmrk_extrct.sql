CREATE TABLE mktg_ops_tbls.arc_fr_txn_bnchmrk_extrct (
    trans_id bigint ENCODE az64,
    cnst_mstr_id bigint ENCODE az64,
    hh_la_id character varying(30) ENCODE lzo COLLATE case_insensitive,
    fcc_cd character varying(40) ENCODE lzo COLLATE case_insensitive,
    fcc_dsc character varying(100) ENCODE lzo COLLATE case_insensitive,
    fr_pckge_cd character varying(10) ENCODE lzo COLLATE case_insensitive,
    fr_pckge_dsc character varying(100) ENCODE lzo COLLATE case_insensitive,
    note_txt character varying(100) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;