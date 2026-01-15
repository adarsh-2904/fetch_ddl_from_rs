CREATE TABLE mktg_ops_tbls.dim_bio_product (
    product_cd character varying(10) ENCODE lzo COLLATE case_sensitive distkey,
    product_dsc character varying(10) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(2) NOT NULL ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY;