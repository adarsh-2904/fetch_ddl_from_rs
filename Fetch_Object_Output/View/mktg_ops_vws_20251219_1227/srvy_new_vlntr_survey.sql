CREATE OR REPLACE VIEW mktg_ops_vws.srvy_new_vlntr_survey
AS
SELECT  
    srvy_id, 
    iwebappid,
    srvy_nm, 
    audience, 
    yr_mth, 
    calendar_mth, 
    calendar_yr, 
    fiscal_yr, 
    season,
    srvy_cnt, 
    respondent_cnt,
    srcsys_trans_ts, 
    dw_trans_ts, 
    row_stat_cd, 
    appl_src_cd, 
    load_id
FROM mktg_ops_tbls.srvy_dim_survey
WHERE srvy_category = 'New Volunteer'
with no schema BINDING;