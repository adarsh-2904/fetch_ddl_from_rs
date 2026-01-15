CREATE TABLE mktg_ops_tbls.aprm_msg_cnt_blk_img (
    email_id integer NOT NULL ENCODE az64,
    ttl character varying(225) ENCODE lzo COLLATE case_insensitive,
    block_id integer NOT NULL ENCODE az64,
    contxt_cd character(1) ENCODE lzo COLLATE case_insensitive,
    dw_srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64,
    upd_flg character(1) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;