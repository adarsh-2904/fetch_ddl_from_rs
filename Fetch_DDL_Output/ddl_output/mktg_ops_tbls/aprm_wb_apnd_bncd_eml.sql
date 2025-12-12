CREATE TABLE mktg_ops_tbls.aprm_wb_apnd_bncd_eml (
    snapshot_ts timestamp without time zone NOT NULL ENCODE az64,
    abstract character varying(4000) ENCODE lzo,
    actvty_id integer ENCODE az64,
    audience_mbr_id integer ENCODE az64,
    bncd_ctgy_id integer ENCODE az64,
    bncd_sub_ctgy character varying(2048) ENCODE lzo,
    bncd_email_term_id integer ENCODE az64,
    data_src_id integer ENCODE az64,
    data_src_key character varying(75) ENCODE lzo,
    dmn character varying(255) ENCODE lzo,
    email_addr character varying(255) ENCODE lzo,
    email_id integer ENCODE az64,
    hist_rec_ts timestamp without time zone ENCODE az64,
    hist_rec_id integer ENCODE az64,
    sub_key character varying(36) ENCODE lzo,
    srcsys_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_create_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_updt_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;