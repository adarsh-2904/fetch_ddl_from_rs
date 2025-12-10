CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_cnst_demographic
AS
SELECT 
    cnst_mstr_id, 
    marital_status_cd, 
    marital_status_dsc, 
    education_level_cd, 
    education_level_dsc, 
    chpt_lapsed_tag1_scrval, 
    un_conv_tag_scrval, 
    sustainer_flg, 
    gender_cd, 
    gender_dsc,
    ethnic_exp_group_cd, 
    ethnic_exp_group_dsc, 
    race_group_dsc, 
    gen_segmnt_key, 
    generation_segmnt_cd, 
    generation_segmnt_dsc, 
    income_group_dsc, 
    political_persona, 
    age_band_dsc
FROM mktg_ops_tbls.bz_dim_cnst_demographic
with no schema binding;