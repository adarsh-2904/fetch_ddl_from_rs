CREATE TABLE mktg_ops_tbls.srvy_hsptl_questn_catgry (
    catgry_id smallint NOT NULL ENCODE az64,
    catgry_dsc character varying(40) ENCODE lzo COLLATE case_insensitive,
    catgry_sort character varying(2) ENCODE lzo COLLATE case_insensitive,
    UNIQUE (catgry_id)
)
DISTSTYLE AUTO;