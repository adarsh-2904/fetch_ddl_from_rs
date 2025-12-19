CREATE TABLE mktg_ops_tbls.pg_src_convrsn (
    orig_src_cd character varying(14) ENCODE lzo COLLATE case_sensitive distkey,
    orig_src_dsc character varying(100) ENCODE lzo COLLATE case_sensitive,
    new_src_cd character varying(14) ENCODE lzo COLLATE case_sensitive,
    new_src_dsc character varying(100) ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE KEY;