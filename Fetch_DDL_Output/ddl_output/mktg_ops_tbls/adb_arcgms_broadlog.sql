CREATE TABLE mktg_ops_tbls.adb_arcgms_broadlog (
    ibroadlogid integer ENCODE az64,
    igmsackid integer ENCODE az64,
    icreatedbyid integer ENCODE az64,
    imodifiedbyid integer ENCODE az64,
    tscreated timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;