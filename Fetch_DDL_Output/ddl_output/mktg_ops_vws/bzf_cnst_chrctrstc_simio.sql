CREATE OR REPLACE VIEW mktg_ops_vws.bzf_cnst_chrctrstc_simio AS 
-- drop view mktg_ops_vws.bzf_cnst_chrctrstc_simio

CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.bzf_cnst_chrctrstc_simio
/*
Create Date: 5/3/2023
Created By: Majeed Mohammad
Purpose:  This view read the simio append data table mktg_ops_tbls.bzfc_cnst_chrctrstc_simio

Modified Date: 5/4/2023
Modified By: Majeed Mohammad
Purpose:  Renamed the view and underlying table as mktg_ops_tbls.bzf_cnst_chrctrstc_simio

Modified Date: 6/8/2023
Modified By: Majeed Mohammad
Purpose:  Removed the columns LOB and batch_num 

Modified Date: 10/19/2023
Modified By: Michael Andrien
Purpose: Added the Qualify statement to eliminate duplicate master id rows.

Modified Date: 10/25/2023
Modified By: Majeed Mohammad 
Purpose: Added the orig_cnst_mstr_id to the SELECT and also added the orig_cnst_mstr_id to the partition statement

Modified Date: 10/30/2024
Modified By: Majeed Mohammad 
Purpose: Added the below new columns to the view. 
							hh_membr_boat_yacht_club
							wealth_scr
							community_charty_ind 
							interest_mil_hist_flg  
							buy_actvty_weeks_since_lst_any_ordr
							buy_actvty_weeks_since_lst_offln_ordr
							buy_actvty_weeks_since_lst_onln_ordr
							buy_actvty_num_ordrs_cash
							buy_actvty_num_ordrs_cc
							buy_actvty_purchsd_dec 
							buy_actvty_total_offln_ordrs_500_999
							buy_actvty_total_offln_ordrs_1k_pls
							buy_actvty_total_onln_ordrs_under_50
							buy_actvty_total_onln_ordrs_1k_pls
							wealth_scr_segmnt
							consumr_prominence_prsn_scr
							income_scr 
							cable_tv_intrnt_scr
							heavy_transctrs_scr

Modified Date: 11/01/2024
Modified By: Majeed Mohammad 
Purpose:  Added a CASE statement to the column 	interest_mil_hist_flg				

Modified Date: 11/20/2024
Modified By: Majeed Mohammad 
Purpose:  		Refreshed the view based on the new columns added. Also, removed the CASE statement for the column 	interest_mil_hist_flg		

Modified Date: 8/29/2025
Modified By: Majeed Mohammad 
Purpose:  Updated to add the new columns pets_owner_dog_ind, exercise_walking_ind and remove the outdated columns buy_actvty_total_onln_ordrs_under_50  , buy_actvty_total_offln_ordrs_500_999
*/
AS
WITH ranked_data AS (
    SELECT *, 
        ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY dw_trans_ts DESC, orig_cnst_mstr_id DESC) AS rn
    FROM mods_bi.mktg_ops_tbls.bzf_cnst_chrctrstc_simio
)
SELECT 
    cnst_mstr_id, orig_cnst_mstr_id, hh_la_id, dm_cnst_prsn_prfx_nm,
    dm_cnst_prsn_f_nm, dm_cnst_prsn_m_nm, dm_cnst_prsn_l_nm, dm_cnst_prsn_suffix_nm,
    dm_cnst_line_1_addr, dm_cnst_line_2_addr, dm_cnst_city_nm, dm_cnst_st_cd,
    dm_cnst_zip_5_cd, dm_cnst_zip_4_cd, lst_arc_patrng_dt, cnst_start_dt,
    run_ts, updated_set, address2, city, state, simio_individual_id,
    pid, file_nm, eductn_cd, home_loan_yr, home_loan_typ_cd, home_loan_to_val_cd,
    home_val_decile, home_insrnc_exp_dt_mth, home_sq_ft_cd, home_built_yr,
    invest_resdntl_proprty_cnt, marital_stat_cd, hh_net_worth_cd,
    lines_of_credit_cnt, occuptn_cd, discrtnry_spend_intl_travl,
    dntn_contrbtn_ind, mail_ordr_buyr_cd, onln_purchs_flg, boat_insrnc_scr,
    satellite_tv_scr, cable_tv_scr, num_ordrs_lwscl_catlg_cd, avg_offln_prch_amt_cd,
    prchs_decmbr_amt_cd, offln_amt_cd, num_ordrs_offln_500_999_cd,
    num_ordrs_offln_1k_pls_cd, avg_onln_prch_amt_cd, num_ordrs_onln_50_under_cd,
    num_ordrs_onln_1k_pls_cd, lst_onln_ordr_num_wks, lst_any_ordr_num_wks,
    vhcl_yr, cause_suprtd_chartbl_ind, cause_suprtd_intl_aid_ind,
    religion_dsc, poltcl_party_dsc, gender_cd, adult_age_18_24_ml_ind,
    adult_age_18_24_fml_ind, adult_age_18_24_unk_ind, adult_age_25_34_ml_ind,
    adult_age_25_34_fml_ind, adult_age_25_34_unk_ind, adult_age_35_44_ml_ind,
    adult_age_35_44_fml_ind, adult_age_35_44_unk_ind, adult_age_45_54_ml_ind,
    adult_age_45_54_fml_ind, adult_age_45_54_unk_ind, adult_age_55_64_ml_ind,
    adult_age_55_64_fml_ind, adult_age_55_64_unk_ind, adult_age_65_74_ml_ind,
    adult_age_65_74_fml_ind, adult_age_65_74_unk_ind, adult_age_75_pls_ml_ind,
    adult_age_75_pls_fml_ind, adult_age_75_pls_unk_ind, child_age_00_02_ml_ind,
    child_age_00_02_fml_ind, child_age_00_02_unk_ind, child_age_03_05_ml_ind,
    child_age_03_05_fml_ind, child_age_03_05_unk_ind, child_age_06_10_ml_ind,
    child_age_06_10_fml_ind, child_age_06_10_unk_ind, child_age_11_15_ml_ind,
    child_age_11_15_fml_ind, child_age_11_15_unk_ind, child_age_16_17_ml_ind,
    child_age_16_17_fml_ind, child_age_16_17_unk_ind, birth_dt_yr,
    country_of_origin_cd, travl_ind, hh_size, hh_num_childrn, senior_adult_in_hh_flg,
    hisp_lang_pref_cd, prem_credit_card_ind, invest_prsnl_ind, invest_re_ind,
    invest_stock_ind, invest_any_past_12_mths_scr, invest_stock_past_12_mths_scr,
    likely_investr_flg, econmc_stablty_scr, veteran_ind, dwelng_typ_cd,
    home_length_resdnce, home_val_cd, home_ownr_rentr_cd, home_purchs_dt_yyyymm,
    video_games_ind, grandchild_ind, travl_cruise_ind, travl_domstc_ind,
    avg_poltcl_contrbtn_amt, race_cd, mail_ordr_dnr_cd, pmt_mthd_cash_amt,
    pmt_mthd_cc_amt, num_ordrs_offln_cd, lst_offln_ordr_num_wks,
    votng_freq_cd, gen_electn_votr_ind, birth_dt_mth, occuptn_dtl_cd,
    hh_income_cd, home_purchs_dt_rp_yyyymm, num_ordrs_upscl_catlg_cd,
    home_eqty_amt_cd, home_loan_amt_cd, collctbls_antqs_ind, hh_membr_boat_yacht_club,
    wealth_scr, community_charty_ind, interest_mil_hist_flg, buy_actvty_weeks_since_lst_any_ordr,
    buy_actvty_weeks_since_lst_offln_ordr, buy_actvty_weeks_since_lst_onln_ordr,
    buy_actvty_num_ordrs_cash, buy_actvty_num_ordrs_cc, buy_actvty_purchsd_dec,
    buy_actvty_total_offln_ordrs_500_999, buy_actvty_total_offln_ordrs_1k_pls,
    buy_actvty_total_onln_ordrs_under_50, buy_actvty_total_onln_ordrs_1k_pls,
    wealth_scr_segmnt, consumr_prominence_prsn_scr, income_scr, cable_tv_intrnt_scr,
    heavy_transctrs_scr, dw_trans_ts, row_stat_cd, appl_src_cd, load_id
FROM ranked_data
WHERE rn = 1
WITH NO SCHEMA BINDING;