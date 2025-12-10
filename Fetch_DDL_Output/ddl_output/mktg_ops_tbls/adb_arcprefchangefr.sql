CREATE TABLE mktg_ops_tbls.adb_arcprefchangefr (
    iblacklistemail_fr smallint ENCODE az64,
    ideliveryid integer ENCODE az64,
    iprefchangefrid integer ENCODE az64,
    irecipientid integer ENCODE az64,
    sfr_em_email character varying(128) ENCODE lzo,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;