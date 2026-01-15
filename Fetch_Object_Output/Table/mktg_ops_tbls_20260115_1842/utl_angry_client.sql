CREATE TABLE mktg_ops_tbls.utl_angry_client (
    contact_email character varying(100) ENCODE raw COLLATE case_sensitive distkey
)
DISTSTYLE KEY
SORTKEY ( contact_email );