CREATE TABLE mktg_ops_tbls.srvy_blood_sponsor_questn_2_srvy_xref (
    question_id integer NOT NULL DEFAULT 0 ENCODE az64,
    srvy_id integer ENCODE az64,
    iwebappid integer ENCODE az64,
    src_attrbt_nm character varying(20) ENCODE lzo,
    srvy_question_num smallint ENCODE az64,
    adobe_path_var character varying(40) ENCODE lzo,
    UNIQUE (question_id, srvy_id, src_attrbt_nm)
)
DISTSTYLE AUTO;