CREATE TABLE mktg_ops_tbls.adb_nmsexcludelogrcp_b401072026 (
    ibroadlogid integer NOT NULL ENCODE az64,
    ideliveryid integer NOT NULL ENCODE az64,
    iflags smallint NOT NULL ENCODE az64,
    imsgid integer NOT NULL ENCODE az64,
    irecipientid integer NOT NULL ENCODE az64,
    istatus smallint NOT NULL ENCODE az64,
    saddress character varying(512) ENCODE lzo COLLATE case_insensitive,
    tsevent timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;