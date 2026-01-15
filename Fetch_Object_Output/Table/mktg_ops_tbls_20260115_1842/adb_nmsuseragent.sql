CREATE TABLE mktg_ops_tbls.adb_nmsuseragent (
    ihashkey integer NOT NULL ENCODE az64,
    sbrowserimage character varying(15) ENCODE lzo COLLATE case_sensitive,
    sbrowsername character varying(50) ENCODE lzo COLLATE case_sensitive,
    sbrowserversion character varying(10) ENCODE lzo COLLATE case_sensitive,
    sdevice character varying(255) ENCODE lzo COLLATE case_sensitive,
    sosfamilly character varying(20) ENCODE lzo COLLATE case_sensitive,
    sosimage character varying(15) ENCODE lzo COLLATE case_sensitive,
    sosname character varying(50) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;