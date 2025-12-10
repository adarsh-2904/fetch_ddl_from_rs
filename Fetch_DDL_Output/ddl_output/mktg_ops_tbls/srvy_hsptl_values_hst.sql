CREATE TABLE mktg_ops_tbls.srvy_hsptl_values_hst (
    value_id smallint NOT NULL ENCODE az64,
    value_num smallint NOT NULL ENCODE az64,
    value_dsc character varying(33) NOT NULL ENCODE lzo,
    value_sort smallint NOT NULL ENCODE az64,
    UNIQUE (value_id)
)
DISTSTYLE AUTO;