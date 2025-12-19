CREATE TABLE mktg_ops_tbls.email_src_cd (
    comnictn_src_key bigint NOT NULL ENCODE az64 distkey,
    nk_comnictn_src_cd character varying(14) ENCODE lzo COLLATE case_sensitive,
    comnictn_src_dsc character varying(100) ENCODE lzo COLLATE case_sensitive,
    channel character varying(255) ENCODE lzo COLLATE case_sensitive,
    curr_prcsd_file_nm character varying(255) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE raw COLLATE case_sensitive,
    appl_src_cd character varying(4) ENCODE lzo COLLATE case_sensitive,
    load_id integer ENCODE az64,
    PRIMARY KEY (comnictn_src_key)
)
DISTSTYLE KEY
SORTKEY ( row_stat_cd );