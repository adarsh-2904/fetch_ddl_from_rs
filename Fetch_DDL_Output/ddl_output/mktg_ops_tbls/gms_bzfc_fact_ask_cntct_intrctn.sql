CREATE TABLE mktg_ops_tbls.gms_bzfc_fact_ask_cntct_intrctn (
    ask_id character varying(20) ENCODE zstd distkey,
    ask_src_cd character varying(80) ENCODE zstd,
    frf_acct_id character varying(20) ENCODE zstd,
    frf_cntct_id character varying(20) ENCODE zstd,
    cnst_mstr_id bigint ENCODE zstd,
    treatmnt_cd character varying(75) ENCODE zstd,
    treatmnt_dsc character varying(75) ENCODE zstd,
    delivery_nm character varying(100) ENCODE zstd,
    delivery_label character varying(128) ENCODE zstd,
    subsrc_cd character varying(40) ENCODE zstd,
    dw_trans_ts timestamp without time zone ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );