CREATE TABLE mktg_ops_tbls.awb_dmail_xtrct (
    cnst_mstr_id bigint ENCODE az64,
    recipient_id integer ENCODE az64,
    src_cd character varying(50) ENCODE lzo COLLATE case_insensitive,
    motivtn_cd character varying(40) ENCODE lzo COLLATE case_insensitive,
    treatmnt_cd character varying(255) ENCODE lzo COLLATE case_insensitive,
    campgn_program_nm character varying(255) ENCODE lzo COLLATE case_insensitive,
    intrctn_ts timestamp without time zone ENCODE az64,
    dm_intrctn_extrct_dt date ENCODE az64
)
DISTSTYLE ALL;