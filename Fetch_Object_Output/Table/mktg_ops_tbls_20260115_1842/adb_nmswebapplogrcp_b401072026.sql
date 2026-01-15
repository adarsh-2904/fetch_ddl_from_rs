CREATE TABLE mktg_ops_tbls.adb_nmswebapplogrcp_b401072026 (
    iwebapplogrcpid integer NOT NULL ENCODE az64,
    iwebappid integer NOT NULL ENCODE az64,
    irecipientid integer NOT NULL ENCODE az64,
    ideliveryid integer NOT NULL ENCODE az64,
    dscore numeric(13,2) NOT NULL ENCODE az64,
    icreation smallint NOT NULL ENCODE az64,
    slanguage character varying(12) ENCODE lzo COLLATE case_insensitive,
    sorigin character varying(80) ENCODE lzo COLLATE case_insensitive,
    tslog timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;