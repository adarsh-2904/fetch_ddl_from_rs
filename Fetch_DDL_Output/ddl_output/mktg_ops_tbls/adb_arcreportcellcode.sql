CREATE TABLE mktg_ops_tbls.adb_arcreportcellcode (
    ireportcellcodeid integer ENCODE az64,
    shighdate character varying(2) ENCODE lzo,
    shighdonation character varying(6) ENCODE lzo,
    slowdate character varying(2) ENCODE lzo,
    slowdonation character varying(4) ENCODE lzo,
    stag character varying(10) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;