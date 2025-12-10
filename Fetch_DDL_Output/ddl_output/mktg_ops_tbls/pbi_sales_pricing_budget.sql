CREATE TABLE mktg_ops_tbls.pbi_sales_pricing_budget (
    cust_id character varying(20) NOT NULL ENCODE lzo distkey,
    prodct character varying(20) ENCODE lzo,
    buckt character varying(20) ENCODE lzo,
    fy_year integer ENCODE az64,
    fy_mnth integer ENCODE az64,
    fy_year_mnth integer ENCODE az64,
    revenue numeric(12,2) ENCODE az64,
    vol integer ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    PRIMARY KEY (cust_id)
)
DISTSTYLE KEY;