CREATE TABLE mktg_ops_tbls.aprm_audmem_map (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    aud_id integer ENCODE az64,
    contxt_cd character(1) ENCODE lzo,
    srcsys_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_create_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_updt_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;