CREATE TABLE mktg_ops_tbls.dim_bio_product (
    product_cd character varying(50) ENCODE lzo,
    product_dsc character varying(50) ENCODE lzo,
    Data Warehouse Transaction Timestamp character varying(50) ENCODE lzo,
    Row Status Code character varying(50) ENCODE lzo,
    Application Source Code character varying(50) ENCODE lzo,
    Load Identifier integer ENCODE az64
)
DISTSTYLE AUTO;