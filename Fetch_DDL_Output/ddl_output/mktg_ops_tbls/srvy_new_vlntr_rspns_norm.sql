CREATE TABLE mktg_ops_tbls.srvy_new_vlntr_rspns_norm (
    rspns_id integer NOT NULL ENCODE az64,
    cnst_mstr_id integer NOT NULL ENCODE az64,
    orig_cnst_mstr_id integer NOT NULL ENCODE az64,
    srvy_id smallint NOT NULL ENCODE az64,
    question_id smallint NOT NULL ENCODE az64,
    value_id smallint NOT NULL ENCODE az64,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;