CREATE TABLE mktg_ops_tbls.srvy_hsptl_survey (
    srvy_id smallint NOT NULL ENCODE az64,
    iwebappid integer ENCODE az64,
    srvy_nm character varying(128) NOT NULL ENCODE lzo COLLATE case_sensitive,
    audience character varying(10) NOT NULL ENCODE lzo COLLATE case_sensitive,
    yr_mth character(7) NOT NULL ENCODE lzo COLLATE case_insensitive,
    calendar_mth smallint ENCODE az64,
    calendar_yr smallint ENCODE az64,
    fiscal_yr smallint ENCODE az64,
    season character varying(11) NOT NULL ENCODE lzo COLLATE case_sensitive,
    srvy_cnt integer ENCODE az64,
    respondent_cnt integer ENCODE az64,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64,
    UNIQUE (srvy_id)
)
DISTSTYLE AUTO;