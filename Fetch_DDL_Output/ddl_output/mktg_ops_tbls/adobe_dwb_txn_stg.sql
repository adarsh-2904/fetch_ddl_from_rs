CREATE TABLE mktg_ops_tbls.adobe_dwb_txn_stg (
    cnst_mstr_id bigint ENCODE az64,
    giftran_key bigint ENCODE az64,
    dntn_gift_dt_src character varying(10) ENCODE lzo,
    dntn_gift_dt date ENCODE az64,
    dntn_gift_ts_src character varying(19) ENCODE lzo,
    dntn_gift_ts timestamp without time zone ENCODE az64,
    atrbtn_block_id character varying(30) ENCODE lzo,
    campgn_src_cd character varying(20) ENCODE lzo,
    sub_src_cd character varying(50) ENCODE lzo,
    gift_src_cd character varying(20) ENCODE lzo,
    frst_tactic_mktg_subchnl character varying(50) ENCODE lzo,
    lst_tactic_mktg_subchnl character varying(50) ENCODE lzo,
    curr_prcsd_file_nm character varying(256) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;