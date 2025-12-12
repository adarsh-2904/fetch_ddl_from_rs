CREATE TABLE mktg_ops_tbls.bz_adobe_analytics_ts_txn (
    month_dt date ENCODE raw distkey,
    month_dt_src character varying(25) ENCODE lzo,
    src_cd character varying(20) ENCODE raw,
    subsrc_cd character varying(256) ENCODE lzo,
    visit_cnt integer ENCODE az64,
    order_cnt integer ENCODE az64,
    revenue_amt numeric(15,2) ENCODE az64,
    curr_prcsd_file_nm character varying(255) ENCODE lzo,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( month_dt, src_cd );