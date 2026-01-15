CREATE TABLE mktg_ops_tbls.cnst_cdi_phss_preferred_dmail (
    cnst_mstr_id bigint ENCODE lzo distkey,
    cnst_hsld_id character varying(18) ENCODE lzo COLLATE case_sensitive,
    cnst_dsp_deceased_cd character(1) ENCODE lzo COLLATE case_sensitive,
    cnst_data_src_cd character varying(10) ENCODE lzo COLLATE case_sensitive,
    cnst_prsn_prfx_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    cnst_prsn_f_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    cnst_prsn_m_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    cnst_prsn_l_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    cnst_prsn_sfx_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    cnst_prsn_full_nm character varying(100) ENCODE lzo COLLATE case_sensitive,
    cnst_alias_in_saltn_nm character varying(120) ENCODE lzo COLLATE case_sensitive,
    cnst_alias_out_saltn_nm character varying(120) ENCODE lzo COLLATE case_sensitive,
    locator_addr_key bigint ENCODE lzo,
    cnst_addr_assessmnt_ctg character varying(40) ENCODE lzo COLLATE case_sensitive,
    dpv_cd character varying(1) ENCODE lzo COLLATE case_sensitive,
    cnst_addr_typ_cd character varying(5) ENCODE lzo COLLATE case_sensitive,
    cnst_line_1_addr character varying(100) ENCODE lzo COLLATE case_sensitive,
    cnst_line_2_addr character varying(100) ENCODE lzo COLLATE case_sensitive,
    cnst_city_nm character varying(100) ENCODE lzo COLLATE case_sensitive,
    cnst_st_cd character(2) ENCODE lzo COLLATE case_sensitive,
    cnst_zip_5_cd character(5) ENCODE lzo COLLATE case_sensitive,
    cnst_zip_4_cd character(4) ENCODE lzo COLLATE case_sensitive,
    cnst_email character varying(100) ENCODE lzo COLLATE case_sensitive,
    cnst_org_nm character varying(150) ENCODE lzo COLLATE case_sensitive,
    cnst_typ_dsc character varying(50) ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );