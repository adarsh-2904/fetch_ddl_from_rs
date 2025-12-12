CREATE TABLE mktg_ops_tbls.load_control_table (
    procedure_nm character varying(100) NOT NULL ENCODE raw,
    table_nm character varying(100) NOT NULL ENCODE raw,
    next_begin_dt timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) ENCODE raw,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    PRIMARY KEY (procedure_nm, table_nm)
)
DISTSTYLE EVEN
SORTKEY ( procedure_nm, table_nm );