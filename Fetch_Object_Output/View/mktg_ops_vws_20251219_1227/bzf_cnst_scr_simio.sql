CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.bzf_cnst_scr_simio
AS
SELECT
    cnst_mstr_id,
    MAX(orig_cnst_mstr_id) AS orig_cnst_mstr_id,
    MAX(sm_scrts) AS sm_scrts,
    MIN(sm_arc_disaster_scrval) AS sm_arc_disaster_scrval,
    MIN(sm_arc_active_scrval) AS sm_arc_active_scrval,
    MIN(sm_arc_lapsed_scrval) AS sm_arc_lapsed_scrval,
    MIN(sm_arc_non_fr_scrval) AS sm_arc_non_fr_scrval,
    MIN(sm_political_left_dnr_scrval) AS sm_political_left_dnr_scrval,
    MIN(sm_political_right_dnr_scrval) AS sm_political_right_dnr_scrval,
    MIN(sm_envirnmnt_dnr_scrval) AS sm_envirnmnt_dnr_scrval,
    MIN(sm_veteran_dnr_scrval) AS sm_veteran_dnr_scrval,
    MIN(sm_health_dnr_scrval) AS sm_health_dnr_scrval,
    MIN(sm_children_dnr_scrval) AS sm_children_dnr_scrval,
    MIN(sm_religious_dnr_scrval) AS sm_religious_dnr_scrval,
    MIN(sm_humanitarian_dnr_scrval) AS sm_humanitarian_dnr_scrval,
    MIN(sm_animal_dnr_scrval) AS sm_animal_dnr_scrval,
    MIN(sm_new_dnr_act_propnsty_scrval) AS sm_new_dnr_act_propnsty_scrval,
    MIN(sm_mid_level_upgrd_propnsty_scrval) AS sm_mid_level_upgrd_propnsty_scrval,
    MIN(sm_mnthly_sust_propnsty_scrval) AS sm_mnthly_sust_propnsty_scrval,
    MIN(sm_mjr_gift_propnsty_scrval) AS sm_mjr_gift_propnsty_scrval,
    MIN(sm_pg_propnsty_scrval) AS sm_pg_propnsty_scrval,
    MIN(sm_dnr_advsd_fund_propnsty_scrval) AS sm_dnr_advsd_fund_propnsty_scrval,
    MAX(sm_rfm_dm_chanl_scrval) AS sm_rfm_dm_chanl_scrval,
    MAX(sm_rfm_oln_chanl_scrval) AS sm_rfm_oln_chanl_scrval,
    MAX(sm_rfm_tm_chanl_scrval) AS sm_rfm_tm_chanl_scrval,
    MAX(sm_rfm_othr_chanl_scrval) AS sm_rfm_othr_chanl_scrval,
    MAX(sm_rfm_lst_dntn_dt_scrval) AS sm_rfm_lst_dntn_dt_scrval,
    MAX(sm_rfm_lftm_dntn_cnt_scrval) AS sm_rfm_lftm_dntn_cnt_scrval,
    MAX(sm_rfm_lftm_dntn_amt_scrval) AS sm_rfm_lftm_dntn_amt_scrval,
    MAX(sm_rfm_max_dntn_amt_scrval) AS sm_rfm_max_dntn_amt_scrval
FROM
    mods_bi.mktg_ops_tbls.bzf_cnst_scr_simio
GROUP BY
    cnst_mstr_id
WITH NO SCHEMA BINDING;