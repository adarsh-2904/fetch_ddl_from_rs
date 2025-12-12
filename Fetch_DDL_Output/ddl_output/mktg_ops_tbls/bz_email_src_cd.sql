CREATE TABLE mktg_ops_tbls.bz_email_src_cd (
    src_key bigint NOT NULL ENCODE az64 distkey,
    src_cd character varying(14) ENCODE lzo,
    src_dsc character varying(100) ENCODE lzo,
    comnictn_src_key bigint ENCODE az64,
    nk_comnictn_src_cd character varying(14) ENCODE lzo,
    comnictn_src_dsc character varying(100) ENCODE lzo,
    channel character varying(255) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( src_key );