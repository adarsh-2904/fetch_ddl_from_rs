CREATE TABLE mktg_ops_tbls.campgn_yr_end_dow_projctn (
    calendar_dt date ENCODE az64,
    channel character varying(25) ENCODE lzo,
    budget_amt integer ENCODE az64,
    fy_cd character varying(4) ENCODE lzo
)
DISTSTYLE AUTO;