CREATE TABLE mktg_ops_tbls.srvy_hsptl_questions_hst (
    question_id smallint NOT NULL ENCODE az64,
    question_dsc character varying(100) NOT NULL ENCODE lzo,
    question_sort smallint NOT NULL ENCODE az64,
    category_id smallint NOT NULL ENCODE az64,
    UNIQUE (question_id)
)
DISTSTYLE AUTO;