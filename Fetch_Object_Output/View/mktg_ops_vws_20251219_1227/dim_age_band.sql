CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.dim_age_band AS
SELECT 
    age_band_key, 
    nk_age_id, 
    CASE 
        WHEN age_band_key = 100 THEN '100+'  
        WHEN age_band_dsc = '75+' THEN '75-99' 
        ELSE age_band_dsc 
    END AS age_band_dsc, 
    benefit_age_band_cd,
    benefit_age_band_dsc, 
    srcsys_ts, 
    dw_create_ts, 
    dw_updt_ts, 
    row_stat_cd, 
    appl_src_cd, 
    load_id, 
    Personal_Lifestyle_Stage
FROM eda.dw_common_vws.dim_age_band
WITH NO SCHEMA BINDING;