CREATE TABLE mktg_ops_tbls.pg_src_convrsn (
    orig_src_cd character varying(14) ENCODE lzo distkey,
    orig_src_dsc character varying(100) ENCODE lzo,
    new_src_cd character varying(14) ENCODE lzo,
    new_src_dsc character varying(100) ENCODE lzo
)
DISTSTYLE KEY;