CREATE TABLE mktg_ops_tbls.bz_dim_cnst_demographic (
    cnst_mstr_id bigint ENCODE raw distkey,
    marital_status_cd character varying(1) ENCODE lzo,
    marital_status_dsc character varying(7) ENCODE lzo,
    education_level_cd character varying(10) ENCODE lzo,
    education_level_dsc character varying(22) ENCODE lzo,
    chpt_lapsed_tag1_scrval character varying(10) ENCODE lzo,
    un_conv_tag_scrval character varying(10) ENCODE lzo,
    sustainer_flg character varying(1) ENCODE lzo,
    gender_cd character varying(100) ENCODE lzo,
    gender_dsc character varying(7) ENCODE lzo,
    ethnic_exp_group_cd character varying(4) ENCODE lzo,
    ethnic_exp_group_dsc character varying(250) ENCODE lzo,
    race_group_dsc character varying(25) ENCODE lzo,
    gen_segmnt_key integer ENCODE az64,
    generation_segmnt_cd character varying(1) ENCODE lzo,
    generation_segmnt_dsc character varying(100) ENCODE lzo,
    income_group_dsc character varying(20) ENCODE lzo,
    political_persona character varying(20) ENCODE lzo,
    age_band_dsc character varying(10) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );