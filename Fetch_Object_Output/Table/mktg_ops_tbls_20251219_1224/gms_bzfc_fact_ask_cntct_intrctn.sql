CREATE TABLE mktg_ops_tbls.gms_bzfc_fact_ask_cntct_intrctn (
    ask_id character varying(20) ENCODE zstd COLLATE case_sensitive distkey,
    ask_src_cd character varying(80) ENCODE zstd COLLATE case_sensitive,
    frf_acct_id character varying(20) ENCODE zstd COLLATE case_sensitive,
    frf_cntct_id character varying(20) ENCODE zstd COLLATE case_sensitive,
    cnst_mstr_id bigint ENCODE zstd,
    treatmnt_cd character varying(75) ENCODE zstd COLLATE case_sensitive,
    treatmnt_dsc character varying(75) ENCODE zstd COLLATE case_sensitive,
    delivery_nm character varying(100) ENCODE zstd COLLATE case_sensitive,
    delivery_label character varying(128) ENCODE zstd COLLATE case_sensitive,
    subsrc_cd character varying(40) ENCODE zstd COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );