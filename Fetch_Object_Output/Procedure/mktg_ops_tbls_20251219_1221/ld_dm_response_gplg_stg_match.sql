CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dm_response_gplg_stg_match()
 LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dm_response_gplg_stg_match', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
        TRUNCATE TABLE mktg_stage_tbls.dm_response_gplg_stg_merge;
		/* 
		Read the staged PG Response data from the mktg_stage_tbls.dm_response_gplg_stg table; apply deduplication logic to the data and insert the dedupped data into the mktg_stage_tbls.dm_response_gplg_stg_match table.
		*/

		INSERT INTO mktg_stage_tbls.dm_response_gplg_stg_merge
		WITH ranked_data AS (
			SELECT 
				a.*,
				/* Set 2 character first names to uppercase to standardize and clean response names.  Otherwise, we format the first name to have first initial uppercase.*/
				CASE WHEN LENGTH(d.first_nm) = 2 THEN UPPER(d.first_nm) ELSE INITCAP(d.first_nm) END AS clnsd_first_nm,
				/*Standardize last name to have first initial uppercase. */	
				INITCAP(d.last_nm) AS clnsd_last_nm,
				/* Standardize email address to lowercase and remove spaces*/
				LOWER(d.email_addr) AS clnsd_email_addr, 
				d.campaign, d.first_response_dt, d.day_between_group, d.response_cnt, d.min_response_ts,
				ROW_NUMBER() OVER (
					PARTITION BY 
						LOWER(REPLACE(a.email_addr, CHR(32), '')),
						INITCAP(d.last_nm),
						CASE WHEN LENGTH(d.first_nm) = 2 THEN UPPER(d.first_nm) ELSE INITCAP(d.first_nm) END,
						d.campaign, 
						d.first_response_dt, 
						d.day_between_group, 
						a.gift_typ, 
						a.frwl_gift_id, 
						a.src_cd 
					ORDER BY a.load_id ASC
				) AS rn
			FROM mktg_stage_tbls.dm_response_gplg_stg a
			INNER JOIN (
				SELECT 
					email_addr, 
					last_nm, 
					first_nm, 
					campaign, 
					first_response_dt,
					day_between_group, 
					gift_typ,
					COUNT(*) AS response_cnt,
					MIN(response_ts) AS min_response_ts
				FROM (
					SELECT
						REPLACE(a.email_addr, CHR(32), '') AS email_addr,
						a.last_nm, 
						a.first_nm, 
						b.campaign,
						b.first_response_dt,
						CASE WHEN a.response_dt IS NULL AND a.appl_src_cd = 'FRWL' 
							 THEN a.gift_created_ts::timestamp 
							 ELSE a.response_dt 
						END AS response_dt,
						DATEDIFF(day, b.first_response_dt, 
							CASE WHEN a.response_dt IS NULL AND a.appl_src_cd = 'FRWL' 
								 THEN a.gift_created_ts::timestamp 
								 ELSE a.response_dt 
							END) AS response_days_between,
						CASE 
							WHEN DATEDIFF(day, b.first_response_dt, 
									CASE WHEN a.response_dt IS NULL AND a.appl_src_cd = 'FRWL' 
										 THEN a.gift_created_ts::timestamp 
										 ELSE a.response_dt 
									END) BETWEEN 0 AND 60 THEN '0-60'
							WHEN DATEDIFF(day, b.first_response_dt, 
									CASE WHEN a.response_dt IS NULL AND a.appl_src_cd = 'FRWL' 
										 THEN a.gift_created_ts::timestamp 
										 ELSE a.response_dt 
									END) BETWEEN 61 AND 120 THEN '61-120'
							WHEN DATEDIFF(day, b.first_response_dt, 
									CASE WHEN a.response_dt IS NULL AND a.appl_src_cd = 'FRWL' 
										 THEN a.gift_created_ts::timestamp 
										 ELSE a.response_dt 
									END) BETWEEN 121 AND 180 THEN '121-180'
							ELSE '181+'
						END AS day_between_group,
						a.gift_typ,
						CASE WHEN a.response_ts IS NULL AND a.appl_src_cd = 'FRWL' 
							 THEN a.gift_created_ts::timestamp 
							 ELSE a.response_ts 
						END AS response_ts
					FROM mktg_stage_tbls.dm_response_gplg_stg a 
					LEFT JOIN (
						SELECT 
							REPLACE(email_addr, CHR(32), '') AS email_addr, 
							last_nm, 
							first_nm, 
							CASE 
								WHEN REGEXP_SUBSTR(site_url, 'tracking/([^/]+)\\.php', 1, 1, 'i') IS NOT NULL 
								THEN REGEXP_SUBSTR(site_url, 'tracking/([^/]+)\\.php', 1, 1, 'i')
								ELSE
									SUBSTRING(
										TRIM(site_url),
										STRPOS(TRIM(site_url), 'redcrosslegacy.org/') + 19,
										CASE 
											WHEN STRPOS(site_url, '?') = 0 
											THEN LENGTH(site_url) 
											ELSE STRPOS(site_url, '?') - (STRPOS(TRIM(site_url), 'redcrosslegacy.org/') + 19) 
										END
									)
							END AS campaign,
							MIN(CASE WHEN response_dt IS NULL AND appl_src_cd = 'FRWL' 
									THEN gift_created_ts::date 
									ELSE response_dt 
								END) AS first_response_dt,
							COALESCE(gift_typ, '') AS gift_typ
						FROM mktg_stage_tbls.dm_response_gplg_stg
						WHERE (TRIM(cds_batch_number) = '' OR cds_batch_number IS NULL) 
						GROUP BY 1, 2, 3, 4, 6
					) b ON REPLACE(a.email_addr, CHR(32), '') = b.email_addr
						AND a.last_nm = b.last_nm 
						AND a.first_nm = b.first_nm 
						AND (
							(
								CASE 
									WHEN REGEXP_SUBSTR(a.site_url, 'tracking/([^/]+)\\.php', 1, 1, 'i') IS NOT NULL 
									THEN REGEXP_SUBSTR(a.site_url, 'tracking/([^/]+)\\.php', 1, 1, 'i')
									ELSE SUBSTRING(
										TRIM(a.site_url),
										STRPOS(TRIM(a.site_url), 'redcrosslegacy.org/') + 19,
										CASE 
											WHEN STRPOS(a.site_url, '?') = 0 
											THEN LENGTH(a.site_url) 
											ELSE STRPOS(a.site_url, '?') - (STRPOS(TRIM(a.site_url), 'redcrosslegacy.org/') + 19) 
										END
									)
								END = b.campaign
							)
							OR (
								CASE 
									WHEN REGEXP_SUBSTR(a.site_url, 'tracking/([^/]+)\\.php', 1, 1, 'i') IS NOT NULL 
									THEN REGEXP_SUBSTR(a.site_url, 'tracking/([^/]+)\\.php', 1, 1, 'i')
									ELSE SUBSTRING(
										TRIM(a.site_url),
										STRPOS(TRIM(a.site_url), 'redcrosslegacy.org/') + 19,
										CASE 
											WHEN STRPOS(a.site_url, '?') = 0 
											THEN LENGTH(a.site_url) 
											ELSE STRPOS(a.site_url, '?') - (STRPOS(TRIM(a.site_url), 'redcrosslegacy.org/') + 19) 
										END
									)
								END IS NULL AND b.campaign IS NULL
							)
						)
						AND COALESCE(a.gift_typ, '') = COALESCE(b.gift_typ, '')
					WHERE (TRIM(a.cds_batch_number) = '' OR a.cds_batch_number IS NULL) 
				) c
				GROUP BY 1, 2, 3, 4, 5, 6, 7
			) d ON REPLACE(a.email_addr, CHR(32), '') = d.email_addr
				AND a.last_nm = d.last_nm 
				AND a.first_nm = d.first_nm 
				AND (a.gift_typ = d.gift_typ OR (a.gift_typ IS NULL AND d.gift_typ IS NULL))
			WHERE 
				CASE WHEN a.response_ts IS NULL AND a.appl_src_cd = 'FRWL' 
					 THEN a.gift_created_ts::timestamp 
					 ELSE a.response_ts::timestamp 
				END = d.min_response_ts::timestamp
				AND a.row_stat_cd <> 'L'
		)
		SELECT 
			pgc_response_id,
			clnsd_first_nm,  
			clnsd_last_nm,  
			clnsd_email_addr, 
			campaign, first_response_dt, day_between_group, response_cnt, min_response_ts, 
			NULL AS match_lob_src,
			NULL AS match_typ,
			cds_batch_number, cds_sequence_number, 
			CASE WHEN response_dt IS NULL AND appl_src_cd = 'FRWL' THEN gift_created_ts_src ELSE response_ts_src END AS response_ts_src,
			CASE WHEN response_dt IS NULL AND appl_src_cd = 'FRWL' THEN gift_created_ts ELSE response_ts END AS response_ts, 
			CASE WHEN response_dt IS NULL AND appl_src_cd = 'FRWL' THEN gift_created_ts::date ELSE response_dt END AS response_dt, 
			site_url, lander_type, nk_ecode, src_cd_src,
			src_cd, cnst_mstr_id_src, cnst_mstr_id, orig_cnst_mstr_id, ttl,
			first_nm, middle_nm, last_nm, sfx, prf_ttl, cmpny_nm, birth_dt_src,
			birth_dt, spouse_birth_dt_src, spouse_birth_dt, addr_ln1, addr_ln2,
			addr_ln3, city, state, zip_cd, 
			phone_num, phone_mobile_ind, phone_home_ind,
			email_addr,
			cntct_prfrnc_phone,
			cntct_prfrnc_text,
			cntct_prfrnc_email,
			cdrp_pg_info_request_pg_information,
			cdrp_pg_confirm_arc_in_will, cga_age_payments_begin, cga_5000,
			cga_10000, cga_50000, cga_100000, cga_other, cga_fdbk, wg_rqst,
			wg_arc_in_will, 
			wg_intend_arc_in_will,
			wg_consider_arc_in_will, wg_fdbk, interest_in_life_income_gift_w_stock,
			interest_in_life_income_gift_w_real_estate, interest_in_life_income_gift_w_ira,
			interest_in_gift_in_will, interest_in_gift_outside_will, interest_in_life_income_gifts,
			interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
			giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
			giving_reason_respond_to_local_or_national_disasters_or_emergencies,
			giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
			influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
			arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
			arc_programs_blood_services, arc_programs_domestic_disaster_relief,
			arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
			means_of_support_check_credit_card, means_of_support_volunteering,
			means_of_support_gift_in_your_will, 
			means_of_support_gift_from_ira_by_qcd,
			means_of_support_gift_by_beneficiary_designation,
			means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
			means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
			marital_status, chldrn, grndchldrn, age, arc_story, cds_image_id,
			gift_typ,
			gift_created_ts_src,
			gift_created_ts::date AS gift_created_dt,
			dcmnt_created_ts_src,
			dcmnt_created_ts::date AS dcmnt_created_dt,
			est_gift_value_amt,
			gift_value_typ,
			plan_typ,
			contigent_lvl,
			message,
			don_ext_id,
			frwl_gift_id,
			asset_type,
			fincl_inst,
			prfrd_nm,
			chng_made_ts_src,
			chng_made_ts::date AS chng_made_dt,
			old_gift_value_amt,
			new_gift_value_amt,
			jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
			curr_prcsd_file_nm, 
			CURRENT_DATE AS last_match_proc_dt, 
			NULL AS stuart_list_proc_dt,
			dw_trans_ts, row_stat_cd, appl_src_cd, load_id
		FROM ranked_data
		WHERE rn = 1;
		
		/* 
		Now apply the update SQL statements below  to link dedupped online response data from PG Calc to CDI master ids.  We've incduled attribute to describe the match type and match LOB source.
		*/
		-- Full Name & Address match update
		WITH full_name_addr_match AS (
			SELECT            
				a.clnsd_first_nm, 
				COALESCE(COLLATE(e.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(f.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(g.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(h.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), NULL) AS dm_cnst_prsn_f_nm, 
				a.clnsd_last_nm, 
				a.clnsd_email_addr, 
				CASE 
					WHEN e.cnst_mstr_id IS NOT NULL THEN COLLATE('FR', 'CASE_INSENSITIVE')
					WHEN f.cnst_mstr_id IS NOT NULL THEN COLLATE('BIO', 'CASE_INSENSITIVE')
					WHEN g.cnst_mstr_id IS NOT NULL THEN COLLATE('TS', 'CASE_INSENSITIVE')
					WHEN h.cnst_mstr_id IS NOT NULL THEN COLLATE('VOL', 'CASE_INSENSITIVE')
					ELSE COLLATE('NULL', 'CASE_INSENSITIVE')
				END AS match_lob_src, 
				COLLATE('Fullname-Addr', 'CASE_INSENSITIVE') AS match_typ, 
				response_ts_src,
				response_ts, response_dt, nk_ecode, src_cd_src,
				src_cd, cnst_mstr_id_src, 
				COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS cnst_mstr_id, 
				COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS orig_cnst_mstr_id, 
				addr_ln1, city, state, zip_cd, email_addr,
				ROW_NUMBER() OVER (
					PARTITION BY clnsd_first_nm, clnsd_last_nm, response_ts, addr_ln1, city, state, zip_cd
					ORDER BY COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) ASC
				) AS rn
			FROM mktg_stage_tbls.dm_response_gplg_stg_merge a
			LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e
				ON COLLATE(CASE WHEN Length(a.first_nm) = 2 THEN Upper(a.first_nm) ELSE Initcap(a.first_nm) END, 'CASE_INSENSITIVE') = COLLATE(e.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(e.dm_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(e.dm_cnst_line_1_addr, 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(e.dm_cnst_city_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(e.dm_cnst_st_cd, 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(e.dm_cnst_zip_5_cd, 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
				ON COLLATE(CASE WHEN Length(a.first_nm) = 2 THEN Upper(a.first_nm) ELSE Initcap(a.first_nm) END, 'CASE_INSENSITIVE') = COLLATE(f.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(f.dm_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(f.dm_cnst_line_1_addr, 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(f.dm_cnst_city_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(f.dm_cnst_st_cd, 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(f.dm_cnst_zip_5_cd, 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
				ON COLLATE(CASE WHEN Length(a.first_nm) = 2 THEN Upper(a.first_nm) ELSE Initcap(a.first_nm) END, 'CASE_INSENSITIVE') = COLLATE(g.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(g.dm_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(g.dm_cnst_line_1_addr, 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(g.dm_cnst_city_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(g.dm_cnst_st_cd, 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(g.dm_cnst_zip_5_cd, 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
				ON COLLATE(CASE WHEN Length(a.first_nm) = 2 THEN Upper(a.first_nm) ELSE Initcap(a.first_nm) END, 'CASE_INSENSITIVE') = COLLATE(h.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(h.dm_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(h.dm_cnst_line_1_addr, 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(h.dm_cnst_city_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(h.dm_cnst_st_cd, 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(h.dm_cnst_zip_5_cd, 'CASE_INSENSITIVE')
			WHERE 
				(COLLATE(TRIM(a.cds_batch_number), 'CASE_INSENSITIVE') = COLLATE('', 'CASE_INSENSITIVE') OR a.cds_batch_number IS NULL) 
				AND COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) IS NOT NULL 
				AND (a.cnst_mstr_id IS NULL OR a.cnst_mstr_id = 0)
		)
		UPDATE mktg_stage_tbls.dm_response_gplg_stg_merge 
		SET 
			cnst_mstr_id_src = a.cnst_mstr_id_src,
			cnst_mstr_id = a.cnst_mstr_id,
			orig_cnst_mstr_id = a.orig_cnst_mstr_id,
			match_typ = a.match_typ,
			match_lob_src = a.match_lob_src
		FROM full_name_addr_match a
		WHERE 
			COLLATE(a.clnsd_first_nm, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_first_nm, 'CASE_INSENSITIVE')
			AND COLLATE(a.clnsd_last_nm, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_last_nm, 'CASE_INSENSITIVE')
			AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.addr_ln1, 'CASE_INSENSITIVE')
			AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.city, 'CASE_INSENSITIVE')
			AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.state, 'CASE_INSENSITIVE')
			AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.zip_cd, 'CASE_INSENSITIVE')
			AND a.response_ts = mktg_stage_tbls.dm_response_gplg_stg_merge.response_ts
			AND a.rn = 1;

		-- Partial Name & Address match update
		WITH partial_name_addr_match AS (
			SELECT            
				a.clnsd_first_nm, 
				COALESCE(COLLATE(e.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(f.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(g.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(h.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), NULL) AS dm_cnst_prsn_f_nm, 
				a.clnsd_last_nm, 
				a.clnsd_email_addr, 
				CASE 
					WHEN e.cnst_mstr_id IS NOT NULL THEN COLLATE('FR', 'CASE_INSENSITIVE')
					WHEN f.cnst_mstr_id IS NOT NULL THEN COLLATE('BIO', 'CASE_INSENSITIVE')
					WHEN g.cnst_mstr_id IS NOT NULL THEN COLLATE('TS', 'CASE_INSENSITIVE')
					WHEN h.cnst_mstr_id IS NOT NULL THEN COLLATE('VOL', 'CASE_INSENSITIVE')
					ELSE COLLATE('NULL', 'CASE_INSENSITIVE')
				END AS match_lob_src, 
				COLLATE('Partial Name-Addr', 'CASE_INSENSITIVE') AS match_typ, 
				response_ts_src,
				response_ts, response_dt, nk_ecode, src_cd_src,
				src_cd, cnst_mstr_id_src, 
				COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS cnst_mstr_id, 
				COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS orig_cnst_mstr_id, 
				addr_ln1, city, state, zip_cd, email_addr,
				ROW_NUMBER() OVER (
					PARTITION BY clnsd_last_nm, response_ts, addr_ln1, city, state, zip_cd
					ORDER BY COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) ASC
				) AS rn
			FROM mktg_stage_tbls.dm_response_gplg_stg_merge a
			LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e
				ON COLLATE(SUBSTRING(a.first_nm, 1, 3), 'CASE_INSENSITIVE') = COLLATE(COALESCE(SUBSTRING(e.dm_cnst_prsn_f_nm, 1, 3), SUBSTRING(e.em_cnst_prsn_f_nm, 1, 3)), 'CASE_INSENSITIVE')
				AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_prsn_l_nm, e.em_cnst_prsn_l_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_line_1_addr, e.em_cnst_line_1_addr), 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_city_nm, e.em_cnst_city_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_st_cd, e.em_cnst_st_cd), 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_st_cd, e.em_cnst_zip_5_cd), 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
				ON COLLATE(SUBSTRING(a.first_nm, 1, 3), 'CASE_INSENSITIVE') = COLLATE(COALESCE(SUBSTRING(f.dm_cnst_prsn_f_nm, 1, 3), SUBSTRING(f.em_cnst_prsn_f_nm, 1, 3)), 'CASE_INSENSITIVE')
				AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_prsn_l_nm, f.em_cnst_prsn_l_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_line_1_addr, f.em_cnst_line_1_addr), 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_city_nm, f.em_cnst_city_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_st_cd, f.em_cnst_st_cd), 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_st_cd, f.em_cnst_zip_5_cd), 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
				ON COLLATE(SUBSTRING(a.first_nm, 1, 3), 'CASE_INSENSITIVE') = COLLATE(COALESCE(SUBSTRING(g.dm_cnst_prsn_f_nm, 1, 3), SUBSTRING(g.em_cnst_prsn_f_nm, 1, 3)), 'CASE_INSENSITIVE')
				AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_prsn_l_nm, g.em_cnst_prsn_l_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_line_1_addr, g.em_cnst_line_1_addr), 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_city_nm, g.em_cnst_city_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_st_cd, g.em_cnst_st_cd), 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_st_cd, g.em_cnst_zip_5_cd), 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
				ON COLLATE(SUBSTRING(a.first_nm, 1, 3), 'CASE_INSENSITIVE') = COLLATE(COALESCE(SUBSTRING(h.dm_cnst_prsn_f_nm, 1, 3), SUBSTRING(h.em_cnst_prsn_f_nm, 1, 3)), 'CASE_INSENSITIVE')
				AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_prsn_l_nm, h.em_cnst_prsn_l_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_line_1_addr, h.em_cnst_line_1_addr), 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_city_nm, h.em_cnst_city_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_st_cd, h.em_cnst_st_cd), 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_st_cd, h.em_cnst_zip_5_cd), 'CASE_INSENSITIVE')
			WHERE 
				(COLLATE(TRIM(a.cds_batch_number), 'CASE_INSENSITIVE') = COLLATE('', 'CASE_INSENSITIVE') OR a.cds_batch_number IS NULL) 
				AND COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id) IS NOT NULL 
				AND (a.cnst_mstr_id IS NULL OR a.cnst_mstr_id = 0)
				AND a.cnst_mstr_id IS NULL
		)
		UPDATE mktg_stage_tbls.dm_response_gplg_stg_merge 
		SET 
			cnst_mstr_id_src = a.cnst_mstr_id_src,
			cnst_mstr_id = a.cnst_mstr_id,
			orig_cnst_mstr_id = a.orig_cnst_mstr_id,
			match_typ = a.match_typ,
			match_lob_src = a.match_lob_src
		FROM partial_name_addr_match a
		WHERE COLLATE(SUBSTRING(a.clnsd_first_nm, 1, 3), 'CASE_INSENSITIVE') = COLLATE(SUBSTRING(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_first_nm, 1, 3), 'CASE_INSENSITIVE')
			AND COLLATE(a.clnsd_last_nm, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_last_nm, 'CASE_INSENSITIVE')
			AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.addr_ln1, 'CASE_INSENSITIVE')
			AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.city, 'CASE_INSENSITIVE')
			AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.state, 'CASE_INSENSITIVE')
			AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.zip_cd, 'CASE_INSENSITIVE')
			AND a.response_ts = mktg_stage_tbls.dm_response_gplg_stg_merge.response_ts
			AND a.rn = 1;

	-- Last Name & Address match update
		WITH last_name_addr_match AS (
			SELECT            
				a.clnsd_first_nm, 
				COALESCE(COLLATE(e.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(f.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(g.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(h.dm_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), NULL) AS dm_cnst_prsn_f_nm, 
				a.clnsd_last_nm, 
				a.clnsd_email_addr, 
				CASE 
					WHEN e.cnst_mstr_id IS NOT NULL THEN COLLATE('FR', 'CASE_INSENSITIVE')
					WHEN f.cnst_mstr_id IS NOT NULL THEN COLLATE('BIO', 'CASE_INSENSITIVE')
					WHEN g.cnst_mstr_id IS NOT NULL THEN COLLATE('TS', 'CASE_INSENSITIVE')
					WHEN h.cnst_mstr_id IS NOT NULL THEN COLLATE('VOL', 'CASE_INSENSITIVE')
					ELSE COLLATE('NULL', 'CASE_INSENSITIVE')
				END AS match_lob_src, 
				COLLATE('Last Name-Addr', 'CASE_INSENSITIVE') AS match_typ, 
				response_ts_src,
				response_ts, response_dt, nk_ecode, src_cd_src,
				src_cd, cnst_mstr_id_src, 
				COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS cnst_mstr_id, 
				COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS orig_cnst_mstr_id, 
				addr_ln1, city, state, zip_cd, email_addr,
				ROW_NUMBER() OVER (
					PARTITION BY clnsd_last_nm, response_ts, addr_ln1, city, state, zip_cd
					ORDER BY COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) ASC
				) AS rn
			FROM mktg_stage_tbls.dm_response_gplg_stg_merge a
			LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e
				ON COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_prsn_l_nm, e.em_cnst_prsn_l_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_line_1_addr, e.em_cnst_line_1_addr), 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_city_nm, e.em_cnst_city_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_st_cd, e.em_cnst_st_cd), 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(COALESCE(e.dm_cnst_st_cd, e.em_cnst_zip_5_cd), 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
				ON COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_prsn_l_nm, f.em_cnst_prsn_l_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_line_1_addr, f.em_cnst_line_1_addr), 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_city_nm, f.em_cnst_city_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_st_cd, f.em_cnst_st_cd), 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(COALESCE(f.dm_cnst_st_cd, f.em_cnst_zip_5_cd), 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
				ON COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_prsn_l_nm, g.em_cnst_prsn_l_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_line_1_addr, g.em_cnst_line_1_addr), 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_city_nm, g.em_cnst_city_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_st_cd, g.em_cnst_st_cd), 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(COALESCE(g.dm_cnst_st_cd, g.em_cnst_zip_5_cd), 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
				ON COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_prsn_l_nm, h.em_cnst_prsn_l_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_line_1_addr, h.em_cnst_line_1_addr), 'CASE_INSENSITIVE')
				AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_city_nm, h.em_cnst_city_nm), 'CASE_INSENSITIVE')
				AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_st_cd, h.em_cnst_st_cd), 'CASE_INSENSITIVE')
				AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(COALESCE(h.dm_cnst_st_cd, h.em_cnst_zip_5_cd), 'CASE_INSENSITIVE')
			WHERE 
				(COLLATE(TRIM(a.cds_batch_number), 'CASE_INSENSITIVE') = COLLATE('', 'CASE_INSENSITIVE') OR a.cds_batch_number IS NULL) 
				AND COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id) IS NOT NULL 
				AND (a.cnst_mstr_id IS NULL OR a.cnst_mstr_id = 0)
				AND COLLATE(COALESCE(a.first_nm, '') || COALESCE(a.last_nm, '') || COALESCE(a.site_url, '') || COALESCE(a.response_ts_src, ''), 'CASE_INSENSITIVE') NOT IN (
					SELECT COLLATE(COALESCE(first_nm, '') || COALESCE(last_nm, '') || COALESCE(site_url, '') || COALESCE(response_ts_src, ''), 'CASE_INSENSITIVE')
					FROM mktg_stage_tbls.dm_response_gplg_stg_merge
				)
		)
		UPDATE mktg_stage_tbls.dm_response_gplg_stg_merge 
		SET 
			cnst_mstr_id_src = a.cnst_mstr_id_src,
			cnst_mstr_id = a.cnst_mstr_id,
			orig_cnst_mstr_id = a.orig_cnst_mstr_id,
			match_typ = a.match_typ,
			match_lob_src = a.match_lob_src
		FROM last_name_addr_match a
		WHERE COLLATE(a.clnsd_last_nm, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_last_nm, 'CASE_INSENSITIVE')
			AND COLLATE(a.addr_ln1, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.addr_ln1, 'CASE_INSENSITIVE')
			AND COLLATE(a.city, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.city, 'CASE_INSENSITIVE')
			AND COLLATE(a.state, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.state, 'CASE_INSENSITIVE')
			AND COLLATE(a.zip_cd, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.zip_cd, 'CASE_INSENSITIVE')
			AND a.response_ts = mktg_stage_tbls.dm_response_gplg_stg_merge.response_ts
			AND a.rn = 1;
			
			
		-- Full Name & Email Address match update
		WITH full_name_email_match AS (
				SELECT            
					a.clnsd_first_nm, 
					COALESCE(COLLATE(e.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(f.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(g.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(h.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), NULL) AS em_cnst_prsn_f_nm, 
					a.clnsd_last_nm, 
					a.clnsd_email_addr, 
					CASE 
						WHEN e.cnst_mstr_id IS NOT NULL THEN COLLATE('FR', 'CASE_INSENSITIVE')
						WHEN f.cnst_mstr_id IS NOT NULL THEN COLLATE('BIO', 'CASE_INSENSITIVE')
						WHEN g.cnst_mstr_id IS NOT NULL THEN COLLATE('TS', 'CASE_INSENSITIVE')
						WHEN h.cnst_mstr_id IS NOT NULL THEN COLLATE('VOL', 'CASE_INSENSITIVE')
						ELSE COLLATE('NULL', 'CASE_INSENSITIVE')
					END AS match_lob_src, 
					COLLATE('Fullname-Email', 'CASE_INSENSITIVE') AS match_typ, 
					response_ts_src,
					response_ts, response_dt, nk_ecode, src_cd_src,
					src_cd, cnst_mstr_id_src, 
					COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS cnst_mstr_id, 
					COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS orig_cnst_mstr_id, 
					addr_ln1, city, state, zip_cd, email_addr,
					ROW_NUMBER() OVER (
						PARTITION BY clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, response_ts
						ORDER BY COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) ASC
					) AS rn
				FROM mktg_stage_tbls.dm_response_gplg_stg_merge a
				LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e
					ON COLLATE(a.first_nm, 'CASE_INSENSITIVE') = COLLATE(e.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE')
					AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(e.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
					AND COLLATE(a.email_addr, 'CASE_INSENSITIVE') = COLLATE(e.em_cnst_email, 'CASE_INSENSITIVE')
				LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
					ON COLLATE(a.first_nm, 'CASE_INSENSITIVE') = COLLATE(f.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE')
					AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(f.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
					AND COLLATE(a.email_addr, 'CASE_INSENSITIVE') = COLLATE(f.em_cnst_email, 'CASE_INSENSITIVE')
				LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
					ON COLLATE(a.first_nm, 'CASE_INSENSITIVE') = COLLATE(g.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE')
					AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(g.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
					AND COLLATE(a.email_addr, 'CASE_INSENSITIVE') = COLLATE(g.em_cnst_email, 'CASE_INSENSITIVE')
				LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
					ON COLLATE(a.first_nm, 'CASE_INSENSITIVE') = COLLATE(h.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE')
					AND COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(h.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
					AND COLLATE(a.email_addr, 'CASE_INSENSITIVE') = COLLATE(h.em_cnst_email, 'CASE_INSENSITIVE')
				WHERE 
					(COLLATE(TRIM(a.cds_batch_number), 'CASE_INSENSITIVE') = COLLATE('', 'CASE_INSENSITIVE') OR a.cds_batch_number IS NULL)
					AND COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id) IS NOT NULL 
					AND (a.cnst_mstr_id IS NULL OR a.cnst_mstr_id = 0)
			)
			UPDATE mktg_stage_tbls.dm_response_gplg_stg_merge 
			SET 
				cnst_mstr_id_src = a.cnst_mstr_id_src,
				cnst_mstr_id = a.cnst_mstr_id,
				orig_cnst_mstr_id = a.orig_cnst_mstr_id,
				match_typ = a.match_typ,
				match_lob_src = a.match_lob_src
			FROM full_name_email_match a
			WHERE COLLATE(a.clnsd_first_nm, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_first_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.clnsd_last_nm, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_last_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.clnsd_email_addr, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_email_addr, 'CASE_INSENSITIVE')
				AND a.response_ts = mktg_stage_tbls.dm_response_gplg_stg_merge.response_ts
				AND a.rn = 1;

		-- Last Name & Email Address match update
		WITH last_name_email_match AS (
			SELECT            
				a.clnsd_first_nm, 
				COALESCE(COLLATE(e.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(f.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(g.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), COLLATE(h.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE'), NULL) AS em_cnst_prsn_f_nm, 
				a.clnsd_last_nm, 
				a.clnsd_email_addr, 
				CASE 
					WHEN e.cnst_mstr_id IS NOT NULL THEN COLLATE('FR', 'CASE_INSENSITIVE')
					WHEN f.cnst_mstr_id IS NOT NULL THEN COLLATE('BIO', 'CASE_INSENSITIVE')
					WHEN g.cnst_mstr_id IS NOT NULL THEN COLLATE('TS', 'CASE_INSENSITIVE')
					WHEN h.cnst_mstr_id IS NOT NULL THEN COLLATE('VOL', 'CASE_INSENSITIVE')
					ELSE COLLATE('NULL', 'CASE_INSENSITIVE')
				END AS match_lob_src, 
				COLLATE('Last Name-Email', 'CASE_INSENSITIVE') AS match_typ, 
				response_ts_src,
				response_ts, response_dt, nk_ecode, src_cd_src,
				src_cd, cnst_mstr_id_src, 
				COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS cnst_mstr_id, 
				COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) AS orig_cnst_mstr_id, 
				addr_ln1, city, state, zip_cd, email_addr,
				ROW_NUMBER() OVER (
					PARTITION BY clnsd_last_nm, clnsd_email_addr, response_ts
					ORDER BY COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id, NULL) ASC
				) AS rn
			FROM mktg_stage_tbls.dm_response_gplg_stg_merge a
			LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr e
				ON COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(e.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.email_addr, 'CASE_INSENSITIVE') = COLLATE(e.em_cnst_email, 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr f 
				ON COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(f.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.email_addr, 'CASE_INSENSITIVE') = COLLATE(f.em_cnst_email, 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr g 
				ON COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(g.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.email_addr, 'CASE_INSENSITIVE') = COLLATE(g.em_cnst_email, 'CASE_INSENSITIVE')
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr h 
				ON COLLATE(a.last_nm, 'CASE_INSENSITIVE') = COLLATE(h.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE')
				AND COLLATE(a.email_addr, 'CASE_INSENSITIVE') = COLLATE(h.em_cnst_email, 'CASE_INSENSITIVE')
			WHERE 
				(COLLATE(TRIM(a.cds_batch_number), 'CASE_INSENSITIVE') = COLLATE('', 'CASE_INSENSITIVE') OR a.cds_batch_number IS NULL)
				AND COALESCE(e.cnst_mstr_id, f.cnst_mstr_id, g.cnst_mstr_id, h.cnst_mstr_id) IS NOT NULL 
				AND (a.cnst_mstr_id IS NULL OR a.cnst_mstr_id = 0)
		)
		UPDATE mktg_stage_tbls.dm_response_gplg_stg_merge 
		SET 
			cnst_mstr_id_src = a.cnst_mstr_id_src,
			cnst_mstr_id = a.cnst_mstr_id,
			orig_cnst_mstr_id = a.orig_cnst_mstr_id,
			match_typ = a.match_typ,
			match_lob_src = a.match_lob_src
		FROM last_name_email_match a
		WHERE COLLATE(a.clnsd_first_nm, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_first_nm, 'CASE_INSENSITIVE')
			AND COLLATE(a.clnsd_last_nm, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_last_nm, 'CASE_INSENSITIVE')
			AND COLLATE(a.clnsd_email_addr, 'CASE_INSENSITIVE') = COLLATE(mktg_stage_tbls.dm_response_gplg_stg_merge.clnsd_email_addr, 'CASE_INSENSITIVE')
			AND a.response_ts = mktg_stage_tbls.dm_response_gplg_stg_merge.response_ts
			AND a.rn = 1;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_stage_tbls.dm_response_gplg_stg_merge) as INTEGER)
        WHERE proc_name = 'ld_dm_response_gplg_stg_match' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_dm_response_gplg_stg_match: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_dm_response_gplg_stg_match', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
