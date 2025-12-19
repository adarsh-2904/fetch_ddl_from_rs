CREATE TABLE mktg_ops_tbls.dim_bio_product (
    product_cd character varying(50) ENCODE lzo COLLATE case_sensitive,
    product_dsc character varying(50) ENCODE lzo COLLATE case_sensitive,
    Data Warehouse Transaction Timestamp character varying(50) ENCODE lzo COLLATE case_sensitive,
    Row Status Code character varying(50) ENCODE lzo COLLATE case_sensitive,
    Application Source Code character varying(50) ENCODE lzo COLLATE case_sensitive,
    Load Identifier integer ENCODE az64
)
DISTSTYLE AUTO;