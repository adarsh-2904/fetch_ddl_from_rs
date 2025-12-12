CREATE TABLE mktg_ops_tbls.adb_nmsaddress (
    iaddressid integer NOT NULL ENCODE az64,
    iconsecutiveerror integer NOT NULL ENCODE az64,
    ideliveryid integer NOT NULL ENCODE az64,
    iquarantinereason smallint NOT NULL ENCODE az64,
    istatus smallint NOT NULL ENCODE az64,
    itype smallint NOT NULL ENCODE az64,
    mquarantinetext character varying(255) ENCODE lzo,
    saddress character varying(192) ENCODE lzo,
    tscreated timestamp without time zone ENCODE az64,
    tslasterror timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;