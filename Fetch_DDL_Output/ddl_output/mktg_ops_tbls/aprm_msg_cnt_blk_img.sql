CREATE TABLE mktg_ops_tbls.aprm_msg_cnt_blk_img (
    email_id integer NOT NULL ENCODE az64,
    ttl character varying(225) ENCODE lzo,
    block_id integer NOT NULL ENCODE az64,
    contxt_cd character(1) ENCODE lzo,
    dw_srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    upd_flg character(1) ENCODE lzo
)
DISTSTYLE ALL;