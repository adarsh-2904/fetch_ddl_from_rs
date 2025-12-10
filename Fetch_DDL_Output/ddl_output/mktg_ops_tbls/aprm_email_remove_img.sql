CREATE TABLE mktg_ops_tbls.aprm_email_remove_img (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    history_record_id integer ENCODE az64,
    history_record_date timestamp without time zone ENCODE az64,
    email_id integer NOT NULL ENCODE az64,
    optout_form_id integer ENCODE az64,
    optout_form_title character varying(225) ENCODE lzo,
    activity_id integer ENCODE az64,
    activity_title character varying(75) ENCODE lzo,
    activity_type_id integer ENCODE az64,
    activity_type_title character varying(75) ENCODE lzo,
    abstract character varying(500) ENCODE lzo,
    type_id integer NOT NULL ENCODE az64,
    contxt_cd character(1) ENCODE lzo,
    dw_srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    upd_flg character(1) ENCODE lzo
)
DISTSTYLE ALL;