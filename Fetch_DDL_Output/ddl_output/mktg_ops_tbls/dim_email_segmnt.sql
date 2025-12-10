CREATE TABLE mktg_ops_tbls.dim_email_segmnt (
    email_segmnt_key integer ENCODE az64,
    email_segmnt_cd character varying(6) ENCODE raw distkey,
    email_segmnt_dsc character varying(30) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( email_segmnt_cd );