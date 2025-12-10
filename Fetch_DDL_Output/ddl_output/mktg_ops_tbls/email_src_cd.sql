CREATE TABLE mktg_ops_tbls.email_src_cd (
    comnictn_src_key bigint NOT NULL ENCODE az64 distkey,
    nk_comnictn_src_cd character varying(14) ENCODE lzo,
    comnictn_src_dsc character varying(100) ENCODE lzo,
    channel character varying(255) ENCODE lzo,
    curr_prcsd_file_nm character varying(255) ENCODE lzo,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE raw,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64,
    PRIMARY KEY (comnictn_src_key)
)
DISTSTYLE KEY
SORTKEY ( row_stat_cd );