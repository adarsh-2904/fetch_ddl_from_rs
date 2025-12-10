CREATE TABLE mktg_ops_tbls.aprm_email_lnk_clkd (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    hist_rec_id integer ENCODE az64,
    hist_rec_ts timestamp without time zone ENCODE az64,
    abstract character varying(600) ENCODE lzo,
    email_id integer NOT NULL ENCODE az64,
    brwsr character varying(75) ENCODE lzo,
    op_sys character varying(75) ENCODE lzo,
    mbl_dvc character varying(75) ENCODE lzo,
    lnk_url character varying(2048) ENCODE lzo,
    is_first_clk integer ENCODE az64,
    lnk_clk_typ integer ENCODE az64,
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