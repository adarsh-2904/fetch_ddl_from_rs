CREATE TABLE mktg_ops_tbls.adobe_analytics_txn (
    hour_dsc character varying(25) ENCODE lzo COLLATE case_insensitive,
    prch_id character varying(20) ENCODE lzo COLLATE case_insensitive,
    source1 character varying(50) ENCODE lzo COLLATE case_insensitive,
    medium1 character varying(50) ENCODE lzo COLLATE case_insensitive,
    cid_dsc character varying(50) ENCODE lzo COLLATE case_insensitive,
    device character varying(25) ENCODE lzo COLLATE case_insensitive,
    lst_touch_chnl character varying(25) ENCODE lzo COLLATE case_insensitive,
    src_cd character varying(20) ENCODE lzo COLLATE case_insensitive,
    subsrc_cd character varying(40) ENCODE lzo COLLATE case_insensitive,
    lightbx_imprsn_cnt smallint ENCODE az64,
    lightbx_accpt_cnt smallint ENCODE az64,
    lightbx_decln_cnt smallint ENCODE az64,
    curr_prcsd_file_nm character varying(256) ENCODE lzo COLLATE case_insensitive,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) ENCODE lzo COLLATE case_insensitive,
    load_id integer ENCODE az64
)
DISTSTYLE ALL;