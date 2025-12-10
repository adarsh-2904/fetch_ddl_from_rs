CREATE TABLE mktg_ops_tbls.aprm_wb_apnd_cell_cds (
    snapshot_ts timestamp without time zone NOT NULL ENCODE az64,
    cell_cd_id integer ENCODE az64,
    default_value character varying(75) ENCODE lzo,
    dsc character varying(255) ENCODE lzo,
    mod_ts timestamp without time zone ENCODE az64,
    status character varying(765) ENCODE lzo,
    ttl character varying(75) ENCODE lzo,
    cnt_num_num integer ENCODE az64,
    lngth integer ENCODE az64,
    modified_user integer ENCODE az64,
    srcsys_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_create_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_updt_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;