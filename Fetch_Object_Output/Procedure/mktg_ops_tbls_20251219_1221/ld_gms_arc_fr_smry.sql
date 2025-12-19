CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_arc_fr_smry()
 LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_gms_arc_fr_smry', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.gms_arc_fr_smry_stg;
		
		DROP TABLE IF EXISTS temp_gift_years;

		CREATE TEMP TABLE temp_gift_years AS
		SELECT 
			cnst_mstr_id,
			cnst_hsld_id,
			dntn_gift_dt,
			EXTRACT(year FROM dntn_gift_dt) AS gift_year,
			fr_pmt_amt
		FROM mktg_ops_vws.gms_arc_fr_txn
		WHERE EXTRACT(year FROM dntn_gift_dt) BETWEEN (EXTRACT(year FROM CURRENT_DATE)-2) AND EXTRACT(year FROM CURRENT_DATE);
		
		
		INSERT INTO mktg_stage_tbls.gms_arc_fr_smry_stg(
			cnst_mstr_id
			,cnst_hsld_id
			,fr_fst_dntn_dt
			,fr_last_dntn_dt
			,fr_last_dntn_amt
			,fr_last_ta_acct_id
			,Loyalty_Scr
			,unit_key
			,affl_lock_ind
			,sf_acct_fmd_ind
			,ta_acct_fmd_ind
			,fr_last_non_distr_dntn_dt
			,fr_last_non_distr_dntn_amt
			,fr_last_distr_dntn_dt
			,fr_last_distr_dntn_amt
			,fr_lftm_dntn_amt
			,fr_lftm_dntn_cnt
			,fr_lftm_max_dntn_amt
			,fr_lftm_min_dntn_amt
			,fr_lftm_avg_dntn_amt
			,fr_lftm_mjr_dntn_cnt
			,fr_lftm_mjr_dntn_amt
			,fr_last_mjr_dntn_dt
			,fr_last_mjr_dntn_amt
			,fr_lftm_midr_dntn_cnt
			,fr_lftm_midr_dntn_amt
			,fr_last_midr_dntn_dt
			,fr_last_midr_dntn_amt
			,fr_lftm_mnr_dntn_cnt
			,fr_lftm_mnr_dntn_amt
			,fr_last_mnr_dntn_dt
			,fr_last_mnr_dntn_amt
			,fr_cfym0_dntn_cnt
			,fr_cfym1_dntn_cnt
			,fr_cfym2_dntn_cnt
			,fr_cfym3_dntn_cnt
			,fr_cfym4_dntn_cnt
			,fr_cfym5_dntn_cnt
			,fr_cfym0_dntn_amt
			,fr_cfym1_dntn_amt
			,fr_cfym2_dntn_amt
			,fr_cfym3_dntn_amt
			,fr_cfym4_dntn_amt
			,fr_cfym5_dntn_amt
			,fr_cfym0_avg_dntn_amt
			,fr_cfym0_mjr_dntn_cnt
			,fr_cfym0_mjr_dntn_amt
			,fr_cfym0_midr_dntn_cnt
			,fr_cfym0_midr_dntn_amt
			,fr_cfym0_mnr_dntn_cnt
			,fr_cfym0_mnr_dntn_amt
			,fr_cfym0_max_dntn_amt
			,fr_cfym0_min_dntn_amt
			,fr_cfym0_last_email_dntn_dt
			,fr_cfym0_email_dntns_cnt
			,fr_cfym0_avg_email_dntn_amt
			,fr_cfym0_last_oln_dntn_dt
			,fr_cfym0_oln_dntns_cnt
			,fr_cfym0_avg_oln_dntn_amt
			,fr_cfym0_last_phn_dntn_dt
			,fr_cfym0_phn_dntns_cnt
			,fr_cfym0_avg_phn_dntn_amt
			,fr_cfym0_last_dm_dntn_dt
			,fr_cfym0_dm_dntns_cnt
			,fr_cfym0_avg_dm_dntn_amt
			,fr_cfym1_avg_dntn_amt
			,fr_cfym1_mjr_dntn_cnt
			,fr_cfym1_mjr_dntn_amt
			,fr_cfym1_midr_dntn_cnt
			,fr_cfym1_midr_dntn_amt
			,fr_cfym1_mnr_dntn_cnt
			,fr_cfym1_mnr_dntn_amt
			,fr_cfym1_max_dntn_amt
			,fr_cfym1_min_dntn_amt
			,fr_cfym1_last_email_dntn_dt
			,fr_cfym1_email_dntns_cnt
			,fr_cfym1_avg_email_dntn_amt
			,fr_cfym1_last_oln_dntn_dt
			,fr_cfym1_oln_dntns_cnt
			,fr_cfym1_avg_oln_dntn_amt
			,fr_cfym1_last_phn_dntn_dt
			,fr_cfym1_phn_dntns_cnt
			,fr_cfym1_avg_phn_dntn_amt
			,fr_cfym1_last_dm_dntn_dt
			,fr_cfym1_dm_dntns_cnt
			,fr_cfym1_avg_dm_dntn_amt
			,fr_cfym2_avg_dntn_amt
			,fr_cfym2_mjr_dntn_cnt
			,fr_cfym2_mjr_dntn_amt
			,fr_cfym2_midr_dntn_cnt
			,fr_cfym2_midr_dntn_amt
			,fr_cfym2_mnr_dntn_cnt
			,fr_cfym2_mnr_dntn_amt
			,fr_cfym2_max_dntn_amt
			,fr_cfym2_min_dntn_amt
			,fr_cfym2_last_email_dntn_dt
			,fr_cfym2_email_dntns_cnt
			,fr_cfym2_avg_email_dntn_amt
			,fr_cfym2_last_oln_dntn_dt
			,fr_cfym2_oln_dntns_cnt
			,fr_cfym2_avg_oln_dntn_amt
			,fr_cfym2_last_phn_dntn_dt
			,fr_cfym2_phn_dntns_cnt
			,fr_cfym2_avg_phn_dntn_amt
			,fr_cfym2_last_dm_dntn_dt
			,fr_cfym2_dm_dntns_cnt
			,fr_cfym2_avg_dm_dntn_amt
			,last_tifny_crcle_dntn_dt
			,last_hmntrn_crcle_dntn_dt
			,last_arc_ldrshp_scty_dntn_dt
			,last_presdnts_cncl_donaton_dt
			,last_chrmn_cncl_dntn_dt
			,mjr_gift_stat_cd
			,dm_mth_appeal_prefnc_ind
			,fr_ry0_dntn_cnt
			,fr_ry1_dntn_cnt
			,fr_ry0_dntn_amt
			,fr_ry1_dntn_amt
			,fr_ry0_avg_dntn_amt
			,fr_ry1_avg_dntn_amt
			,fr_ry0_mjr_dntn_cnt
			,fr_ry1_mjr_dntn_cnt
			,fr_ry0_mjr_dntn_amt
			,fr_ry1_mjr_dntn_amt
			,fr_ry0_midr_dntn_cnt
			,fr_ry1_midr_dntn_cnt
			,fr_ry0_midr_dntn_amt
			,fr_ry1_midr_dntn_amt
			,fr_ry0_mnr_dntn_cnt
			,fr_ry1_mnr_dntn_cnt
			,fr_ry0_mnr_dntn_amt
			,fr_ry1_mnr_dntn_amt
			,fr_ry0_max_dntn_amt
			,fr_ry1_max_dntn_amt
			,fr_ry0_min_dntn_amt
			,fr_ry1_min_dntn_amt
			,fr_ry0_last_email_dntn_dt
			,fr_ry1_last_email_dntn_dt
			,fr_ry0_email_dntns_cnt
			,fr_ry1_email_dntns_cnt
			,fr_ry0_avg_email_dntn_amt
			,fr_ry1_avg_email_dntn_amt
			,fr_ry0_last_oln_dntn_dt
			,fr_ry1_last_oln_dntn_dt
			,fr_ry0_oln_dntns_cnt
			,fr_ry1_oln_dntns_cnt
			,fr_ry0_avg_oln_dntn_amt
			,fr_ry1_avg_oln_dntn_amt
			,fr_ry0_last_phn_dntn_dt
			,fr_ry1_last_phn_dntn_dt
			,fr_ry0_phn_dntns_cnt
			,fr_ry1_phn_dntns_cnt
			,fr_ry0_avg_phn_dntn_amt
			,fr_ry1_avg_phn_dntn_amt
			,fr_ry0_last_dm_dntn_dt
			,fr_ry1_last_dm_dntn_dt
			,fr_ry0_dm_dntns_cnt
			,fr_ry1_dm_dntns_cnt
			,fr_ry0_avg_dm_dntn_amt
			,fr_ry1_avg_dm_dntn_amt
			,fr_first_dntn_fund_key
			,fr_first_dntn_fund_cd
			,fr_latest_dntn_fund_key
			,fr_latest_dntn_fund_cd
			,fr_max_dntn_fund_key
			,fr_max_dntn_fund_cd
			,fr_min_dntn_fund_key
			,fr_min_dntn_fund_cd
			,portfolio_category
			,cb_re_engmnt_flg
			,fr_cym0_dntn_cnt
			,fr_cym0_dntn_amt
			,fr_cym1_dntn_cnt
			,fr_cym1_dntn_amt
			,fr_cym2_dntn_cnt
			,fr_cym2_dntn_amt
			,cb_eligblty_ind
			,cb_eligblty_cym0_dt
			,cb_eligblty_cym1_dt
			,cb_eligblty_cym2_dt
			,fr_first_dntn_typ
			,fr_first_comnictn_src_cd
			,fr_first_dntn_dt
			,fr_first_dntn_fcc_cd
			,fr_first_dntn_amt
			,fr_first_dstr_comnictn_src_cd
			,fr_first_dstr_dntn_fund_cd
			,fr_first_dstr_dntn_dt
			,fr_first_dstr_dntn_fcc_cd
			,fr_first_dstr_dntn_amt
			,fr_first_non_distr_comn_src_cd
			,fr_first_non_distr_dntn_fnd_cd
			,fr_first_non_distr_dntn_dt
			,fr_first_non_distr_dntn_fcc_cd
			,fr_first_non_distr_dntn_amt
			,benevity_gift_cnt
			,benevity_suprsn_ind
			,dw_trans_ts
			,appl_src_cd
			,load_id
		)

		WITH TRAN AS (
			SELECT
				NULL AS cnst_fsa_key,
				cnst_mstr_id,
				cnst_hsld_id,
				fr_pmt_amt,
				dntn_gift_dt,
				current_timestamp as dw_trans_ts,
				fr_distr_dntn_ind,
				gift_src_cd,
				fcc_key,
				trans_fund_cd,
				ta_acct_id,
				dim_giftran_key
			FROM mktg_ops_vws.gms_arc_fr_txn
		),

		/* contact_preference_filter AS (
		SELECT
			txn.cnst_mstr_id AS PM_A0,
			MAX(cnst_fsa_cntct_prefc.act_ind) AS PM_A1,
			MAX(txn.dw_trans_ts) AS PM_A2
		FROM TRAN txn
		LEFT JOIN ddcoe_vws.bz_cnst_fsa_cntct_prefc cnst_fsa_cntct_prefc
			ON cnst_fsa_cntct_prefc.cnst_fsa_key = txn.cnst_fsa_key
			AND (
				CASE 
					WHEN cnst_fsa_cntct_prefc.cntct_prefc_typ_cd IS NULL THEN NULL
					WHEN cnst_fsa_cntct_prefc.cntct_prefc_typ_cd IN (
						'APPEAL|OKAPR', 'APPEAL|OKAUG', 'APPEAL|OKDEC', 'APPEAL|OKFEB',
						'APPEAL|OKJAN', 'APPEAL|OKJUL', 'APPEAL|OKJUN', 'APPEAL|OKMAR',
						'APPEAL|OKMAY', 'APPEAL|OKNOV', 'APPEAL|OKOCT', 'APPEAL|OKSEP'
					) THEN 1
					ELSE 0
				END <> 0
			)
		GROUP BY txn.cnst_mstr_id
		) */

		-- Simplified contact_preference_filter CTE by removing:
		-- 1. LEFT JOIN to bz_cnst_fsa_cntct_prefc and related logic
		-- 2. PM_A1 column (MAX(act_ind)) as it's unused in final output
		-- Core functionality (PM_A0 and PM_A2) remains unchanged 

		contact_preference_filter AS (
		SELECT
			txn.cnst_mstr_id AS PM_A0,
			MAX(txn.dw_trans_ts) AS PM_A2
		FROM TRAN txn
		GROUP BY txn.cnst_mstr_id
		),

		constituency_base AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				MAX(NULL) AS PM_A1,
				MAX(NULL) AS PM_A2,
				MAX(NULL) AS PM_A3,
				MAX(NULL) AS PM_A4,
				MAX(NULL) AS PM_A5
			FROM mktg_ops_vws.gms_bzf_cnst_cnstcy 
			GROUP BY cnst_mstr_id
		),


		/* donations_over_1_million AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN (fr_pmt_amt >= 1000000) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN (fr_pmt_amt >= 1000000) THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN (fr_pmt_amt >= 1000000) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		), */

		/* donations_over_100k	 AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN (fr_pmt_amt >= 100000) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN (fr_pmt_amt >= 100000) THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn 
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN (fr_pmt_amt >= 100000) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		), */


		/* donations_25k_to_100k AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN ((fr_pmt_amt >= 25000) AND (fr_pmt_amt < 100000)) 
					  THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN ((fr_pmt_amt >= 25000) AND (fr_pmt_amt < 100000)) 
					THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN ((fr_pmt_amt >= 25000) AND (fr_pmt_amt < 100000)) 
					  THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		), */

		/* donations_10k_to_25k AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN ((fr_pmt_amt >= 10000) AND (fr_pmt_amt < 25000)) 
					  THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN ((fr_pmt_amt >= 10000) AND (fr_pmt_amt < 25000)) 
					THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN ((fr_pmt_amt >= 10000) AND (fr_pmt_amt < 25000)) 
					  THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		), */

		donations_over_10k AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN (fr_pmt_amt >= 10000) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN (fr_pmt_amt >= 10000) THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN (fr_pmt_amt >= 10000) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		),

		non_disaster_donations AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN (fr_distr_dntn_ind = 0) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN (fr_distr_dntn_ind = 0) THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN (fr_distr_dntn_ind = 0) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		),

		disaster_donations AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN (fr_distr_dntn_ind = 1) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN (fr_distr_dntn_ind = 1) THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN (fr_distr_dntn_ind = 1) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		),

		donations_under_100 AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN (fr_pmt_amt < 100) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN (fr_pmt_amt < 100) THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN (fr_pmt_amt < 100) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		),

		donations_100_to_1k AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN ((fr_pmt_amt >= 100) AND (fr_pmt_amt < 1000)) 
					  THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN ((fr_pmt_amt >= 100) AND (fr_pmt_amt < 1000)) 
					THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id, 
					 (CASE WHEN ((fr_pmt_amt >= 100) AND (fr_pmt_amt < 1000)) 
					  THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		),

		donations_over_1k AS (
			SELECT
				cnst_mstr_id AS PM_A0,
				(CASE WHEN (fr_pmt_amt >= 1000) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END) AS PM_A1,
				SUM((CASE WHEN (fr_pmt_amt >= 1000) THEN fr_pmt_amt ELSE NULL END)) AS PM_A2
			FROM TRAN txn
			GROUP BY cnst_mstr_id, cnst_hsld_id,
					(CASE WHEN (fr_pmt_amt >= 1000) THEN cast(dntn_gift_dt as timestamp(6)) ELSE NULL END)
		),

		cumulative_sums AS (
			SELECT 
				cnst_mstr_id,
				cnst_hsld_id,
				dntn_gift_dt,
				gift_year,
				SUM(fr_pmt_amt) OVER (
					PARTITION BY cnst_mstr_id, cnst_hsld_id, gift_year
					ORDER BY dntn_gift_dt
					ROWS UNBOUNDED PRECEDING
				) AS cumul_sum
			FROM temp_gift_years
		),

		donation_summary AS ( 
		SELECT
			(y.PM_A0) AS PM_A0,
			(y.PM_A1) AS PM_A1,
			--(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN y.PM_A2 ELSE NULL END))) AS PM_A2,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN y.PM_A2 ELSE NULL END))) AS PM_A3,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN y.PM_A2 ELSE NULL END))) AS PM_A4,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN y.PM_A2 ELSE NULL END))) AS PM_A5,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN y.PM_A2 ELSE NULL END))) AS PM_A6,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN y.PM_A2 ELSE NULL END))) AS PM_A7,
			(MIN((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) <> 0) THEN y.PM_A2 ELSE NULL END))) AS PM_A8,
			(MAX((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) <> 0) THEN y.PM_A2 ELSE NULL END))) AS PM_A9,
			(SUM(CAST(y.PM_A3 AS DECIMAL(13, 2)))) AS PM_A10,
			(SUM(CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)))) AS PM_A11,
			(MAX(CAST(y.PM_A3 AS DECIMAL(13, 2)))) AS PM_A12,
			(MIN((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A13,
			(AVG(CAST(y.PM_A3 AS DECIMAL(13, 2)))) AS PM_A14,
			(MAX((CASE WHEN (CAST(y.PM_A4 AS DECIMAL(13, 2)) > 0) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) <> 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A15,
			(MAX((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 10000) THEN y.PM_A2 ELSE NULL END))) AS PM_A16,
			(MAX((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 10000) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 25000)) THEN y.PM_A2 ELSE NULL END))) AS PM_A17,
			(MAX((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 25000) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100000)) THEN y.PM_A2 ELSE NULL END))) AS PM_A18,
			(MAX((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100000) THEN y.PM_A2 ELSE NULL END))) AS PM_A19,
			(MAX((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000000) THEN y.PM_A2 ELSE NULL END))) AS PM_A20,
			(MAX((CASE WHEN (CAST(y.PM_A5 AS DECIMAL(13, 2)) > 0) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) <> 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A21,
			(SUM((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A22,
			(SUM((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A23,
			(SUM((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A24,
			(SUM(CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)))) AS PM_A25,
			(SUM(CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)))) AS PM_A26,
			(SUM(CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)))) AS PM_A27,
			(MAX((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN y.PM_A2 ELSE NULL END))) AS PM_A28,
			(MAX((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN y.PM_A2 ELSE NULL END))) AS PM_A29,
			(MAX((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN y.PM_A2 ELSE NULL END))) AS PM_A30,
			(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A31,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A32,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A33,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A34,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A35,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A36,
			(MIN((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A37,
			(MIN((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A38,
			(MIN((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A39,
			--(MIN((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A40,
			--(MIN((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A41,
			--(MIN((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A42,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A43,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A44,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A45,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A46,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A47,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A48,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A49,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A50,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A51,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A52,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A53,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A54,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A55,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A56,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A57,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A58,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A59,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A60,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A61,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A62,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A63,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A64,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A65,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A66,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A67,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A68,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A69,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A70,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A71,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) ELSE 0 END))) AS PM_A72,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A73,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A74,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A75,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A76,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A77,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A78,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A79,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A80,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A81,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A82,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A83,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A84,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A85,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A86,
			SUM(CASE WHEN x.fiscal_yr = (x.fiscal_yr_1 - 2) THEN CAST(CASE WHEN CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0 AND CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100 THEN 1 ELSE 0 END AS DECIMAL(11, 2)) ELSE 0 END) AS PM_A87,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A88,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A89,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST((CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A90,
			--(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A91,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A92,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A93,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A94,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A95,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 1000) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A96,
			--(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A97,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A98,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A99,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A100,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A101,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) >= 100) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 1000)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A102,
			--(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A103,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A104,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A105,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A106,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A107,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN ((CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) AND (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 100)) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A108,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST(y.PM_A6 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A109,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST(y.PM_A6 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A110,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST(y.PM_A6 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A111,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST(y.PM_A6 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A112,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST(y.PM_A6 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A113,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST(y.PM_A6 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A114,
			(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A115,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A116,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A117,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A118,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A119,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A120,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST((CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A121,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST((CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A122,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST((CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A123,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST((CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A124,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST((CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A125,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST((CASE WHEN (CAST(y.PM_A6 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A126,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST(y.PM_A7 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A127,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST(y.PM_A7 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A128,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST(y.PM_A7 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A129,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST(y.PM_A7 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A130,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST(y.PM_A7 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A131,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST(y.PM_A7 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A132,
			(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A133,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A134,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A135,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A136,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A137,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A138,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST((CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A139,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST((CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A140,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST((CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A141,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST((CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A142,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST((CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A143,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST((CASE WHEN (CAST(y.PM_A7 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A144,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST(y.PM_A8 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A145,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST(y.PM_A8 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A146,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST(y.PM_A8 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A147,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST(y.PM_A8 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A148,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST(y.PM_A8 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A149,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST(y.PM_A8 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A150,
			(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A151,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A152,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A153,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A154,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A155,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A156,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST((CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A157,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST((CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A158,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST((CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A159,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST((CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A160,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST((CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A161,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST((CASE WHEN (CAST(y.PM_A8 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A162,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST(y.PM_A9 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A163,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST(y.PM_A9 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A164,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST(y.PM_A9 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A165,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST(y.PM_A9 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A166,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST(y.PM_A9 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A167,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST(y.PM_A9 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A168,
			(MAX((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN (CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A169,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN (CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A170,
			(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN (CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A171,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN (CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A172,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN (CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A173,
			--(MAX((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN (CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN y.PM_A2 ELSE NULL END) ELSE NULL END))) AS PM_A174,
			(SUM((CASE WHEN (x.fiscal_yr = x.fiscal_yr_1) THEN CAST((CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A175,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 1)) THEN CAST((CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A176,
			(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 2)) THEN CAST((CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A177,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 3)) THEN CAST((CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A178,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 4)) THEN CAST((CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A179,
			--(SUM((CASE WHEN (x.fiscal_yr = (x.fiscal_yr_1 - 5)) THEN CAST((CASE WHEN (CAST(y.PM_A9 AS DECIMAL(13, 2)) > 0) THEN 1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END))) AS PM_A180,
			(MAX((CASE WHEN ((((CASE WHEN (x.calendar_yr = (x.calendar_yr1 - 2)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) >= 1000) AND ((CASE WHEN (x.calendar_yr = (x.calendar_yr1 - 1)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) < 1000)) AND ((CASE WHEN (x.calendar_yr = x.calendar_yr1) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END) = 0)) THEN 'Y' ELSE 'N' END))) AS PM_A181,
			(SUM(CAST((CASE WHEN (x.calendar_yr = x.calendar_yr1) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END) AS INTEGER))) AS PM_A182,
			(SUM((CASE WHEN (x.calendar_yr = x.calendar_yr1) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A183,
			(SUM(CAST((CASE WHEN (x.calendar_yr = (x.calendar_yr1 - 1)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END) AS INTEGER))) AS PM_A184,
			(SUM((CASE WHEN (x.calendar_yr = (x.calendar_yr1 - 1)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A185,
			(SUM(CAST((CASE WHEN (x.calendar_yr = (x.calendar_yr1 - 2)) THEN CAST((CASE WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) > 0) THEN 1 WHEN (CAST(y.PM_A3 AS DECIMAL(13, 2)) < 0) THEN -1 ELSE 0 END) AS DECIMAL(11, 2)) ELSE 0 END) AS INTEGER))) AS PM_A186,
			(SUM((CASE WHEN (x.calendar_yr = (x.calendar_yr1 - 2)) THEN CAST(y.PM_A3 AS DECIMAL(13, 2)) ELSE 0 END))) AS PM_A187,
			(MAX((CASE WHEN NOT ((CASE WHEN (z.fcc_key = x.calendar_yr1) THEN z.dntn_gift_dt ELSE NULL END) IS NULL) THEN 1 ELSE 0 END))) AS PM_A188,
			(MAX((CASE WHEN (z.fcc_key = x.calendar_yr1) THEN z.dntn_gift_dt ELSE NULL END))) AS PM_A189,
			(MAX((CASE WHEN (z.fcc_key = (x.calendar_yr1 - 1)) THEN z.dntn_gift_dt ELSE NULL END))) AS PM_A190,
			(MAX((CASE WHEN (z.fcc_key = (x.calendar_yr1 - 2)) THEN z.dntn_gift_dt ELSE NULL END))) AS PM_A191
			FROM (
				SELECT 
					a.calendar_dt,
					a.calendar_yr,
					a.fiscal_yr,
					b.calendar_yr AS calendar_yr1,
					b.fiscal_yr AS fiscal_yr_1
				FROM eda.dw_common_vws.dim_calendar a 
				CROSS JOIN eda.dw_common_vws.dim_calendar b
				WHERE b.calendar_dt = CURRENT_DATE
			) x
			INNER JOIN (
				SELECT
					txn.cnst_mstr_id AS PM_A0,
					txn.cnst_hsld_id AS PM_A1,
					txn.dntn_gift_dt AS PM_A2,
					SUM(txn.fr_pmt_amt) AS PM_A3,
					SUM(CASE WHEN txn.fr_distr_dntn_ind = 1 THEN txn.fr_pmt_amt ELSE 0 END) AS PM_A4,
					SUM(CASE WHEN txn.fr_distr_dntn_ind = 0 THEN txn.fr_pmt_amt ELSE 0 END) AS PM_A5,
					SUM(CASE 
							WHEN (fcc.gl_fcc_cd = '27763' OR 
								 (fcc.gl_fcc_cd = '27764' AND src.src_cd IS NOT NULL)) 
							THEN txn.fr_pmt_amt 
							ELSE 0 
						END) AS PM_A6,
					SUM(CASE 
							WHEN (fcc.gl_fcc_cd = '27763' OR fcc.gl_fcc_cd = '27764') 
							THEN txn.fr_pmt_amt 
							ELSE 0 
						END) AS PM_A7,
					SUM(CASE 
							WHEN (SUBSTRING(txn.gift_src_cd, 1, 2) = 'RP' OR fcc.gl_fcc_cd = '27762') 
							THEN txn.fr_pmt_amt 
							ELSE 0 
						END) AS PM_A8,
					SUM(CASE 
							WHEN (SUBSTRING(txn.gift_src_cd, 1, 2) IN ('RQ', 'RR') OR 
								  fcc.gl_fcc_cd IN ('27760', '27761')) 
							THEN txn.fr_pmt_amt 
							ELSE 0 
						END) AS PM_A9
				FROM TRAN txn
				LEFT JOIN mktg_ops_vws.gmpbz_dim_gl_fcc fcc ON txn.fcc_key = fcc.gl_fcc_key
				LEFT JOIN mktg_ops_vws.bz_email_src_cd src ON src.src_cd = txn.gift_src_cd
				GROUP BY 
					txn.cnst_mstr_id,
					txn.cnst_hsld_id,
					txn.dntn_gift_dt
			) y ON (y.PM_A2 = x.calendar_dt)
			LEFT JOIN (
				SELECT 
					cnst_mstr_id,
					cnst_hsld_id,
					dntn_gift_dt,
					gift_year as fcc_key
				FROM (
					SELECT 
						*,
						ROW_NUMBER() OVER (
							PARTITION BY cnst_mstr_id, gift_year
							ORDER BY dntn_gift_dt, cumul_sum
						) AS rn
					FROM cumulative_sums
					WHERE cumul_sum >= 1000
				) t
				WHERE rn = 1
			) z ON ((z.cnst_mstr_id = y.PM_A0) AND (z.dntn_gift_dt = y.PM_A2))
			GROUP BY PM_A0, PM_A1
		),


		daily_donation_summary AS (
			SELECT 
				arc_fr_txn_Last_Trans.cnst_mstr_id AS PM_A0,
				CAST(arc_fr_txn_Last_Trans.dntn_gift_dt AS TIMESTAMP) AS PM_A1,
				SUM(arc_fr_txn_Last_Trans.fr_pmt_amt) AS PM_A2
			FROM TRAN arc_fr_txn_Last_Trans
			GROUP BY 
				arc_fr_txn_Last_Trans.cnst_mstr_id,
				arc_fr_txn_Last_Trans.cnst_hsld_id,
				CAST(arc_fr_txn_Last_Trans.dntn_gift_dt AS TIMESTAMP)
		),


		donor_rolling_year_analysis  AS ( 

		SELECT
			x.cnst_mstr_id AS PM_A0,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN 1 ELSE 0 END) AS INTEGER) AS PM_A1,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN 1 ELSE 0 END) AS INTEGER) AS PM_A2,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN x.fr_pmt_amt ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A3,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN x.fr_pmt_amt ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A4,
			CASE WHEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN 1 ELSE 0 END) AS INTEGER) > 0 THEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN x.fr_pmt_amt ELSE 0 END) AS DECIMAL(13, 2)) / CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN 1 ELSE 0 END) AS INTEGER) ELSE 0 END AS PM_A5,
			CASE WHEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN 1 ELSE 0 END) AS INTEGER) > 0 THEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN x.fr_pmt_amt ELSE 0 END) AS DECIMAL(13, 2)) / CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN 1 ELSE 0 END) AS INTEGER) ELSE 0 END AS PM_A6,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.fr_pmt_amt >= 1000) THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A7,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.fr_pmt_amt >= 1000) THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A8,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.fr_pmt_amt >= 1000) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A9,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.fr_pmt_amt >= 1000) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A10,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.fr_pmt_amt >= 100 AND x.fr_pmt_amt < 1000) THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A11,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.fr_pmt_amt >= 100 AND x.fr_pmt_amt < 1000) THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A12,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.fr_pmt_amt >= 100 AND x.fr_pmt_amt < 1000) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A13,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.fr_pmt_amt >= 100 AND x.fr_pmt_amt < 1000) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A14,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.fr_pmt_amt > 0 AND x.fr_pmt_amt < 100) THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A15,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.fr_pmt_amt > 0 AND x.fr_pmt_amt < 100) THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A16,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.fr_pmt_amt > 0 AND x.fr_pmt_amt < 100) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A17,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.fr_pmt_amt > 0 AND x.fr_pmt_amt < 100) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A18,
			MAX(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN x.fr_pmt_amt ELSE 0 END) AS PM_A19,
			MAX(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN x.fr_pmt_amt ELSE 0 END) AS PM_A20,
			MIN(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN x.fr_pmt_amt ELSE 0 END) AS PM_A21,
			MIN(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN x.fr_pmt_amt ELSE 0 END) AS PM_A22,
			MAX(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN x.dntn_gift_dt ELSE NULL END ELSE NULL END) AS PM_A23,
			MAX(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN x.dntn_gift_dt ELSE NULL END ELSE NULL END) AS PM_A24,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A25,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A26,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A27,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A28,
			CASE WHEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) > 0 THEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) / CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) ELSE 0 END AS PM_A29,
			CASE WHEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) > 0 THEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) / CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR (x.gl_fcc_cd = '27764' AND x.email_src_cd IS NOT NULL)) THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) ELSE 0 END AS PM_A30,
			MAX(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN x.dntn_gift_dt ELSE NULL END ELSE NULL END) AS PM_A31,
			MAX(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN x.dntn_gift_dt ELSE NULL END ELSE NULL END) AS PM_A32,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A33,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A34,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A35,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A36,
			CASE WHEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) > 0 THEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) / CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) ELSE 0 END AS PM_A37,
			CASE WHEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) > 0 THEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) / CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (x.gl_fcc_cd = '27763' OR x.gl_fcc_cd = '27764') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) ELSE 0 END AS PM_A38,
			MAX(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN x.dntn_gift_dt ELSE NULL END ELSE NULL END) AS PM_A39,
			MAX(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN x.dntn_gift_dt ELSE NULL END ELSE NULL END) AS PM_A40,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A41,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A42,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A43,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A44,
			CASE WHEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) > 0 THEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) / CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) ELSE 0 END AS PM_A45,
			CASE WHEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) > 0 THEN CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) / CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RP' OR x.gl_fcc_cd = '27762') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) ELSE 0 END AS PM_A46,
			MAX(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RQ' OR SUBSTRING(x.gift_src_cd, 1, 2) = 'RR' OR x.gl_fcc_cd = '27760' OR x.gl_fcc_cd = '27761') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN x.dntn_gift_dt ELSE NULL END ELSE NULL END) AS PM_A47,
			MAX(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RQ' OR SUBSTRING(x.gift_src_cd, 1, 2) = 'RR' OR x.gl_fcc_cd = '27760' OR x.gl_fcc_cd = '27761') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN x.dntn_gift_dt ELSE NULL END ELSE NULL END) AS PM_A48,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RQ' OR SUBSTRING(x.gift_src_cd, 1, 2) = 'RR' OR x.gl_fcc_cd = '27760' OR x.gl_fcc_cd = '27761') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A49,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= CURRENT_TIMESTAMP AND x.dntn_gift_dt >= x.rolling_1yr) THEN CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RQ' OR SUBSTRING(x.gift_src_cd, 1, 2) = 'RR' OR x.gl_fcc_cd = '27760' OR x.gl_fcc_cd = '27761') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A50,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RQ' OR SUBSTRING(x.gift_src_cd, 1, 2) = 'RR' OR x.gl_fcc_cd = '27760' OR x.gl_fcc_cd = '27761') THEN x.fr_pmt_amt ELSE 0 END) > 0 THEN 1 ELSE 0 END ELSE 0 END) AS INTEGER) AS PM_A51,
			CAST(SUM(CASE WHEN (x.dntn_gift_dt <= x.rolling_1yr AND x.dntn_gift_dt >= x.rolling_2yr) THEN CASE WHEN (SUBSTRING(x.gift_src_cd, 1, 2) = 'RQ' OR SUBSTRING(x.gift_src_cd, 1, 2) = 'RR' OR x.gl_fcc_cd = '27760' OR x.gl_fcc_cd = '27761') THEN x.fr_pmt_amt ELSE 0 END ELSE 0 END) AS DECIMAL(13, 2)) AS PM_A52
		from (
			SELECT 
				cnst_mstr_id,
				cnst_hsld_id,
				fr_pmt_amt,
				dntn_gift_dt,
				gift_src_cd,
				fcc.gl_fcc_cd,
				fr_distr_dntn_ind,
				dateadd(month, -12, current_date) AS rolling_1yr,
				dateadd(month, -24, current_date) AS rolling_2yr,
				src.src_cd AS email_src_cd
			FROM Tran txn
			LEFT OUTER JOIN mktg_ops_vws.gmpbz_dim_gl_fcc fcc 
				ON txn.fcc_key = fcc.gl_fcc_key
			LEFT OUTER JOIN mktg_ops_vws.bz_email_src_cd src 
				ON src.src_cd = txn.gift_src_cd) x
		group by x.cnst_mstr_id
		),



		first_donation_fund AS (
			SELECT 
				first_dntn.cnst_mstr_id, 
				first_dntn.fund_key, 
				first_dntn.fund_cd 
			FROM ((
				SELECT
					txn.cnst_mstr_id,
					MIN(fund.fund_key) AS min_fund_key,
					MAX(fund.fund_key) AS max_fund_key
				FROM (
					SELECT
						cnst_mstr_id,
						MIN(dntn_gift_dt) AS first_donation_date
					FROM TRAN
					GROUP BY cnst_mstr_id
				) first_donations
				JOIN TRAN txn
					ON first_donations.cnst_mstr_id = txn.cnst_mstr_id
					AND first_donations.first_donation_date = txn.dntn_gift_dt
				JOIN eda.ufds_vws.gmpbz_dim_fund fund
					ON fund.fund_cd = txn.trans_fund_cd
				GROUP BY txn.cnst_mstr_id
			) fund_info
			JOIN eda.ufds_vws.gmpbz_dim_fund fund_details
				ON fund_details.fund_key = (
					CASE 
						WHEN fund_info.min_fund_key = fund_info.max_fund_key 
						THEN fund_info.max_fund_key 
						ELSE 99999 
					END
				)) as first_dntn
		),


		latest_donation_fund AS (
			SELECT 
				latest_dntn.cnst_mstr_id, 
				latest_dntn.fund_key, 
				latest_dntn.fund_cd 
			FROM ((
				SELECT
					txn.cnst_mstr_id,
					MIN(fund.fund_key) AS min_fund_key,
					MAX(fund.fund_key) AS max_fund_key
				FROM (
					SELECT
						cnst_mstr_id,
						MAX(dntn_gift_dt) AS latest_donation_date
					FROM TRAN
					GROUP BY cnst_mstr_id
				) latest_donations
				JOIN TRAN txn
					ON latest_donations.cnst_mstr_id = txn.cnst_mstr_id
					AND latest_donations.latest_donation_date = txn.dntn_gift_dt
				JOIN eda.ufds_vws.gmpbz_dim_fund fund
					ON fund.fund_cd = txn.trans_fund_cd
				GROUP BY txn.cnst_mstr_id
			) fund_info
			JOIN eda.ufds_vws.gmpbz_dim_fund fund_details
				ON fund_details.fund_key = (
					CASE 
						WHEN fund_info.min_fund_key = fund_info.max_fund_key 
						THEN fund_info.max_fund_key 
						ELSE 99999 
					END
				)) as latest_dntn
		),


		minimum_payment_fund AS (
			SELECT 
				min_dntn.cnst_mstr_id,
				min_dntn.fund_key,
				min_dntn.fund_cd
			FROM ((
				SELECT
					trn.cnst_mstr_id,
					trn.min_fcc_key AS min_fcc_key,
					trn.max_fcc_key AS max_fcc_key
				FROM (
					SELECT
						cnst_mstr_id,
						MIN(sum_fr_pmt_amt) AS min_sum_fr_pmt_amt
					FROM (
						SELECT
							cnst_mstr_id,
							dntn_gift_dt,
							SUM(fr_pmt_amt) AS sum_fr_pmt_amt
						FROM TRAN
						GROUP BY cnst_mstr_id, dntn_gift_dt
					) txn
					GROUP BY cnst_mstr_id
				) min_txn
				RIGHT JOIN (
					SELECT
						cnst_mstr_id,
						SUM(fr_pmt_amt) AS s_fr_pmt_amt,
						MIN(fcc_key) AS min_fcc_key,
						MAX(fcc_key) AS max_fcc_key
					FROM TRAN
					GROUP BY cnst_mstr_id
				) trn 
					ON trn.cnst_mstr_id = min_txn.cnst_mstr_id 
					AND trn.s_fr_pmt_amt = min_txn.min_sum_fr_pmt_amt
			) fund_info
			INNER JOIN eda.ufds_vws.gmpbz_dim_fund fund_details
				ON fund_details.fund_key = (
					CASE 
						WHEN fund_info.min_fcc_key = fund_info.max_fcc_key 
						THEN fund_info.max_fcc_key 
						ELSE 99999 
					END
				)) as min_dntn
		),

		maximum_payment_fund AS (
			SELECT 
				max_dntn.cnst_mstr_id,
				max_dntn.fund_key,
				max_dntn.fund_cd
			FROM ((
				SELECT
					trn.cnst_mstr_id,
					trn.min_fcc_key AS min_fcc_key,
					trn.max_fcc_key AS max_fcc_key
				FROM (
					SELECT
						cnst_mstr_id,
						MAX(sum_fr_pmt_amt) AS max_sum_fr_pmt_amt
					FROM (
						SELECT
							cnst_mstr_id,
							dntn_gift_dt,
							SUM(fr_pmt_amt) AS sum_fr_pmt_amt
						FROM TRAN
						GROUP BY cnst_mstr_id, dntn_gift_dt
					) txn
					GROUP BY cnst_mstr_id
				) max_txn
				RIGHT JOIN (
					SELECT
						cnst_mstr_id,
						SUM(fr_pmt_amt) AS s_fr_pmt_amt,
						MIN(fcc_key) AS min_fcc_key,
						MAX(fcc_key) AS max_fcc_key
					FROM TRAN
					GROUP BY cnst_mstr_id
				) trn 
					ON trn.cnst_mstr_id = max_txn.cnst_mstr_id 
					AND trn.s_fr_pmt_amt = max_txn.max_sum_fr_pmt_amt
			) fund_info
			INNER JOIN eda.ufds_vws.gmpbz_dim_fund fund_details
				ON fund_details.fund_key = (
					CASE 
						WHEN fund_info.min_fcc_key = fund_info.max_fcc_key 
						THEN fund_info.max_fcc_key 
						ELSE 99999 
					END
				)) as max_dntn
		),
		 
		/* latest_donation_with_affiliation AS (
			SELECT 
				latest_txn.cnst_mstr_id,
				latest_txn.cnst_hsld_id,
				latest_txn.ta_acct_id,
				latest_txn.dntn_gift_dt,
				latest_txn.fr_pmt_amt,
				cnst_affl_info.bzd_acct_affl_lock_ind,
				cnst_affl_info.bzd_prim_affl_unit_key,
				cnst_affl_info.bzd_sf_acct_fmd_ind,
				cnst_affl_info.bzd_ta_acct_fmd_ind,
				cnst_affl_info.nk_ta_acct_id
			FROM (
				SELECT
					cnst_mstr_id,
					cnst_hsld_id,
					ta_acct_id,
					dntn_gift_dt,
					fr_pmt_amt,
					ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY dntn_gift_dt DESC) as rn
				FROM TRAN
			) latest_txn
			LEFT OUTER JOIN (
				SELECT
					cnst_affl.cnst_mstr_id,
					cnst_affl.bzd_acct_affl_lock_ind,
					cnst_affl.bzd_prim_affl_unit_key,
					cnst_affl.bzd_sf_acct_fmd_ind,
					cnst_affl.bzd_ta_acct_fmd_ind,
					CASE 
						WHEN fsa_cnst.nk_ta_acct_id IS NULL 
						THEN fsa_acct.nk_ta_acct_id 
						ELSE fsa_cnst.nk_ta_acct_id 
					END AS nk_ta_acct_id
				FROM eda.arc_mdm_vws.bzfc_fr_cnst_affl_prfl cnst_affl
				LEFT OUTER JOIN eda.ddcoe_vws.cnst_fsa fsa_acct 
					ON cnst_affl.bzd_cnst_fsa_key = fsa_cnst.cnst_fsa_key
				LEFT OUTER JOIN eda.ddcoe_vws.cnst_fsa fsa_acct 
					ON cnst_affl.bzd_acct_fsa_key = fsa_acct.cnst_fsa_key
			) cnst_affl_info 
				ON cnst_affl_info.cnst_mstr_id = latest_txn.cnst_mstr_id
			WHERE latest_txn.rn = 1
		), */

		-- Removed LEFT JOINs to eda.ddcoe_vws.cnst_fsa (fsa_cnst & fsa_acct) because:
		-- They were only used to derive `nk_ta_acct_id`, which is NOT selected in the final output.
		-- Retained all other columns (bzd_*) as they come directly from bzfc_fr_cnst_affl_prfl.

		latest_donation_with_affiliation AS ( 
			select
				latest_txn.cnst_mstr_id,
				cnst_affl_info.bzd_acct_affl_lock_ind, 
				cnst_affl_info.bzd_prim_affl_unit_key, 
				cnst_affl_info.bzd_sf_acct_fmd_ind, 
				cnst_affl_info.bzd_ta_acct_fmd_ind
			FROM ( 
				SELECT 
					cnst_mstr_id, 
					cnst_hsld_id, 
					ta_acct_id, 
					dntn_gift_dt, 
					fr_pmt_amt, 
					ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY dntn_gift_dt DESC) as rn 
				FROM TRAN 
			) latest_txn 
			LEFT OUTER JOIN ( 
				SELECT 
					cnst_affl.cnst_mstr_id, 
					cnst_affl.bzd_acct_affl_lock_ind, 
					cnst_affl.bzd_prim_affl_unit_key, 
					cnst_affl.bzd_sf_acct_fmd_ind, 
					cnst_affl.bzd_ta_acct_fmd_ind
				FROM eda.arc_mdm_vws.bzfc_fr_cnst_affl_prfl cnst_affl 
			) cnst_affl_info  
				ON cnst_affl_info.cnst_mstr_id = latest_txn.cnst_mstr_id 
			WHERE latest_txn.rn = 1 
		),

		highest_priority_portfolio AS (
			SELECT 
				cnst_mstr_id,
				portfolio_category
			FROM (
				SELECT
					aa.cnst_mstr_id,
					bb.portfolio_category,
					ROW_NUMBER() OVER (
						PARTITION BY aa.cnst_mstr_id 
						ORDER BY (
							CASE 
								WHEN bb.portfolio_category = 'High Focus' THEN 1 
								WHEN bb.portfolio_category = 'Medium Focus' THEN 2 
								WHEN bb.portfolio_category = 'Low Focus' THEN 3 
								WHEN bb.portfolio_category = 'Org Contact' THEN 4 
								ELSE 5 
							END
						)
					) AS rn
				FROM eda.arc_mdm_vws.bzl_cnst_mstr_fsa_in aa 
				LEFT OUTER JOIN eda.ddcoe_vws.bzfc_cnst_fsa_all bb 
					ON bb.cnst_fsa_key = aa.bzd_acct_fsa_key 
				WHERE bb.portfolio_category IS NOT NULL
			) ranked_portfolios
			WHERE rn = 1
		),

		benevity_donation_count AS (
			SELECT 
				a.cnst_mstr_id AS dim_giftran_key,
				COUNT(*) AS adj_seq
			FROM TRAN a
			LEFT JOIN mktg_ops_vws.gmpbz_dim_giftran b 
				ON a.dim_giftran_key = b.dim_giftran_key
			WHERE b.third_prty = 'Benevity'
			GROUP BY a.cnst_mstr_id
		),

		first_donation_analysis AS (
			SELECT 
				first_dntn.cnst_mstr_id,
				CASE 
					WHEN first_dstr_dntn.fr_first_dstr_dntn_dt = first_non_dstr_dntn.fr_first_non_dstr_dntn_dt THEN 'Both' 
					WHEN first_dntn.fr_first_dntn_dt = first_non_dstr_dntn.fr_first_non_dstr_dntn_dt THEN 'Mission' 
					WHEN first_dntn.fr_first_dntn_dt = first_dstr_dntn.fr_first_dstr_dntn_dt THEN 'Disaster' 
				END AS fr_first_dntn_typ,
				first_dntn.fr_first_gift_src_cd,
				first_dntn.fr_first_dntn_dt,
				first_dntn.fr_first_dntn_gl_fcc_cd AS fr_first_dntn_fcc_cd,
				first_dntn.fr_first_dntn_amt,
				first_dstr_dntn.fr_first_dstr_gift_src_cd,
				first_dstr_dntn.fr_first_dstr_dntn_fund_cd,
				first_dstr_dntn.fr_first_dstr_dntn_dt,
				first_dstr_dntn.fr_first_dstr_dntn_gl_fcc_cd AS fr_first_dstr_dntn_fcc_cd,
				first_dstr_dntn.fr_first_dstr_dntn_amt,
				first_non_dstr_dntn.fr_first_non_dstr_gift_src_cd AS fr_first_non_distr_gift_src_cd,
				first_non_dstr_dntn.fr_first_non_dstr_dntn_fund_cd AS fr_first_non_distr_dntn_fnd_cd,
				first_non_dstr_dntn.fr_first_non_dstr_dntn_dt AS fr_first_non_distr_dntn_dt,
				first_non_dstr_dntn.fr_first_non_dstr_dntn_gl_fcc_cd AS fr_first_non_distr_dntn_fcc_cd,
				first_non_dstr_dntn.fr_first_non_dstr_dntn_amt AS fr_first_non_distr_dntn_amt
			FROM (
				-- First overall donation per constituent
				SELECT
					min_dtn_dt.cnst_mstr_id,
					CASE 
						WHEN MIN(a.gift_src_cd) = MAX(a.gift_src_cd) 
						THEN MIN(a.gift_src_cd) 
						ELSE 'MULTI' 
					END AS fr_first_gift_src_cd,
					CASE 
						WHEN MIN(a.trans_fund_cd) = MAX(a.trans_fund_cd) 
						THEN MIN(a.trans_fund_cd) 
						ELSE 'MULTI' 
					END AS fr_first_dntn_fund_cd,
					MIN(min_dtn_dt.dntn_gift_dt) AS fr_first_dntn_dt,
					CASE 
						WHEN MIN(b.gl_fcc_cd) = MAX(b.gl_fcc_cd) 
						THEN MIN(b.gl_fcc_cd) 
						ELSE 'MULTI' 
					END AS fr_first_dntn_gl_fcc_cd,
					SUM(a.fr_pmt_amt) AS fr_first_dntn_amt
				FROM (
					SELECT 
						cnst_mstr_id,
						MIN(dntn_gift_dt) AS dntn_gift_dt 
					FROM TRAN
					GROUP BY cnst_mstr_id
				) min_dtn_dt
				LEFT OUTER JOIN TRAN a 
					ON a.cnst_mstr_id = min_dtn_dt.cnst_mstr_id 
					AND a.dntn_gift_dt = min_dtn_dt.dntn_gift_dt
				LEFT OUTER JOIN eda.ufds_vws.gmpbz_dim_gl_fcc b 
					ON a.fcc_key = b.gl_fcc_key
				GROUP BY min_dtn_dt.cnst_mstr_id
			) first_dntn
			LEFT OUTER JOIN (
				-- First disaster donation per constituent
				SELECT 
					min_dtn_dt.cnst_mstr_id,
					CASE 
						WHEN MIN(a.gift_src_cd) = MAX(a.gift_src_cd) 
						THEN MIN(a.gift_src_cd) 
						ELSE 'MULTI' 
					END AS fr_first_dstr_gift_src_cd,
					CASE 
						WHEN MIN(a.trans_fund_cd) = MAX(a.trans_fund_cd) 
						THEN MIN(a.trans_fund_cd) 
						ELSE 'MULTI' 
					END AS fr_first_dstr_dntn_fund_cd,
					MIN(min_dtn_dt.dntn_gift_dt) AS fr_first_dstr_dntn_dt,
					CASE 
						WHEN MIN(b.gl_fcc_cd) = MAX(b.gl_fcc_cd) 
						THEN MIN(b.gl_fcc_cd) 
						ELSE 'MULTI' 
					END AS fr_first_dstr_dntn_gl_fcc_cd,
					SUM(a.fr_pmt_amt) AS fr_first_dstr_dntn_amt
				FROM (
					SELECT 
						cnst_mstr_id,
						MIN(dntn_gift_dt) AS dntn_gift_dt 
					FROM TRAN
					WHERE fr_distr_dntn_ind = 1   
					GROUP BY cnst_mstr_id
				) min_dtn_dt 
				LEFT OUTER JOIN TRAN a 
					ON a.cnst_mstr_id = min_dtn_dt.cnst_mstr_id 
					AND a.dntn_gift_dt = min_dtn_dt.dntn_gift_dt 
					AND a.fr_distr_dntn_ind = 1 
				LEFT OUTER JOIN eda.ufds_vws.gmpbz_dim_gl_fcc b 
					ON a.fcc_key = b.gl_fcc_key
				GROUP BY min_dtn_dt.cnst_mstr_id
			) first_dstr_dntn 
				ON first_dntn.cnst_mstr_id = first_dstr_dntn.cnst_mstr_id 
			LEFT OUTER JOIN (
				-- First non-disaster (mission) donation per constituent
				SELECT 
					min_dtn_dt.cnst_mstr_id,
					CASE 
						WHEN MIN(a.gift_src_cd) = MAX(a.gift_src_cd) 
						THEN MIN(a.gift_src_cd) 
						ELSE 'MULTI' 
					END AS fr_first_non_dstr_gift_src_cd,
					CASE 
						WHEN MIN(a.trans_fund_cd) = MAX(a.trans_fund_cd) 
						THEN MIN(a.trans_fund_cd) 
						ELSE 'MULTI' 
					END AS fr_first_non_dstr_dntn_fund_cd,
					MIN(min_dtn_dt.dntn_gift_dt) AS fr_first_non_dstr_dntn_dt,
					CASE 
						WHEN MIN(b.gl_fcc_cd) = MAX(b.gl_fcc_cd) 
						THEN MIN(b.gl_fcc_cd) 
						ELSE 'MULTI' 
					END AS fr_first_non_dstr_dntn_gl_fcc_cd,
					SUM(a.fr_pmt_amt) AS fr_first_non_dstr_dntn_amt
				FROM (
					SELECT 
						cnst_mstr_id,
						MIN(dntn_gift_dt) AS dntn_gift_dt 
					FROM TRAN
					WHERE fr_distr_dntn_ind = 0
					GROUP BY cnst_mstr_id
				) min_dtn_dt 
				LEFT OUTER JOIN TRAN a
					ON a.cnst_mstr_id = min_dtn_dt.cnst_mstr_id 
					AND a.dntn_gift_dt = min_dtn_dt.dntn_gift_dt 
					AND a.fr_distr_dntn_ind = 0
				LEFT OUTER JOIN eda.ufds_vws.gmpbz_dim_gl_fcc b 
					ON a.fcc_key = b.gl_fcc_key
				GROUP BY min_dtn_dt.cnst_mstr_id
			) first_non_dstr_dntn
				ON first_dntn.cnst_mstr_id = first_non_dstr_dntn.cnst_mstr_id
		)

		SELECT 
			donation_summary.PM_A0
			,donation_summary.PM_A1
			,CAST(donation_summary.PM_A8 AS date)
			,CAST(donation_summary.PM_A9 AS date)
			,CAST(daily_donation_summary.PM_A2 AS DECIMAL(13, 2))
			,NULL
			,NULL
			,latest_donation_affiliation.bzd_prim_affl_unit_key
			,latest_donation_affiliation.bzd_acct_affl_lock_ind
			,latest_donation_affiliation.bzd_sf_acct_fmd_ind
			,latest_donation_affiliation.bzd_ta_acct_fmd_ind
			,CAST(donation_summary.PM_A21 AS date)
			,CAST(non_disaster_don.PM_A2 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A15 AS date)
			,CAST(disaster_don.PM_A2 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A10 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A11 AS INTEGER)
			,donation_summary.PM_A12
			,donation_summary.PM_A13
			,CAST(donation_summary.PM_A14 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A25 AS INTEGER)
			,CAST(donation_summary.PM_A22 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A28 AS date)
			,CAST(donations_1k_plus.PM_A2 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A26 AS INTEGER)
			,CAST(donation_summary.PM_A23 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A29 AS date)
			,CAST(donations_100_to_1k.PM_A2 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A27 AS INTEGER)
			,CAST(donation_summary.PM_A24 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A30 AS date)
			,CAST(donations_under_100.PM_A2 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A49 AS INTEGER)
			,CAST(donation_summary.PM_A50 AS INTEGER)
			,CAST(donation_summary.PM_A51 AS INTEGER)
			,CAST(donation_summary.PM_A52 AS INTEGER)
			,CAST(donation_summary.PM_A53 AS INTEGER)
			,CAST(donation_summary.PM_A54 AS INTEGER)
			,CAST(donation_summary.PM_A43 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A44 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A45 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A46 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A47 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A48 AS DECIMAL(13, 2))
			,CAST((CASE WHEN (CAST(donation_summary.PM_A49 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A43 AS DECIMAL(13, 2)) / CAST(donation_summary.PM_A49 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A73 AS INTEGER)
			,CAST(donation_summary.PM_A55 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A79 AS INTEGER)
			,CAST(donation_summary.PM_A61 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A85 AS INTEGER)
			,CAST(donation_summary.PM_A67 AS DECIMAL(13, 2))
			,donation_summary.PM_A31
			,donation_summary.PM_A37
			,CAST(donation_summary.PM_A115 AS date)
			,CAST(donation_summary.PM_A121 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A121 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A109 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A121 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A133 AS date)
			,CAST(donation_summary.PM_A139 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A139 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A127 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A139 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A151 AS date)
			,CAST(donation_summary.PM_A157 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A157 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A145 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A157 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A169 AS date)
			,CAST(donation_summary.PM_A175 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A175 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A163 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A175 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST((CASE WHEN (CAST(donation_summary.PM_A50 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A44 AS DECIMAL(13, 2)) / CAST(donation_summary.PM_A50 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A74 AS INTEGER)
			,CAST(donation_summary.PM_A56 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A80 AS INTEGER)
			,CAST(donation_summary.PM_A62 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A86 AS INTEGER)
			,CAST(donation_summary.PM_A68 AS DECIMAL(13, 2))
			,donation_summary.PM_A32
			,donation_summary.PM_A38
			,CAST(donation_summary.PM_A116 AS date)
			,CAST(donation_summary.PM_A122 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A122 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A110 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A122 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A134 AS date)
			,CAST(donation_summary.PM_A140 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A140 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A128 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A140 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A152 AS date)
			,CAST(donation_summary.PM_A158 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A158 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A146 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A158 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A170 AS date)
			,CAST(donation_summary.PM_A176 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A176 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A164 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A176 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST((CASE WHEN (CAST(donation_summary.PM_A51 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A45 AS DECIMAL(13, 2)) / CAST(donation_summary.PM_A51 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A75 AS INTEGER)
			,CAST(donation_summary.PM_A57 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A81 AS INTEGER)
			,CAST(donation_summary.PM_A63 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A87 AS INTEGER)
			,CAST(donation_summary.PM_A69 AS DECIMAL(13, 2))
			,donation_summary.PM_A33
			,donation_summary.PM_A39
			,CAST(donation_summary.PM_A117 AS date)
			,CAST(donation_summary.PM_A123 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A123 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A111 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A123 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A135 AS date)
			,CAST(donation_summary.PM_A141 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A141 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A129 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A141 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A153 AS date)
			,CAST(donation_summary.PM_A159 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A159 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A147 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A159 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A171 AS date)
			,CAST(donation_summary.PM_A177 AS INTEGER)
			,CAST((CASE WHEN (CAST(donation_summary.PM_A177 AS INTEGER) > 0) THEN (CAST(donation_summary.PM_A165 AS DECIMAL(11, 2)) / CAST(donation_summary.PM_A177 AS INTEGER)) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST(constituency.PM_A1 AS date)
			,CAST(constituency.PM_A2 AS date)
			,CAST(constituency.PM_A3 AS date)
			,CAST(constituency.PM_A4 AS date)
			,CAST(constituency.PM_A5 AS date)
			,CAST((CASE WHEN NOT (CAST(donations_10k_plus.PM_A2 AS DECIMAL(13, 2)) IS NULL) THEN (CASE WHEN (CAST(donations_10k_plus.PM_A2 AS DECIMAL(13, 2)) >= 1000000) THEN 'Chairmans Counsel   ' WHEN (CAST(donations_10k_plus.PM_A2 AS DECIMAL(13, 2)) >= 100000) THEN 'Presidents Counsel ' WHEN (CAST(donations_10k_plus.PM_A2 AS DECIMAL(13, 2)) >= 25000) THEN 'Leadership Society  ' WHEN (CAST(donations_10k_plus.PM_A2 AS DECIMAL(13, 2)) >= 10000) THEN 'Humanitarian Circle  ' ELSE NULL END) ELSE '' END) AS VARCHAR(20))
			,(CASE WHEN NULL IS NULL THEN 0 ELSE 1 END)
			,donor_rolling_analysis.PM_A1
			,donor_rolling_analysis.PM_A2
			,donor_rolling_analysis.PM_A3
			,donor_rolling_analysis.PM_A4
			,CAST(donor_rolling_analysis.PM_A5 AS DECIMAL(13, 2))
			,CAST(donor_rolling_analysis.PM_A6 AS DECIMAL(13, 2))
			,donor_rolling_analysis.PM_A7
			,donor_rolling_analysis.PM_A8
			,donor_rolling_analysis.PM_A9
			,donor_rolling_analysis.PM_A10
			,donor_rolling_analysis.PM_A11
			,donor_rolling_analysis.PM_A12
			,donor_rolling_analysis.PM_A13
			,donor_rolling_analysis.PM_A14
			,donor_rolling_analysis.PM_A15
			,donor_rolling_analysis.PM_A16
			,donor_rolling_analysis.PM_A17
			,donor_rolling_analysis.PM_A18
			,donor_rolling_analysis.PM_A19
			,donor_rolling_analysis.PM_A20
			,donor_rolling_analysis.PM_A21
			,donor_rolling_analysis.PM_A22
			,CAST(donor_rolling_analysis.PM_A23 AS date)
			,CAST(donor_rolling_analysis.PM_A24 AS date)
			,donor_rolling_analysis.PM_A25
			,donor_rolling_analysis.PM_A27
			,CAST(donor_rolling_analysis.PM_A29 AS DECIMAL(13, 2))
			,CAST(donor_rolling_analysis.PM_A30 AS DECIMAL(13, 2))
			,CAST(donor_rolling_analysis.PM_A31 AS date)
			,CAST(donor_rolling_analysis.PM_A32 AS date)
			,donor_rolling_analysis.PM_A33
			,donor_rolling_analysis.PM_A34
			,CAST(donor_rolling_analysis.PM_A37 AS DECIMAL(13, 2))
			,CAST(donor_rolling_analysis.PM_A38 AS DECIMAL(13, 2))
			,CAST(donor_rolling_analysis.PM_A39 AS date)
			,CAST(donor_rolling_analysis.PM_A40 AS date)
			,donor_rolling_analysis.PM_A41
			,donor_rolling_analysis.PM_A42
			,CAST(donor_rolling_analysis.PM_A45 AS DECIMAL(13, 2))
			,CAST(donor_rolling_analysis.PM_A46 AS DECIMAL(13, 2))
			,CAST(donor_rolling_analysis.PM_A47 AS date)
			,CAST(donor_rolling_analysis.PM_A48 AS date)
			,donor_rolling_analysis.PM_A49
			,donor_rolling_analysis.PM_A51
			,CAST((CASE WHEN (donor_rolling_analysis.PM_A49 > 0) THEN (donor_rolling_analysis.PM_A50 / donor_rolling_analysis.PM_A49) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST((CASE WHEN (donor_rolling_analysis.PM_A51 > 0) THEN (donor_rolling_analysis.PM_A52 / donor_rolling_analysis.PM_A51) ELSE 0 END) AS DECIMAL(13, 2))
			,CAST((CASE WHEN first_donation_fund.fund_key IS NULL THEN 11111 ELSE first_donation_fund.fund_key END) AS INTEGER) as fr_first_dntn_fund_key
			,(CASE WHEN first_donation_fund.fund_cd IS NULL THEN 'default' ELSE first_donation_fund.fund_cd END) AS fr_first_dntn_fund_cd
			,CAST((CASE WHEN latest_donation_fund.fund_key IS NULL THEN 11111 ELSE latest_donation_fund.fund_key END) AS INTEGER) AS fr_latest_dntn_fund_key
			,(CASE WHEN latest_donation_fund.fund_cd IS NULL THEN 'default' ELSE latest_donation_fund.fund_cd END) AS fr_latest_dntn_fund_cd
			,CAST((CASE WHEN max_payment_fund.fund_key IS NULL THEN 11111 ELSE max_payment_fund.fund_key END) AS INTEGER) AS fr_max_dntn_fund_key
			,(CASE WHEN max_payment_fund.fund_cd IS NULL THEN 'default' ELSE max_payment_fund.fund_cd END) AS fr_max_dntn_fund_cd
			,CAST((CASE WHEN min_payment_fund.fund_key IS NULL THEN 11111 ELSE min_payment_fund.fund_key END) AS INTEGER) AS fr_min_dntn_fund_key
			,(CASE WHEN min_payment_fund.fund_cd IS NULL THEN 'default' ELSE min_payment_fund.fund_cd END) AS fr_min_dntn_fund_cd
			,priority_portfolio.portfolio_category
			,donation_summary.PM_A181
			,CAST(donation_summary.PM_A182 AS INTEGER)
			,CAST(donation_summary.PM_A183 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A184 AS INTEGER)
			,CAST(donation_summary.PM_A185 AS DECIMAL(13, 2))
			,CAST(donation_summary.PM_A186 AS INTEGER)
			,CAST(donation_summary.PM_A187 AS DECIMAL(13, 2))
			,donation_summary.PM_A188
			,CAST(donation_summary.PM_A189 AS date)
			,CAST(donation_summary.PM_A190 AS date)
			,CAST(donation_summary.PM_A191 AS date)
			,first_donation_analysis.fr_first_dntn_typ
			,first_donation_analysis.fr_first_gift_src_cd
			,CAST(first_donation_analysis.fr_first_dntn_dt AS date)
			,first_donation_analysis.fr_first_dntn_fcc_cd
			,first_donation_analysis.fr_first_dntn_amt
			,first_donation_analysis.fr_first_dstr_gift_src_cd
			,first_donation_analysis.fr_first_dstr_dntn_fund_cd
			,CAST(first_donation_analysis.fr_first_dstr_dntn_dt AS date)
			,first_donation_analysis.fr_first_dstr_dntn_fcc_cd
			,first_donation_analysis.fr_first_dstr_dntn_amt
			,first_donation_analysis.fr_first_non_distr_gift_src_cd
			,first_donation_analysis.fr_first_non_distr_dntn_fnd_cd
			,CAST(first_donation_analysis.fr_first_non_distr_dntn_dt AS date)
			,first_donation_analysis.fr_first_non_distr_dntn_fcc_cd
			,first_donation_analysis.fr_first_non_distr_dntn_amt
			,benevity_donation_count.adj_seq
			,(CASE WHEN ((benevity_donation_count.adj_seq > 0) AND (benevity_donation_count.adj_seq = CAST(donation_summary.PM_A11 AS INTEGER))) THEN 1 ELSE 0 END)
			,CAST(contact_pref.PM_A2 AS TIMESTAMP)
			,'MKTG'
			,0
		FROM((((((((((
			contact_preference_filter as
			contact_pref 
			RIGHT OUTER JOIN (
			constituency_base as
			constituency 
			
			
			-- COMMENTED OUT: The following 4 RIGHT OUTER JOINs are not being used in the SELECT statement
			-- These joins were adding unnecessary processing overhead without contributing any columns to the final result
			-- Can be uncommented if columns from these tables are needed in future modifications
			
			-- RIGHT OUTER JOIN(
			-- donations_over_1_million as
			-- donations_1m_plus 
			-- RIGHT OUTER JOIN(
			-- donations_over_100k as
			-- donations_100k_plus 
			-- RIGHT OUTER JOIN(
			-- donations_25k_to_100k as
			-- donations_25k_to_100k 
			-- RIGHT OUTER JOIN(
			-- donations_10k_to_25k as     
			-- donations_10k_to_25k 
			
			RIGHT OUTER JOIN(
			donations_over_10k as
			donations_10k_plus 
			RIGHT OUTER JOIN(
			non_disaster_donations as
			non_disaster_don 
			RIGHT OUTER JOIN(
			disaster_donations as
			disaster_don 
			RIGHT OUTER JOIN(
			donations_under_100 as
			donations_under_100 
			RIGHT OUTER JOIN(
			donations_100_to_1k as
			donations_100_to_1k 
			RIGHT OUTER JOIN(
			donations_over_1k as
			donations_1k_plus
			RIGHT OUTER JOIN(
			donation_summary as
			donation_summary 
			LEFT OUTER JOIN
			daily_donation_summary as
			daily_donation_summary
			 ON ((daily_donation_summary.PM_A0 = donation_summary.PM_A0) AND (daily_donation_summary.PM_A1 = donation_summary.PM_A9))) ON ((donation_summary.PM_A0 = donations_1k_plus.PM_A0) AND (donation_summary.PM_A28 = donations_1k_plus.PM_A1))) ON ((donation_summary.PM_A0 = donations_100_to_1k.PM_A0) AND (donation_summary.PM_A29 = donations_100_to_1k.PM_A1))) ON ((donation_summary.PM_A0 = donations_under_100.PM_A0) AND (donation_summary.PM_A30 = donations_under_100.PM_A1))) ON ((donation_summary.PM_A0 = disaster_don.PM_A0) AND (donation_summary.PM_A15 = disaster_don.PM_A1))) ON ((donation_summary.PM_A0 = non_disaster_don.PM_A0) AND (donation_summary.PM_A21 = non_disaster_don.PM_A1))) ON ((donation_summary.PM_A0 = donations_10k_plus.PM_A0) AND (donation_summary.PM_A16 = donations_10k_plus.PM_A1))) 
			 
				
				-- CORRESPONDING ON CLAUSES for the commented tables above:
				
			-- ON ((donation_summary.PM_A0 = donations_10k_to_25k.PM_A0) AND (donation_summary.PM_A17 = donations_10k_to_25k.PM_A1))) 
			-- ON ((donation_summary.PM_A0 = donations_25k_to_100k.PM_A0) AND (donation_summary.PM_A18 = donations_25k_to_100k.PM_A1))) 
			-- ON ((donation_summary.PM_A0 = donations_100k_plus.PM_A0) AND (donation_summary.PM_A19 = donations_100k_plus.PM_A1))) 
			-- ON ((donation_summary.PM_A0 = donations_1m_plus.PM_A0) AND (donation_summary.PM_A20 = donations_1m_plus.PM_A1))) 
			
			ON (donation_summary.PM_A0 = constituency.PM_A0)) ON (donation_summary.PM_A0 = contact_pref.PM_A0))
			 
			LEFT OUTER JOIN
			donor_rolling_year_analysis as donor_rolling_analysis ON (donor_rolling_analysis.PM_A0 = donation_summary.PM_A0))
			
			LEFT OUTER JOIN
			first_donation_fund as first_donation_fund ON (first_donation_fund.cnst_mstr_id = donation_summary.PM_A0))
					
			LEFT OUTER JOIN
			latest_donation_fund as latest_donation_fund ON (latest_donation_fund.cnst_mstr_id = donation_summary.PM_A0))
				
			LEFT OUTER JOIN
			minimum_payment_fund as min_payment_fund ON (min_payment_fund.cnst_mstr_id = donation_summary.PM_A0))
				
			LEFT OUTER JOIN
			maximum_payment_fund as max_payment_fund ON (max_payment_fund.cnst_mstr_id = donation_summary.PM_A0))
				
			LEFT OUTER JOIN
			latest_donation_with_affiliation as latest_donation_affiliation ON (latest_donation_affiliation.cnst_mstr_id = donation_summary.PM_A0))
						
			LEFT OUTER JOIN
			highest_priority_portfolio as priority_portfolio  ON (priority_portfolio.cnst_mstr_id = donation_summary.PM_A0))
			LEFT OUTER JOIN 
			first_donation_analysis as first_donation_analysis ON (first_donation_analysis.cnst_mstr_id = donation_summary.PM_A0))
			LEFT OUTER JOIN
			benevity_donation_count as benevity_donation_count ON (benevity_donation_count.dim_giftran_key = donation_summary.PM_A0));

		TRUNCATE TABLE mods_bi.mktg_ops_tbls.gms_arc_fr_smry;
		
		-- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.gms_arc_fr_smry
        SELECT * FROM mods_bi.mktg_stage_tbls.gms_arc_fr_smry_stg;
			
		v_end_time := GETDATE();
		v_ok_message = cast((select count(*) from mods_bi.mktg_ops_tbls.gms_arc_fr_smry) as nvarchar)+ ' Records inserted.';
        
        UPDATE mods_bi.mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message
        WHERE proc_name = 'ld_gms_arc_fr_smry' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;
		
	EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_gms_arc_fr_smry: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_gms_arc_fr_smry', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
