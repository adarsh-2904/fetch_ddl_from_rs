CREATE TABLE mktg_ops_tbls.adb_nmsexcludelogrcp (
    ibroadlogid integer NOT NULL ENCODE az64,
    ideliveryid integer NOT NULL ENCODE az64,
    iflags smallint NOT NULL ENCODE az64,
    imsgid integer NOT NULL ENCODE az64,
    irecipientid integer NOT NULL ENCODE az64,
    istatus smallint NOT NULL ENCODE az64,
    saddress character varying(512) ENCODE lzo,
    tsevent timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;