CREATE TABLE mktg_ops_tbls.srvy_dim_survey (
    srvy_id smallint NOT NULL ENCODE az64,
    iwebappid integer ENCODE az64,
    srvy_nm character varying(128) NOT NULL ENCODE lzo,
    audience character varying(10) NOT NULL ENCODE lzo,
    yr_mth character(7) NOT NULL ENCODE lzo,
    calendar_mth smallint ENCODE az64,
    calendar_yr smallint ENCODE az64,
    fiscal_yr smallint ENCODE az64,
    season character varying(11) NOT NULL ENCODE lzo,
    srvy_cnt integer ENCODE az64,
    respondent_cnt integer ENCODE az64,
    srvy_category character varying(20) ENCODE lzo,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    UNIQUE (srvy_id)
)
DISTSTYLE AUTO;