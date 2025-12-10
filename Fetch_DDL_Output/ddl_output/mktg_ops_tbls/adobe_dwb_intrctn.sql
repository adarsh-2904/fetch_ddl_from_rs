CREATE TABLE mktg_ops_tbls.adobe_dwb_intrctn (
    cnst_mstr_id bigint ENCODE az64,
    adb_recpnt_id bigint ENCODE az64,
    intrctn_dt date ENCODE az64,
    intrctn_ts timestamp without time zone ENCODE az64,
    atrbtn_block_id character varying(30) ENCODE lzo,
    log_src_id character varying(20) ENCODE lzo,
    mktg_chnl character varying(25) ENCODE lzo,
    mktg_subchnl character varying(25) ENCODE lzo,
    src_cd character varying(20) ENCODE lzo,
    sub_src_cd character varying(50) ENCODE lzo,
    motivtn_cd character varying(20) ENCODE lzo,
    atrbtn_spc_weight numeric(6,2) ENCODE az64,
    atrbtn_spc_typ character varying(20) ENCODE lzo,
    ts_denorm bigint ENCODE az64,
    curr_prcsd_file_nm character varying(256) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;