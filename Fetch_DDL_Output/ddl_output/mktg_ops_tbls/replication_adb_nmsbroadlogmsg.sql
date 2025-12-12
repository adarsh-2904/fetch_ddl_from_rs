CREATE TABLE mktg_ops_tbls.replication_adb_nmsbroadlogmsg (
    ibroadlogmsgid integer NOT NULL ENCODE raw distkey,
    icount integer NOT NULL ENCODE az64,
    ifailurereason smallint NOT NULL ENCODE az64,
    ifailuretype smallint NOT NULL ENCODE az64,
    iqualifstatus smallint NOT NULL ENCODE az64,
    iruleid integer NOT NULL ENCODE az64,
    sfirstaddress character varying(192) ENCODE lzo,
    sfirsttext character varying(512) ENCODE lzo,
    smd5 character varying(32) ENCODE lzo,
    stext character varying(512) ENCODE lzo,
    tscreated timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( ibroadlogmsgid );