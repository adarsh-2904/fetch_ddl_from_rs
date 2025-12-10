CREATE TABLE mktg_ops_tbls.adb_anlytc_hit_stg (
    cnst_mstr_id bigint ENCODE az64,
    orig_cnst_mstr_id bigint ENCODE az64,
    frst_prty_id character varying(50) ENCODE lzo,
    rco_dntn_id character varying(20) ENCODE lzo,
    hit_tm_ts timestamp without time zone ENCODE az64,
    fr_lftm_max_dntn_amt numeric(19,2) ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;