CREATE TABLE mktg_ops_tbls.adb_arcreportcellcode (
    ireportcellcodeid integer ENCODE az64,
    shighdate character varying(2) ENCODE lzo COLLATE case_insensitive,
    shighdonation character varying(6) ENCODE lzo COLLATE case_insensitive,
    slowdate character varying(2) ENCODE lzo COLLATE case_insensitive,
    slowdonation character varying(4) ENCODE lzo COLLATE case_insensitive,
    stag character varying(10) ENCODE lzo COLLATE case_insensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;