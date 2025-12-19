CREATE TABLE mktg_ops_tbls.adb_arctreatmentcode (
    itreatmentcodeid integer ENCODE az64,
    streatmentcode character varying(255) ENCODE lzo COLLATE case_insensitive,
    sreportcellcodeid character varying(255) ENCODE lzo COLLATE case_insensitive,
    iactive smallint ENCODE az64,
    streatmentdesc character varying(255) ENCODE lzo COLLATE case_insensitive,
    tscreated timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;