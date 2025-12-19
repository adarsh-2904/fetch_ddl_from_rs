CREATE TABLE mktg_ops_tbls.bz_dim_cnst_demographic (
    cnst_mstr_id bigint ENCODE raw distkey,
    marital_status_cd character varying(1) ENCODE lzo COLLATE case_sensitive,
    marital_status_dsc character varying(7) ENCODE lzo COLLATE case_sensitive,
    education_level_cd character varying(10) ENCODE lzo COLLATE case_sensitive,
    education_level_dsc character varying(22) ENCODE lzo COLLATE case_sensitive,
    chpt_lapsed_tag1_scrval character varying(10) ENCODE lzo COLLATE case_sensitive,
    un_conv_tag_scrval character varying(10) ENCODE lzo COLLATE case_sensitive,
    sustainer_flg character varying(1) ENCODE lzo COLLATE case_sensitive,
    gender_cd character varying(100) ENCODE lzo COLLATE case_sensitive,
    gender_dsc character varying(7) ENCODE lzo COLLATE case_sensitive,
    ethnic_exp_group_cd character varying(4) ENCODE lzo COLLATE case_sensitive,
    ethnic_exp_group_dsc character varying(250) ENCODE lzo COLLATE case_sensitive,
    race_group_dsc character varying(25) ENCODE lzo COLLATE case_sensitive,
    gen_segmnt_key integer ENCODE az64,
    generation_segmnt_cd character varying(1) ENCODE lzo COLLATE case_sensitive,
    generation_segmnt_dsc character varying(100) ENCODE lzo COLLATE case_sensitive,
    income_group_dsc character varying(20) ENCODE lzo COLLATE case_sensitive,
    political_persona character varying(20) ENCODE lzo COLLATE case_sensitive,
    age_band_dsc character varying(10) ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );