CREATE TABLE mktg_ops_tbls.srvy_hsptl_values (
    value_id smallint NOT NULL ENCODE az64,
    value_num smallint NOT NULL ENCODE az64,
    value_dsc character varying(33) NOT NULL ENCODE lzo,
    value_sort smallint NOT NULL ENCODE az64,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    UNIQUE (value_id)
)
DISTSTYLE AUTO;