CREATE TABLE mktg_ops_tbls.replication_bz_email_src_cd (
    src_key bigint NOT NULL ENCODE az64 distkey,
    src_cd character varying(14) ENCODE lzo COLLATE case_sensitive,
    src_dsc character varying(100) ENCODE lzo COLLATE case_sensitive,
    comnictn_src_key bigint ENCODE az64,
    nk_comnictn_src_cd character varying(14) ENCODE lzo COLLATE case_sensitive,
    comnictn_src_dsc character varying(100) ENCODE lzo COLLATE case_sensitive,
    channel character varying(255) ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE KEY
SORTKEY ( src_key );