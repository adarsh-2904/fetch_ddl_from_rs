CREATE TABLE mktg_ops_tbls.adb_enumrtn_lkp (
    table_nm character varying(50) ENCODE lzo,
    column_nm character varying(50) ENCODE lzo,
    enumrtn_label character varying(50) ENCODE lzo,
    enumrtn_cd character varying(50) ENCODE lzo,
    enumrtn_dsc character varying(200) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;