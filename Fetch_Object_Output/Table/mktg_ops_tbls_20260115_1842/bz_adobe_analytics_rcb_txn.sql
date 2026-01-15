CREATE TABLE mktg_ops_tbls.bz_adobe_analytics_rcb_txn (
    month_dt date ENCODE raw distkey,
    month_dt_src character varying(25) ENCODE lzo COLLATE case_sensitive,
    src_cd character varying(25) ENCODE raw COLLATE case_sensitive,
    subsrc_cd character varying(256) ENCODE lzo COLLATE case_sensitive,
    appt_cnt integer ENCODE az64,
    visit_cnt integer ENCODE az64,
    curr_prcsd_file_nm character varying(255) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) ENCODE lzo COLLATE case_sensitive,
    load_id integer ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( month_dt, src_cd );