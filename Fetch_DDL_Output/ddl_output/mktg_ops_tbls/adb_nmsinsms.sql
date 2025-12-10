CREATE TABLE mktg_ops_tbls.adb_nmsinsms (
    icountrycode integer NOT NULL ENCODE az64,
    iextaccountid integer NOT NULL ENCODE az64,
    iinsmsid integer NOT NULL ENCODE az64,
    ioperatorcode integer NOT NULL ENCODE az64,
    salias character varying(64) ENCODE lzo,
    slargeaccount character varying(64) ENCODE lzo,
    slinkedsmsid character varying(32) ENCODE lzo,
    smessage character varying(255) ENCODE lzo,
    sorigin character varying(32) ENCODE lzo,
    sproviderid character varying(64) ENCODE lzo,
    sseparator character varying(8) ENCODE lzo,
    tscreated timestamp without time zone ENCODE az64,
    tsdelivery timestamp without time zone ENCODE az64,
    tsmessage timestamp without time zone ENCODE az64,
    tsreceival timestamp without time zone ENCODE az64,
    ibroadlogrcpid integer NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;