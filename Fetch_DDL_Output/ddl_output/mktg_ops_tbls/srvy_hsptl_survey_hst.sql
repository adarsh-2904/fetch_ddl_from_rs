CREATE TABLE mktg_ops_tbls.srvy_hsptl_survey_hst (
    srvy_id smallint NOT NULL ENCODE az64,
    srvy_nm character varying(20) NOT NULL ENCODE lzo,
    audience character varying(10) NOT NULL ENCODE lzo,
    yr_mth character(7) NOT NULL ENCODE lzo,
    srvy_cnt integer ENCODE az64,
    respondent_cnt integer ENCODE az64,
    UNIQUE (srvy_id)
)
DISTSTYLE AUTO;