CREATE TABLE mktg_ops_tbls.srvy_blood_sponsor_questions (
    question_id smallint NOT NULL ENCODE az64,
    question_dsc character varying(100) NOT NULL ENCODE lzo,
    question_sort smallint NOT NULL ENCODE az64,
    category_id smallint NOT NULL ENCODE az64,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    UNIQUE (question_id)
)
DISTSTYLE AUTO;