CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_arc_fr_txn()
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
	VALUES ('ld_gms_arc_fr_txn', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.gms_arc_fr_txn_stg;
	
		INSERT INTO mktg_stage_tbls.gms_arc_fr_txn_stg(
			cnst_mstr_id, giftran_key, gift_cnst_grp_key, nk_gift_id, dim_giftran_key, 
			alt_trans_id, bzd_unique_trans_id, ta_acct_id, nk_ta_gift_seq, nk_sf_gift_id, 
			gift_versn, gift_num, gift_tran_typ_key, pmt_mthd_key, dntn_chan_key, 
			sustnr_typ_key, gift_rec_dt_key, gift_rec_dt, dntn_gift_dt_key, dntn_gift_dt, 
			released_dt_key, released_dt, orig_released_dt_key, orig_released_dt, 
			deposit_dt_key, deposit_dt, orig_deposit_dt_key, orig_deposit_dt, gift_appl_src_cd, 
			pmt_typ_key, email_segmnt_key, channel_typ_key, online_channel_key, 
			online_channel_cd, txn_channel, gl_debit_acct_key, gl_credit_acct_key, 
			trans_fund_key, trans_fund_cd, trans_fund_dsc, giftran_src_key, gift_src_key, 
			orig_gift_src_key, gift_src_cd, gift_sub_src_cd, campgn_src_key, 
			orig_campgn_src_key, campgn_src_cd, gift_src_dsc, fr_affl_unit_key, gift_amt_tier_key, 
			fr_affl_cd, gift_trbt_key, gift_trbt_typ_cd, gift_trbt_typ_dsc, gift_trbt_nm, 
			gift_trbt_from, giftran_typ_dsc, vendor_key, merchant_key, sc_affl_unit_key, 
			sc_affl_unit_cd, dim_gift_sku_key, dim_gift_premium_key, fr_merchant_id, fcc_key, 
			prog_key, derived_channel, cnst_typ_cd, rco_dntn_id, rco_subscription_id, 
			subscription_id, recurng_start_dt, recurring_ind, fr_distr_dntn_ind, active_ind, 
			ack_ind, thankyou_ind, soft_credit_ind, gift_anon_ind, split_gift_ind, trbt_gift_ind, 
			installment_ind, confidence_ind, gift_ask_mult_lnk_ind, dnr_geogrphc_intrst_local_ind,
			gift_in_care_of_ind, evnt_benefit_ind, conv_trans_ind, ta_trans_ind, do_not_feed_gl_ind, 
			adj_ind, bdgt_rlvng_ind, released_ind, manual_entry_ind, reject_ind, misdirected_ind, 
			vsblty_ind, fr_credit_ind, prior_prd_ind, gl_override_ind, stock_gift_ind, inkind_gift_ind, 
			dnr_adv_gift_ind, episodic_gift_ind, fmd_txn_ind, prvt_ind, fr_pmt_amt, totl_gift_amt, 
			gift_exps_amt, arc_fr_txn_seq_num, dntn_entity_url, srcsys_create_ts, srcsys_update_ts, 
			trans_update_dt, dw_trans_ts, appl_src_cd, load_id
		) 
		WITH 
		unified_src_cte AS (
			SELECT 
				src_key, 
				src_cd, 
				src_dsc, 
				row_eff_from_ts, 
				row_eff_to_ts,
				active_ind,
				ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
			FROM 
				eda.ufds_vws.gmpbzal_dim_src
		),
		
		atg_cte AS (
			SELECT 
				nk_trans_sub_src_cd, 
				order_id, 
				recurring_ind, 
				recurng_start_dt, 
				channel_key AS atg_channel_key, 
				nk_channel_cd AS atg_nk_channel_cd,
				ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY nk_trans_sub_src_cd DESC) AS rn
			FROM 
				mods_bi.mktg_ops_vws.fact_atg_order_line  
			WHERE 
				SUBSTRING(nk_product_cd, 1, 4) = 'prod'
		),
		ranked_data AS (
			SELECT
				COALESCE(c.cnst_mstr_id, 0) AS cnst_mstr_id, 
				a.giftran_key,
				a.gift_cnst_grp_key, 
				a.nk_gift_id, 
				a.dim_giftran_key, 
				dg.alt_trans_id, 
				'X' || TRIM(a.nk_ta_acct_id) || '_' ||                               
				UPPER(TO_CHAR(a.gift_dt, 'DD')) || '_' ||
				UPPER(TO_CHAR(a.gift_dt, 'MON')) || '_' ||
				UPPER(TO_CHAR(a.gift_dt, 'YY')) || '_' ||
				TRIM(TRIM(TRAILING '.' FROM a.nk_ta_gift_seq)) || '_' || 
				TRIM(TRIM(TRAILING '.' FROM a.nk_ta_gift_adj_seq)) AS bzd_unique_trans_id,  
				a.nk_ta_acct_id, 
				a.nk_ta_gift_seq,
				a.nk_sf_gift_id, 
				a.gift_versn,
				a.gift_num, 
				a.giftran_typ_key,
				a.pmt_mthd_key, 
				segmnt.email_segmnt_key,
				a.dntn_chan_key,
				CASE 
					WHEN a.gift_dt >= '2018-08-10' THEN aem_channel.online_channel_key 
					WHEN a.gift_dt < '2018-08-10' THEN atg_channel.online_channel_key 
					ELSE NULL 
				END AS online_channel_key, 
				CASE 
					WHEN a.gift_dt >= '2018-08-10' THEN aem_channel.online_channel_cd 
					WHEN a.gift_dt < '2018-08-10' THEN atg_channel.online_channel_cd 
					ELSE NULL 
				END AS online_channel_cd, 
				em_src.channel AS txn_channel,
				a.sustnr_typ_key, 
				a.gift_rec_dt_key,
				a.gift_rec_dt, 
				a.gift_dt_key,
				a.gift_dt, 
				a.released_dt_key,
				a.released_dt, 
				a.orig_released_dt_key,
				a.orig_released_dt, 
				a.deposit_dt_key,
				a.deposit_dt, 
				a.orig_deposit_dt_key,
				a.orig_deposit_dt, 
				a.appl_src_cd AS gift_appl_src_cd,  
				a.gl_debit_acct_key,
				a.gl_credit_acct_key, 
				a.fund_key,
				i.fund_cd, 
				i.fund_dsc, 
				i.gl_company_fund_cd, 
				a.sc_affl_key AS sc_affl_unit_key, 
				unit.nk_ecode AS sc_affl_unit_cd, 
				a.dim_gift_sku_key, 
				a.dim_gift_premium_key, 
				a.src_key AS giftran_src_key, 
				j.src_key,
				j.src_cd, 
				j.src_dsc, 
				CASE 
					WHEN b.subsrc_cd IS NULL AND atg.nk_trans_sub_src_cd IS NOT NULL THEN atg.nk_trans_sub_src_cd
					WHEN b.subsrc_cd IS NULL AND aem.subsrc_cd IS NOT NULL THEN aem.subsrc_cd  
					ELSE b.subsrc_cd 
				END AS gift_sub_src_cd,
				campgn_src_key.src_key AS campgn_src_key, 
				CASE 
					WHEN b.src_cd IS NOT NULL THEN b.src_cd 
					ELSE j.src_cd 
				END AS campgn_src_cd, 
				a.dim_gift_trbt_key AS gift_trbt_key, 
				NULL::VARCHAR AS gift_trbt_typ_cd, 
				NULL::VARCHAR AS gift_trbt_typ_dsc, 
				NULL::VARCHAR AS gift_trbt_nm, 
				NULL::VARCHAR AS gift_trbt_from,
				l.giftran_typ_dsc, 
				a.vendor_key, 
				a.merchant_key, 
				a.gl_fcc_key,
				mstr.cnst_typ_cd, 
				CASE 
					WHEN aem.rco_dntn_id IS NULL THEN atg.order_id 
					ELSE aem.rco_dntn_id 
				END AS rco_dntn_id, 
				aem.rco_subscription_id, 
				aem.subscription_id, 
				CASE 
					WHEN atg.recurng_start_dt IS NOT NULL THEN atg.recurng_start_dt
					WHEN aem.recurring_start_dt IS NOT NULL THEN aem.recurring_start_dt 
					ELSE NULL 
				END AS recurng_start_dt,
				CASE 
					WHEN atg.recurring_ind = 'Y' OR aem.recurring_gift_flg = 'Y' THEN 1 
					ELSE 0 
				END AS recurring_ind,
				a.active_ind, 
				a.ack_ind, 
				a.thankyou_ind,
				a.sc_ind, 
				a.gift_anon_ind,
				a.split_gift_ind, 
				a.trbt_gift_ind,
				a.installment_ind, 
				a.confidence_ind,
				a.gift_ask_mult_lnk_ind, 
				a.dnr_geogrphc_intrst_local_ind,
				a.gift_in_care_of_ind, 
				a.evnt_benefit_ind,
				a.conv_trans_ind, 
				a.ta_trans_ind,
				a.gift_amt, 
				a.totl_gift_amt,
				a.gift_exps_amt, 
				ROW_NUMBER() OVER (PARTITION BY a.giftran_key ORDER BY c.cnst_mstr_id) AS arc_fr_txn_seq_num, 
				CURRENT_TIMESTAMP AS dw_trans_ts, 
				a.do_not_feed_gl_ind, 
				a.adj_ind, 
				a.bdgt_rlvng_ind, 
				a.released_ind, 
				a.manual_entry_ind, 
				a.reject_ind, 
				a.misdirected_ind, 
				a.vsblty_ind, 
				a.fr_credit_ind, 
				a.prior_prd_ind, 
				a.gl_override_ind, 
				a.stock_gift_ind, 
				a.inkind_gift_ind, 
				a.dnr_adv_gift_ind, 
				a.episodic_gift_ind, 
				CASE 
					WHEN (COALESCE(unf.frf_gift_mngd_dnr_ind, 0) + COALESCE(unf.frf_cur_mngd_dnr_ind, 0)) > 0 THEN 1 
					ELSE 0 
				END AS fmd_txn_ind, 
				a.prvt_ind, 
				a.gift_rev_credit_key AS fr_affl_unit_key, 
				tier.dollar_tier_key AS gift_amt_tier_key, 
				unit1.nk_ecode AS fr_affl_cd, 
				CASE 
					WHEN j.src_cd = 'RSG00000MCDF' THEN 'internet reply form'
					WHEN SUBSTRING(j.src_cd, 1, 3) IN ('WPW','WPM') THEN 'workplace'
					WHEN dg.gift_note_txt LIKE '%Crowdrise%' THEN 'crowdrise'
					WHEN v.vendor_cd IN ('l53','CVNT') AND gl_acct.fcc = '27740' THEN 'cvent'
					WHEN SUBSTRING(i.fund_cd, 1, 1) = 'A' OR gl_acct.nat_acct = '41300' THEN 'event'
					WHEN gl_acct.fcc IN ('27760','27761','27765') AND SUBSTRING(j.src_cd, 1, 2) IN ('RR','RQ') THEN 'cdrp_dm'
					WHEN gl_acct.fcc IN ('27763','27764') THEN 'online'
					WHEN gl_acct.fcc = '27762' THEN 'phone'
					WHEN gl_acct.fcc LIKE '2776_' THEN 'other cdrp'
					WHEN j.src_cd = 'GGG0900' AND dntn_chan.dntn_chan_cd = 'mail' THEN 'white mail'
					WHEN gl_acct.nat_acct = '41210' THEN 'corporate'
					WHEN gl_acct.nat_acct IN ('43100','43300','43800') THEN 'in-kind'
					WHEN gl_acct.nat_acct = '41220' THEN 'foundation'
					WHEN gl_acct.nat_acct = '41230' THEN 'other individual'
					ELSE 'other'
				END AS derived_channel,
				a.prog_key, 
				aem.dntn_entity_url, 
				a.srcsys_create_ts, 
				a.srcsys_update_ts, 
				aem.trans_update_dt  
			FROM
				mods_bi.mktg_stage_tbls.gms_arc_fr_giftran_stg stg 
				INNER JOIN eda.ufds_vws.bzfc_fact_giftran a ON stg.giftran_key = a.giftran_key  
				LEFT OUTER JOIN eda.ufds_vws.bzl_gift_cnst_mstr_brg c ON a.gift_cnst_grp_key = c.gift_cnst_grp_key
				LEFT OUTER JOIN eda.ufds_vws.gmpbz_dim_giftran dg ON dg.dim_giftran_key = a.dim_giftran_key
				LEFT OUTER JOIN eda.ufds_vws.gmpbzal_dim_fund i ON a.fund_key = i.fund_key 
				LEFT OUTER JOIN eda.ufds_vws.gmpbzal_dim_src j ON a.src_key = j.src_key 
				LEFT OUTER JOIN unified_src_cte j2 ON j.src_cd = j2.src_cd AND j2.rn = 1
				LEFT OUTER JOIN eda.ufds_vws.gmpbz_dim_giftran_typ l ON a.giftran_typ_key = l.giftran_typ_key 		
				LEFT JOIN (
					SELECT 
						trans_id, 
						a.rco_dntn_id, 
						a.dntn_entity_url, 
						c.rco_subscription_id, 
						c.subscription_id, 
						recurring_gift_flag AS recurring_gift_flg, 
						trans_src_cd AS src_cd, 
						trans_sub_src_cd AS subsrc_cd, 
						cal.calendar_dt AS trans_update_dt, 
						CASE 
							WHEN CAST(c.rcrng_start_ts AS TIMESTAMP) <= CAST(c.intl_subscription_ts AS TIMESTAMP) 
							THEN CAST(c.rcrng_start_ts AS TIMESTAMP)  
							ELSE CAST(c.intl_subscription_ts AS TIMESTAMP)  
						END AS recurring_start_dt, 
						a.chn_key
					FROM 
						eda.rco_vws.bz_fact_dnr_trans a 
						LEFT JOIN eda.rco_vws.bz_dim_trans_src b ON a.trans_src_key = b.trans_src_key
						LEFT JOIN eda.rco_vws.bz_dim_subscription c ON a.subscription_key = c.subscription_key
						LEFT JOIN eda.dw_common_vws.dim_calendar cal ON cal.calendar_key = a.trans_ts_key 
					WHERE 
						CAST(a.created_ts AS DATE) >= '2018-08-10'  
						AND a.trans_id NOT IN (
							SELECT 
								trans_id
							FROM 
								eda.rco_vws.bz_fact_dnr_trans a 
								LEFT JOIN eda.rco_vws.bz_dim_trans_src b ON a.trans_src_key = b.trans_src_key
								LEFT JOIN eda.rco_vws.bz_dim_subscription c ON a.subscription_key = c.subscription_key
							WHERE 
								CAST(a.created_ts AS DATE) >= '2018-08-10'  
							GROUP BY 
								1
							HAVING 
								COUNT(*) > 1
						)
				) aem ON dg.alt_trans_id = aem.trans_id 	
				LEFT OUTER JOIN atg_cte atg ON dg.alt_trans_id = atg.order_id AND dg.alt_trans_id LIKE 'ON%' AND atg.rn = 1
				LEFT OUTER JOIN mods_bi.mktg_ops_tbls.dim_online_channel atg_channel ON atg_channel.atg_channel_key = atg.atg_channel_key
				LEFT OUTER JOIN mods_bi.mktg_ops_tbls.dim_online_channel aem_channel ON aem_channel.aem_channel_key = aem.chn_key
				LEFT OUTER JOIN eda.dw_common_vws.dim_unit unit ON unit.unit_key = a.sc_affl_key 
				LEFT OUTER JOIN eda.dw_common_vws.dim_unit unit1 ON unit1.unit_key = a.gift_rev_credit_key
				LEFT OUTER JOIN eda.ufds_vws.bzfc_dim_unf_fr_cnst unf ON unf.unf_fr_cnst_key = a.gift_cnst_grp_key 
					AND unf.cnst_typ_cd IN ('IG','OG') 
					AND (COALESCE(unf.frf_gift_mngd_dnr_ind, 0) + COALESCE(unf.frf_cur_mngd_dnr_ind, 0)) > 0
				LEFT OUTER JOIN eda.ufds_vws.gmpbz_dim_dollar_tier tier ON a.gift_amt BETWEEN tier.low_val AND tier.high_val 
				LEFT OUTER JOIN eda.arc_mdm_vws.cnst_mstr mstr ON mstr.cnst_mstr_id = c.cnst_mstr_id 
				LEFT OUTER JOIN mods_bi.mktg_ops_vws.bz_email_src_cd em_src ON j2.src_cd = em_src.src_cd
				LEFT JOIN mods_bi.mktg_ops_vws.bz_gms_arc_fr_txn_segmnt segmnt ON a.giftran_key = segmnt.giftran_key AND c.cnst_mstr_id = segmnt.cnst_mstr_id 
				LEFT JOIN mods_bi.mktg_ops_vws.bz_rr_dm_srccd_aprm_cellcd b ON j.src_cd = b.motivtn_cd 
				LEFT JOIN unified_src_cte ds2 ON b.src_cd = ds2.src_cd AND ds2.rn = 1
				LEFT JOIN (
					SELECT 
						gl_acct_key, 
						nat_acct, 
						fcc
					FROM 
						eda.cfs_vws.bz_dim_gl_acct 
				) gl_acct ON a.gl_credit_acct_key = gl_acct.gl_acct_key
				LEFT JOIN mods_bi.mktg_ops_vws.gmpbz_dim_vendor v ON a.vendor_key = v.vendor_key
				LEFT JOIN mods_bi.mktg_ops_vws.gmpbz_dim_dntn_chan dntn_chan ON a.dntn_chan_key = dntn_chan.dntn_chan_key
				LEFT JOIN unified_src_cte campgn_src_key ON COALESCE(b.src_cd, j.src_cd) = campgn_src_key.src_cd AND campgn_src_key.rn = 1
			WHERE  
				a.active_ind = 1
				AND stg.row_stat_cd = 'I'
		)
		SELECT 
			cnst_mstr_id, 
			giftran_key, 
			gift_cnst_grp_key, 
			nk_gift_id, 
			dim_giftran_key, 
			CAST(alt_trans_id AS VARCHAR(40)), 
			bzd_unique_trans_id, 
			nk_ta_acct_id, 
			nk_ta_gift_seq, 
			nk_sf_gift_id, 
			gift_versn, 
			gift_num, 
			CAST(NULLIF(TRIM(giftran_typ_key), '') AS INTEGER), 
			pmt_mthd_key, 
			dntn_chan_key, 
			CAST(NULLIF(TRIM(sustnr_typ_key), '') AS INTEGER), 
			CAST(NULLIF(TRIM(gift_rec_dt_key), '') AS INTEGER), 
			CAST(gift_rec_dt AS DATE), 
			CAST(NULLIF(TRIM(gift_dt_key), '') AS INTEGER), 
			CAST(gift_dt AS DATE), 
			CAST(NULLIF(TRIM(released_dt_key), '') AS INTEGER), 
			CAST(released_dt AS DATE), 
			CAST(NULLIF(TRIM(orig_released_dt_key), '') AS INTEGER), 	
			CAST(orig_released_dt AS DATE), 
			CAST(NULLIF(TRIM(deposit_dt_key), '') AS INTEGER), 		
			CAST(deposit_dt AS DATE), 
			CAST(NULLIF(TRIM(orig_deposit_dt_key), '') AS INTEGER), 
			CAST(orig_deposit_dt AS DATE), 
			gift_appl_src_cd, 
			pmt_mthd_key, 
			email_segmnt_key, 
			dntn_chan_key, 
			online_channel_key, 
			online_channel_cd, 
			txn_channel, 
			gl_debit_acct_key, 
			gl_credit_acct_key, 
			CAST(NULLIF(TRIM(fund_key), '') AS INTEGER), 
			fund_cd, 
			fund_dsc, 
			giftran_src_key, 
			CAST(NULLIF(TRIM(src_key), '') AS INTEGER), 
			CAST(NULLIF(TRIM(src_key), '') AS INTEGER), 
			src_cd, 
			gift_sub_src_cd, 
			campgn_src_key, 
			campgn_src_key, 
			campgn_src_cd, 
			src_dsc, 
			fr_affl_unit_key, 
			gift_amt_tier_key, 
			fr_affl_cd, 
			gift_trbt_key, 
			gift_trbt_typ_cd, 
			gift_trbt_typ_dsc, 
			gift_trbt_nm, 
			gift_trbt_from, 
			giftran_typ_dsc, 
			CAST(NULLIF(TRIM(vendor_key), '') AS INTEGER),  
			CAST(NULLIF(TRIM(CAST(merchant_key AS VARCHAR(64))), '') AS INTEGER),
			sc_affl_unit_key, 
			sc_affl_unit_cd, 
			dim_gift_sku_key, 
			dim_gift_premium_key, 
			CAST(merchant_key AS VARCHAR(64)), 
			gl_fcc_key, 
			prog_key, 
			derived_channel, 
			cnst_typ_cd, 
			rco_dntn_id, 
			rco_subscription_id, 
			subscription_id, 
			CAST(recurng_start_dt AS TIMESTAMP), 
			CAST(NULLIF(TRIM(recurring_ind), '') AS INTEGER), 
			(CASE 
				WHEN (
					((CASE 
						WHEN gl_company_fund_cd IS NULL THEN NULL 
						WHEN (gl_company_fund_cd = '051') OR (gl_company_fund_cd = '052') OR (gl_company_fund_cd = '062') THEN 1 
						ELSE 0 
					END) <> 0) 
					AND (fund_cd <> '4900-dm')
				) 
				AND NOT (
					(CASE 
						WHEN SUBSTRING(src_cd, 1, 5) IS NULL THEN NULL 
						WHEN (SUBSTRING(src_cd, 1, 5) = 'RQA15') OR 
							(SUBSTRING(src_cd, 1, 5) = 'RQL15') OR 
							(SUBSTRING(src_cd, 1, 5) = 'RQC15') OR 
							(SUBSTRING(src_cd, 1, 5) = 'RQD15') THEN 1 
						ELSE 0 
					END) <> 0
				) 
				AND (src_cd <> 'RQD14120M000') THEN 1 
				ELSE 0 
			END), 
			active_ind, 
			ack_ind, 
			thankyou_ind, 
			sc_ind, 
			gift_anon_ind, 
			split_gift_ind, 
			trbt_gift_ind, 
			installment_ind, 
			CAST(NULLIF(TRIM(confidence_ind), '') AS INTEGER), 	
			gift_ask_mult_lnk_ind, 
			dnr_geogrphc_intrst_local_ind, 
			gift_in_care_of_ind, 
			evnt_benefit_ind, 
			CAST(NULLIF(TRIM(conv_trans_ind), '') AS INTEGER), 
			CAST(NULLIF(TRIM(ta_trans_ind), '') AS INTEGER), 
			do_not_feed_gl_ind, 
			adj_ind, 
			bdgt_rlvng_ind, 
			released_ind, 
			manual_entry_ind, 
			reject_ind, 
			misdirected_ind, 
			vsblty_ind, 
			fr_credit_ind, 
			CAST(NULLIF(TRIM(prior_prd_ind), '') AS INTEGER), 
			CAST(NULLIF(TRIM(gl_override_ind), '') AS INTEGER),
			stock_gift_ind, 
			inkind_gift_ind, 
			dnr_adv_gift_ind, 
			episodic_gift_ind, 
			fmd_txn_ind, 
			prvt_ind, 
			gift_amt, 
			totl_gift_amt, 
			gift_exps_amt, 
			arc_fr_txn_seq_num, 
			dntn_entity_url, 
			CAST(srcsys_create_ts AS TIMESTAMP), 
			CAST(srcsys_update_ts AS TIMESTAMP), 
			CAST(trans_update_dt AS DATE), 
			CAST(dw_trans_ts AS TIMESTAMP), 
			'MKTG', 
			100 
		FROM 
			ranked_data;
		
		DELETE FROM mods_bi.mktg_ops_tbls.gms_arc_fr_txn
		WHERE giftran_key IN (SELECT giftran_key FROM mods_bi.mktg_stage_tbls.gms_arc_fr_giftran_stg);
		
		-- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.gms_arc_fr_txn
        SELECT * FROM mods_bi.mktg_stage_tbls.gms_arc_fr_txn_stg;
			
		v_end_time := GETDATE();
		v_ok_message = cast((select count(*) from mods_bi.mktg_stage_tbls.gms_arc_fr_txn_stg) as nvarchar)+ ' Records inserted.';
        
        UPDATE mods_bi.mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message
        WHERE proc_name = 'ld_gms_arc_fr_txn' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;
		
	EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_gms_arc_fr_txn: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_gms_arc_fr_txn', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
