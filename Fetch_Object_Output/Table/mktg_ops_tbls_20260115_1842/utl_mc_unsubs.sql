CREATE TABLE mktg_ops_tbls.utl_mc_unsubs (
    email_addr character varying(255) ENCODE raw COLLATE case_sensitive distkey
)
DISTSTYLE KEY
SORTKEY ( email_addr );