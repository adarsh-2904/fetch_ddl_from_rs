CREATE OR REPLACE VIEW mktg_ops_vws.gms_arc_fr_smry_sustnr
AS
SELECT
    cnst_mstr_id, 
    cy0_year_dsc, 
    cy0_first_offline_sustnr_gift_dt,
    cy0_last_offline_sustnr_gift_dt, 
    cy0_offline_sustnr_gift_cnt,
    cy0_offline_sustnr_gift_amt, 
    cy1_year_dsc, 
    cy1_first_offline_sustnr_gift_dt,
    cy1_last_offline_sustnr_gift_dt, 
    cy1_offline_sustnr_gift_cnt,
    cy1_offline_sustnr_gift_amt, 
    cy2_year_dsc, 
    cy2_first_offline_sustnr_gift_dt,
    cy2_last_offline_sustnr_gift_dt, 
    cy2_offline_sustnr_gift_cnt,
    cy2_offline_sustnr_gift_amt, 
    cy0_first_online_sustnr_gift_dt,
    cy0_last_online_sustnr_gift_dt, 
    cy0_online_sustnr_gift_cnt, 
    cy0_online_sustnr_gift_amt,
    cy1_first_online_sustnr_gift_dt, 
    cy1_last_online_sustnr_gift_dt,
    cy1_online_sustnr_gift_cnt, 
    cy1_online_sustnr_gift_amt, 
    cy2_first_online_sustnr_gift_dt,
    cy2_last_online_sustnr_gift_dt, 
    cy2_online_sustnr_gift_cnt, 
    cy2_online_sustnr_gift_amt,
    cy0_first_phone_sustnr_gift_dt, 
    cy0_last_phone_sustnr_gift_dt,
    cy0_phone_sustnr_gift_cnt, 
    cy0_phone_sustnr_gift_amt, 
    cy1_first_phone_sustnr_gift_dt,
    cy1_last_phone_sustnr_gift_dt, 
    cy1_phone_sustnr_gift_cnt, 
    cy1_phone_sustnr_gift_amt,
    cy2_first_phone_sustnr_gift_dt, 
    cy2_last_phone_sustnr_gift_dt,
    cy2_phone_sustnr_gift_cnt, 
    cy2_phone_sustnr_gift_amt, 
    cy0_first_othr_sustnr_gift_dt,
    cy0_last_othr_sustnr_gift_dt, 
    cy0_othr_sustnr_gift_cnt, 
    cy0_othr_sustnr_gift_amt,
    cy1_first_othr_sustnr_gift_dt, 
    cy1_last_othr_sustnr_gift_dt,
    cy1_othr_sustnr_gift_cnt, 
    cy1_othr_sustnr_gift_amt, 
    cy2_first_othr_sustnr_gift_dt,
    cy2_last_othr_sustnr_gift_dt, 
    cy2_othr_sustnr_gift_cnt, 
    cy2_othr_sustnr_gift_amt,
    cy0_first_f2f_sustnr_gift_dt, 
    cy0_last_f2f_sustnr_gift_dt, 
    cy0_f2f_sustnr_gift_cnt,
    cy0_f2f_sustnr_gift_amt, 
    cy1_first_f2f_sustnr_gift_dt, 
    cy1_last_f2f_sustnr_gift_dt,
    cy1_f2f_sustnr_gift_cnt, 
    cy1_f2f_sustnr_gift_amt, 
    cy2_first_f2f_sustnr_gift_dt,
    cy2_last_f2f_sustnr_gift_dt, 
    cy2_f2f_sustnr_gift_cnt, 
    cy2_f2f_sustnr_gift_amt,
    cy0_offline_sustainer_ind, 
    cy0_offline_sustainer_flg, 
    cy1_offline_sustainer_ind,
    cy1_offline_sustainer_flg, 
    cy2_offline_sustainer_ind, 
    cy2_offline_sustainer_flg,
    cy0_online_sustainer_ind, 
    cy0_online_sustainer_flg, 
    cy1_online_sustainer_ind,
    cy1_online_sustainer_flg, 
    cy2_online_sustainer_ind, 
    cy2_online_sustainer_flg,
    cy0_phone_sustainer_ind, 
    cy0_phone_sustainer_flg, 
    cy1_phone_sustainer_ind,
    cy1_phone_sustainer_flg, 
    cy2_phone_sustainer_ind, 
    cy2_phone_sustainer_flg,
    cy0_othr_sustainer_ind, 
    cy0_othr_sustainer_flg, 
    cy1_othr_sustainer_ind,
    cy1_othr_sustainer_flg, 
    cy2_othr_sustainer_ind, 
    cy2_othr_sustainer_flg,
    cy0_f2f_sustainer_ind, 
    cy0_f2f_sustainer_flg, 
    cy1_f2f_sustainer_ind,
    cy1_f2f_sustainer_flg, 
    cy2_f2f_sustainer_ind, 
    cy2_f2f_sustainer_flg,
    current_sustnr_ind, 
    cy0_sustainer_ind, 
    cy1_sustainer_ind, 
    cy2_sustainer_ind,
    first_sustnr_dt, 
    first_sustnr_gift_amt, 
    last_sustnr_dt, 
    last_sustnr_gift_amt
FROM mktg_ops_tbls.gms_arc_fr_smry_sustnr
with no schema binding;