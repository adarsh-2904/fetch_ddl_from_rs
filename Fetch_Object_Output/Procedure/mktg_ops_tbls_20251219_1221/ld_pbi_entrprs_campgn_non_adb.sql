CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_pbi_entrprs_campgn_non_adb()
 LANGUAGE plpgsql
AS $$
/*
Created By:	Michael Andrien
Create Date:	07/20/2022
Purpose:		This macro was create to replace the manual SQL steps Robert Shoemake had been running to maintain non-Adobe cross-promotion campaign and enterprise contact data referenced in PBI dashboards.  The macro 
will be schedule to run daily and relocates the data formally stored in data_lab_mktg_tbls.rs_non_adb_cross_promo to mktg_ops_tbls.pbi_entrprs_campgn_non_adb.  This allows the Cross-Promo and Enterprise Contact PBI model reloads to be
fully automated.

Modified By:	Michael Andrien
Modified Date:	08/31/2022
Purpose:	Replaced INTERVAL date logic with add_months function
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_pbi_entrprs_campgn_non_adb', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		-- Truncate staging table
		TRUNCATE TABLE mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg;
		
		/*----------------------- XLOB BIO to CFR ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'BIO'::char(4) AS LOB,
			'CFR'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: BIO XLOB to CFR Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'BIO_XLOB_CFR_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'BIO' 
			AND target_audience = 'CFR' 
			AND channel = 'Email' 
			AND xpromo_ind = 1  
			AND is_trigg_msg_ind = 0 
			AND sent_cnt > 0;
			
		/*----------------------- XLOB BIO to TS ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'BIO'::char(4) AS LOB,
			'TS'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: BIO XLOB to TS Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'BIO_XLOB_TS_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'BIO'
			AND target_audience = 'TS'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB BIO to VOL ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'BIO'::char(4) AS LOB,
			'VOL'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: BIO XLOB to VOL Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'BIO_XLOB_VOL_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'BIO'
			AND target_audience = 'VOL'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB BIO to All Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'BIO'::char(4) AS LOB,
			'XLOB'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: BIO XLOB to All Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_BIO_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'BIO'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB CFR to BIO ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'CFR'::char(4) AS LOB,
			'BIO'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: CFR XLOB to BIO Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'CFR_XLOB_BIO_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'CFR'
			AND target_audience = 'BIO'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB CFR to TS ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'CFR'::char(4) AS LOB,
			'TS'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: CFR XLOB to TS Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'CFR_XLOB_TS_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'CFR'
			AND target_audience = 'TS'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB CFR to VOL ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'CFR'::char(4) AS LOB,
			'VOL'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: CFR XLOB to VOL Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'CFR_XLOB_VOL_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'CFR'
			AND target_audience = 'VOL'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB CFR to All Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'CFR'::char(4) AS LOB,
			'XLOB'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: CFR XLOB to All Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_CFR_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'CFR'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB TS to BIO ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'TS'::char(4) AS LOB,
			'BIO'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: TS XLOB to BIO Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'TS_XLOB_BIO_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'TS'
			AND target_audience = 'BIO'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB TS to CFR ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'TS'::char(4) AS LOB,
			'CFR'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: TS XLOB to CFR Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'TS_XLOB_CFR_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'TS'
			AND target_audience = 'CFR'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB TS to VOL ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'TS'::char(4) AS LOB,
			'VOL'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: TS XLOB to VOL Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'TS_XLOB_VOL_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'TS'
			AND target_audience = 'VOL'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB TS to All Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'TS'::char(4) AS LOB,
			'XLOB'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: TS XLOB to All Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_TS_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'TS'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB VOL to BIO ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'VOL'::char(4) AS LOB,
			'BIO'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: VOL XLOB to BIO Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'VOL_XLOB_BIO_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'VOL'
			AND target_audience = 'BIO'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB VOL to CFR ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'VOL'::char(4) AS LOB,
			'CFR'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: VOL XLOB to CFR Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'VOL_XLOB_CFR_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'VOL'
			AND target_audience = 'CFR'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB VOL to TS ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'VOL'::char(4) AS LOB,
			'TS'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: VOL XLOB to TS Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'VOL_XLOB_TS_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'VOL'
			AND target_audience = 'TS'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB VOL to All Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'VOL'::char(4) AS LOB,
			'XLOB'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: VOL XLOB to All Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_TS_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'VOL'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB to BIO Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'XLOB'::char(4) AS LOB,
			'BIO'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: XLOB to BIO Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_to_BIO_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND target_audience = 'BIO'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB to CFR Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'XLOB'::char(4) AS LOB,
			'CFR'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: XLOB to CFR Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_to_CFR_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND target_audience = 'CFR'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB to TS Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'XLOB'::char(4) AS LOB,
			'TS'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: XLOB to TS Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_to_TS_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND target_audience = 'TS'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB to VOL Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'XLOB'::char(4) AS LOB,
			'VOL'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: XLOB to VOL Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_to_VOL_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND target_audience = 'VOL'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- XLOB to All Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'XLOB'::char(4) AS LOB,
			'XLOB'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: All XLOB Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'XLOB_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;

		/*----------------------- Crossnotes to All Audiences ------------------------*/
		INSERT INTO mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg
		SELECT 
			'2099-01-01'::date AS email_launch_dt,
			'Crossnotes'::char(10) AS LOB,
			'XLOB'::char(4) AS audience_target,
			'Email' AS channel,
			COUNT(DISTINCT src_cd) AS target_cnt,
			'Email Benchmark: Crossnotes XLOB to All Dynamic' AS delivery_label,
			'' AS target_method,
			'NA' AS approval,
			SUM(sent_cnt) AS final_qty,
			NULL AS notes,
			SUM(open_cnt) AS opens,
			SUM(click_cnt) AS clicks,
			SUM(unsub_cnt) AS unsubs,
			NULL AS resp,
			NULL AS Rev,
			NULL AS cost_per_piece,
			NULL AS dials,
			NULL AS connects,
			NULL,
			NULL AS cost_per_dial,
			'BM Adobe' AS source_sys,
			COUNT(DISTINCT src_cd) AS src_cd,
			'Crossnotes_EmailBenchmark' AS subsrc_cd,
			NULL,
			99 AS load_id,
			CURRENT_DATE AS load_dt,
			1 AS xpromo_ind
		FROM 
			mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE 
			launch_dt BETWEEN DATEADD(month, -12, CURRENT_DATE) + 1 AND CURRENT_DATE
			AND lob = 'Crossnotes'
			AND channel = 'Email'
			AND xpromo_ind = 1
			AND is_trigg_msg_ind = 0
			AND sent_cnt > 0;
		
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_non_adb
		WHERE load_id = 99;
        
        -- Insert data from staging to target
        INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_non_adb
        SELECT * FROM mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_stage_tbls.pbi_entrprs_campgn_non_adb_stg) as INTEGER)
        WHERE proc_name = 'ld_pbi_entrprs_campgn_non_adb' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_pbi_entrprs_campgn_non_adb: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_pbi_entrprs_campgn_non_adb', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
