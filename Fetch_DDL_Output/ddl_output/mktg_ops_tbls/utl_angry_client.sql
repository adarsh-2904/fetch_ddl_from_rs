CREATE TABLE mktg_ops_tbls.utl_angry_client (
    contact_email character varying(100) ENCODE raw distkey
)
DISTSTYLE KEY
SORTKEY ( contact_email );