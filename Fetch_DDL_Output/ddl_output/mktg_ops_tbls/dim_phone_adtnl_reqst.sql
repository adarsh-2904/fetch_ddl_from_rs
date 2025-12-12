CREATE TABLE mktg_ops_tbls.dim_phone_adtnl_reqst (
    adtnl_reqst_key integer ENCODE zstd distkey,
    adtnl_reqst_cd character(2) ENCODE zstd,
    adtnl_reqst_dsc character varying(50) ENCODE zstd,
    dw_create_ts timestamp without time zone NOT NULL ENCODE zstd,
    dw_updt_ts timestamp without time zone NOT NULL ENCODE zstd,
    row_stat_cd character(1) NOT NULL ENCODE zstd,
    appl_src_cd character(4) NOT NULL ENCODE zstd,
    load_id integer NOT NULL ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( dw_updt_ts );