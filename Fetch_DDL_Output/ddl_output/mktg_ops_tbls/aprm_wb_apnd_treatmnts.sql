CREATE TABLE mktg_ops_tbls.aprm_wb_apnd_treatmnts (
    snapshot_ts timestamp without time zone NOT NULL ENCODE az64,
    actvty_specific character varying(765) ENCODE lzo,
    channel character varying(255) ENCODE lzo,
    currency_cd character varying(255) ENCODE lzo,
    dsc character varying(255) ENCODE lzo,
    dmn character varying(255) ENCODE lzo,
    last_mod_by character varying(765) ENCODE lzo,
    last_mod_ts timestamp without time zone ENCODE az64,
    status character varying(765) ENCODE lzo,
    ttl character varying(75) ENCODE lzo,
    trmt_cd character varying(75) ENCODE lzo,
    trmt_id integer ENCODE az64,
    typ character varying(255) ENCODE lzo,
    cnt_num integer ENCODE az64,
    srcsys_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_updt_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;