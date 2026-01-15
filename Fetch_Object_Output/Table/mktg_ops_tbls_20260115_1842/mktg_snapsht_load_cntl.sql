CREATE TABLE mktg_ops_tbls.mktg_snapsht_load_cntl (
    database_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    table_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    load_begin_dt date ENCODE az64,
    dw_trans_ts timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;