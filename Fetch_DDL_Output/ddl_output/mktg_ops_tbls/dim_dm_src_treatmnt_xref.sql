CREATE TABLE mktg_ops_tbls.dim_dm_src_treatmnt_xref (
    src_key integer ENCODE az64,
    src_cd character varying(14) ENCODE lzo distkey,
    pg_src_cd character varying(14) ENCODE lzo,
    nk_treatmnt_id integer ENCODE raw,
    treatmnt_cd character varying(255) ENCODE lzo,
    treatmnt_dsc character varying(255) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( nk_treatmnt_id );