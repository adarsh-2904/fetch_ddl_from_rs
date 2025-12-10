CREATE TABLE mktg_ops_tbls.srvy_hsptl_rspns_hst (
    rspns_id integer NOT NULL ENCODE az64,
    respondent_id smallint NOT NULL ENCODE az64,
    srvy_id smallint NOT NULL ENCODE az64,
    question_id smallint NOT NULL ENCODE az64,
    value_id smallint NOT NULL ENCODE az64,
    UNIQUE (rspns_id)
)
DISTSTYLE AUTO;