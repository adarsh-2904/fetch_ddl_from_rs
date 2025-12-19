CREATE TABLE mktg_ops_tbls.adb_nmssubscription (
    iconfirmationid integer ENCODE az64,
    ideletestatus smallint ENCODE az64,
    iemailformat smallint ENCODE az64,
    irecipientid integer ENCODE az64,
    iserviceid integer ENCODE az64,
    saddressspecific character varying(128) ENCODE lzo COLLATE case_insensitive,
    tscreated timestamp without time zone ENCODE az64,
    tsexpiration timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;