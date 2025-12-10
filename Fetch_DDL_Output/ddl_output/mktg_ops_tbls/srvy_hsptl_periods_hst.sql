CREATE TABLE mktg_ops_tbls.srvy_hsptl_periods_hst (
    calendar_yr_mth character(7) NOT NULL ENCODE lzo,
    calendar_mth smallint NOT NULL ENCODE az64,
    calendar_yr smallint NOT NULL ENCODE az64,
    fiscal_yr smallint NOT NULL ENCODE az64,
    season character varying(11) NOT NULL ENCODE lzo,
    UNIQUE (calendar_yr_mth)
)
DISTSTYLE AUTO;