CREATE TABLE mktg_ops_tbls.dim_edrtl_response_period (
    edrtl_respns_period_key integer ENCODE az64,
    edrtl_respns_yr integer ENCODE az64,
    edrtl_respns_mth integer ENCODE az64,
    edrtl_respns_period character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;