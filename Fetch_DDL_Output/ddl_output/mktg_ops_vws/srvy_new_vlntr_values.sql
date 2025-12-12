CREATE OR REPLACE VIEW mktg_ops_vws.srvy_new_vlntr_values
AS
SELECT  
    value_id, 
    value_num, 
    value_dsc, 
    value_sort,
    CASE WHEN value_id BETWEEN 1 AND 6 THEN 'ER' /* Experience Rating */
        WHEN value_id BETWEEN 7 AND 13 THEN 'AD' /* Likelihood to Recommend 6-Scale Rating */
        WHEN value_id BETWEEN 14 AND 24 THEN 'NPS' /* NPS Response */
        WHEN value_id BETWEEN 25 AND 26 THEN 'YN' /* Yes/No Response */
        WHEN value_id BETWEEN 27 AND 33 THEN 'WHYVOL' /* Why Volunteer Response */
        ELSE 'NA'
    END AS value_catgry_cd,
    srcsys_trans_ts, 
    dw_trans_ts, 
    row_stat_cd, 
    appl_src_cd, 
    load_id
FROM mktg_ops_tbls.srvy_vlntr_dim_values
with no schema binding;