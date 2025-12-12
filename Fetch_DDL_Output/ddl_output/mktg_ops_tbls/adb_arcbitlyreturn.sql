CREATE TABLE mktg_ops_tbls.adb_arcbitlyreturn (
    ibitlyreturnid integer NOT NULL ENCODE az64,
    icreatedbyid integer NOT NULL ENCODE az64,
    idelproduct smallint NOT NULL ENCODE az64,
    idonorclickcount integer NOT NULL ENCODE az64,
    idonorcount integer NOT NULL ENCODE az64,
    imodifiedbyid integer NOT NULL ENCODE az64,
    ioptoutcount integer NOT NULL ENCODE az64,
    irepliescount integer NOT NULL ENCODE az64,
    scampaignlabel character varying(128) ENCODE lzo,
    scampaignname character varying(64) ENCODE lzo,
    sdelnature character varying(64) ENCODE lzo,
    sdeliverylabel character varying(128) ENCODE lzo,
    sdeliveryname character varying(100) ENCODE lzo,
    tscreated timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    tslaunch timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;