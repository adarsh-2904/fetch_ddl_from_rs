CREATE TABLE mktg_ops_tbls.srvy_vlntr_dim_values (
    value_id smallint NOT NULL ENCODE az64,
    value_num smallint NOT NULL ENCODE az64,
    value_dsc character varying(100) NOT NULL ENCODE lzo COLLATE case_insensitive,
    value_sort smallint NOT NULL ENCODE az64,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64,
    UNIQUE (value_id)
)
DISTSTYLE AUTO;