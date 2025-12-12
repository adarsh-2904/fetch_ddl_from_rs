CREATE TABLE mktg_ops_tbls.name_gender (
    name character varying(15) NOT NULL ENCODE lzo,
    gender character varying(1) NOT NULL ENCODE lzo,
    probability character varying(18) NOT NULL ENCODE lzo
)
DISTSTYLE EVEN;