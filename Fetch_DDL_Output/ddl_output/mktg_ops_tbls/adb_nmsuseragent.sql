CREATE TABLE mktg_ops_tbls.adb_nmsuseragent (
    ihashkey integer NOT NULL ENCODE az64,
    sbrowserimage character varying(15) ENCODE lzo,
    sbrowsername character varying(50) ENCODE lzo,
    sbrowserversion character varying(10) ENCODE lzo,
    sdevice character varying(255) ENCODE lzo,
    sosfamilly character varying(20) ENCODE lzo,
    sosimage character varying(15) ENCODE lzo,
    sosname character varying(50) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;