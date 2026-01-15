CREATE TABLE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_sync (
    cnst_mstr_id bigint ENCODE az64 distkey,
    dm_cnst_zip_5_cd character(5) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE zstd,
    row_stat_cd character(1) NOT NULL ENCODE zstd COLLATE case_sensitive
)
DISTSTYLE AUTO
SORTKEY ( dw_trans_ts );