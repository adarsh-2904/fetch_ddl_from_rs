CREATE TABLE mktg_ops_tbls.name_gender (
    name character varying(15) NOT NULL ENCODE lzo COLLATE case_sensitive,
    gender character varying(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    probability character varying(18) NOT NULL ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE EVEN;