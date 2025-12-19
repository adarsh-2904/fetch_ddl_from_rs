CREATE OR REPLACE view mods_bi.mktg_ops_vws.bz_cnst_birth_best AS
SELECT 
    cnst_mstr_id, 
    pid,
    pid as simio_pid,
    cnst_srcsys_id, 
    arc_srcsys_cd, 
    cnst_birth_dy_num,
    cnst_birth_mth_num, 
    cnst_birth_yr_num, 
    bzd_char_month, 
    bzd_char_day,
    bzd_char_yr, 
    bzd_birth_dt, 
    bzd_altered_dt_flg, 
    bzd_derived_age, 
    experian_age, 
    experian_birth_yrmth, 
    experian_derived_age, 
    bb_age_cd, 
    CASE 
        WHEN bb_age_cd = 1 THEN 25
        WHEN bb_age_cd = 2 THEN 35
        WHEN bb_age_cd = 3 THEN 45
        WHEN bb_age_cd = 4 THEN 55
        WHEN bb_age_cd = 5 THEN 65
        WHEN bb_age_cd = 6 THEN 75
        WHEN bb_age_cd = 7 THEN 85
        ELSE NULL
    END AS bb_age_value,
    simio_birth_dt_yr_num, 
    simio_birth_dt_mth_num, 
    simio_derived_birth_dt, 
    simio_derived_age,
    cnst_birth_strt_ts, 
    cnst_birth_end_dt, 
    gen_segmnt_key, 
    generation_segmnt_cd,
    generation_segmnt_dsc, 
    cnst_birth_best_los_ind,  
    trans_key, 
    user_id,
    dw_srcsys_trans_ts, 
    row_stat_cd, 
    appl_src_cd, 
    load_id
FROM mods_bi.mktg_ops_tbls.bz_cnst_birth_best a
WITH NO SCHEMA BINDING;