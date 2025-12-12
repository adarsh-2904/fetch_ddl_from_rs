CREATE TABLE mktg_ops_tbls.adb_nmspropositionrcp (
    dweight double precision NOT NULL ENCODE raw,
    ideliveryid integer NOT NULL ENCODE az64,
    ienginetype smallint NOT NULL ENCODE az64,
    iinteractionid integer NOT NULL ENCODE az64,
    iofferid integer NOT NULL ENCODE az64,
    iofferspaceid integer NOT NULL ENCODE az64,
    ipropositionid integer NOT NULL ENCODE az64,
    irank smallint NOT NULL ENCODE az64,
    irecipientid integer NOT NULL ENCODE az64,
    istatus smallint NOT NULL ENCODE az64,
    tsevent timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;