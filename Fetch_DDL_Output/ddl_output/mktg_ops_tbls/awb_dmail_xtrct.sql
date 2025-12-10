CREATE TABLE mktg_ops_tbls.awb_dmail_xtrct (
    cnst_mstr_id bigint ENCODE az64,
    recipient_id integer ENCODE az64,
    src_cd character varying(50) ENCODE lzo,
    motivtn_cd character varying(40) ENCODE lzo,
    treatmnt_cd character varying(255) ENCODE lzo,
    campgn_program_nm character varying(255) ENCODE lzo,
    intrctn_ts timestamp without time zone ENCODE az64,
    dm_intrctn_extrct_dt date ENCODE az64
)
DISTSTYLE ALL;