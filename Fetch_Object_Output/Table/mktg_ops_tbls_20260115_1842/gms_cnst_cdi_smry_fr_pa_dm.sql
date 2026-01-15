CREATE TABLE mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm (
    cnst_mstr_id bigint ENCODE zstd distkey,
    pa_unit_key bigint ENCODE zstd,
    dm_cnst_line_1_addr character varying(787) ENCODE zstd COLLATE case_sensitive,
    dm_cnst_line_2_addr character varying(513) ENCODE zstd COLLATE case_sensitive,
    dm_cnst_city_nm character varying(256) ENCODE zstd COLLATE case_sensitive,
    dm_cnst_st_cd character varying(101) ENCODE zstd COLLATE case_sensitive,
    dm_cnst_zip_5_cd character varying(51) ENCODE zstd COLLATE case_sensitive,
    dm_cnst_zip_4_cd character varying(51) ENCODE zstd COLLATE case_sensitive,
    dm_cnst_addr_county_nm character varying(401) ENCODE zstd COLLATE case_sensitive,
    affl_lock_ind integer ENCODE zstd,
    cnst_line_1_addr character varying(787) ENCODE zstd COLLATE case_sensitive,
    cnst_line_2_addr character varying(513) ENCODE zstd COLLATE case_sensitive,
    cnst_city_nm character varying(256) ENCODE zstd COLLATE case_sensitive,
    cnst_st_cd character varying(101) ENCODE zstd COLLATE case_sensitive,
    cnst_zip_5_cd character varying(51) ENCODE zstd COLLATE case_sensitive,
    cnst_zip_4_cd character varying(51) ENCODE zstd COLLATE case_sensitive,
    cnst_addr_county_nm character varying(401) ENCODE zstd COLLATE case_sensitive,
    pa_locator_addr_key bigint ENCODE zstd,
    dm_locator_addr_key bigint ENCODE zstd,
    pa_addr_assessmnt_ctg character varying(129) ENCODE zstd COLLATE case_sensitive,
    dm_addr_assessmnt_ctg character varying(129) ENCODE zstd COLLATE case_sensitive,
    dm_unit_key integer ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( pa_unit_key );