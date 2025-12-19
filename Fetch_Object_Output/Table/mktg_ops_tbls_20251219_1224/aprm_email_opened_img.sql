CREATE TABLE mktg_ops_tbls.aprm_email_opened_img (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    history_record_date timestamp without time zone ENCODE az64,
    abstract character varying(1500) ENCODE lzo COLLATE case_insensitive,
    subsequent_open_count integer ENCODE az64,
    render_count integer NOT NULL ENCODE az64,
    email_id integer NOT NULL ENCODE az64,
    history_record_id integer ENCODE az64,
    contxt_cd character(1) ENCODE lzo COLLATE case_insensitive,
    dw_srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64,
    upd_flg character(1) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;