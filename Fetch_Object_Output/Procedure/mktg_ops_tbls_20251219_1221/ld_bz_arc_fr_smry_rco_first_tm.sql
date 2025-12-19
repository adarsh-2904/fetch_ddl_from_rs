CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_arc_fr_smry_rco_first_tm()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Andrien
Created on:  12/18/2018
Purpose: This macro instantiates the table mktg_ops_tbls.bz_cnst_cdi_smry_fr_rco_first_tm using the view mktg_ops_vws.cnst_cdi_smry_fr_rco_first_tm_src.  The 
					is used within Adobe to identify new, first time donors for the 'Welcome Series' email campaign.
*/
/* Below is the comments for the mktg_ops_vws.arc_fr_smry_rco_first_tm_src */
/*
Created By: Mike Andrien
Created Date: 12/12/2018
Purpose: Added the RCO source to include online transactions from the AEM/RCO online gift system.  This system replaced ATG on 8/10/2018.
					NOTE: This replaces the mktg_ops_vws.arc_fr_smry_atg_first_tm_src view.   This view feeds the macro that load the data into a physical table
									for the view reference within the Adobe Campaign schema.

Modified By: Mike Andrien
Modified Date: 01/24/2019
Purpose: 		Modified the join below to fix issues with NULL cnst_mstr_ids in the view results
					left join rco_tbls.dim_CDI_1C_trans_bridge tb on  a.dnr_trans_key = tb.dnr_trans_key  -- a.rco_acct_id = tb.rco_acct_id and a.trans_billng_key = tb.trans_billng_key (1/24/2019 - MTA changed join logic to address NULL cnst_mstr_ids)

Modified by: Michael Andrien
Modified on: 04/27/2020
Purpose: Changed the FR Smry and Preferred joins to the GMS views.

Modified by: Michael Andrien
Modified on: 11/06/2020
Purpose: Updated the arc_fr_txn table reference to gms_arc_fr_txn.

Modified By: Michael Andrien
Modified Date: 04/01/2022
Purpose: Removed the 'and a.f_tym_email_dnr_ind = 1' qualifier from the outer where clause in the query.   This qualifier was intended to limit the returned rows to those identified as being
the first online donation for the donor.  Something changed in the RCO views around 1/5/2021 that resulted in the indicator not being set to 1.

Modified by: Greg Seaberg
Deployed by: Michael Andrien
Modified on: 05/27/2022
Purpose: Added a second qualify criterion to produce a table that's distinct at the email / cnst_mstr_id grain using the following logic
	row_number() over (partition by coalesce(prfr.em_cnst_email,b.billng_email,cast(mb.cnst_mstr_id as varchar(15))) order by a.dntn_regis_ts) = 1
	This results in a table with only one row per email address or master ID; previously, the query returned all rows for any constituent with no fr_smry profile or credited transactions in fr_txn (meaning a different master ID was credited)
	cnst_mstr_id is included in the coalesce group to avoid eliminating phone transactions processed through an RCO donation form (which don't require an email)
	Also introduced the following changes:
	- OLD: a.trans_stat = 'PROCESSED'
	- NEW: a.trans_stat in('PENDING','PROCESSED')
	This brings in pending transactions
	- OLD: prfr.em_cnst_email = txn.em_cnst_email
	- NEW: coalesce(prfr.em_cnst_email,b.billng_email) = txn.em_cnst_email
	This joins the txn derived table to the RCO transaction when a billing email is present but a preferred email is not
*/

/*  AEM/RCO First time donors:
		Added the query section below to include the first time donors from the AEM/RCO application, which replaced ATG on 8/10/2018
*/
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_bz_arc_fr_smry_rco_first_tm', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN
		-- Truncate the staging table before loading new data
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.bz_arc_fr_smry_rco_first_tm_stg;
		-- Load data into staging table
		INSERT INTO mktg_stage_tbls.bz_arc_fr_smry_rco_first_tm_stg (
			cnst_mstr_id, 
			trans_id, 
			rco_dntn_id, 
			first_time_trans_dt, 
			billing_email, 
			billing_f_nm, 
			billing_l_nm, 
			em_cnst_data_src_cd, 
			em_cnst_email, 
			cnst_mstr_id_cnt, 
			first_cnst_mstr_id, 
			last_cnst_mstr_id
		)
		WITH ranked_transactions AS (
			SELECT 
				mb.cnst_mstr_id,
				a.trans_id,
				tb.rco_dntn_id,
				CAST(a.dntn_regis_ts AS DATE) AS first_time_trans_dt,
				COLLATE(b.billng_email::text, 'CASE_INSENSITIVE') AS billing_email,
				b.billng_f_nm AS billing_f_nm, 
				b.billng_l_nm AS billing_l_nm,
				prfr.em_cnst_data_src_cd,
				prfr.em_cnst_email,
				txn.cnst_mstr_id_cnt,
				txn.first_cnst_mstr_id,
				txn.last_cnst_mstr_id,
				a.dnr_trans_key,
				a.trans_ts,
				a.dntn_regis_ts,
				ROW_NUMBER() OVER (PARTITION BY a.dnr_trans_key ORDER BY a.trans_ts DESC) AS trans_rank,
				ROW_NUMBER() OVER (PARTITION BY COALESCE(prfr.em_cnst_email, COLLATE(b.billng_email::text, 'CASE_INSENSITIVE'), CAST(mb.cnst_mstr_id AS VARCHAR(15))) ORDER BY a.dntn_regis_ts) AS email_rank    FROM eda.rco_vws.bz_fact_dnr_trans a 
			LEFT JOIN eda.rco_vws.bz_dim_trans_billng b 
				ON a.trans_billng_key = b.trans_billng_key 
			LEFT JOIN eda.rco_vws.bz_dim_CDI_1C_trans_bridge tb 
				ON a.dnr_trans_key = tb.dnr_trans_key
			LEFT JOIN eda.rco_vws.bz_dim_acct_prsn_CDI_1C ap 
				ON tb.acct_prsn_key = ap.acct_prsn_key
			LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge mb 
				ON mb.cnst_mstr_subj_area_id = ap.acct_prsn_key 
				AND mb.cnst_mstr_subj_area_cd = 'RCO'
			LEFT JOIN mods_bi.mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr prfr 
				ON mb.cnst_mstr_id = prfr.cnst_mstr_id
			/*  
			Added the arc_fr_smry join so we can compare the RCO trans date to the first donation date in the Mktg FR summary profile.  Since the intent is to capture the first time donation
			before the RCO gift has been processed through Team Approach and into the DW, we expect the summary record to be NULL or at best equal to the incoming ATG trans date.  This
			additional join was added becuase we discovered RCO order line records marked as first time when in fact we have earlier transactions/gifts in the DW for the constituent.  This is one of
			two checks we added to the query to ensure we pull the correct records.
			*/
			LEFT JOIN mods_bi.mktg_ops_vws.gms_arc_fr_smry smry 
				ON mb.cnst_mstr_id = smry.cnst_mstr_id
			/*
			The join below is intended to check the earliest date in our transaction tables based on any consituent in our FR preferrer profile sharing the same email address.  We do 
			this at the email address grain because this view is referenced in the triggered Welcome Series email campaign within Adobe Campaign.  We want to make sure we get to earliest donation 
			date associated with the email to make sure we do not send a new donor welcome email to someone for whom this is not their first donation.
			*/
			LEFT JOIN (
				SELECT 
					b.em_cnst_email,
					MIN(a.dntn_gift_dt) AS first_dntn_dt,
					COUNT(DISTINCT a.cnst_mstr_id) AS cnst_mstr_id_cnt,
					MIN(a.cnst_mstr_id) AS first_cnst_mstr_id,            
					MAX(a.cnst_mstr_id) AS last_cnst_mstr_id
				FROM mods_bi.mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN mods_bi.mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr b 
					ON a.cnst_mstr_id = b.cnst_mstr_id
				GROUP BY b.em_cnst_email
			) txn ON COALESCE(COLLATE(prfr.em_cnst_email::text, 'CASE_INSENSITIVE'), COLLATE(b.billng_email::text, 'CASE_INSENSITIVE')) = COLLATE(txn.em_cnst_email::text, 'CASE_INSENSITIVE')
			WHERE CAST(a.created_ts AS DATE) > '2018-08-10'  
				AND a.trans_stat IN ('PROCESSED', 'PENDING')
				AND (smry.fr_fst_dntn_dt IS NULL 
					 OR smry.fr_fst_dntn_dt = CAST(a.dntn_regis_ts AS DATE)) 
				AND (txn.first_dntn_dt IS NULL 
					 OR CAST(a.dntn_regis_ts AS DATE) <= txn.first_dntn_dt)
		)

		SELECT 
			cnst_mstr_id,
			trans_id,
			rco_dntn_id,
			first_time_trans_dt,
			billing_email,
			billing_f_nm,
			billing_l_nm,
			em_cnst_data_src_cd,
			em_cnst_email,
			cnst_mstr_id_cnt,
			first_cnst_mstr_id,
			last_cnst_mstr_id
		FROM ranked_transactions
		WHERE trans_rank = 1
			AND email_rank = 1;
			
		-- Only proceed to target table if staging was successful
        TRUNCATE TABLE mods_bi.mktg_ops_tbls.bz_arc_fr_smry_rco_first_tm;
        
        -- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.bz_arc_fr_smry_rco_first_tm
        SELECT * FROM mods_bi.mktg_stage_tbls.bz_arc_fr_smry_rco_first_tm_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bz_arc_fr_smry_rco_first_tm) as INTEGER)
        WHERE proc_name = 'ld_bz_arc_fr_smry_rco_first_tm' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bz_arc_fr_smry_rco_first_tm: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bz_arc_fr_smry_rco_first_tm', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
