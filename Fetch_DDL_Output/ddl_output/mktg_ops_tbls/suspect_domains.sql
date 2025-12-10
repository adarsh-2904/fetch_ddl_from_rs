CREATE TABLE mktg_ops_tbls.suspect_domains (
    bad_domain character varying(29) NOT NULL ENCODE raw distkey,
    PRIMARY KEY (bad_domain)
)
DISTSTYLE KEY
SORTKEY ( bad_domain );