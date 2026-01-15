CREATE TABLE mktg_ops_tbls.cnst_scr_acct (
    cnst_fsa_key bigint NOT NULL ENCODE az64,
    scr_id bigint ENCODE az64,
    srcsys_cd character varying(4) ENCODE lzo COLLATE case_insensitive,
    srcsys_uid character varying(255) ENCODE lzo COLLATE case_insensitive,
    scr_val character varying(9) ENCODE lzo COLLATE case_insensitive,
    scr_ts timestamp without time zone ENCODE az64,
    dw_srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;