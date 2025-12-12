CREATE TABLE mktg_ops_tbls.google_analytics_txn (
    session_dt date ENCODE raw distkey,
    session_yr integer ENCODE az64,
    session_mnth integer ENCODE az64,
    trans_id character varying(12) ENCODE lzo,
    source1 character varying(100) ENCODE lzo,
    medium1 character varying(300) ENCODE lzo,
    campaign character varying(100) ENCODE lzo,
    device character varying(10) ENCODE lzo,
    channel_grp character varying(50) ENCODE lzo,
    trans_cnt integer ENCODE az64,
    revn_amt numeric(13,2) ENCODE az64,
    curr_prcsd_file_nm character varying(50) ENCODE lzo,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character varying(1) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( session_dt );