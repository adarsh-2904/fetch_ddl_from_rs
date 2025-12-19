CREATE TABLE mktg_ops_tbls.adobe_dwb_intrctn_stg_tmp (
    cnst_mstr_id bigint ENCODE az64,
    adb_recpnt_id bigint ENCODE az64,
    intrctn_dt_src character varying(10) ENCODE lzo COLLATE case_insensitive,
    intrctn_dt date ENCODE az64,
    intrctn_ts_src character varying(19) ENCODE lzo COLLATE case_insensitive,
    intrctn_ts timestamp without time zone ENCODE az64,
    atrbtn_block_id character varying(30) ENCODE lzo COLLATE case_insensitive,
    log_src_id character varying(20) ENCODE lzo COLLATE case_insensitive,
    mktg_chnl character varying(25) ENCODE lzo COLLATE case_insensitive,
    mktg_subchnl character varying(25) ENCODE lzo COLLATE case_insensitive,
    src_cd character varying(20) ENCODE lzo COLLATE case_insensitive,
    sub_src_cd character varying(50) ENCODE lzo COLLATE case_insensitive,
    motivtn_cd character varying(20) ENCODE lzo COLLATE case_insensitive,
    atrbtn_spc_weight numeric(6,2) ENCODE az64,
    atrbtn_spc_typ character varying(20) ENCODE lzo COLLATE case_insensitive,
    ts_denorm bigint ENCODE az64,
    curr_prcsd_file_nm character varying(256) ENCODE lzo COLLATE case_insensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;