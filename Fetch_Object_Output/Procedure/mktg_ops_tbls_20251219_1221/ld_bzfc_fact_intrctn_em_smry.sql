CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_fact_intrctn_em_smry()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 01-May-2015
Purpose: This macro instantiates the fact interaction email summary view into a physical table
				to help improve Campaign effectiveness reporting.  See the mktg_ops_vws.bzfc_fact_intrctn_em_smry_src
				view details for column name/title details.
				
Modified  by: Majeed Mohammad
Modified  date: 12-Aug-2015
Purpose: Added the explicit columnnames to the INSERT statement. 

Modified by: Mike Andrien
Modified Date: 2/17/16
Purpose: Added primary_cnst_mstr_id to align the interation email summary with the fact interaction all table.  Both tables
				are indexed on the primary master id.  Prior to this change the email summary was indexed on the master id and 
				the interaction table was indexed on the primary, which caused spool issues when joining the table.  Both table should
				be joined to the TXN master id on the primary master when linking interactions to TXNs to avoid spool issues.
				
Modified by: Mike Andrien
Modified Date: 03/04/16
Purpose: Added update statements to update the primary cnst mstr id to account for merged master ids and to set the true primary master id
				for accounts the have more than one person in the account.  This will align the primary master id in the interaction with the cnst_mstr_id in the arc_fr_txn and arc_fr_smry tables.
				
				
Modified by: Majeed Mohammad
Modified Date: 04/13/2016
Purpose: Changed the logic to load to the Image table and then to the actual table. The intent is to free up the actual table while the macro is executed so that the user reports are not impacted. 
I did not add the INSERT SQLs to load the actual table after IMG is loaded because I noticed that the macro locks up all the tables while it is executed and this defeats the purpose of loading to the image table. 
------------------------------------------------------------------------------------------------------------------------------------ */

/* The below following comment refers to the table mktg_ops_vws.bzfc_fact_intrctn_em_smry_src, which existed in Teradata but has now been incorporated directly into the Redshift stored procedure. */
/*
    Created By:  Michael Andrien
    Create Date: 02/06/2015
    Purpose:  This view provides summary metrics for email (EM) campaign interactions.  Each records aggregates the email sent, open, link clicked, bounced 
                     and removed (Feedback Loop Complaint - FBL) stats at the activity, segmentation, segment, email and outbound id grain.  
                     The view will be joined with the bzfc_fact_interaction_all table and is intended to support campaign effectiveness reporting
   
   Modified by Michael Andrien
   Modified 02/27/2015
   Purpose: Added Select/Group By to email remove LEFT JOIN to eliminate duplicate.  The desired objective with this Email Summary view is to get one summary record per email sent from 
                  Aprimo.  The summary aggregated opens, clicks, removes, etc into one record.
       
   Modified by Michael Andrien
   Modified 08/06/2015
   Purpose: Alex Fulton added a new Aprimo wb table to collapse the preference center data into a single table and to capture the cnst_mstr_id and outbound msg id (OBM ID) in the table.  The 
   				  email profile view references this table to link the email unsubscribe to the Aprimo email campaign.

   Modified by Michael Andrien
   Modified 02/17/2016
   Purpose:   Added placeholder for primary_cnst_mstr_id               

   Modified by Michael Andrien
   Modified 04/12/2016
   Purpose:   Added first_link_clicked_dt and last_link_clicked_dt attributes to the view.  
   
    Modified by Michael Andrien
   Modified 04/18/2016
   Purpuse: Added the UNION ALL in the Unsubscribe join to pull in the preference center lite data to the previous unsubscribe data set.          
   
   Updated by: Majeed Mohammad
Updated on;: 4-29-2016
Purpose: Add the check to filter out the non-numeric outbound id records 
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_fact_intrctn_em_smry', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		-- Truncate staging table
        TRUNCATE TABLE mods_bi.mktg_stage_tbls.bzfc_fact_intrctn_em_smry_stg;
    
		-- Insert new data
		INSERT INTO mktg_stage_tbls.bzfc_fact_intrctn_em_smry_stg (
			cnst_mstr_id, primary_cnst_mstr_id, sent_hist_rec_id, sent_hist_rec_ts, eml_gen_run_id,
			actvty_id, actvty_ttl, sgmtn_id, sgmtn_title, sgmt_id, sgmt_title,
			outbnd_id, outbnd_ttl, email_id, sent_abstract, sent_dt, dlvrd_dt,
			to_email, to_domain, from_email, from_display_nm, reply_to_email,
			forwarding_email, is_forwarded_ind, bounce_hist_rec_id, asbounce_hist_rec_ts,
			bncd_ctgy_id, bncd_ctgy_ttl, bncd_subctgy_ttl, bounce_abstract,
			remove_optout_form_id, remove_optout_form_ttl, remove_abstract,
			remove_min_hist_rec_id, remove_min_hist_rec_ts, remove_max_hist_rec_id,
			remove_max_hist_rec_ts, open_tracking_hist_rec_id, open_tracking_hist_rec_ts,
			open_tracking_abstract, min_unsubscrb_dt, max_unsubscrb_dt, unsubscrb_min_hist_rec_id,
			unsubscrb_max_hist_rec_id, sent_ind, delivered_ind, bounced_ind,
			hard_bounce_ind, soft_bounce_ind, block_bounce_ind, technical_bounce_ind,
			unknown_bounce_ind, opened_ind, unique_render_ind, total_renders_cnt,
			total_open_cnt, removed_ind, spam_complnt_cnt, spam_complnt_ind,
			unsbscrb_ind, unsbscrb_cnt, total_click_cnt, unique_click_cnt
		) 
		
		WITH emr AS (
			SELECT 
				email_id,  
				min(hist_rec_id) AS min_hist_rec_id, 
				max(hist_rec_id) AS max_hist_rec_id, 
				min(hist_rec_ts) AS min_hist_rec_ts,
				max(hist_rec_ts) AS max_hist_rec_ts,
				max(abstract) AS abstract, 
				max(optout_form_id) AS optout_form_id, 
				max(optout_form_ttl) AS optout_form_ttl,
				sum(CASE WHEN type_id = 2 THEN 1 ELSE 0 END) AS spam_complnt_cnt
			FROM mktg_ops_vws.bz_aprm_email_remove
			GROUP BY email_id
		),

		emlc AS (
			SELECT 
				email_id,  
				COUNT(*) AS total_click_cnt,  
				MAX(is_first_clk) AS unique_click_cnt,  
				min(hist_rec_ts::date) AS first_link_click_dt, 
				max(hist_rec_ts::date) AS last_link_click_dt
			FROM mktg_ops_vws.bz_aprm_email_lnk_clkd
			GROUP BY email_id
		),

		aprm_unsubscrb AS (
			SELECT 
				cnst_mstr_id,
				outbnd_id, 
				min(hist_rec_ts::date) AS min_unsubscrb_dt, 
				max(hist_rec_ts::date) AS max_unsubscrb_dt, 
				min(hist_rec_id) AS min_hist_rec_id, 
				max(hist_rec_id) AS max_hist_rec_id, 
				count(email_addr) AS unsubscrb_cnt,  
				1 AS unsubscr_ind
			FROM mktg_ops_vws.bz_aprm_wb_apnd_unsubs_rplc
			WHERE cnst_mstr_id IS NOT NULL AND outbnd_id IS NOT NULL
			GROUP BY cnst_mstr_id, outbnd_id
			
			UNION ALL
			
			SELECT 
				cnst_mstr_id,
				outbnd_id, 
				min(hist_rec_ts::date) AS min_unsubscrb_dt, 
				max(hist_rec_ts::date) AS max_unsubscrb_dt, 
				min(hist_rec_id) AS min_hist_rec_id, 
				max(hist_rec_id) AS max_hist_rec_id, 
				count(email_addr) AS unsubscrb_cnt,  
				1 AS unsubscr_ind
			FROM mktg_ops_vws.bz_aprm_wb_rplc_fr_prf_cntr_lt
			WHERE cnst_mstr_id IS NOT NULL AND outbnd_id IS NOT NULL
			AND (CASE WHEN COALESCE(TRY_CAST(outbnd_id AS INTEGER),0) > 0 THEN 1 ELSE 0 END) = 1
			GROUP BY cnst_mstr_id, outbnd_id
		), 
		
		ranked_data AS (
			SELECT  
				/* Aprimo email sent attributes */
				ems.cnst_mstr_id, 
				ems.cnst_mstr_id AS primary_cnst_mstr_id,
				ems.hist_rec_id AS sent_hist_rec_id, 
				ems.hist_rec_ts AS sent_hist_rec_ts, 
				ems.eml_gen_run_id, 
				ems.actvty_id, 
				ems.actvty_ttl, 
				ems.sgmtn_id,
				ems.sgmtn_title, 
				ems.sgmt_id, 
				ems.sgmt_title, 
				ems.outbnd_id,
				ems.outbnd_ttl, 
				ems.email_id, 
				ems.abstract AS sent_abstract, 
				ems.sent_ts::date AS sent_dt,
				ems.dlvrd_ts::date AS dlvrd_dt, 
				ems.to_email,
				ems.to_domain,  
				ems.from_email, 
				ems.from_display_nm, 
				ems.reply_to_email, 
				ems.forwarding_email, 
				ems.is_forwarded AS is_forwarded_ind, 
				
				/* Aprimo email bounce attributes */
				emb.hist_rec_id AS bounce_hist_rec_id,  
				emb.hist_rec_ts AS asbounce_hist_rec_ts,  
				emb.bncd_ctgy_id,  
				emb.bncd_ctgy_ttl,  
				emb.bncd_subctgy_ttl,  
				emb.abstract AS bounce_abstract, 
				
				/* Aprimo email remove attributes */
				emr.optout_form_id AS remove_optout_form_id,
				emr.optout_form_ttl AS remove_optout_form_ttl,
				emr.abstract AS remove_abstract,
				emr.min_hist_rec_id AS remove_min_hist_rec_id, 
				emr.min_hist_rec_ts AS remove_min_hist_rec_ts, 
				emr.max_hist_rec_id AS remove_max_hist_rec_id, 
				emr.max_hist_rec_ts AS remove_max_hist_rec_ts, 
				
				/* Aprimo email open attributes */
				emo.hist_rec_id AS open_tracking_hist_rec_id, 
				emo.hist_rec_ts AS open_tracking_hist_rec_ts, 
				emo.abstract AS open_tracking_abstract, 
				
				/* Aprimo email unsubscribe attributes */
				aprm_unsubscrb.min_unsubscrb_dt,
				aprm_unsubscrb.max_unsubscrb_dt,
				aprm_unsubscrb.min_hist_rec_id AS unsubscrb_min_hist_rec_id, 
				aprm_unsubscrb.max_hist_rec_id AS unsubscrb_max_hist_rec_id, 
				
				/* Aprimo email sent attributes */
				COALESCE((CASE WHEN COALESCE(ems.is_forwarded,0) = 0 THEN 1 ELSE 0 END), 0) AS sent_ind, 
				
				/* Aprimo email bounce attributes */
				COALESCE((CASE WHEN (emb.hist_rec_id IS NULL AND ems.dlvrd_ts IS NOT NULL AND (ems.is_forwarded = 0 OR ems.is_forwarded IS NULL)) THEN 1 ELSE 0 END), 0) AS delivered_ind, 
				COALESCE((CASE WHEN emb.hist_rec_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS bounced_ind, 
				COALESCE((CASE WHEN emb.hist_rec_id IS NOT NULL AND emb.bncd_ctgy_id = 1 THEN 1 ELSE 0 END), 0) AS hard_bounce_ind, 
				COALESCE((CASE WHEN emb.hist_rec_id IS NOT NULL AND emb.bncd_ctgy_id = 2 THEN 1 ELSE 0 END), 0) AS soft_bounce_ind, 
				COALESCE((CASE WHEN emb.hist_rec_id IS NOT NULL AND emb.bncd_ctgy_id = 3 THEN 1 ELSE 0 END), 0) AS block_bounce_ind, 
				COALESCE((CASE WHEN emb.hist_rec_id IS NOT NULL AND emb.bncd_ctgy_id = 4 THEN 1 ELSE 0 END), 0) AS technical_bounce_ind, 
				COALESCE((CASE WHEN emb.hist_rec_id IS NOT NULL AND emb.bncd_ctgy_id = 5 THEN 1 ELSE 0 END), 0) AS unknown_bounce_ind, 
				
				/* Aprimo email open attributes */
				COALESCE((CASE WHEN emo.hist_rec_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS opened_ind, 
				COALESCE((CASE WHEN emo.render_cnt > 0 THEN 1 ELSE 0 END), 0) AS unique_render_ind, 
				COALESCE(emo.render_cnt, 0) AS total_renders_cnt, 
				COALESCE(emo.subs_open_cnt, 0) + 
				COALESCE((CASE WHEN emo.hist_rec_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_open_cnt, 
				
				/* Aprimo email remove attributes */
				COALESCE((CASE WHEN emr.min_hist_rec_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS removed_ind, 
				COALESCE(emr.spam_complnt_cnt, 0) AS spam_complnt_cnt,
				COALESCE((CASE WHEN emr.spam_complnt_cnt > 0 THEN 1 ELSE 0 END), 0) AS spam_complnt_ind, 
				
				/* Aprimo Unsubscribe attributes */
				COALESCE(aprm_unsubscrb.unsubscr_ind, 0) AS unsbscrb_ind, 
				COALESCE(aprm_unsubscrb.unsubscrb_cnt, 0) AS unsbscrb_cnt,
				
				/* Aprimo email link clicked attributes */
				COALESCE(emlc.total_click_cnt, 0) AS total_click_cnt, 
				COALESCE(emlc.unique_click_cnt, 0) AS unique_click_cnt,
				emlc.first_link_click_dt,
				emlc.last_link_click_dt

			FROM mktg_ops_vws.bz_aprm_email_sent ems  
			LEFT OUTER JOIN mktg_ops_vws.bz_aprm_email_bncd emb 
				ON ems.email_id = emb.email_id 
			LEFT OUTER JOIN emr
				ON ems.email_id = emr.email_id  
			LEFT OUTER JOIN mktg_ops_vws.bz_aprm_email_opened emo 
				ON ems.email_id = emo.email_id 
			LEFT OUTER JOIN emlc 
				ON ems.email_id = emlc.email_id
			LEFT OUTER JOIN aprm_unsubscrb 
				ON ems.cnst_mstr_id = aprm_unsubscrb.cnst_mstr_id 
				AND ems.outbnd_id = aprm_unsubscrb.outbnd_id)
				
		SELECT 
			cnst_mstr_id, primary_cnst_mstr_id, sent_hist_rec_id, sent_hist_rec_ts, eml_gen_run_id,
			actvty_id, actvty_ttl, sgmtn_id, sgmtn_title, sgmt_id, sgmt_title,
			outbnd_id, outbnd_ttl, email_id, sent_abstract, sent_dt, dlvrd_dt,
			to_email, to_domain, from_email, from_display_nm, reply_to_email,
			forwarding_email, is_forwarded_ind, bounce_hist_rec_id, asbounce_hist_rec_ts,
			bncd_ctgy_id, bncd_ctgy_ttl, bncd_subctgy_ttl, bounce_abstract,
			remove_optout_form_id, remove_optout_form_ttl, remove_abstract,
			remove_min_hist_rec_id, remove_min_hist_rec_ts, remove_max_hist_rec_id,
			remove_max_hist_rec_ts, open_tracking_hist_rec_id, open_tracking_hist_rec_ts,
			open_tracking_abstract, min_unsubscrb_dt, max_unsubscrb_dt, unsubscrb_min_hist_rec_id,
			unsubscrb_max_hist_rec_id, sent_ind, delivered_ind, bounced_ind,
			hard_bounce_ind, soft_bounce_ind, block_bounce_ind, technical_bounce_ind,
			unknown_bounce_ind, opened_ind, unique_render_ind, total_renders_cnt,
			total_open_cnt, removed_ind, spam_complnt_cnt, spam_complnt_ind,
			unsbscrb_ind, unsbscrb_cnt, total_click_cnt, unique_click_cnt
		FROM ranked_data;
		
		-- Only proceed to target table if staging was successful
        TRUNCATE TABLE mods_bi.mktg_ops_tbls.bzfc_fact_intrctn_em_smry;
        
        -- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.bzfc_fact_intrctn_em_smry
        SELECT * FROM mods_bi.mktg_stage_tbls.bzfc_fact_intrctn_em_smry_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_ops_tbls.bzfc_fact_intrctn_em_smry) as INTEGER)
        WHERE proc_name = 'ld_bzfc_fact_intrctn_em_smry' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bzfc_fact_intrctn_em_smry: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bzfc_fact_intrctn_em_smry', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
