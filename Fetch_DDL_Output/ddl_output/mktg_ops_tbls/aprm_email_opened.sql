CREATE TABLE mktg_ops_tbls.aprm_email_opened (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    hist_rec_id integer ENCODE az64,
    hist_rec_ts timestamp without time zone ENCODE az64,
    abstract character varying(500) ENCODE lzo,
    email_id integer NOT NULL ENCODE az64,
    subs_open_cnt integer ENCODE az64,
    render_cnt integer ENCODE az64,
    contxt_cd character(1) ENCODE lzo,
    srcsys_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_create_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_updt_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    UNIQUE (cnst_mstr_id, hist_rec_id, email_id, contxt_cd)
)
DISTSTYLE ALL;