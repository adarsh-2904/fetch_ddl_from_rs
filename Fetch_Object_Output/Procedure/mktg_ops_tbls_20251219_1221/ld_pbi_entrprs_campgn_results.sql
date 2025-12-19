CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_pbi_entrprs_campgn_results()
 LANGUAGE plpgsql
AS $$
/*
Created By:	Michael Andrien
Create Date:	07/19/2022
Purpose:		This macro was create to replace the manual SQL steps Robert Shoemake had been running to maintain cross-promotion campaign and enterprise contact data referenced in PBI dashboards.  The macro 
will be schedule to run daily and relocates the data formally stored in data_lab_mktg_tbls.rs_prod_enterprise_results to mktg_ops_tbls.ld_pbi_entrprs_campgn_results.  This allows the Cross-Promo and Enterprise Contact PBI model reloads to be
fully automated.

Modified By:	Michael Andrien
Modified Date:	07/20/2022
Purpose:		Removed all references to data_lab_mktg_tbls.

Modified By:	Majeed Mohammad
Modified Date:	04/13/2023
Purpose:	Updated the sections for Email Revenue and Email Gift Count. Replaced the view bz_dim_delivery with a subquery to select one record for the combination of Src_cd and Subsrc_cd. This duplicate records in this view for these column combination was causing 1:M join with the bz_dim_trans table. The numbers were being double counted. 

Modified By:	Michael Andrien
Modified Date:	09/02/2025
Purpose: Fixed the join in the --XLOB to All Audiences-- section.  The INNER Join below referenced mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd on both sides of the join.
INNER JOIN mktg_ops_tbls.pbi_entrprs_campgn_smry  ON mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
	v_ins_count INT := 0;
    v_del_count INT := 0;
    v_rows INT;
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_pbi_entrprs_campgn_results', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		-- Step 5 - Benchmark Sends Inserts: DELETE statement
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_results 
		WHERE src_system NOT IN ('BM - Adobe Analytics', 'Google Analytics (manual)');
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		-- INSERT statement for Adobe RCB Visits (RSG source code indicates Paid Search)
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			CAST('Adobe RCB Visits' AS VARCHAR(45)) AS result_type, 
			subsrc_cd, 
			SUM(visit_cnt) AS campaign_result, 
			CAST('Adobe Analytics' AS VARCHAR(45)) AS src_system, 
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rcb_txn 
		WHERE src_cd <> 'RSG00000E017'
		GROUP BY subsrc_cd
		HAVING SUM(visit_cnt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Adobe RCB Appts' AS result_type, 
			subsrc_cd, 
			SUM(appt_cnt) AS campaign_result, 
			'Adobe Analytics' AS src_system, 
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rcb_txn 
		WHERE src_cd <> 'RSG00000E017'
		GROUP BY subsrc_cd
		HAVING SUM(appt_cnt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Triggered Adobe RCB Appts' AS result_type,  
			(CASE cal.calendar_qtr
				WHEN 1 THEN '01-01-'
				WHEN 2 THEN '04-01-'
				WHEN 3 THEN '07-01-'
				WHEN 4 THEN '10-01-'
			END || CAST(calendar_yr AS VARCHAR)) || subsrc_cd AS subsrc_cd, 
			SUM(appt_cnt) AS campaign_result, 
			'Adobe Analytics' AS src_system, 
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rcb_txn 
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON bz_adobe_analytics_rcb_txn.month_dt = cal.calendar_dt
		WHERE subsrc_cd IN (
			SELECT subsrc_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
			WHERE is_trigg_msg_ind = 1
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Triggered Adobe RCB Visits' AS result_type,  
			(CASE cal.calendar_qtr
				WHEN 1 THEN '01-01-'
				WHEN 2 THEN '04-01-'
				WHEN 3 THEN '07-01-'
				WHEN 4 THEN '10-01-'
			END || CAST(calendar_yr AS VARCHAR)) || subsrc_cd AS subsrc_cd, 
			SUM(visit_cnt) AS campaign_result, 
			'Adobe Analytics' AS src_system, 
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rcb_txn 
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON bz_adobe_analytics_rcb_txn.month_dt = cal.calendar_dt
		WHERE subsrc_cd IN (
			SELECT subsrc_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
			WHERE is_trigg_msg_ind = 1
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Adobe RCO Visits' AS result_type, 
			subsrc_cd, 
			SUM(visit_cnt) AS campaign_result, 
			'Adobe Analytics' AS src_system, 
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rco_txn 
		GROUP BY subsrc_cd
		HAVING SUM(visit_cnt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Adobe RCO Revenue' AS result_type, 
			subsrc_cd, 
			SUM(revenue_amt) AS campaign_result, 
			'Adobe Analytics' AS src_system, 
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rco_txn 
		GROUP BY subsrc_cd
		HAVING SUM(revenue_amt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Adobe RCO Orders' AS result_type, 
			subsrc_cd, 
			SUM(order_cnt) AS campaign_result, 
			'Adobe Analytics' AS src_system, 
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rco_txn 
		GROUP BY subsrc_cd
		HAVING SUM(order_cnt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;


		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Triggered Adobe RCO Orders' AS result_type,
			(CASE cal.calendar_qtr
				WHEN 1 THEN '01-01-'
				WHEN 2 THEN '04-01-'
				WHEN 3 THEN '07-01-'
				WHEN 4 THEN '10-01-'
			END || CAST(calendar_yr AS VARCHAR)) || subsrc_cd AS subsrc_cd,
			SUM(order_cnt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rco_txn 
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON bz_adobe_analytics_rco_txn.month_dt = cal.calendar_dt
		WHERE subsrc_cd IN (
			SELECT subsrc_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
			WHERE is_trigg_msg_ind = 1
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Triggered Adobe RCO Visits' AS result_type,
			(CASE cal.calendar_qtr
				WHEN 1 THEN '01-01-'
				WHEN 2 THEN '04-01-'
				WHEN 3 THEN '07-01-'
				WHEN 4 THEN '10-01-'
			END || CAST(calendar_yr AS VARCHAR)) || subsrc_cd AS subsrc_cd,
			SUM(visit_cnt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rco_txn 
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON bz_adobe_analytics_rco_txn.month_dt = cal.calendar_dt
		WHERE subsrc_cd IN (
			SELECT subsrc_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
			WHERE is_trigg_msg_ind = 1
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Triggered Adobe RCO Revenue' AS result_type,
			(CASE cal.calendar_qtr
				WHEN 1 THEN '01-01-'
				WHEN 2 THEN '04-01-'
				WHEN 3 THEN '07-01-'
				WHEN 4 THEN '10-01-'
			END || CAST(calendar_yr AS VARCHAR)) || subsrc_cd AS subsrc_cd,
			SUM(revenue_amt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_rco_txn 
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON bz_adobe_analytics_rco_txn.month_dt = cal.calendar_dt
		WHERE subsrc_cd IN (
			SELECT subsrc_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
			WHERE is_trigg_msg_ind = 1
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Adobe TS Visits' AS result_type,
			subsrc_cd,
			SUM(visit_cnt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_ts_txn 
		GROUP BY 2
		HAVING SUM(visit_cnt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Adobe TS Revenue' AS result_type,
			subsrc_cd,
			SUM(revenue_amt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_ts_txn 
		GROUP BY 2
		HAVING SUM(revenue_amt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;
		
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Adobe TS Orders' AS result_type,
			subsrc_cd,
			SUM(order_cnt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_ts_txn 
		GROUP BY 2
		HAVING SUM(order_cnt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Triggered Adobe TS Visits' AS result_type,
			(CASE cal.calendar_qtr
				WHEN 1 THEN '01-01-'
				WHEN 2 THEN '04-01-'
				WHEN 3 THEN '07-01-'
				WHEN 4 THEN '10-01-'
			END || CAST(calendar_yr AS VARCHAR)) || subsrc_cd AS subsrc_cd,
			SUM(visit_cnt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_ts_txn 
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON bz_adobe_analytics_ts_txn.month_dt = cal.calendar_dt
		WHERE subsrc_cd IN (
			SELECT subsrc_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
			WHERE is_trigg_msg_ind = 1
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Triggered Adobe TS Revenue' AS result_type,
			(CASE cal.calendar_qtr
				WHEN 1 THEN '01-01-'
				WHEN 2 THEN '04-01-'
				WHEN 3 THEN '07-01-'
				WHEN 4 THEN '10-01-'
			END || CAST(calendar_yr AS VARCHAR)) || subsrc_cd AS subsrc_cd,
			SUM(revenue_amt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_ts_txn 
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON bz_adobe_analytics_ts_txn.month_dt = cal.calendar_dt
		WHERE subsrc_cd IN (
			SELECT subsrc_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
			WHERE is_trigg_msg_ind = 1
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Triggered Adobe TS Orders' AS result_type,
			(CASE cal.calendar_qtr
				WHEN 1 THEN '01-01-'
				WHEN 2 THEN '04-01-'
				WHEN 3 THEN '07-01-'
				WHEN 4 THEN '10-01-'
			END || CAST(calendar_yr AS VARCHAR)) || subsrc_cd AS subsrc_cd,
			SUM(order_cnt) AS campaign_result,
			'Adobe Analytics' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_tbls.bz_adobe_analytics_ts_txn 
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON bz_adobe_analytics_ts_txn.month_dt = cal.calendar_dt
		WHERE subsrc_cd IN (
			SELECT subsrc_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
			WHERE is_trigg_msg_ind = 1
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'BIO Adobe Credited Appts' AS result_type,
			CAST(camp_wave_key AS VARCHAR(50)) AS subsrc_cd,
			SUM(totl_credt_appt_cnt) AS campaign_result,
			'BIO Adobe Attribution' AS src_system,
			CURRENT_DATE AS load_date
		FROM eda.bio_campaign_vws.bzl_campgn_smry_rslt 
		GROUP BY 2
		HAVING SUM(totl_credt_appt_cnt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'BIO Adobe Aggregate XLOB Credited Appts' AS result_type,
			CAST(campaign_key AS VARCHAR(50)) AS subsrc_cd,
			SUM(totl_credt_appt_cnt) AS campaign_result,
			'BIO Adobe Attribution' AS src_system,
			CURRENT_DATE AS load_date
		FROM eda.bio_campaign_vws.bzl_campgn_smry_rslt
		WHERE campaign_key IN (
			SELECT src_cd 
			FROM mktg_ops_tbls.pbi_entrprs_campgn_smry  
			WHERE src_system = 'Adobe - BIO' 
				AND (delivery_label LIKE 'BHQ_CAMPAIGN_CROSS_LOB_BVM%'
					OR delivery_label LIKE 'BHQ_CAMPAIGN_CROSS_LOB_MO_DM%'
					OR delivery_label LIKE 'DM_BHQ_RE_WB_ABO_CrossLOB%')
		)
		GROUP BY 2;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*--Direct Mail joined at the source code level */
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Direct Mail Revenue' AS result_type,
			campgn_src_cd AS subsrc_cd,
			SUM(fr_pmt_amt) AS campaign_result,
			'EDW DM' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_vws.gms_arc_fr_txn 
		WHERE fr_pmt_amt > 0 
			AND dntn_gift_dt >= DATE '2017-01-01'
		GROUP BY 2
		HAVING SUM(fr_pmt_amt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT 
			'Direct Mail Gift Count' AS result_type,
			campgn_src_cd AS subsrc_cd,
			COUNT(nk_gift_id) AS campaign_result,
			'EDW DM' AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_vws.gms_arc_fr_txn 
		WHERE fr_pmt_amt > 0 
			AND dntn_gift_dt >= DATE '2017-01-01'
		GROUP BY 2
		HAVING COUNT(nk_gift_id) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT
			'Email Revenue' AS result_type,
			bz_dim_trans_src.trans_sub_src_cd AS subsrc_cd,
			SUM(bz_fact_dnr_trans.amt) AS campaign_result,
			'EDW/RCO Vws EM' AS src_system,
			CURRENT_DATE AS load_date
		FROM
			(SELECT src_cd, subsrc_cd
			 FROM (
				 SELECT src_cd, subsrc_cd, srcsys_trans_ts,
						ROW_NUMBER() OVER (PARTITION BY src_cd, subsrc_cd ORDER BY srcsys_trans_ts DESC) AS rn
				 FROM mktg_ops_vws.bz_dim_delivery
				 WHERE is_trigg_msg_ind = 0
					 AND delivery_start_dt >= DATE '2017-01-01'
					 AND delivery_nm NOT LIKE 'FCP%'
					 AND src_cd <> 'RSG00000E111'
					 AND exclude_rptng_ind = 0
			 ) ranked
			 WHERE rn = 1
			) AS bz_del
		LEFT JOIN eda.rco_vws.bz_dim_trans_src 
			ON bz_del.src_cd = bz_dim_trans_src.trans_src_cd 
			AND bz_del.subsrc_cd = bz_dim_trans_src.trans_sub_src_cd
		LEFT JOIN eda.rco_vws.bz_fact_dnr_trans 
			ON bz_fact_dnr_trans.trans_src_key = bz_dim_trans_src.trans_src_key
		LEFT JOIN (
			SELECT src_key, src_cd, src_dsc
			FROM (
				SELECT src_key, src_cd, src_dsc, active_ind,
					   ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
				FROM mktg_ops_vws.gmpbzal_dim_src
			) ranked
			WHERE rn = 1
		) dim_src ON bz_dim_trans_src.trans_src_cd = dim_src.src_cd
		WHERE
			bz_fact_dnr_trans.trans_stat IN ('Pending','Processed')
			AND bz_fact_dnr_trans.amt > 0
		GROUP BY 2
		HAVING SUM(bz_fact_dnr_trans.amt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results  
		SELECT
			'Email Gift Count' AS result_type,
			bz_dim_trans_src.trans_sub_src_cd AS subsrc_cd,
			COUNT(bz_fact_dnr_trans.trans_id) AS campaign_result,
			'EDW/RCO Vws EM' AS src_system,
			CURRENT_DATE AS load_date
		FROM
			(SELECT src_cd, subsrc_cd
			 FROM (
				 SELECT src_cd, subsrc_cd, srcsys_trans_ts,
						ROW_NUMBER() OVER (PARTITION BY src_cd, subsrc_cd ORDER BY srcsys_trans_ts DESC) AS rn
				 FROM mktg_ops_vws.bz_dim_delivery
				 WHERE is_trigg_msg_ind = 0
					 AND delivery_start_dt >= DATE '2017-01-01'
					 AND delivery_nm NOT LIKE 'FCP%'
					 AND src_cd <> 'RSG00000E111'
					 AND exclude_rptng_ind = 0
			 ) ranked
			 WHERE rn = 1
			) AS bz_del
		LEFT JOIN eda.rco_vws.bz_dim_trans_src 
			ON bz_del.src_cd = bz_dim_trans_src.trans_src_cd 
			AND bz_del.subsrc_cd = bz_dim_trans_src.trans_sub_src_cd
		LEFT JOIN eda.rco_vws.bz_fact_dnr_trans 
			ON bz_fact_dnr_trans.trans_src_key = bz_dim_trans_src.trans_src_key
		LEFT JOIN (
			SELECT src_key, src_cd, src_dsc
			FROM (
				SELECT src_key, src_cd, src_dsc, active_ind,
					   ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
				FROM mktg_ops_vws.gmpbzal_dim_src
			) ranked
			WHERE rn = 1
		) dim_src ON bz_dim_trans_src.trans_src_cd = dim_src.src_cd
		WHERE
			bz_fact_dnr_trans.trans_stat IN ('Pending','Processed')
			AND bz_fact_dnr_trans.amt > 0
		GROUP BY 2
		HAVING COUNT(bz_fact_dnr_trans.trans_id) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*--Manually loading TS results provide by TS Google Analytics to with their figures */
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_results 
		WHERE (
			subsrc_cd IN ('nhqfy21dects10bio', 'nhqfy21dects10cfr', 'nhqfy21dects30bio', 'nhqfy21dects30cfr') /*--2012_TS Cross LOB: Donor Thank You Offer/RSC20120E003 */
			OR subsrc_cd IN ('nhqfy21febtsstorebio', 'nhqfy21febtsstorecfr') /*--2102_TS Cross LOB: Store Offer/RSC21020E005 */
			OR subsrc_cd IN ('nhqfy21tscoursevol') /*--2103_TS Cross LOB: VOL Course Offer/RSC21030E002 */
			OR subsrc_cd IN ('nhqfy21maytsstore10bio', 'nhqfy21maytsstore10cfr', 'nhqfy21maytsstore10vol', 'nhqfy21maytsstore20bio', 'nhqfy21maytsstore20cfr', 'nhqfy21maytsstore20vol') /*--2105_TS Cross LOB: Store Offer/RSC21050E005 */
		)
		AND src_system <> 'BM - Adobe Analytics'
		AND src_system = 'Adobe Analytics';
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		/*  Begin Step 6 - benchmark result inserts */
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_results 
		WHERE src_system = 'BM - Adobe Analytics';
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;


		----------------------------------------------------------------------------- Adobe RCB Visits --------------------------------------------------------------------------

		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   cast('XLOB_EmailBenchmark' as varchar(45)) as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--Crossnotes to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   cast('Crossnotes_EmailBenchmark' as varchar(45)) as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'Crossnotes' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast('Adobe RCB Visits' as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;


		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast('Adobe RCB Visits' as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;


		----------------------------------------------------------------------------- Adobe RCO Visits --------------------------------------------------------------------------

		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--Crossnotes to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'Crossnotes_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'Crossnotes' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' 
		and target_audience = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' 
		and target_audience = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' 
		and target_audience = 'TS' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;
		
		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' 
		and target_audience = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' 
		and target_audience = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' 
		and target_audience = 'TS' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' 
		and target_audience = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' 
		and target_audience = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' 
		and target_audience = 'TS' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		----------------------------------------------------------------------------- Adobe RCB Appts --------------------------------------------------------------------------

		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--Crossnotes to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'Crossnotes_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'Crossnotes' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' 
		and target_audience = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' 
		and target_audience = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'BIO' 
		and target_audience = 'TS' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' 
		and target_audience = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' 
		and target_audience = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'CFR' 
		and target_audience = 'TS' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' 
		and target_audience = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' 
		and target_audience = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'VOL' 
		and target_audience = 'TS' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'BIO' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'CFR' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result, 
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry 
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCB Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date
		and lob = 'TS' 
		and target_audience = 'VOL' 
		and channel = 'Email' 
		and xpromo_ind = 1 
		and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		----------------------------------------------------------------------------- Adobe TS Visits --------------------------------------------------------------------------

		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;
		
		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Visits'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		----------------------------------------------------------------------------- Adobe TS Revenue --------------------------------------------------------------------------

		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		----------------------------------------------------------------------------- Email Revenue --------------------------------------------------------------------------

		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--Crossnotes to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'Crossnotes_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'Crossnotes' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1 and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1 and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		---------------------------------------------------------------------------- Email Gift Count --------------------------------------------------------------------------

		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--Crossnotes to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'Crossnotes_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'Crossnotes' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Email Gift Count'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;


		----------------------------------------------------------------------------- Adobe RCO Orders --------------------------------------------------------------------------
		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--Crossnotes to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'Crossnotes_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'Crossnotes' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;
		
		----------------------------------------------------------------------------- Adobe RCO Revenue --------------------------------------------------------------------------
		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--Crossnotes to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'Crossnotes_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'Crossnotes' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;
		
		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe RCO Revenue'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		----------------------------------------------------------------------------- BIO Adobe Aggregate XLOB Credited Appts --------------------------------------------------------------------------
		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   cast('XLOB_EmailBenchmark' as varchar(45)) as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;
		
		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Aggregate XLOB Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		----------------------------------------------------------------------------- BIO Adobe Credited Appts --------------------------------------------------------------------------
		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;
		
		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'BIO Adobe Credited Appts'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		----------------------------------------------------------------------------- Adobe TS Orders --------------------------------------------------------------------------
		--XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to All Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--BIO XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'BIO_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'BIO' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--CFR XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'CFR_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'CFR' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to VOL Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_VOL_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'VOL' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--TS XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'TS_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'TS' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to BIO Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_BIO_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'BIO' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to CFR Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_CFR_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'CFR' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		--VOL XLOB to TS Audiences--
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_results 
		select cast(result_type as varchar(45)) as result_type, 
			   'VOL_XLOB_TS_EmailBenchmark' as subsrc_cd, 
			   sum(campaign_result) as campaign_result,  
			   'BM - Adobe Analytics' as src_system, 
			   current_date as load_date
		from  mktg_ops_tbls.pbi_entrprs_campgn_results 
		inner join mktg_ops_tbls.pbi_entrprs_campgn_smry  
			on mktg_ops_tbls.pbi_entrprs_campgn_results.subsrc_cd = mktg_ops_tbls.pbi_entrprs_campgn_smry.subsrc_cd
		where result_type = 'Adobe TS Orders'
		and launch_dt between dateadd(month, -12, current_date) + 1  and current_date  
		and lob = 'VOL' and target_audience = 'TS' and channel = 'Email' and xpromo_ind = 1  and is_trigg_msg_ind = 0
		group by 1,2,4,5;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;
		
        v_end_time := GETDATE();
		v_ok_message := v_ins_count || ' rows inserted, ' ||
                        v_del_count || ' rows deleted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = v_ins_count + v_del_count
        WHERE proc_name = 'ld_pbi_entrprs_campgn_results' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE();
			v_error_message := 'Error in ld_pbi_entrprs_campgn_results: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_pbi_entrprs_campgn_results', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
