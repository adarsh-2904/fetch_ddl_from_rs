CREATE TABLE mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm (
    cnst_mstr_id bigint ENCODE zstd distkey,
    pa_unit_key integer ENCODE zstd,
    dm_cnst_line_2_addr character varying(100) ENCODE zstd,
    dm_cnst_city_nm character varying(100) ENCODE zstd,
    dm_cnst_st_cd character varying(2) ENCODE zstd,
    dm_cnst_zip_5_cd character varying(5) ENCODE zstd,
    dm_cnst_zip_4_cd character varying(5) ENCODE zstd,
    dm_cnst_addr_county_nm character varying(100) ENCODE zstd,
    affl_lock_ind smallint ENCODE zstd,
    cnst_line_1_addr character varying(100) ENCODE zstd,
    cnst_line_2_addr character varying(100) ENCODE zstd,
    cnst_city_nm character varying(100) ENCODE zstd,
    cnst_st_cd character varying(2) ENCODE zstd,
    cnst_zip_5_cd character varying(5) ENCODE zstd,
    cnst_zip_4_cd character varying(4) ENCODE zstd,
    cnst_addr_county_nm character varying(100) ENCODE zstd,
    pa_locator_addr_key bigint ENCODE zstd,
    dm_locator_addr_key bigint ENCODE zstd,
    pa_addr_assessmnt_ctg character varying(40) ENCODE zstd,
    dm_addr_assessmnt_ctg character varying(40) ENCODE zstd,
    dm_unit_key integer ENCODE zstd,
    dm_cnst_line_1_addr character varying(255) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( pa_unit_key );