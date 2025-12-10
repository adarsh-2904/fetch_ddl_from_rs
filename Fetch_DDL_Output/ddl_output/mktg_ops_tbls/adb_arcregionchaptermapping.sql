CREATE TABLE mktg_ops_tbls.adb_arcregionchaptermapping (
    ichaptercode integer NOT NULL ENCODE az64,
    ilocalorgunitid integer NOT NULL ENCODE az64,
    schaptername character varying(50) ENCODE lzo,
    sregioncode character varying(5) ENCODE lzo,
    sregionname character varying(50) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;