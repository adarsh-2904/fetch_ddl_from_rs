CREATE TABLE mktg_ops_tbls.adb_nmsbroadlogmsg (
    ibroadlogmsgid integer NOT NULL ENCODE raw distkey,
    icount integer NOT NULL ENCODE az64,
    ifailurereason smallint NOT NULL ENCODE az64,
    ifailuretype smallint NOT NULL ENCODE az64,
    iqualifstatus smallint NOT NULL ENCODE az64,
    iruleid integer NOT NULL ENCODE az64,
    sfirstaddress character varying(230) ENCODE lzo COLLATE case_sensitive,
    sfirsttext character varying(614) ENCODE lzo COLLATE case_sensitive,
    smd5 character varying(38) ENCODE lzo COLLATE case_sensitive,
    stext character varying(614) ENCODE lzo COLLATE case_sensitive,
    tscreated timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64,
    PRIMARY KEY (ibroadlogmsgid)
)
DISTSTYLE KEY
SORTKEY ( ibroadlogmsgid );