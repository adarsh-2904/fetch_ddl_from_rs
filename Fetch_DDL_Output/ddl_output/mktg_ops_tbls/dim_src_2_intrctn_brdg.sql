CREATE TABLE mktg_ops_tbls.dim_src_2_intrctn_brdg (
    src_key bigint NOT NULL DEFAULT 0 ENCODE az64 distkey,
    src_cd character varying(20) ENCODE lzo,
    pg_src_cd character varying(20) ENCODE lzo,
    mail_dt date ENCODE az64,
    email_launch_dt date ENCODE az64,
    intrctn_dt date ENCODE az64,
    row_status_cd character varying(1) ENCODE lzo,
    dw_trans_ts timestamp without time zone ENCODE az64,
    load_id integer DEFAULT 0 ENCODE az64,
    appl_src_cd character varying(4) ENCODE lzo
)
DISTSTYLE KEY;