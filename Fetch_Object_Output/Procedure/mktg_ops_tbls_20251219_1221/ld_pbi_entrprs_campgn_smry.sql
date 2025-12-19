CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_pbi_entrprs_campgn_smry()
 LANGUAGE plpgsql
AS $$
/*
Created By:	Michael Andrien
Create Date:	07/19/2022
Purpose:		This macro was create to replace the manual SQL steps Robert Shoemake had been running to maintain cross-promotion campaign and enterprise contact data referenced in PBI dashboards.  The macro 
will be schedule to run daily and relocates the data formally stored in data_lab_mktg_tbls.rs_union_test_inserts to mktg_ops_tbls.pbi_entrprs_campgn_smry.  This allows the Cross-Promo and Enterprise Contact PBI model reloads to be
fully automated.

Modified By:	Michael Andrien
Modified Date:	07/20/2022
Purpose:		Removed all references to data_lab_mktg_tbls.

Modified By:	Majeed Mohammad
Modified Date:	09/07/2022
Purpose:	Added the below update statement to mktg_ops_tbls.pbi_entrprs_campgn_smry based on feedback from Amy
					when delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtLaborDayCrDSportCL_NA1_NA2_082422' then '2208_August Heartbeat'  
					
Modified By:	Majeed Mohammad
Modified Date:	11/30/2022
Purpose:	Added the below update statement to mktg_ops_tbls.pbi_entrprs_campgn_smry based on feedback from Amy					
						when delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtCrDBeanie_NOV10gcADP_NA4_NA1_NA2_111622' then '2211_Heartbeat Newsletter'
						
Modified By:	Michael Andrien
Modified Date:	01/05/2023
Purpose: Modified the date offset for the delete and insert sections below fromTRUNC(date,'yyyy') to add_months(trunc(current_date, 'mm'),-1) --TRUNC(date,'yyyy').  This was done 
because the original date offset prevented interaction with a month end date from being added to the table.

Modified By:	Majeed Mohammad
Modified Date:	04/03/2023
Purpose:	Added the below update statement to mktg_ops_tbls.pbi_entrprs_campgn_smry based on feedback from Amy					
						when delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtMrch_PeanutsTee_NA4_NA1_NA2_032523' then '2303_Heartbeat Newsletter'
						

Modified By:	Majeed Mohammad
Modified Date:	06/05/2023
Purpose:	Added the below update statement to mktg_ops_tbls.pbi_entrprs_campgn_smry 
								when delivery_label = 'TR_BHQ_IN_WB_CrossLOB_NA3_NA4_NA1_PROS_052223' then '2023 Supporter Survey XLOB Follow-up'
								when delivery_label = 'TX_BHQ_IN_WB_ABO_CrossLOBFund_NAPromo_NA4_NA1_CLOB_052223' then 'May Sustainer Campaign Text'
								when delivery_label = 'EM_BHQ_IN_WB_ABO_MayHrbt_CrDTowelADP_NA4_NA1_NA2_052423' then '2305_Heartbeat Newsletter'
					Added the below update to the section Heartbeat Exceptions for Multi-LOB - Updating LOB to Heartbeat  
								when src_cd = '70382' then 'Multi'
								when src_cd = '70398' then 'CFR'
								
Modified By:	Majeed Mohammad
Modified Date:	06/30/2023
Purpose:		Added the below update statement to mktg_ops_tbls.pbi_entrprs_campgn_smry 			
					when delivery_label = 'TX_BHQ_IN_WB_ABO_CrossLOBFund_NAPromo_NA4_NA1_CLOB_062723' then 'Fiscal Year End Appeal Text'	
					
Modified By: Michael Andrien
Modified Date: 07/10/2023
Purpose:  Modified the LOB update to include the line 'when scr_cd = '71060' then 'CFR'.

Modified By:	Majeed Mohammad
Modified Date:	08/02/2023
Purpose:		Added the below update statement to mktg_ops_tbls.pbi_entrprs_campgn_smry 	
									when delivery_label = 'TR_BHQ_IN_WB_CrossLOB_8SKSWP10ADP_NA4_NA1_PROS_073123' then '2023 Supporter Survey XLOB Follow-up'
						Added the below update to the section Heartbeat Exceptions for Multi-LOB - Updating LOB to Heartbeat  
								when src_cd = '71641' then 'Multi'
				
Modified By:	Majeed Mohammad
Modified Date:	10/16/2024 
Purpose:		Added the column appt_cnt to the table mktg_ops_tbls.pbi_entrprs_campgn_smry. Updated the logic in the macro to insert NULL where applicable. The macro inserts the APPT_CNT from the table mktg_ops_tbls.pbi_entrprs_campgn_non_adb in the manual campaigns section 
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
	v_ins_count INT := 0;
    v_upd_count INT := 0;
    v_del_count INT := 0;
    v_rows INT;
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_pbi_entrprs_campgn_smry', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		/*--delete records for Adobe Direct Mail campaigns; Refresh with new inserts*/
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
		WHERE src_system = 'Adobe - FR Triggered';
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		/*--re-insert updated Adobe FR Triggered Email Campaigns*/
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_smry
		SELECT 
			launch_dt, 
			CAST(channel AS VARCHAR(20)) AS channel, 
			LOB, 
			CAST(target_audience AS VARCHAR(25)) AS target_audience, 
			CASE 
				WHEN src_cd = 'RSW00000E006' AND subsrc_cd = 'NewDonor3phss' 
				THEN 'New Donor Welcome Series 3' 
				ELSE delivery_label 
			END AS delivery_label, 
			yrqtr, 
			src_cd, 
			subsrc_cd, 
			campgn_program_nm, 
			xpromo_ind, 
			is_trigg_msg_ind, 
			SUM(sent_cnt) AS sent_cnt, 
			SUM(open_cnt) AS open_cnt, 
			SUM(click_cnt) AS click_cnt, 
			SUM(bounce_cnt) AS bounce_cnt, 
			SUM(unsub_cnt) AS unsub_cnt, 
			NULL AS appt_cnt, 
			CAST('Adobe - FR Triggered' AS CHAR(25)) AS src_system, 
			CURRENT_DATE AS load_date
		FROM mktg_ops_vws.bzfc_trigrd_campgn_smry
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*---updated statement to combine FY22 New Donor Welcome Series 1 with New Donor Welcome Series */
		-- Delete records for Adobe Direct Mail campaigns; Refresh with new inserts
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
		WHERE src_system = 'Adobe - FR DM';
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		-- Direct Mail Campaigns Insert
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_smry
		SELECT 
			dmi.intrctn_dt + 14 AS in_home_dt,
			'Direct Mail' AS channel,
			CASE 
				WHEN dd.xpromo_from IS NULL THEN 
					CASE 
						WHEN mktg_ops_vws.gmpbzal_dim_src.src_dsc LIKE '%Acq%' THEN 'CFR'
						WHEN mktg_ops_vws.gmpbzal_dim_src.src_dsc LIKE '%Newsletter%' THEN 'Crossnotes'
						WHEN mktg_ops_vws.gmpbzal_dim_src.src_dsc LIKE '%Wills Guide%' THEN 'PG'
						WHEN mktg_ops_vws.gmpbzal_dim_src.src_dsc LIKE '%GPLG%' THEN 'PG'
					END
				ELSE dd.xpromo_from 
			END AS LOB,
			'tbd' AS target_audience,
			src_dsc,
			calendar_yr::varchar(4) || 'Q' || calendar_qtr::varchar(1) AS yrqtr,
			dmi.src_cd,
			'tbd' AS subsrc_cd,
			'Direct Mail' AS campgn_program_nm,
			xpromo_ind,
			is_trigg_msg_ind,
			SUM(dmi.mail_drop_cnt) AS sent_cnt,
			NULL AS open_cnt,
			NULL AS click_cnt,
			NULL AS bounce_cnt,
			NULL AS unsub_cnt,
			NULL AS appt_cnt,
			CAST('Adobe - FR DM' AS CHAR(25)) AS src_system,
			CURRENT_DATE AS load_date
		FROM mktg_ops_vws.bzfc_fact_dmail_interaction dmi
		LEFT JOIN mktg_ops_vws.bz_dim_delivery dd 
			ON dmi.delivery_key = dd.delivery_key
		LEFT JOIN mktg_ops_vws.gmpbzal_dim_src 
			ON dmi.src_key = mktg_ops_vws.gmpbzal_dim_src.src_key
		LEFT JOIN eda.dw_common_vws.dim_calendar cal 
			ON dmi.intrctn_dt + 14 = cal.calendar_dt
		WHERE dmi.intrctn_dt >= DATE '2017-01-01'
			AND exclude_rptng_ind = 0
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*--------------------------------------------- */
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
		WHERE src_system = 'Adobe - TS Triggered';
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		/*--------------------------------------------- */
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_smry 
		SELECT  
			launch_date, 
			'Email' AS channel, 
			'TS' AS LOB, 
			'BIO' AS target_audience, 
			calendar_yr::char(4) || 'Q' || calendar_qtr::char(1) || 'First Time Donor Welcome Series' AS delivery_label,
			calendar_yr::varchar(4) || 'Q' || calendar_qtr::varchar(1) AS yrqtr,
			'First Time Donor Welcome Series' AS src_cd, 
			'First Time Donor Welcome Series' AS subsrc_cd,
			'First Time Donor Welcomes Series' AS campgn_program_nm,
			CASE WHEN launch_date >= '2022-01-01'::date THEN 0 ELSE 1 END AS xpromo_ind, /*---offer ended in Dec 2021 */
			1 AS is_trigg_msg_ind,
			SUM(wave_cnt) AS sent_cnt, 
			SUM(opens) AS opens,
			SUM(clicks) AS clicks,
			SUM(bounce_cnt) AS bounce_cnt,
			SUM(unsub) AS unsub,
			NULL AS appt_cnt, 
			CAST('Adobe - TS Triggered' AS VARCHAR(25)) AS src_system, 
			CURRENT_DATE AS load_date
		FROM (
			SELECT 
				DATE(calendar_yr::varchar || '-' || 
					CASE cal.calendar_qtr
						WHEN 1 THEN '01'
						WHEN 2 THEN '04'
						WHEN 3 THEN '07'
						WHEN 4 THEN '10'
					END || '-01')
				AS launch_date,		
				cal.calendar_qtr, 
				calendar_yr,
				bz_dim_camp_wave.wave_cnt, 
				camp_nm, 
				BIO_CE.map_chan, 
				opens, 
				clicks, 
				bounce_cnt, 
				unsub
			FROM (
				SELECT 
					map_chan, 
					launch_dt, 
					campgn_key, 
					campgn_wave_key,
					SUM(opened_ind) AS opens,
					SUM(clicked_ind) AS clicks,
					SUM(bncd_any_ind) AS bounce_cnt,
					SUM(email_opt_out_ind) AS unsub,
					CURRENT_DATE AS last_refresh_dt
				FROM eda.bio_campaign_vws.bz_fact_email_e2e
				WHERE launch_dt >= '2017-01-01'::date
				GROUP BY 1,2,3,4
			) BIO_CE
			LEFT JOIN eda.bio_campaign_vws.bz_dim_camp_wave ON BIO_CE.campgn_wave_key = bz_dim_camp_wave.camp_wave_key
			LEFT JOIN eda.dw_common_vws.dim_calendar cal ON BIO_CE.launch_dt = cal.calendar_dt
			WHERE wave_launch_dt >= '2017-01-01'::date 
				AND camp_status IN ('Completed', 'Launched') 
				AND camp_cat <> 'Hold Out'
				AND (camp_nm LIKE '%RE_WB_ABO_FTD%' 
					OR camp_nm LIKE '%RE_WB_ABO_BTFTD%' 
					OR camp_nm LIKE 'BHQ_IN_WB__ThankYouCOVID%'
				)
		) qry1
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*--------------------------------------------- */
		/*--- Delete current year's Biomed Marketing Activity - It will be inserted in the statement below this one. */
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
		WHERE src_system = 'Adobe - BIO' 
		AND launch_dt >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month';
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		/*---Biomed Marketing Activity - Non-Triggered Campaigns (see where clause) */
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_smry
		SELECT
		  b.wave_launch_dt AS wave_launch_dt,
		  CASE WHEN b.map_chan = 'DM' THEN 'Direct Mail' ELSE b.map_chan END AS map_chan, 
		  'BIO' AS LOB, 
		  'BIO' AS target_audience, 
		  camp_nm,
		  calendar_yr::varchar(4) || 'Q' || calendar_qtr::varchar(1) AS yrqtr,
		  a.campgn_key::varchar(20) AS capmgn_key,
		  b.camp_wave_key::varchar(40) AS camp_wave_key,
		  'Biomed Adobe' AS campgn_program_nm,
		  CASE 
			WHEN camp_nm LIKE '%CROSS_LOB_LAPSED%' THEN 0
			WHEN camp_nm LIKE '%CROSS_LOB%' THEN 1
			WHEN camp_nm LIKE '%CROSSLOB%' THEN 1 
			WHEN camp_nm LIKE '%BHQ_CAMPAIGN_PROSPECT_LOB_FS%' THEN 1
			WHEN camp_nm LIKE '%BHQ_CAMPAIGN_INCREMENTAL_LOB_PROSPECT%' THEN 1
			ELSE 0
		  END AS xpromo_ind,
		  0 AS is_trigg_msg_ind,
		  COUNT(DISTINCT(a.ssi_wave_cntct_id)) AS wave_cntct_cnt,
		  open_cnt,
		  click_cnt,
		  bounce_cnt,
		  unsub_cnt,
		  NULL AS appt_cnt, 
		  'Adobe - BIO'::varchar(25) AS src_system, 
		  CURRENT_DATE AS load_date
		FROM eda.bio_campaign_vws.bz_fact_wave_cntct a
		LEFT JOIN eda.bio_campaign_vws.bz_dim_camp_wave b ON (a.campgn_wave_key = b.camp_wave_key)
		LEFT JOIN eda.dw_common_vws.dim_calendar c ON (b.wave_launch_dt = c.calendar_dt)
		LEFT JOIN (
		  SELECT 
			campgn_key, 
			campgn_wave_key, 
			SUM(opened_ind) AS open_cnt,
			SUM(clicked_ind) AS click_cnt,
			SUM(bncd_any_ind) AS bounce_cnt,
			SUM(email_opt_out_ind) AS unsub_cnt
		  FROM eda.bio_campaign_vws.bz_fact_email_e2e
		  GROUP BY 1,2
		) d ON (d.campgn_wave_key = b.camp_wave_key)
		WHERE
		  b.wave_launch_dt >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
		  AND COALESCE(b.map_chan, 'none') <> 'External Marketing'
		  AND (camp_nm NOT LIKE '%RE_WB_ABO_FTD%' 
			   AND camp_nm NOT LIKE '%RE_WB_ABO_BTFTD%' 
			   AND camp_nm NOT LIKE 'BHQ_IN_WB__ThankYouCOVID%')  /*---triggered campaigns */
		GROUP BY 1,2,3,4,5,6,7,8,9,10,11,13,14,15,16;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*--- Delete TS Emails RS maintains table for now */
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
		WHERE src_system = 'TS SF Marketing Cloud';
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		/*- --TS Emails RS maintains table for now */
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_smry
		SELECT email_launch_dt, 
			   'Email' AS channel, 
			   'TS' AS LOB, 
			   'TS' AS target_audience, 
			   src_cd AS delivery_label, /*--- no delivery name for TS */
			   calendar_yr::VARCHAR(4) || 'Q' || calendar_qtr::VARCHAR(1) AS yrqtr,
			   src_cd, 
			   sub_src, 
			   'TS SF Marketing Cloud' AS campgn_program_nm, 
			   xpromo_ind, 
			   0 AS is_trigg_msg_ind,  
			   sendcount AS send_cnt,
			   opens AS open_cnt,
			   clicks AS click_cnt,
			   bounces AS bounce_cnt,
			   unsub AS unsub_cnt, 
			   NULL AS appt_cnt, 
			   'TS SF Marketing Cloud'::VARCHAR(25) AS src_system, 
			   CURRENT_DATE AS load_dt
		FROM mktg_ops_tbls.pbi_entrprs_campgn_ts_sends a
		LEFT JOIN eda.dw_common_vws.dim_calendar c ON (a.email_launch_dt = c.calendar_dt);
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*-- Delete manual campaigns (text, PSA, package inserts, non digital campaigns) - RS maintains table*/
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
		WHERE src_system = 'Manual non-EDW Campaigns';
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_smry
		/*---manual campaigns (text, PSA, package inserts, non digital campaigns) - RS maintains table */
		SELECT xp.email_launch_dt, 
			channel, 
			lob, 
			audience_target AS target_audience, 
			delivery_label,
			calendar_yr::VARCHAR(4) || 'Q' || calendar_qtr::VARCHAR(1) AS yrqtr,
			src_cd, 
			subsrc_cd,
			source_sys AS campgn_program_nm, 
			xpromo_ind, 
			0 AS is_trigg_msg_ind,
			xp.final_qty AS sent_cnt, 
			opens AS open_cnt, 
			clicks AS click_cnt, 
			NULL AS bounce_cnt, 
			unsubs AS unsub_cnt, 
			appts AS appt_cnt, 
			'Manual non-EDW Campaigns', 
			CURRENT_DATE AS load_dt
		FROM mktg_ops_tbls.pbi_entrprs_campgn_non_adb xp
		LEFT JOIN eda.dw_common_vws.dim_calendar c ON (xp.email_launch_dt = c.calendar_dt);
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*--- Delete current year's CFR Marketing Activity - It will be inserted in the statement below this one. */
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_smry 
		WHERE src_system = 'Adobe - FR' 
		  AND launch_dt >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month';
		 /*--- MM notes */
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		/*---fact email interaction - CFR Adobe Instance */
		INSERT INTO mktg_ops_tbls.pbi_entrprs_campgn_smry
		SELECT mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.email_launch_dt::DATE AS launch_date,
			   'Email' AS channel,
			   CASE WHEN bz_dim_delivery.xpromo_from IS NULL 
					THEN mktg_ops_vws.bz_dim_campgn.campgn_program_nm 
					ELSE xpromo_from 
			   END AS LOB,
			   bz_dim_delivery.xpromo_to::VARCHAR(20) AS target_audience,
			   mktg_ops_vws.gmpbzal_dim_src.src_dsc,
			   calendar_yr::VARCHAR(4) || 'Q' || calendar_qtr::VARCHAR(1) AS yrqtr,
			   mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.src_cd,
			   mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.subsrc_cd,
			   mktg_ops_vws.bz_dim_campgn.campgn_program_nm,
			   CASE WHEN (CASE WHEN bz_dim_delivery.xpromo_from IS NULL 
							   THEN mktg_ops_vws.bz_dim_campgn.campgn_program_nm 
							   ELSE xpromo_from 
						  END) = 'Crossnotes' 
					THEN 1 
					ELSE xpromo_ind 
			   END AS xpromo_ind,
			   is_trigg_msg_ind,
			   SUM(mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.email_sent_cnt) AS sent_cnt,
			   SUM(mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.email_open_ind) AS open_cnt,
			   SUM(mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.email_link_click_ind) AS click_cnt,
			   SUM(mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.total_bounce_cnt) AS bounce_cnt,
			   SUM(mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.unsbscrb_ind) AS unsub_cnt,
			   NULL AS appt_cnt, 
			   'Adobe - FR'::VARCHAR(25) AS src_system, 
			   CURRENT_DATE AS load_date
		FROM mktg_ops_vws.bz_dim_campgn 
			 RIGHT JOIN mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry 
				 ON mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.campaign_key = mktg_ops_vws.bz_dim_campgn.campgn_key
			 LEFT JOIN mktg_ops_vws.gmpbzal_dim_src 
				 ON mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.src_key = mktg_ops_vws.gmpbzal_dim_src.src_key
			 LEFT JOIN mktg_ops_vws.bz_dim_delivery 
				 ON mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.delivery_key = mktg_ops_vws.bz_dim_delivery.delivery_key 
			 LEFT JOIN mktg_ops_vws.dim_email_segmnt 
				 ON mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.email_segmnt_key = mktg_ops_vws.dim_email_segmnt.email_segmnt_key 
			 LEFT JOIN eda.dw_common_vws.dim_calendar c 
				 ON (gms_bzfc_fact_email_intrctn_smry.email_launch_dt = c.calendar_dt)
		WHERE mktg_ops_vws.bz_dim_delivery.is_trigg_msg_ind = 0
		   AND gms_bzfc_fact_email_intrctn_smry.email_launch_dt >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
		   AND gms_bzfc_fact_email_intrctn_smry.src_cd NOT IN ('TESTIGNORE', '123456789012')
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
		HAVING SUM(mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry.email_sent_cnt) > 0;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_ins_count := v_ins_count + v_rows;

		/*  Now apply updates to reclassify the LOBs  */
		/*--2021-04-26--updated update statement to reflect new Adobe To/From Fields*/
		UPDATE mktg_ops_tbls.pbi_entrprs_campgn_smry  
		SET LOB = 
		CASE 
		  WHEN launch_dt <= '2021-04-18'::DATE THEN  /*--new delivery to/from columns added*/
			CASE 
			  WHEN src_cd = 'RSC20040E001' THEN 'TS'
			  WHEN src_cd = 'RSD00000E034' THEN 'Multi'
			  WHEN src_cd = 'RSD00000E035' THEN 'Multi'
			  WHEN src_cd = 'RSC17020E000' THEN 'BIO'
			  WHEN src_cd = 'biomeddss' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%safsus%' THEN 'SAF'
			  WHEN src_cd LIKE '%vmsnewvol%' THEN 'Market Research'
			  WHEN src_cd LIKE '%vmsmonthlyann%' THEN 'Market Research'
			  WHEN src_cd LIKE '%vmsann%' THEN 'Market Research'
			  WHEN src_cd LIKE '%voleqc%' THEN 'Market Research'
			  WHEN campgn_program_nm = 'Biomed' THEN 'BIO'
			  WHEN campgn_program_nm = 'BDSS v7.2 Survey Invite' THEN 'Market Research'
			  WHEN campgn_program_nm LIKE '%Fundraising%' THEN 'CFR'
			  WHEN campgn_program_nm LIKE '%Year End%' THEN 'CFR'
			  WHEN campgn_program_nm LIKE '%Volunteer%' THEN 'VOL'
			  WHEN campgn_program_nm LIKE '%PHSS%' THEN 'TS'
			  WHEN campgn_program_nm = 'Training Services' THEN 'TS'
			  WHEN subsrc_cd = 'nhqfy20staprevfr' THEN 'CFR'
			  WHEN campgn_program_nm LIKE '%Sound the Alarm%' THEN 'VOL'
			  WHEN subsrc_cd LIKE '%SoundAlarm%' THEN 'VOL'
			  WHEN campgn_program_nm LIKE '%SAF%' THEN 'SAF'
			  WHEN delivery_label LIKE 'SAF%' THEN 'SAF'
			  WHEN delivery_label LIKE '%SAF Sust%' THEN 'SAF'
			  WHEN delivery_label LIKE '%SAF Biannual%' THEN 'SAF'
			  WHEN delivery_label LIKE '%Memorial Day Engagement%' THEN 'SAF'
			  WHEN campgn_program_nm LIKE 'Non-Emergency Engagement' THEN 'CFR'
			  WHEN campgn_program_nm LIKE '%Giving Day%' THEN 'CFR'
			  WHEN delivery_label LIKE '%Giving Tuesday%' THEN 'CFR'
			  WHEN delivery_label LIKE '%Blood Appeal%' THEN 'CFR'
			  WHEN delivery_label LIKE '%Vehicle Donation%' THEN 'CFR'
			  WHEN delivery_label LIKE '%Make A Will%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%willguide%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%vmsmonthlyann%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%donorsurvey%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%crosssellres%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%LEAD_Wave2_%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%vmsnewvol%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%newvolsurvey%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%biomeddss%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%bdss%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%newvolsurvey%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%bloodComplete%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%bloodDeferred%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%plateletComplete%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%plateletDeferred%' THEN 'Market Research'
			  WHEN subsrc_cd LIKE '%febwg%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%lobwelcomebio%' THEN 'Multi'
			  WHEN subsrc_cd LIKE '%newdonor%sustainer%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%newdonorwelcome%' THEN 'CFR'
			  WHEN src_cd LIKE '%NHQFY%%MKRS%' THEN 'Market Research'
			  WHEN src_cd LIKE '%TIFNY%' THEN 'CFR'
			  WHEN src_cd LIKE '%NHQLOB_YOUTH%' THEN 'CFR'
			  WHEN src_cd LIKE '%NHQLOB_SAF%' THEN 'SAF'
			  WHEN subsrc_cd LIKE '%harveyapplicants%' THEN 'VOL'
			  WHEN subsrc_cd LIKE '%profqtrly%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%pgsurvey%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%legacy' THEN 'PG'
			  WHEN subsrc_cd LIKE '%mawm%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%willsguide%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%gaildonation%' THEN 'ARC'
			  WHEN subsrc_cd LIKE '%pgwg%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%janwg%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%lifeincomegifts%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%cga%' THEN 'PG'
			  WHEN subsrc_cd LIKE 'legacy%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%nhqfy18gpspringlegacy%' THEN 'PG'
			  WHEN subsrc_cd LIKE '%phssfr%' THEN 'TS'
			  WHEN subsrc_cd LIKE '%summitinvite%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%falltorch%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%NewDonor%Thankyou%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%NewDonor%phss%' THEN 'TS'
			  WHEN delivery_label LIKE '%1905_Memorial Day Engagement%' THEN 'SAF'
			  WHEN subsrc_cd LIKE '%bioto%' THEN 'BIO'
			  WHEN campgn_program_nm = 'Holiday Catalog' THEN 'CFR'
			  WHEN campgn_program_nm LIKE '%Biomed Sponsor Jour%' THEN 'BIO'
			  WHEN campgn_program_nm = 'Chapter Email Campaigns' THEN 'Chapter'
			  WHEN campgn_program_nm = 'Chapter Portal' THEN 'Chapter'
			  WHEN campgn_program_nm LIKE 'eGram%' THEN 'CFR'
			  WHEN campgn_program_nm LIKE 'FR Segmented Appeals%' THEN 'CFR'
			  WHEN campgn_program_nm LIKE 'FR Crossnotes Email%' THEN 'CFR'
			  WHEN campgn_program_nm LIKE 'FR Engagement Email%' THEN 'CFR'
			  WHEN campgn_program_nm LIKE 'FR Welcome Series%' THEN 'CFR'
			  WHEN campgn_program_nm = 'Engagements' THEN 'CFR'
			  WHEN campgn_program_nm = 'CGA' THEN 'PG'
			  WHEN campgn_program_nm LIKE 'Professional Advisor%' THEN 'PG'
			  WHEN campgn_program_nm = 'Segmented Appeals' THEN 'CFR'
			  WHEN campgn_program_nm = 'Social Ambassador' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%donorsustainer%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%fy17maytiffanytorch%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%fy20valentine%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%NewDonor2Survey%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%decembertorch%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%fy17givingday6higher%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%DailyAnniversaryAppeal%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%HolidaySurvey%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%phssbiof%' THEN 'TS'
			  WHEN subsrc_cd LIKE '%phssstorefr%' THEN 'TS'
			  WHEN subsrc_cd LIKE '%phssbiostore%' THEN 'TS'
			  WHEN src_cd LIKE '%MJDR%' THEN 'Development'
			  WHEN src_cd LIKE '%NHQFY18_OLOB%' THEN 'Development'
			  WHEN src_cd LIKE '%TCTO%' THEN 'Development'
			  WHEN src_cd LIKE 'fy19VmsAnnSurv%' THEN 'Market Research'
			  WHEN src_cd LIKE '%VmsAnnSurv%' THEN 'Market Research'
			  WHEN campgn_program_nm LIKE '%Legacy%' THEN 'PG'
			  WHEN campgn_program_nm LIKE 'Sustainer%' THEN 'CFR'
			  WHEN campgn_program_nm LIKE 'Tiffany%' THEN 'CFR'
			  WHEN campgn_program_nm LIKE 'VMS%' THEN 'VOL'
			  WHEN campgn_program_nm = 'Triggered Series' THEN 'CFR'
			  WHEN campgn_program_nm = 'FR Holiday Email Campaigns' THEN 'CFR'
			  WHEN campgn_program_nm = 'Youthwire' THEN 'VOL'
			  WHEN src_cd = 'RSG00100E018' AND subsrc_cd = 'localemail' THEN 'Chapter'
			  WHEN delivery_label LIKE '%GPLG%' THEN 'PG'
			  WHEN src_cd = 'FY21HOSPSURV' THEN 'Market Research'
			  WHEN src_cd LIKE 'RQA%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%p2p%' THEN 'CFR'
			  WHEN subsrc_cd LIKE '%biosurv%' THEN 'Market Research'
			  WHEN delivery_label = 'FY18 CDRP Harvey Responder Postcard' THEN 'CFR'
			  WHEN delivery_label LIKE '%Holiday Giving Print Catalog%' THEN 'CFR'
			  WHEN delivery_label LIKE '%GPLG%' THEN 'PG'
			  WHEN delivery_label LIKE '%Daily Disaster Update%' THEN 'CFR'
			  WHEN delivery_label LIKE '%Annual Fund%' THEN 'CFR'
			  WHEN delivery_label = '2103_DM Survey Fulfillment_Multi' THEN 'Multi'
			  WHEN delivery_label = '2103_DM Survey Fulfillment_SAF' THEN 'SAF'
			  WHEN delivery_label = '2103_DM Survey Fulfillment_TS' THEN 'TS'
			  WHEN delivery_label = '2103_DM Survey Fulfillment_VOL' THEN 'VOL'
			  ELSE LOB
			END
		  ELSE LOB
		END;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_upd_count := v_upd_count + v_rows;

		UPDATE mktg_ops_tbls.pbi_entrprs_campgn_smry  
		SET target_audience = 
			CASE 
				WHEN launch_dt <= '2021-04-18'::date THEN /*---new delivery to/from columns added */
					CASE 
						WHEN delivery_label = 'nhqfy19septbio' THEN 'CFR' 
						WHEN delivery_label LIKE '%DM Survey Fulfillment%' THEN 'CFR'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 1, 2) = 'ts' THEN 'TS'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 2, 3) = 'bio' THEN 'BIO'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 2, 3) = 'vol' THEN 'VOL'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 2, 3) = 'cfr' THEN 'CFR'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 3, 4) = 'phss' THEN 'TS'
						WHEN delivery_label = 'nhqfy19marbioinact' THEN 'CFR'
						WHEN delivery_label = 'nhqfy18biomt1fund' THEN 'CFR'
						WHEN delivery_label = 'nhqfy19biomt2fund' THEN 'CFR'
						WHEN delivery_label = 'nhqfy19biomtrsfund' THEN 'CFR' 
						
						/*---one character added to end */
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 2, 3) LIKE '%ts%' THEN 'TS'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 3, 4) LIKE '%vol%' THEN 'VOL'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 3, 4) LIKE '%cfr%' THEN 'CFR'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 3, 4) LIKE '%bio%' THEN 'BIO'
						
						/*---two characters added to end */
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 3, 4) LIKE '%ts%' THEN 'TS'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 4, 5) LIKE '%vol%' THEN 'VOL'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 4, 5) LIKE '%cfr%' THEN 'CFR'

						/*- --more than 2 characters added to end */
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 7, 8) LIKE '%bio%' THEN 'BIO'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 7, 8) LIKE '%vol%' THEN 'VOL'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 7, 8) LIKE '%cfr%' THEN 'CFR'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 6, 7) LIKE '%ts%' THEN 'TS'
						
						/*- --more than 2 characters added to end */
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 10, 11) LIKE '%bio%' THEN 'BIO'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 10, 11) LIKE '%vol%' THEN 'VOL'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 10, 11) LIKE '%cfr%' THEN 'CFR'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 10, 11) LIKE '%fund%' THEN 'CFR'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 10, 11) LIKE '%phss%' THEN 'TS'
						WHEN SUBSTRING(TRIM(delivery_label), LENGTH(TRIM(delivery_label)) - 9, 10) LIKE '%ts%' THEN 'TS'
						
						/*- --crossnotes catch all for CFR */
						WHEN LOB = 'Crossnotes' THEN 'CFR'
						WHEN LOB = 'SAF' THEN 'CFR'
						/*- --Biomed */
						WHEN target_audience = 'Biomed' THEN 'BIO'
						WHEN delivery_label LIKE '%SAF Sustainer Appeal%' THEN 'CFR'
						WHEN delivery_label LIKE '%Memorial Day SAF Engagement%' THEN 'CFR'
						WHEN subsrc_cd LIKE '%biocfr%' THEN 'CFR'
						WHEN subsrc_cd LIKE '%biovol%' THEN 'VOL'
						WHEN subsrc_cd LIKE '%biots%' THEN 'TS'
						WHEN subsrc_cd LIKE '%biophss%' THEN 'TS'
						WHEN subsrc_cd LIKE '%lobwelcomebio%' THEN 'BIO'
						WHEN subsrc_cd LIKE '%NewDonor3phss%' THEN 'CFR'
						WHEN subsrc_cd = 'NewDonor1Thankyou' THEN 'CFR'
						WHEN subsrc_cd = 'NewDonor2Survey' THEN 'CFR'
						WHEN subsrc_cd LIKE '%mawm%' THEN 'PG'
						WHEN subsrc_cd LIKE '%willsguide%' THEN 'PG'
						WHEN subsrc_cd = 'newdonor4sustainerapp1' THEN 'CFR'
						WHEN subsrc_cd LIKE '%abdnform' THEN 'CFR'
						WHEN src_cd LIKE '%vmsnewvo%' THEN 'VOL'
						WHEN src_cd LIKE '%vmsmonthlyan%' THEN 'VOL'
						WHEN src_cd LIKE 'fy19VmsAnnSurv%' THEN 'VOL'
						WHEN src_cd LIKE 'biomeddss%' THEN 'BIO'
						WHEN src_cd LIKE 'BIODS%' THEN 'BIO'
						WHEN subsrc_cd = 'nhqfy20staprevfr' THEN 'CFR'
						WHEN src_cd = 'RSG00100E018' AND subsrc_cd = 'localemail' THEN 'CFR'
						WHEN subsrc_cd LIKE '%p2p%' THEN 'CFR'
						WHEN subsrc_cd LIKE '%vol' THEN 'VOL' 
						WHEN subsrc_cd LIKE '%vola' THEN 'VOL' 
						WHEN subsrc_cd LIKE '%volb' THEN 'VOL'
						WHEN subsrc_cd LIKE '%vols' THEN 'VOL' 
						WHEN subsrc_cd LIKE '%vols2' THEN 'VOL' 
						WHEN subsrc_cd LIKE '%vms' THEN 'VOL' 
						WHEN subsrc_cd LIKE '%bio' THEN 'BIO' 
						WHEN subsrc_cd LIKE '%cfr' THEN 'CFR'
						WHEN subsrc_cd LIKE '%cfra' THEN 'CFR'
						WHEN subsrc_cd LIKE '%cfrb' THEN 'CFR'
						WHEN subsrc_cd LIKE '%phss' THEN 'TS'  
						WHEN subsrc_cd LIKE '%ts' THEN 'TS' 
						WHEN subsrc_cd LIKE '%ts2' THEN 'TS' 
						WHEN subsrc_cd LIKE '%tsa' THEN 'TS'
						WHEN subsrc_cd LIKE '%tsb' THEN 'TS' 
						WHEN subsrc_cd LIKE '%multi' THEN 'Multi' 
						WHEN src_cd = 'RSD00000E034' THEN 'Multi'
						WHEN src_cd = 'RSD00000E035' THEN 'Multi'
						WHEN src_cd = 'APP21014E000' THEN 'Multi'
						WHEN subsrc_cd = 'nhqfy20edtabeng' THEN 'CFR'
						WHEN subsrc_cd = 'nhqfy20marbiohigh' THEN 'CFR'
						WHEN subsrc_cd = 'nhqfy20biojulappcfrhp' THEN 'CFR'
						ELSE target_audience
					END
				ELSE target_audience
			END;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_upd_count := v_upd_count + v_rows;
			
		/* add update statement to end of SQL to remove campaigns */
		DELETE FROM mktg_ops_tbls.pbi_entrprs_campgn_smry
		WHERE (src_cd IN ('55872', '55752', '57073', '57072', '57589', '57600', '59788') 
			  AND src_system = 'Adobe - BIO');
		/*Small Bio Sends, Updated in manual table; Holdout and Test Sends Removed;*/
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_del_count := v_del_count + v_rows;

		/*--Friendly Campaign Name Update */
		UPDATE mktg_ops_tbls.pbi_entrprs_campgn_smry  
		SET delivery_label = 
			CASE  
				WHEN delivery_label = 'BV_BHQ_IN_WB_ABO_ProspCrossLOBSmr1_NA1_ACT_062421' THEN 'Biomed June Shortage BVM'
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_CrossLOBSummerTestPromo2_NA1_NA2_061821' THEN 'Biomed June Tango Promo Test'
				WHEN delivery_label = 'June Blood Shortage copy' THEN 'Biomed June Shortage Text'
				WHEN delivery_label = 'BV_BHQ_IN_WB_ABO_CrossLOBTestPromo1Prosp_NA1_NA2_060321' THEN 'Biomed June Tango Promo Test'
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_CrossLOBSummerTestPromo1_NA1_NA2_052821' THEN 'Biomed June Tango Promo Test'
				WHEN delivery_label = 'Biomed LOB copy' THEN 'Biomed Cross LOB Text'
				WHEN delivery_label = 'TX_BHQ_IN_WB_ABO_VolCrossLOB_NA1_NA2_092220' THEN 'Biomed Cross LOB Text'
				WHEN delivery_label = 'BV_BHQ_IN_WB_ABO_ProspCrossLOBSmr2_NA1_ACT_071921' THEN 'Biomed ADP/Shortage BVM'
				WHEN delivery_label = 'BV_BHQ_IN_WB_ABO_ProspCrossLOBSmr2_NA1_ACT_081721' THEN 'Biomed Shortage BVM Resend'
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtAug_NA1_NA2_081821' THEN '2108_Heartbeat'
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtNOVAMZADP_NA1_NA2_111721' THEN '2111_Heartbeat'
				WHEN delivery_label = 'TR_BHQ_IN_WB_ABO_CrossLOBApplBloodCrisis_NA1_ACT_013122' THEN 'Biomed Winter Appeal TR'
				WHEN delivery_label = 'BV_ARZ_IN_WB_ABO_CrossLOBFanaticsMLBSG_NA1_ACT_022422' THEN 'Biomed AZ Expansion BVM'
				WHEN delivery_label = 'BV_BHQ_IN_SC_ABO_PSCrossLOBNFLBigGame_AMZ_ACT_011722' THEN 'Biomed Sickle Cell Journey BVM'
				WHEN delivery_label = 'BV_BHQ_IN_SC_ABO_PSCrossLOBNFLBigGame_NFL_ACT_011722' THEN 'Biomed Sickle Cell Journey BVM'
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtMrchFanaticsMLB_NA1_NA2_031622' THEN '2203_Heartbeat'    
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtElvisSWPFanaticsMLB_NA1_NA2_051822' THEN '2205_Heartbeat'    
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtLaborDayCrDSportCL_NA1_NA2_082422' THEN '2208_August Heartbeat'
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtCrDBeanie_NOV10gcADP_NA4_NA1_NA2_111622' THEN '2211_Heartbeat Newsletter'
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_HrbtMrch_PeanutsTee_NA4_NA1_NA2_032523' THEN '2303_Heartbeat Newsletter'
				WHEN delivery_label = 'TR_BHQ_IN_WB_CrossLOB_NA3_NA4_NA1_PROS_052223' THEN '2023 Supporter Survey XLOB Follow-up'
				WHEN delivery_label = 'TX_BHQ_IN_WB_ABO_CrossLOBFund_NAPromo_NA4_NA1_CLOB_052223' THEN 'May Sustainer Campaign Text'
				WHEN delivery_label = 'EM_BHQ_IN_WB_ABO_MayHrbt_CrDTowelADP_NA4_NA1_NA2_052423' THEN '2305_Heartbeat Newsletter'
				WHEN delivery_label = 'TX_BHQ_IN_WB_ABO_CrossLOBFund_NAPromo_NA4_NA1_CLOB_062723' THEN 'Fiscal Year End Appeal Text'
				WHEN delivery_label = 'TR_BHQ_IN_WB_CrossLOB_8SKSWP10ADP_NA4_NA1_PROS_073123' THEN '2023 Supporter Survey XLOB Follow-up'
				ELSE delivery_label
			END;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_upd_count := v_upd_count + v_rows;
			
		/*-- Heartbeat Exceptions for Multi-LOB - Updating LOB to Heartbeat */
		UPDATE mktg_ops_tbls.pbi_entrprs_campgn_smry  
		SET LOB = 
			CASE  
				WHEN delivery_label LIKE '%Heartbeat%' THEN 'Heartbeat'
				WHEN delivery_label LIKE '%Hrbt%' THEN 'Heartbeat'
				WHEN src_cd = '70382' THEN 'Multi'
				WHEN src_cd = '70398' THEN 'CFR'
				WHEN src_cd = '71060' THEN 'CFR'
				WHEN src_cd = '71641' THEN 'Multi' 
				ELSE LOB
			END;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_upd_count := v_upd_count + v_rows;

		/*-- Heartbeat Exceptions for Multi-LOB - Setting xpromo_ind */
		UPDATE mktg_ops_tbls.pbi_entrprs_campgn_smry  
		SET xpromo_ind = 
			CASE  
				WHEN delivery_label = 'HeartbeatWebTrue' THEN '0' /*--faulty Heartbeat message */
				WHEN delivery_label LIKE '%Heartbeat%' THEN '1'
				WHEN delivery_label LIKE '%Hrbt%' THEN '1'
				ELSE xpromo_ind
			END;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_upd_count := v_upd_count + v_rows;

		/*-- Setting BVM channel where BVM sends are null */
		UPDATE mktg_ops_tbls.pbi_entrprs_campgn_smry  
		SET channel = 
			CASE  
				WHEN delivery_label LIKE 'BV_%' AND channel IS NULL THEN 'BVM'
				WHEN delivery_label = 'Biomed AZ Expansion BVM' THEN 'BVM'
				WHEN delivery_label = 'Biomed Sickle Cell Journey BVM' THEN 'BVM'
				ELSE channel
			END;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_upd_count := v_upd_count + v_rows;
			
		/*-- Welcome Series 3 change to TS LOB */
		UPDATE mktg_ops_tbls.pbi_entrprs_campgn_smry  
		SET LOB = 'TS'
		WHERE LOB = 'CFR' 
		  AND delivery_label = 'New Donor Welcome Series 3' 
		  AND xpromo_ind = 1 
		  AND is_trigg_msg_ind = 1;
		GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_upd_count := v_upd_count + v_rows;
		
        v_end_time := GETDATE();
		v_ok_message := v_ins_count || ' rows inserted, ' ||
                        v_upd_count || ' rows updated, ' ||
                        v_del_count || ' rows deleted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = v_ins_count + v_upd_count + v_del_count
        WHERE proc_name = 'ld_pbi_entrprs_campgn_smry' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE();
			v_error_message := 'Error in ld_pbi_entrprs_campgn_smry: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_pbi_entrprs_campgn_smry', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
