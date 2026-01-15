CREATE TABLE mktg_ops_tbls.dim_phone_script (
    script_id integer ENCODE az64 distkey,
    script_dsc character varying(100) ENCODE lzo COLLATE case_sensitive,
    script_num smallint ENCODE az64,
    script_appeal character varying(50) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE raw,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );