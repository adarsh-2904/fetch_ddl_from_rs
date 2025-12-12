CREATE TABLE mktg_ops_tbls.sw_email_subscrb (
    email_addr character varying(100) ENCODE lzo distkey,
    email_stat character varying(12) ENCODE lzo,
    curr_prcsd_file_nm character varying(255) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE raw,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );