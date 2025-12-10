CREATE TABLE mktg_ops_tbls.adb_arctreatmentcode (
    itreatmentcodeid integer ENCODE az64,
    streatmentcode character varying(255) ENCODE lzo,
    sreportcellcodeid character varying(255) ENCODE lzo,
    iactive smallint ENCODE az64,
    streatmentdesc character varying(255) ENCODE lzo,
    tscreated timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;