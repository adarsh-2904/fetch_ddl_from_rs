CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_arc_fr_smry_rco_last_sustnr_donat()
 LANGUAGE plpgsql
AS $$
	/*
Created by: Michael Andrien (NOTE: Code provided by Greg Seaberg)
Created on:  05/14/2020
Purpose: This macro instantiates the table mktg_ops_tbls.bz_arc_fr_smry_rco_last_sustnr_donat using the view mktg_ops_vws.cnst_cdi_smry_fr_rco_first_tm_src.  The table
is used within Adobe to identify the most recent online sustaining donation for a donor.  The table was created to enable the MODS Ops team to send triggered sustainer reactivation messages
to online donors more quickly.  A view over the table will be exposed in the Adobe schema to activate the data.  This data enables the team to act on the data before it is available in the gift processing system.
This was adapted from the existing macro mktg_ops_tbls.ld_bz_arc_fr_smry_rco_last_donat

Modified By:  Michael Andrien
Modified Date:  7/15/2020
Purpose:  Greg Seaberg oberved an increase in lapse sustainer donations - after investigating the cause he found that some RCO subscriptions id are getting assigned multiple master ids.  We decided to 
modify the qualify statement in the macro to limit the target table to one row per subscription id and to load the one with the most recent dontn_regis_ts.
  Old Qualify: qualify row_number() over (partition by  mb.cnst_mstr_id order by  a.trans_ts desc ) = 1;
  New Qualify: qualify row_number() over (partition by  sb.rco_subscription_id order by  a.dntn_regis_ts desc ) = 1;
Also, added the a.trans_stat in ('Pending','Processed) qualifier the the query to exclude failed or rejected transactions.

Modified By:  Greg Seaberg - Depolyed by - Michael Andrien
Modified Date:  5/25/2022
Purpose:  Add sustainer lightbox conversions so they can be suppressed from the new donor welcome series sustainer solicitation
Added a union all for lightbox conversions and wrapped in an outer query
Also, added cnst_mstr_id to the order by criteria for each qualify statement to make master ID selection consistent when multiple are credited (each inner query and the outer query have their own qualify statements)

Modified By:    Greg Seaberg
Deployed by:    Michael Andrien
Modified Date:  8/30/2023
Purpose:        Corrects channel code logic to account for PGP transactions

Modified By:    Greg Seaberg
Deployed by:    Michael Andrien
Modified Date:  6/03/2024
Purpose:        Added subscription status as well as one-click upgrade public code, the associated email, active status, and expiration date; 
								returns active one-click upgrade public codes only

Modified By:    Greg Seaberg
Deployed by:    Michael Andrien
Modified Date:  12/10/2024
Purpose:        Added subscription last upgraded and magic link last created timestamp fields from rco_vws.bz_dim_subscription
*/
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_arc_fr_smry_rco_last_sustnr_donat', 'Stored Procedure', 'Inprogress', v_start_time);


begin

			truncate table mktg_stage_tbls.bz_arc_fr_smry_rco_last_sustnr_donat_stg;
			
			insert into mktg_stage_tbls.bz_arc_fr_smry_rco_last_sustnr_donat_stg
			SELECT 
			        cnst_mstr_id,
			        trans_id,
			        rco_dntn_id,
			        dntn_regis_dt,
			        billing_email,
			        billing_f_nm, 
			        billing_l_nm,
			        em_cnst_data_src_cd,
			        em_cnst_email,
			        rco_subscription_id,
					subscription_stat,
			        online_channel_cd,
					nk_public_code,
					ocu_email,
					ocu_active_ind,
					ocu_expiry_ts,
					subscription_last_upgraded,
					magic_link_last_created
			from (
			
						SELECT 
				        mb.cnst_mstr_id,
				        a.trans_id,
				        tb.rco_dntn_id,
				        Cast(dntn_regis_ts AS DATE) AS dntn_regis_dt,
				        b.billng_email AS billing_email,
				        b.billng_f_nm AS billing_f_nm, 
				        b.billng_l_nm AS billing_l_nm,
				        prfr.em_cnst_data_src_cd,
				        prfr.em_cnst_email,
				        sb.rco_subscription_id,
								'STAT' subscription_stat,
				        CASE WHEN ch.chn_dsc = 'Recurring Online Donation' THEN 'RD' 
				          WHEN ch.chn_dsc = 'Recurring Phone Donation' THEN 'RP' 
				          WHEN ch.chn_dsc = 'Phone Donation' THEN 'PD' 
				          ELSE 'OD' end AS online_channel_cd,
						ocu.nk_public_code,
						ocu.email ocu_email,
						ocu.active ocu_active_ind,
						ocu.expires ocu_expiry_ts,
						sb.subscription_last_upgraded,
						sb.magic_link_last_created,
						Row_Number() Over (PARTITION BY  sb.rco_subscription_id ORDER BY  a.dntn_regis_ts DESC, mb.cnst_mstr_id ) as rn
					    FROM rco_vws.bz_fact_dnr_trans a 
					    LEFT JOIN rco_vws.bz_dim_trans_billng b ON a.trans_billng_key = b.trans_billng_key 
					    LEFT JOIN rco_vws.bz_dim_CDI_1C_trans_bridge tb ON  a.dnr_trans_key = tb.dnr_trans_key  -- a.rco_acct_id = tb.rco_acct_id and a.trans_billng_key = tb.trans_billng_key (1/24/2019 - MTA changed join logic to address NULL cnst_mstr_ids)
					    LEFT JOIN rco_vws.bz_dim_acct_prsn_CDI_1C ap ON tb.acct_prsn_key = ap.acct_prsn_key
					    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge mb ON mb.cnst_mstr_subj_area_id = ap.acct_prsn_key AND mb.cnst_mstr_subj_area_cd = 'RCO'
					    LEFT JOIN  mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr prfr ON mb.cnst_mstr_id=prfr.cnst_mstr_id
					    LEFT JOIN rco_vws.bz_dim_subscription sb ON a.subscription_key = sb.subscription_key
					    LEFT JOIN rco_vws.bz_dim_chn ch ON a.chn_key = ch.chn_key
							LEFT JOIN rco_vws.bz_dim_one_click_upgrade ocu ON a.subscription_key = ocu.subscription_key
					    WHERE mb.cnst_mstr_id IS NOT NULL
					                    AND recurring_gift_flag = 'Y'
					                    AND a.trans_stat IN ('Pending','Processed')
			
			  ) as subqry
			  
			  where subqry.rn=1;
			
			
			
			 
			  insert into mktg_stage_tbls.bz_arc_fr_smry_rco_last_sustnr_donat_stg                  
			  SELECT 
			        cnst_mstr_id,
			        trans_id,
			        rco_dntn_id,
			        dntn_regis_dt,
			        billing_email,
			        billing_f_nm, 
			        billing_l_nm,
			        em_cnst_data_src_cd,
			        em_cnst_email,
			        rco_subscription_id,
					subscription_stat,
			        online_channel_cd,
					nk_public_code,
					ocu_email,
					ocu_active_ind,
					ocu_expiry_ts,
					subscription_last_upgraded,
					magic_link_last_created
					
			from (
			
						  SELECT  /*identify sustainer lightbox conversions, which are new subscriptions with a future recurring_start_ts and no associated transactions*/
					      brg.cnst_mstr_id,
					      fdt.trans_id, /*trans_id of the most recent one-time transaction preceding the creation of a new subscription due to lightbox conversion*/
					      fdt.rco_dntn_id,  /*rco_dntn_id of the most recent one-time transaction preceding the creation of a new subscription due to lightbox conversion*/
					      Cast(sub.created_ts AS DATE) AS dntn_regis_dt,  /*created_ts in lieu of dntn_regis_ts*/
					      bil.billng_email AS billing_email,
					      bil.billng_f_nm AS billing_f_nm,
					      bil.billng_l_nm AS billing_l_nm,
					      frp.em_cnst_data_src_cd,
					      frp.em_cnst_email,
					      sub.rco_subscription_id,
						  'STAT' subscription_stat,
					      'OD' AS online_channel_cd,
							ocu.nk_public_code,
							ocu.email ocu_email,
							ocu.active ocu_active_ind,
							ocu.expires ocu_expiry_ts,
							sub.subscription_last_upgraded,
							sub.magic_link_last_created,
							Row_Number() Over(PARTITION BY sub.rco_subscription_id ORDER BY fdt.dntn_regis_ts DESC, brg.cnst_mstr_id) as rn
					    FROM rco_vws.bz_dim_trans_billng bil
					    INNER JOIN rco_vws.bz_dim_subscription sub ON bil.acct_key = sub.acct_key
					    INNER JOIN rco_vws.bz_fact_dnr_trans fdt ON bil.trans_billng_key = fdt.trans_billng_key AND Cast(sub.created_ts AS DATE) = Cast(fdt.dntn_regis_ts AS DATE) AND sub.created_ts >= fdt.dntn_regis_ts AND fdt.trans_stat IN ('PENDING','PROCESSED')
					    INNER JOIN rco_vws.bz_dim_CDI_1C_trans_bridge cdi1c ON bil.trans_billng_key = cdi1c.trans_billng_key 
					    INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge brg ON cdi1c.acct_prsn_key = brg.cnst_mstr_subj_area_id AND brg.cnst_mstr_subj_area_cd = 'RCO'
					    LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr frp ON brg.cnst_mstr_id = frp.cnst_mstr_id
							LEFT JOIN rco_vws.bz_dim_one_click_upgrade ocu ON sub.subscription_key = ocu.subscription_key AND ocu.active = 1
					    WHERE sub.created_ts >= DATE '2022-04-20' /*first lightbox conversion date*/
					      AND sub.rcrng_start_ts >= sub.created_ts + INTERVAL '15' DAY  /*recurring start date for lightbox conversions should be 30 days out from created date in subscription table*/
					      AND sub.rcrng_start_ts > Current_Date /*only considers lightbox conversions with future recurring start dates since there should be transactions starting on the recurring start date*/
					      AND sub.first_rco_dntn_id IS NULL /*lightbox conversions should have null values for first and last rco_dntn_id columns until the recurring start date*/
			
			    ) as subqry
			    
			    where subqry.rn = 1;
			
			  
			    
			truncate table mktg_ops_tbls.bz_arc_fr_smry_rco_last_sustnr_donat;
			
			insert into mktg_ops_tbls.bz_arc_fr_smry_rco_last_sustnr_donat
			
			SELECT 
			         cnst_mstr_id,
			    trans_id ,
			    rco_dntn_id,
			    last_dntn_regis_dt,
			    billing_email,
			    billing_f_nm,
			    billing_l_nm,
			    em_cnst_data_src_cd ,
			    em_cnst_email,
			    rco_subscription_id ,
			    subscription_stat,
			    online_channel_cd ,
			    nk_public_cd ,
			    ocu_email,
			    ocu_active_ind,
			    ocu_expiry_ts,
			    subscription_last_upgraded,
			    magic_link_last_created 
			    
			  from (
			  
			  			SELECT 
					        cnst_mstr_id,
						    trans_id ,
						    rco_dntn_id,
						    last_dntn_regis_dt,
						    billing_email,
						    billing_f_nm,
						    billing_l_nm,
						    em_cnst_data_src_cd ,
						    em_cnst_email,
						    rco_subscription_id ,
						    subscription_stat,
						    online_channel_cd ,
						    nk_public_cd ,
						    ocu_email,
						    ocu_active_ind,
						    ocu_expiry_ts,
						    subscription_last_upgraded,
						    magic_link_last_created ,
							Row_Number() Over(PARTITION BY rco_subscription_id ORDER BY last_dntn_regis_dt DESC, cnst_mstr_id) as rn
						from mktg_stage_tbls.bz_arc_fr_smry_rco_last_sustnr_donat_stg
			 
			       ) as subqry
			       
			    where subqry.rn=1;

		
		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bz_arc_fr_smry_rco_last_sustnr_donat) as INTEGER)
			WHERE proc_name = 'ld_bz_arc_fr_smry_rco_last_sustnr_donat' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bz_arc_fr_smry_rco_last_sustnr_donat', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
