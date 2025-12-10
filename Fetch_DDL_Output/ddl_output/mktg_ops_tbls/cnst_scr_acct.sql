CREATE TABLE mktg_ops_tbls.cnst_scr_acct (
    cnst_fsa_key bigint NOT NULL ENCODE az64,
    scr_id bigint ENCODE az64,
    srcsys_cd character varying(4) ENCODE lzo,
    srcsys_uid character varying(255) ENCODE lzo,
    scr_val character varying(9) ENCODE lzo,
    scr_ts timestamp without time zone ENCODE az64,
    dw_srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;