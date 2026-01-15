CREATE TABLE mktg_ops_tbls.adb_arcregionchaptermapping (
    ichaptercode integer NOT NULL ENCODE az64,
    ilocalorgunitid integer NOT NULL ENCODE az64,
    schaptername character varying(50) ENCODE lzo COLLATE case_insensitive,
    sregioncode character varying(5) ENCODE lzo COLLATE case_insensitive,
    sregionname character varying(50) ENCODE lzo COLLATE case_insensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;