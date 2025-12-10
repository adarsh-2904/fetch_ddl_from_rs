CREATE TABLE mktg_ops_tbls.adb_accistbl_contacts (
    icreatedbyid integer NOT NULL ENCODE az64,
    imodifiedbyid integer NOT NULL ENCODE az64,
    iorgentityid integer NOT NULL ENCODE az64,
    irecipientid integer NOT NULL ENCODE az64,
    tscreated timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;