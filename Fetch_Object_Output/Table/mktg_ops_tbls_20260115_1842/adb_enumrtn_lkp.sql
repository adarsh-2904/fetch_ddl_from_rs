CREATE TABLE mktg_ops_tbls.adb_enumrtn_lkp (
    table_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    column_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    enumrtn_label character varying(50) ENCODE lzo COLLATE case_insensitive,
    enumrtn_cd character varying(50) ENCODE lzo COLLATE case_insensitive,
    enumrtn_dsc character varying(200) ENCODE lzo COLLATE case_insensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;