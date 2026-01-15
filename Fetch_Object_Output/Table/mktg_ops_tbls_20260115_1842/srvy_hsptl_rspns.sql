CREATE TABLE mktg_ops_tbls.srvy_hsptl_rspns (
    rspns_id integer NOT NULL ENCODE az64,
    respondent_id smallint NOT NULL ENCODE az64,
    srvy_id smallint NOT NULL ENCODE az64,
    question_id smallint NOT NULL ENCODE az64,
    value_id smallint NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;