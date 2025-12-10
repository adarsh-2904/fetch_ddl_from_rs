CREATE OR REPLACE VIEW mktg_ops_vws.gms_arc_fr_smry AS
SELECT
a.cnst_mstr_id, cnst_hsld_id, fr_fst_dntn_dt, 
		a.fr_last_dntn_dt, a.fr_last_dntn_amt, 
		lgd.txn_last_dntn_dt, lgd.txn_last_dntn_amt, 
		fr_last_ta_acct_id, Loyalty_Scr, unit_key,
		affl_lock_ind, sf_acct_fmd_ind, ta_acct_fmd_ind, fr_last_non_distr_dntn_dt,
		fr_last_non_distr_dntn_amt, fr_last_distr_dntn_dt, fr_last_distr_dntn_amt,
		fr_lftm_dntn_amt, fr_lftm_dntn_cnt, fr_lftm_max_dntn_amt, fr_lftm_min_dntn_amt,
		fr_lftm_avg_dntn_amt, fr_lftm_mjr_dntn_cnt, fr_lftm_mjr_dntn_amt,
		fr_last_mjr_dntn_dt, fr_last_mjr_dntn_amt, fr_lftm_midr_dntn_cnt,
		fr_lftm_midr_dntn_amt, fr_last_midr_dntn_dt, fr_last_midr_dntn_amt,
		fr_lftm_mnr_dntn_cnt, fr_lftm_mnr_dntn_amt, fr_last_mnr_dntn_dt,
		fr_last_mnr_dntn_amt, fr_susdnr_ind, fr_susdnr_determination_dt,
		fr_last_susdnrdntn_dt, fr_avg_susdnrdntn_amt, fr_cfym0_dntn_cnt,
		fr_cfym1_dntn_cnt, fr_cfym2_dntn_cnt, fr_cfym3_dntn_cnt, fr_cfym4_dntn_cnt,
		fr_cfym5_dntn_cnt, fr_cfym0_dntn_amt, fr_cfym1_dntn_amt, fr_cfym2_dntn_amt,
		fr_cfym3_dntn_amt, fr_cfym4_dntn_amt, fr_cfym5_dntn_amt, fr_cfym0_avg_dntn_amt,
		fr_cfym0_mjr_dntn_cnt, fr_cfym0_mjr_dntn_amt, fr_cfym0_midr_dntn_cnt,
		fr_cfym0_midr_dntn_amt, fr_cfym0_mnr_dntn_cnt, fr_cfym0_mnr_dntn_amt,
		fr_cfym0_max_dntn_amt, fr_cfym0_min_dntn_amt, fr_cfym0_last_susdnrdntn_dt,
		fr_cfym0_last_email_dntn_dt, fr_cfym0_email_dntns_cnt, fr_cfym0_avg_email_dntn_amt,
		fr_cfym0_last_oln_dntn_dt, fr_cfym0_oln_dntns_cnt, fr_cfym0_avg_oln_dntn_amt,
		fr_cfym0_last_txt_dntn_dt, fr_cfym0_txt_dntns_cnt, fr_cfym0_avg_txt_dntn_amt,
		fr_cfym0_last_phn_dntn_dt, fr_cfym0_phn_dntns_cnt, fr_cfym0_avg_phn_dntn_amt,
		fr_cfym0_last_dm_dntn_dt, fr_cfym0_dm_dntns_cnt, fr_cfym0_avg_dm_dntn_amt,
		fr_cfym0_last_othr_dntn_dt, fr_cfym0_othr_dntns_cnt, fr_cfym0_avg_othr_dntn_amt,
		fr_cfym0_lstavg_susdnrdntn_amt, fr_cfym1_avg_dntn_amt, fr_cfym1_mjr_dntn_cnt,
		fr_cfym1_mjr_dntn_amt, fr_cfym1_midr_dntn_cnt, fr_cfym1_midr_dntn_amt,
		fr_cfym1_mnr_dntn_cnt, fr_cfym1_mnr_dntn_amt, fr_cfym1_max_dntn_amt,
		fr_cfym1_min_dntn_amt, fr_cfym1_last_susdnrdntn_dt, fr_cfym1_last_email_dntn_dt,
		fr_cfym1_email_dntns_cnt, fr_cfym1_avg_email_dntn_amt, fr_cfym1_last_oln_dntn_dt,
		fr_cfym1_oln_dntns_cnt, fr_cfym1_avg_oln_dntn_amt, fr_cfym1_last_txt_dntn_dt,
		fr_cfym1_txt_dntns_cnt, fr_cfym1_avg_txt_dntn_amt, fr_cfym1_last_phn_dntn_dt,
		fr_cfym1_phn_dntns_cnt, fr_cfym1_avg_phn_dntn_amt, fr_cfym1_last_dm_dntn_dt,
		fr_cfym1_dm_dntns_cnt, fr_cfym1_avg_dm_dntn_amt, fr_cfym1_last_othr_dntn_dt,
		fr_cfym1_othr_dntns_cnt, fr_cfym1_avg_othr_dntn_amt, fr_cfym1_lstavg_susdnrdntn_amt,
		fr_cfym2_avg_dntn_amt, fr_cfym2_mjr_dntn_cnt, fr_cfym2_mjr_dntn_amt,
		fr_cfym2_midr_dntn_cnt, fr_cfym2_midr_dntn_amt, fr_cfym2_mnr_dntn_cnt,
		fr_cfym2_mnr_dntn_amt, fr_cfym2_last_susdnrdntn_dt, fr_cfym2_max_dntn_amt,
		fr_cfym2_min_dntn_amt, fr_cfym2_last_email_dntn_dt, fr_cfym2_email_dntns_cnt,
		fr_cfym2_avg_email_dntn_amt, fr_cfym2_last_oln_dntn_dt, fr_cfym2_oln_dntns_cnt,
		fr_cfym2_avg_oln_dntn_amt, fr_cfym2_last_txt_dntn_dt, fr_cfym2_txt_dntns_cnt,
		fr_cfym2_avg_txt_dntn_amt, fr_cfym2_last_phn_dntn_dt, fr_cfym2_phn_dntns_cnt,
		fr_cfym2_avg_phn_dntn_amt, fr_cfym2_last_dm_dntn_dt, fr_cfym2_dm_dntns_cnt,
		fr_cfym2_avg_dm_dntn_amt, fr_cfym2_last_othr_dntn_dt, fr_cfym2_othr_dntns_cnt,
		fr_cfym2_avg_othr_dntn_amt, fr_cfym2_lstavg_susdnrdntn_amt, last_tifny_crcle_dntn_dt,
		last_tifny_crcle_dntn_amt, last_hmntrn_crcle_dntn_dt, last_hmntrn_crcle_dntn_amt,
		last_arc_ldrshp_scty_dntn_dt, last_arc_ldrshp_scty_dntn_amt,
		last_presdnts_cncl_donaton_dt, last_presdnts_cncl_dntn_amt, last_chrmn_cncl_dntn_dt,
		last_chrmn_cncl_dntn_amt, mjr_gift_stat_cd, last_mjr_gift_dt,
		fr_distr_dnr_ind, hi_need_dnr_ind, chpt_only_dnr_ind, thrd_prty_dntn_ind,
		thrd_prty_dntn_cnt, thrd_prty_dntn_avg_amt, last_thrd_prty_dntn_gift_dt,
		fr_hldy_campgn_dnr_ind, fr_hldy_dnr_ind, fr_yr_end_dnr_ind, fr_opt_out_dnr_ind,
		fr_cfym0_last_susdnrdntn_amt, fr_cfym1_last_susdnrdntn_amt, fr_cfym2_last_susdnrdntn_amt,
		dm_mth_appeal_prefnc_ind, fr_ry0_dntn_cnt, fr_ry1_dntn_cnt, fr_ry0_dntn_amt,
		fr_ry1_dntn_amt, fr_ry0_avg_dntn_amt, fr_ry1_avg_dntn_amt, fr_ry0_mjr_dntn_cnt,
		fr_ry1_mjr_dntn_cnt, fr_ry0_mjr_dntn_amt, fr_ry1_mjr_dntn_amt,
		fr_ry0_midr_dntn_cnt, fr_ry1_midr_dntn_cnt, fr_ry0_midr_dntn_amt,
		fr_ry1_midr_dntn_amt, fr_ry0_mnr_dntn_cnt, fr_ry1_mnr_dntn_cnt,
		fr_ry0_mnr_dntn_amt, fr_ry1_mnr_dntn_amt, fr_ry0_max_dntn_amt,
		fr_ry1_max_dntn_amt, fr_ry0_min_dntn_amt, fr_ry1_min_dntn_amt,
		fr_ry0_last_susdnrdntn_dt, fr_ry1_last_susdnrdntn_dt, fr_ry0_last_email_dntn_dt,
		fr_ry1_last_email_dntn_dt, fr_ry0_email_dntns_cnt, fr_ry1_email_dntns_cnt,
		fr_ry0_avg_email_dntn_amt, fr_ry1_avg_email_dntn_amt, fr_ry0_last_oln_dntn_dt,
		fr_ry1_last_oln_dntn_dt, fr_ry0_oln_dntns_cnt, fr_ry1_oln_dntns_cnt,
		fr_ry0_avg_oln_dntn_amt, fr_ry1_avg_oln_dntn_amt, fr_ry0_last_txt_dntn_dt,
		fr_ry1_last_txt_dntn_dt, fr_ry0_txt_dntns_cnt, fr_ry1_txt_dntns_cnt,
		fr_ry0_avg_txt_dntn_amt, fr_ry1_avg_txt_dntn_amt, fr_ry0_last_phn_dntn_dt,
		fr_ry1_last_phn_dntn_dt, fr_ry0_phn_dntns_cnt, fr_ry1_phn_dntns_cnt,
		fr_ry0_avg_phn_dntn_amt, fr_ry1_avg_phn_dntn_amt, fr_ry0_last_dm_dntn_dt,
		fr_ry1_last_dm_dntn_dt, fr_ry0_dm_dntns_cnt, fr_ry1_dm_dntns_cnt,
		fr_ry0_avg_dm_dntn_amt, fr_ry1_avg_dm_dntn_amt, fr_ry0_last_othr_dntn_dt,
		fr_ry1_last_othr_dntn_dt, fr_ry0_othr_dntns_cnt, fr_ry1_othr_dntns_cnt,
		fr_ry0_avg_othr_dntn_amt, fr_ry1_avg_othr_dntn_amt, fr_ry0_lstavg_susdnrdntn_amt,
		fr_ry1_lstavg_susdnrdntn_amt, fr_first_dntn_fund_key, fr_first_dntn_fund_cd,
		fr_latest_dntn_fund_key, fr_latest_dntn_fund_cd, fr_max_dntn_fund_key,
		fr_max_dntn_fund_cd, fr_min_dntn_fund_key, fr_min_dntn_fund_cd,
		portfolio_category, 
		cb_re_engmnt_flg, 
		CASE WHEN cbg_eligblty_cym2_dt IS NOT NULL AND cbg_eligblty_cym1_dt IS NULL THEN 'Y' ELSE 'N' end  AS cbg_re_engmnt_flg, 
		fr_cym0_dntn_cnt, fr_cym0_dntn_amt,
		fr_cym1_dntn_cnt, fr_cym1_dntn_amt, fr_cym2_dntn_cnt, fr_cym2_dntn_amt,
		cb_eligblty_ind, cb_eligblty_cym0_dt, cb_eligblty_cym1_dt, cb_eligblty_cym2_dt,
		COALESCE(CASE WHEN cbg_eligblty_cym0_dt IS NOT NULL THEN 1 ELSE 0 END, 0) AS cbg_eligblty_ind,
		cbg_eligblty_cym0_dt , 
		cbg_eligblty_cym1_dt  , 
		cbg_eligblty_cym2_dt  , 		
		fr_first_dntn_typ, fr_first_comnictn_src_cd, fr_first_dntn_dt,
		fr_first_dntn_fcc_cd, fr_first_dntn_amt, fr_first_dstr_comnictn_src_cd,
		fr_first_dstr_dntn_fund_cd, fr_first_dstr_dntn_dt, fr_first_dstr_dntn_fcc_cd,
		fr_first_dstr_dntn_amt, fr_first_non_distr_comn_src_cd, fr_first_non_distr_dntn_fnd_cd,
		fr_first_non_distr_dntn_dt, fr_first_non_distr_dntn_fcc_cd, fr_first_non_distr_dntn_amt,
		CASE WHEN cb_eligblty_cym0_dt IS NOT NULL THEN 1 ELSE 0 end AS fr_cym0_cb_ind,
		CASE WHEN cb_eligblty_cym1_dt IS NOT NULL THEN 1 ELSE 0 end AS fr_cym1_cb_ind,
		CASE WHEN cb_eligblty_cym2_dt IS NOT NULL THEN 1 ELSE 0 end AS fr_cym2_cb_ind,
		CASE WHEN cbg_eligblty_cym0_dt IS NOT NULL THEN 1 ELSE 0 END AS fr_cym0_cbg_ind,
		CASE WHEN cbg_eligblty_cym1_dt IS NOT NULL THEN 1 ELSE 0 END AS fr_cym1_cbg_ind,
		CASE WHEN cbg_eligblty_cym2_dt IS NOT NULL THEN 1 ELSE 0 END AS fr_cym2_cbg_ind,
		CASE WHEN fr_cfym0_dntn_amt >= 2500 THEN 1 ELSE 0 end AS fr_cfym0_major_donor_ind,
		CASE WHEN fr_cfym1_dntn_amt >= 2500 THEN 1 ELSE 0 end AS fr_cfym1_major_donor_ind,
		CASE WHEN fr_cfym2_dntn_amt >= 2500 THEN 1 ELSE 0 end AS fr_cfym2_major_donor_ind,
		CASE WHEN fr_cfym3_dntn_amt >= 2500 THEN 1 ELSE 0 end AS fr_cfym3_major_donor_ind,
		CASE WHEN fr_cfym4_dntn_amt >= 2500 THEN 1 ELSE 0 end AS fr_cfym4_major_donor_ind,
		CASE WHEN fr_cfym5_dntn_amt >= 2500 THEN 1 ELSE 0 end AS fr_cfym5_major_donor_ind,	
		CASE WHEN fr_last_non_distr_dntn_dt >= Add_Months(Current_Date,-24) AND fr_last_non_distr_dntn_amt BETWEEN 500.00 AND 999.99 THEN 1 ELSE 0 end AS high_core_ind,
		CASE WHEN fr_last_non_distr_dntn_dt >= Add_Months(Current_Date,-24) AND fr_last_non_distr_dntn_amt BETWEEN 100.00 AND 499.99 THEN 1 ELSE 0 end AS mid_core_ind,
		CASE WHEN fr_last_non_distr_dntn_dt >= Add_Months(Current_Date,-24) AND fr_last_non_distr_dntn_amt BETWEEN 10.00 AND 99.99 THEN 1 ELSE 0 end AS low_core_ind,
		CASE WHEN  fr_last_non_distr_dntn_dt >= Add_Months(Current_Date,-24) AND fr_last_non_distr_dntn_amt BETWEEN 500.00 AND 999.99 THEN 'High Core'
				WHEN fr_last_non_distr_dntn_dt >= Add_Months(Current_Date,-24) AND fr_last_non_distr_dntn_amt BETWEEN 100.00 AND 499.99 THEN 'Mid Core'
				WHEN fr_last_non_distr_dntn_dt >= Add_Months(Current_Date,-24) AND fr_last_non_distr_dntn_amt BETWEEN 10.00 AND 99.99 THEN 'Low core'
				WHEN cb_eligblty_cym0_dt IS NOT NULL AND fr_cfym0_dntn_amt BETWEEN 1000.00 AND 9999.99 THEN 'Clara Barton CY0'
				WHEN cb_eligblty_cym1_dt IS NOT NULL AND fr_cfym1_dntn_amt BETWEEN 1000.00 AND 9999.99 THEN 'Clara Barton CY1'
				ELSE 'Other'
		end AS dm_segment_dsc,
		a.benevity_gift_cnt, a.benevity_suprsn_ind, 
		dw_trans_ts, appl_src_cd, load_id
FROM mktg_ops_tbls.gms_arc_fr_smry a
LEFT JOIN mktg_ops_tbls.gms_arc_fr_smry_cbg b 
    ON a.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN (
    SELECT cnst_mstr_id, dntn_gift_dt AS txn_last_dntn_dt, 
           SUM(fr_pmt_amt) AS txn_last_dntn_amt
    FROM (
        SELECT cnst_mstr_id, dntn_gift_dt, fr_pmt_amt,
               ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY dntn_gift_dt DESC) AS rn
        FROM mktg_ops_vws.gms_arc_fr_txn
        WHERE fr_pmt_amt > 0
    ) ranked_txns
    WHERE rn = 1
    GROUP BY cnst_mstr_id, dntn_gift_dt
) lgd 
    ON a.cnst_mstr_id = lgd.cnst_mstr_id		
		WITH NO SCHEMA BINDING;