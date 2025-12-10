CREATE TABLE mktg_ops_tbls.vaidity_email_valdtn (
    email_addr character varying(47) NOT NULL ENCODE raw distkey,
    valdtn_status character varying(24) ENCODE lzo,
    valdtn_dt date ENCODE az64,
    valdtn_file_nm character varying(100) ENCODE lzo,
    PRIMARY KEY (email_addr)
)
DISTSTYLE KEY
SORTKEY ( email_addr );