CREATE TABLE mktg_ops_tbls.adobe_analytics_txn (
    hour_dsc character varying(25) ENCODE lzo,
    prch_id character varying(20) ENCODE lzo,
    source1 character varying(50) ENCODE lzo,
    medium1 character varying(50) ENCODE lzo,
    cid_dsc character varying(50) ENCODE lzo,
    device character varying(25) ENCODE lzo,
    lst_touch_chnl character varying(25) ENCODE lzo,
    src_cd character varying(20) ENCODE lzo,
    subsrc_cd character varying(40) ENCODE lzo,
    lightbx_imprsn_cnt smallint ENCODE az64,
    lightbx_accpt_cnt smallint ENCODE az64,
    lightbx_decln_cnt smallint ENCODE az64,
    curr_prcsd_file_nm character varying(256) ENCODE lzo,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64
)
DISTSTYLE ALL;