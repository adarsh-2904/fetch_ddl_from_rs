CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_bzfc_cnst_fr_prfr_em_prfl()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 2/15/16
Purpose: This macro creates a physical table for what was once a view.  The original view links the CDI FR Preferred view to the Preferred email profile view to create and extention to the 
				CDI FR Preferred view (cnst_cdi_fr_smry_prfr  to the bzfc_cdi_fr_prfr_email_profile).  The intent is to provide an email profile summary record on each 
               cnst that allows marketers to include suppressio logic in email campaigns based on email unsubscribe, bounced and feedback loop (FBL) complaints.

updated by: Majeed Mohammad
Updated date: 4/14/2016
Purpose:Added the logic to load to the image table. The intent is to free up the actual table while the macro is executed so that the user reports are not impacted. 
I did not add the INSERT SQLs to load the actual table after IMG is loaded because I noticed that the macro locks up all the tables while it is executed and this defeats the purpose of loading to the image table. 

Modified by: Michael Andrien
Modified date: 5/24/16
Purpose: Added joins to include the CMET_401_GLOBAL_OPTOUT and CMET_501_GLOBAL_OPTOUT  tables and added aprm_global_opt_out_ind column to the view to capture Aprimo Global opt outs.

Modified by: Michael Andrien
Modified date: 6/16/16
Purpose: Added Disaster Only and Newsletter Only columns to the table.

Modified by: Michael Andrien
Modified date: 8/31/16
Purpose: Updated database references to replace aprimo_lndng_tbls with mktg_ops_vws on the 2700 view.  The 2580 referenced  aprimo_lndng_tbls because of the sync process.

Modified by: Majeed Mohammad
Modified date: 4/26/17
Purpose: Added the explicit columnnames to the insert statement. Mapped NULL values to the newly added columns adb_unsbscrb_ind, adb_unsbscrb_click_cnt,
		adb_first_unsbscrb_dt, adb_last_unsbscrb_dt

Modified by: Mike Andrien
Modified date: 5/6/17
Purpose:  Added Adobe bounce and Convio Reactivation details.  Also commented out the TA/CDI opt-outs

Modified by: Majeed Mohammad
Modified date: 5/9/17
Purpose: Removed the zeroifnull on the date columns adb_first_unsbscrb_dt and adb_last_unsbscrb_dt,

Modified by: Majeed Mohammad
Modified date: 9/19/17
Purpose:  Changed the macro to use the table mktg_ops_tbls.cnst_cdi_smry_fr_prfr instead of the view mktg_ops_vws.cnst_cdi_smry_fr_prfr

Modified by: Mike Andrien 
Modified on: 10/10/2017
Purpose:  Added Email Stats: First and last email sent, opened and link clicked.

Modified by: Mike Andrien 
Modified on: 12/04/2017
Purpose: Added section to truncate and load the mktg_stage_tbls.stg_cdi_fr_prfr_email_profile table.  Then reference this table in the insert statement to load mktg_stage_tbls.bzfc_cnst_fr_prfr_em_prfl_img.
				When joining to this table, I'm using a sub-query to avoid joining the null email addresses.  This was causing skewing issues with the macro.

 Modified By: Michael Andrien
Modified Date: 02/29/2020
Purpose: Created GMS version of the view to reference the new GMS FR profiles tables and views

 Modified By: Majeed Mohammad
Modified Date: 06/30/2020
Purpose: Added the SQLs to load to the final table. Added the delete for mktg_stage_tbls.stg_gms_cdi_fr_prfr_email_profile 

 Modified By: Michael Andrien
Modified Date: 12/23/2020
Purpose: Added Adobe Disaster Only and Newsletter Only attributes

 Modified By: Michael Andrien
Modified Date: 04/02/2021
Purpose:  Added the new attributes listed below to capture the Adobe re-opt in link click details.  Also, updated the logic for setting the 'Ok to Email Flag'' to evaluate the compare the Convio, Aprimo and Adobe unsub and opt out
dates to the re-opt in last clicked 'Yes' date to ensure the opt out data is greater than the re-opt in date.
		-- Email Re-opt in attributes
		yes_reopt_in_cnt, 
		no_reopt_in_cnt, 
		first_yes_link_click_dt, 
		last_yes_link_click_dt, 
		first_no_link_click_dt, 
		last_no_link_click_dt
		
Modified By: Michael Andrien
Modified Date: 04/28/2021
Purpose:  Removed the truncate and load steps to load the physical email interaction profile view data into the mktg_stage_tbls.stg_gms_cdi_fr_prfr_email_profile table below.
We replaced this with a macro that is scheduled in our evening Mktg load processes and loads the physical table mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile and reference this 
new table in this macro and the ld_gms_cnst_cdi_smry_fr_prfr macro.
	delete from mktg_stage_tbls.stg_gms_cdi_fr_prfr_email_profile all; 
	
 Modified By: Michael Andrien
Modified Date: 06/09/2021
Purpose: Modified the ok_to_email_flg logic to ensure the Fresh Address (FAEM) and Pacific East (PEEM) sourced email overrides in the GMS FR preferred table are not set to 'N' when 
the email address from the mktg_ops_vws.gms_bzfc_cdi_fr_prfr_email_profile table is null.  This was causing the bulk of the appended email records to be marked as ok_to_email_flg = 'N'.
	case  when ok_to_email_flg = 'Y' and zeroifnull(aprm_global_opt_out_ind) = 0 then 'Y'
	when ok_to_email_flg = 'N' or  zeroifnull(aprm_global_opt_out_ind) = 1  then 'N' 
	when ok_to_email_flg is null and prfr.em_cnst_email is not null and prfr.em_cnst_data_src_cd in ('PEEM', 'FAEM') and zeroifnull(aprm_global_opt_out_ind) = 0 then 'Y'
	else 'N' end as ok_to_email_flg,		   

Modified By: Michael Andrien
Modified Date: 11/01/2022
Purpose: Added the Adobe Spam Reject attributes and changed the insert into statement from a 'select * from..' to a fully qualified select listing each column in the table/view.

Modified By: Michael Andrien
Modified Date: 11/08/2022
Purpose:  Added section for Validity Email Validation Return file checks and modified ok_to_email_flg logic to include Validity Valid email verification.------------------------------------------------------------------------------------------------------------------------------------ 

Modified By: Michael Andrien
Modified Date: 11/22/2022
Purpose: Added the bad domain check.  The suspect domain table will be manually maintained and monitored periodically for spam traps.
The long term plan is to add the bad domains to the Stuart domain validation process to set the email assessment codes to a not usable status.

Modified By: Michael Andrien
Modified Date: 05/30/2023
Purpose: Added the new Adobe Contact Preference Center table (adobe_tbls.pref_cnst_mstr) as a source

Modified By: Michael Andrien
Modified Date: 08/04/2023
Purpose: Modified the ok_to_email_flg logic
-- added zeroifnull to this line zeroifnull(apc.apc_fr_email_opt_out) to account for null values
-- added the date comparision 'cast(apc.apc_fr_last_upd_ts as date format 'yyyy-mm-dd') <= cast(last_yes_link_click_dt as date format 'yyyy-mm-dd')' to assess whether 
the opt-in date is >= the apc opt-out date.
	case  	when ok_to_email_flg = 'Y' 
				and zeroifnull(aprm_global_opt_out_ind) = 0 
				and zeroifnull(apc.apc_fr_email_opt_out) = 0 then 'Y' 
			when ok_to_email_flg = 'Y' 
				and zeroifnull(aprm_global_opt_out_ind) = 0 
				and zeroifnull(apc.apc_fr_email_opt_out) = 1 
				and cast(apc.apc_fr_last_upd_ts as date format 'yyyy-mm-dd') <= cast(last_yes_link_click_dt as date format 'yyyy-mm-dd') then 'Y'
	        when ok_to_email_flg = 'N' or  zeroifnull(aprm_global_opt_out_ind) = 1 or zeroifnull(apc.apc_fr_email_opt_out) = 1 then 'N' 
			when ok_to_email_flg is null and prfr.em_cnst_email is not null and prfr.em_cnst_data_src_cd in ('PEEM', 'FAEM') and zeroifnull(aprm_global_opt_out_ind) = 0 and apc.apc_fr_email_opt_out = 0 then 'Y'
			else 'N' end as ok_to_email_flg

Modified By: Michael Andrien
Modified Date: 12/12/2023
Purpose: Added iblacklistemail_fr attribute to the table and to the ok_to_email_flg logic.

Modified By: Michael Andrien
Modified Date: 01/17/2024
Purpose - Added the ack_email_ok_flg attribute to the profile table.

Modified By: Michael Andrien
Modified Date: 01/18/2024
Purpose - Added logic when setting the ack_email_ok_flg attribute value to be set to 'Y' if the FR Preferred profile record contains a validated email address but our 
email profile record has not information for the preferred email address.

Modified By: Adarsh Ram
Modified Date: 08/21/2024
Purpose - No TD Prod data was found. As per Majeed’s suggestion, I commented out lines 354 to 368 because aprimo_wrk_tbls.CMET_401_GLOBAL_OPTOUT and aprimo_wrk_tbls.CMET_501_GLOBAL_OPTOUT are not present in Redshift. 
Also, I commented out coalesce(aprm_global_opt_out_ind,0) =0 and adobe_tbls.pref_cnst_mstr is replaced with mktg_ops_tbls.pref_cnst_mstr.

 */	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
	total_updated int :=0;
	tmp_count INT;

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_bzfc_cnst_fr_prfr_em_prfl', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		truncate table mktg_stage_tbls.gms_bzfc_cnst_fr_prfr_em_prfl_img;
		
		INSERT INTO mktg_stage_tbls.gms_bzfc_cnst_fr_prfr_em_prfl_img
		(
			cnst_mstr_id, email_addr, ok_to_email_flg,
			ack_email_ok_flg,
			cnvo_reactvtn_flg, total_bounce_cnt,
			aprm_total_bounce_cnt, aprm_hard_bounce_cnt, aprm_soft_bounce_cnt,
			aprm_block_bounce_cnt, aprm_technical_bounce_cnt, aprm_unknown_bounce_cnt,
			aprm_total_soft_bounce_cnt, aprm_fbl_cnt, aprm_unsbscrb_cnt, aprm_first_unsbscrb_dt,
			aprm_last_unsbscrb_dt, aprm_dstr_only_cnt, aprm_dstr_only_ind,
			aprm_first_dstr_only_dt, aprm_last_dstr_only_dt, aprm_newsltr_only_cnt,
			aprm_newsltr_only_ind, aprm_first_newsltr_only_dt, aprm_last_newsltr_only_dt,
			adb_first_newsltr_only_dt, adb_last_newsltr_only_dt, adb_first_dstr_only_dt, adb_last_dstr_only_dt, adb_newsltr_only_ind, adb_dstr_only_ind, adb_newsltr_only_cnt, adb_dstr_only_cnt,		
			cnvo_opt_out_cnt, cnvo_first_opt_out_dt, cnvo_last_opt_out_dt,
			cnvo_hard_bounce_cnt, cnvo_soft_bounce_cnt, cnvo_reactvtn_start_dt, cnvo_reactvtn_end_dt,
			global_domain_opt_out_ind,global_opt_out_ind, global_cnst_opt_out_ind, intl_addr_ind, 
			--cdi_email_opt_out_cnt, ta_in_email_opt_out_cnt, ta_org_email_opt_out_cnt, 
			untd_way_blkout_ind,
			aprm_global_opt_out_ind, adb_unsbscrb_ind, adb_unsbscrb_click_cnt,
			adb_first_unsbscrb_dt, adb_last_unsbscrb_dt,adb_total_bounce_cnt,adb_hard_bounce_cnt,adb_soft_bounce_cnt,adb_fbl_cnt,adb_first_bounce_dt,adb_last_bounce_dt ,
			first_em_sent_dt,last_em_sent_dt, first_em_open_dt, last_em_open_dt, first_em_link_click_dt, last_em_link_click_dt,
			yes_reopt_in_cnt, no_reopt_in_cnt, first_yes_link_click_dt, last_yes_link_click_dt, first_no_link_click_dt, last_no_link_click_dt, first_spam_rejct_dt, last_spam_rejct_dt, spam_rejct_cnt,
			valdtn_status, valdtn_dt, bad_domain_ind,
			apc_fr_email_opt_out,apc_fr_email_opt_in_newsltr,apc_fr_email_opt_in_dstr,apc_fr_email_opt_in_loclnws,apc_fr_last_upd_ts,
			iblacklistemail_fr
		) 
		SELECT  
		prfr.cnst_mstr_id, 
		email_addr,  
		/*case when (ok_to_email_flg is null or global_cnst_opt_out_ind is null or ok_to_email_flg = 'Y')  then 'Y' 
		          when (global_cnst_opt_out_ind = 1 or ok_to_email_flg ='N')  then 'N' 
		          end ok_to_email_flg , */  -- replaced on 1/12/2015 by Mike Andrien - this was not setting the ok_to_email_flg correctly.
		case  	when ok_to_email_flg = 'Y' 
		            --and coalesce(aprm_global_opt_out_ind,0) =0 
					and coalesce(apc.apc_fr_email_opt_out,0) = 0 then 'Y' 
				when ok_to_email_flg = 'Y'
				   --and coalesce(aprm_global_opt_out_ind,0) =0
					and coalesce(apc.apc_fr_email_opt_out,0) = 1 
					and cast(apc.apc_fr_last_upd_ts as date) <= cast(last_yes_link_click_dt as date ) then 'Y'
		        when ok_to_email_flg = 'N' /*or  coalesce(aprm_global_opt_out_ind,0) = 1 */ or coalesce(apc.apc_fr_email_opt_out,0) = 1 then 'N' 
				when ok_to_email_flg is null and prfr.em_cnst_email is not null and prfr.em_cnst_data_src_cd in ('PEEM', 'FAEM') /*and coalesce(aprm_global_opt_out_ind,0) = 0 */and apc.apc_fr_email_opt_out = 0 then 'Y'
				else 'N' end as ok_to_email_flg,	
		case when prfr.em_cnst_email is not null and prfr.em_cnst_email_assessmnt_ctg in ('Validated', 'Use with Caution') and emp.ack_email_ok_flg is null then 'Y' else emp.ack_email_ok_flg end as ack_email_ok_flg,
		case when cnvo_reactvtn_flg is null then 'N' else cnvo_reactvtn_flg end as cnvo_reactvtn_flg,
		coalesce(total_bounce_cnt,0) total_bounce_cnt,
		coalesce(aprm_total_bounce_cnt,0) aprm_total_bounce_cnt,
		coalesce(aprm_hard_bounce_cnt,0) aprm_hard_bounce_cnt, 
		coalesce(aprm_soft_bounce_cnt,0) aprm_soft_bounce_cnt,
		coalesce(aprm_block_bounce_cnt,0) aprm_block_bounce_cnt,
		coalesce(aprm_technical_bounce_cnt,0) aprm_technical_bounce_cnt,
		coalesce(aprm_unknown_bounce_cnt,0) aprm_unknown_bounce_cnt,
		coalesce(aprm_total_soft_bounce_cnt,0) aprm_total_soft_bounce_cnt,
		coalesce(aprm_fbl_cnt,0) aprm_fbl_cnt, 
		coalesce(aprm_unsbscrb_cnt,0) aprm_unsbscrb_cnt,
		aprm_first_unsbscrb_dt,
		aprm_last_unsbscrb_dt,
		coalesce(aprm_dstr_only_cnt,0) aprm_dstr_only_cnt,
		coalesce(aprm_dstr_only_ind,0) aprm_dstr_only_ind,
		aprm_first_dstr_only_dt,
		aprm_last_dstr_only_dt,
		coalesce(aprm_newsltr_only_cnt,0) as aprm_newsltr_only_cnt,
		coalesce(aprm_newsltr_only_ind,0) as aprm_newsltr_only_ind,
		aprm_first_newsltr_only_dt,
		aprm_last_newsltr_only_dt,
		adb_first_newsltr_only_dt, adb_last_newsltr_only_dt, adb_first_dstr_only_dt, adb_last_dstr_only_dt, 
		coalesce(adb_newsltr_only_ind,0), 
		coalesce(adb_dstr_only_ind,0), 
		coalesce(adb_newsltr_only_cnt,0), 
		coalesce(adb_dstr_only_cnt,0),
		coalesce(cnvo_opt_out_cnt,0) as  cnvo_opt_out_cnt, 
		cnvo_first_opt_out_dt,
		cnvo_last_opt_out_dt,
		coalesce(cnvo_hard_bounce_cnt,0) as cnvo_hard_bounce_cnt, 
		coalesce(cnvo_soft_bounce_cnt,0) as cnvo_soft_bounce_cnt,
		cnvo_reactvtn_start_dt,
		cnvo_reactvtn_end_dt,
		coalesce (global_domain_opt_out_ind,0) as global_domain_opt_out_ind,
		coalesce (global_opt_out_ind,0) as  global_opt_out_ind,
		coalesce (global_cnst_opt_out_ind,0) as global_cnst_opt_out_ind,
		coalesce( intl_addr_ind,0) as intl_addr_ind,
		--zeroifnull(cdi_email_opt_out_cnt) (TITLE 'CDI Email Opt Out Count') cdi_email_opt_out_cnt,
		--zeroifnull(ta_in_email_opt_out_cnt) (TITLE 'TA Indiv Email Opt Out Count') ta_in_email_opt_out_cnt,
		--zeroifnull(ta_org_email_opt_out_cnt) (TITLE 'TA Org Email Opt Out Count') ta_org_email_opt_out_cnt,
		coalesce(untd_way_blkout_ind,0) as untd_way_blkout_ind,
		null as aprm_global_opt_out_ind, 
		coalesce(adb_unsbscrb_ind,0), 
		coalesce(adb_unsbscrb_click_cnt,0),
		adb_first_unsbscrb_dt, 
		adb_last_unsbscrb_dt,
		coalesce(adb_total_bounce_cnt,0),
		coalesce(adb_hard_bounce_cnt,0),
		coalesce(adb_soft_bounce_cnt,0),
		coalesce(adb_fbl_cnt,0),
		adb_first_bounce_dt,
		adb_last_bounce_dt,
		first_em_sent_dt, 
		last_em_sent_dt, 
		first_em_open_dt, 
		last_em_open_dt, 
		first_em_link_click_dt, 
		last_em_link_click_dt,
		coalesce(yes_reopt_in_cnt,0), 
		coalesce(no_reopt_in_cnt,0), 
		first_yes_link_click_dt, 
		last_yes_link_click_dt, 
		first_no_link_click_dt,
		last_no_link_click_dt,
		first_spam_rejct_dt, 
		last_spam_rejct_dt, 
		spam_rejct_cnt,
		valdtn_status, 
		valdtn_dt,
		bad_domain_ind,
		/* Adobe Pref Center (apc) Attributes */
		coalesce(apc.apc_fr_email_opt_out,0) as apc_fr_email_opt_out,
		coalesce(apc.apc_fr_email_opt_in_newsltr,0) as apc_fr_email_opt_in_newsltr,
		coalesce(apc.apc_fr_email_opt_in_dstr,0) as apc_fr_email_opt_in_dstr,
		coalesce(apc.apc_fr_email_opt_in_loclnws,0) as apc_fr_email_opt_in_loclnws,
		apc.apc_fr_last_upd_ts,
		iblacklistemail_fr
		
		FROM  mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr prfr
		 left outer join 
		 (
				select	
					prfr.cnst_mstr_id, email_addr, ok_to_email_flg, 
					ack_email_ok_flg,
					cnvo_reactvtn_flg, total_bounce_cnt,
					aprm_total_bounce_cnt, aprm_hard_bounce_cnt, aprm_soft_bounce_cnt,
					aprm_block_bounce_cnt, aprm_technical_bounce_cnt, aprm_unknown_bounce_cnt,
					aprm_total_soft_bounce_cnt, aprm_fbl_cnt, aprm_unsbscrb_cnt,
					aprm_first_unsbscrb_dt, aprm_last_unsbscrb_dt, aprm_dstr_only_cnt,
					aprm_dstr_only_ind, aprm_first_dstr_only_dt, aprm_last_dstr_only_dt,
					aprm_newsltr_only_cnt, aprm_newsltr_only_ind, aprm_first_newsltr_only_dt,aprm_last_newsltr_only_dt, 
					adb_first_newsltr_only_dt, adb_last_newsltr_only_dt, adb_first_dstr_only_dt, adb_last_dstr_only_dt, adb_newsltr_only_ind, adb_dstr_only_ind, adb_newsltr_only_cnt, adb_dstr_only_cnt,			
					cnvo_opt_out_cnt, cnvo_first_opt_out_dt,
					cnvo_last_opt_out_dt, cnvo_hard_bounce_cnt, cnvo_soft_bounce_cnt,
					cnvo_reactvtn_start_dt, cnvo_reactvtn_end_dt, global_domain_opt_out_ind,
					global_opt_out_ind, intl_addr_ind, untd_way_blkout_ind, adb_unsbscrb_ind,
					adb_unsbscrb_click_cnt, adb_first_unsbscrb_dt, adb_last_unsbscrb_dt,
					adb_total_bounce_cnt, adb_hard_bounce_cnt, adb_soft_bounce_cnt,
					adb_fbl_cnt, adb_first_bounce_dt, adb_last_bounce_dt, first_em_sent_dt,
					last_em_sent_dt, first_em_open_dt, last_em_open_dt, first_em_link_click_dt,
					last_em_link_click_dt,
					yes_reopt_in_cnt, no_reopt_in_cnt, first_yes_link_click_dt, last_yes_link_click_dt, first_no_link_click_dt, last_no_link_click_dt,
					first_spam_rejct_dt, last_spam_rejct_dt, spam_rejct_cnt,
					valdtn_status, valdtn_dt, bad_domain_ind,
					iblacklistemail_fr
			/* from mktg_stage_tbls.stg_gms_cdi_fr_prfr_email_profile emp 
				replaced with the table reference below
			*/ 
			from mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile emp
			join mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr prfr on collate(emp.email_addr::text,'CASE_INSENSITIVE') = collate(prfr.em_cnst_email::text,'CASE_INSENSITIVE')
			where prfr.em_cnst_email is not null      --data is not populated because prfr.em_cnst_email contains no data----          
		) emp (cnst_mstr_id, email_addr, ok_to_email_flg, ack_email_ok_flg, cnvo_reactvtn_flg, total_bounce_cnt,
					aprm_total_bounce_cnt, aprm_hard_bounce_cnt, aprm_soft_bounce_cnt,
					aprm_block_bounce_cnt, aprm_technical_bounce_cnt, aprm_unknown_bounce_cnt,
					aprm_total_soft_bounce_cnt, aprm_fbl_cnt, aprm_unsbscrb_cnt,
					aprm_first_unsbscrb_dt, aprm_last_unsbscrb_dt, aprm_dstr_only_cnt,
					aprm_dstr_only_ind, aprm_first_dstr_only_dt, aprm_last_dstr_only_dt,
					aprm_newsltr_only_cnt, aprm_newsltr_only_ind, aprm_first_newsltr_only_dt, aprm_last_newsltr_only_dt, 
					adb_first_newsltr_only_dt, adb_last_newsltr_only_dt, adb_first_dstr_only_dt, adb_last_dstr_only_dt, adb_newsltr_only_ind, adb_dstr_only_ind, adb_newsltr_only_cnt, adb_dstr_only_cnt,		
					cnvo_opt_out_cnt, cnvo_first_opt_out_dt,
					cnvo_last_opt_out_dt, cnvo_hard_bounce_cnt, cnvo_soft_bounce_cnt,
					cnvo_reactvtn_start_dt, cnvo_reactvtn_end_dt, global_domain_opt_out_ind,
					global_opt_out_ind, intl_addr_ind, untd_way_blkout_ind, adb_unsbscrb_ind,
					adb_unsbscrb_click_cnt, adb_first_unsbscrb_dt, adb_last_unsbscrb_dt,
					adb_total_bounce_cnt, adb_hard_bounce_cnt, adb_soft_bounce_cnt,
					adb_fbl_cnt, adb_first_bounce_dt, adb_last_bounce_dt, first_em_sent_dt,
					last_em_sent_dt, first_em_open_dt, last_em_open_dt, first_em_link_click_dt,
					last_em_link_click_dt, yes_reopt_in_cnt, no_reopt_in_cnt, first_yes_link_click_dt, last_yes_link_click_dt, first_no_link_click_dt, last_no_link_click_dt,
					first_spam_rejct_dt, last_spam_rejct_dt, spam_rejct_cnt, valdtn_status, valdtn_dt, bad_domain_ind, iblacklistemail_fr
				) on emp.cnst_mstr_id = prfr.cnst_mstr_id
		left join 
		/* Now add the Global Cnst Email Opt-Out table - this table enables to exclude a particular cnst_mstr_id email from consideration for email campaigns
		    and helps address issues when more than one person shares an email address and one wants the email and the other does not.  Entries 
		    in this table allow us to exlude the master id for the constituent that does not want the email.  They'll still receive the email, but it will be 
		    personalized to the person name that wants the email.
		 */
		    (select cnst_mstr_id, email_addr, 1 as global_cnst_opt_out_ind
		    from mktg_ops_tbls.global_suprs_cnst_email) gbl_cnst_opt_out(cnst_mstr_id, email_acct, global_cnst_opt_out_ind)
		    on prfr.cnst_mstr_id = gbl_cnst_opt_out.cnst_mstr_id and collate(prfr.em_cnst_email::text,'CASE_INSENSITIVE') = collate(gbl_cnst_opt_out.email_acct::text,'CASE_INSENSITIVE')
		/*
		 This next section was added by Mike Andrien on 5/24/2016 to include the Aprimo Global  Opt Out records
		*/
		    
		 /* Majeed sugested this is not required */
		--left join  (select 
		--					distinct case when b.cnst_mstr_id is null then a.cnst_mstr_id else b.new_cnst_mstr_id end, 
		--					1 as aprm_global_opt_out_ind
		--				 from aprimo_wrk_tbls.CMET_401_GLOBAL_OPTOUT a
		--				 left join mktg_ops_vws.cnst_mstr_id_map  b on a.cnst_mstr_id = b.cnst_mstr_id
		--				 
		--				 UNION 
		--				 
		--				 select 
		--				 	distinct case when b.cnst_mstr_id is null then a.cnst_mstr_id else b.new_cnst_mstr_id end,
		--					1 as aprm_global_opt_out_ind
		--				 from aprimo_wrk_tbls.CMET_501_GLOBAL_OPTOUT a
		--				 left join mktg_ops_vws.cnst_mstr_id_map  b on a.cnst_mstr_id = b.cnst_mstr_id
		--				) aprm_globl_opt_out (cnst_mstr_id, aprm_global_opt_out_ind)
		--				on prfr.cnst_mstr_id = aprm_globl_opt_out.cnst_mstr_id 
		
		/* Now join the Adobe Enterprise Contact Preference Table - Note the Adobe pref center v1.0 captures email opt-outs for FR and Bio at the cnst_mstr_id grain not at the email locator grain. */
		left join 
		(
			select 
				cnst_mstr_id,
				fr_email_opt_out,
				fr_email_opt_in_newsletters, 
				fr_email_opt_in_disaster, 
				fr_email_opt_in_localnews,
				fr_last_upd_date as fr_last_upd_ts
			from mktg_ops_tbls.pref_cnst_mstr
		) apc (cnst_mstr_id,apc_fr_email_opt_out,apc_fr_email_opt_in_newsltr,apc_fr_email_opt_in_dstr,apc_fr_email_opt_in_loclnws,apc_fr_last_upd_ts) on prfr.cnst_mstr_id = apc.cnst_mstr_id; 
		
		truncate table mktg_ops_tbls.gms_bzfc_cnst_fr_prfr_em_prfl;
		 
		insert into mktg_ops_tbls.gms_bzfc_cnst_fr_prfr_em_prfl
		select	
			cnst_mstr_id, email_addr, ok_to_email_flg, ack_email_ok_flg, cnvo_reactvtn_flg,
			total_bounce_cnt, aprm_total_bounce_cnt, aprm_hard_bounce_cnt,
			aprm_soft_bounce_cnt, aprm_block_bounce_cnt, aprm_technical_bounce_cnt,
			aprm_unknown_bounce_cnt, aprm_total_soft_bounce_cnt, aprm_fbl_cnt,
			aprm_unsbscrb_cnt, aprm_first_unsbscrb_dt, aprm_last_unsbscrb_dt,
			aprm_dstr_only_cnt, aprm_dstr_only_ind, aprm_first_dstr_only_dt,
			aprm_last_dstr_only_dt, aprm_newsltr_only_cnt, aprm_newsltr_only_ind,
			aprm_first_newsltr_only_dt, aprm_last_newsltr_only_dt, adb_first_newsltr_only_dt,
			adb_last_newsltr_only_dt, adb_first_dstr_only_dt, adb_last_dstr_only_dt,
			adb_newsltr_only_ind, adb_dstr_only_ind, adb_newsltr_only_cnt,
			adb_dstr_only_cnt, cnvo_opt_out_cnt, cnvo_first_opt_out_dt, cnvo_last_opt_out_dt,
			cnvo_hard_bounce_cnt, cnvo_soft_bounce_cnt, cnvo_reactvtn_start_dt,
			cnvo_reactvtn_end_dt, global_domain_opt_out_ind, global_opt_out_ind,
			global_cnst_opt_out_ind, intl_addr_ind, cdi_email_opt_out_cnt,
			ta_in_email_opt_out_cnt, ta_org_email_opt_out_cnt, untd_way_blkout_ind,
			aprm_global_opt_out_ind, adb_unsbscrb_ind, adb_unsbscrb_click_cnt,
			adb_first_unsbscrb_dt, adb_last_unsbscrb_dt, adb_total_bounce_cnt,
			adb_hard_bounce_cnt, adb_soft_bounce_cnt, adb_fbl_cnt, adb_first_bounce_dt,
			adb_last_bounce_dt, first_em_sent_dt, last_em_sent_dt, first_em_open_dt,
			last_em_open_dt, first_em_link_click_dt, last_em_link_click_dt,
			yes_reopt_in_cnt, no_reopt_in_cnt, first_yes_link_click_dt, last_yes_link_click_dt,
			first_no_link_click_dt, last_no_link_click_dt, first_spam_rejct_dt,
			last_spam_rejct_dt, spam_rejct_cnt,valdtn_status, valdtn_dt, bad_domain_ind,
			apc_fr_email_opt_out, apc_fr_email_opt_in_newsltr, apc_fr_email_opt_in_dstr, apc_fr_email_opt_in_loclnws, apc_fr_last_upd_ts,
			iblacklistemail_fr
		from mktg_stage_tbls.gms_bzfc_cnst_fr_prfr_em_prfl_img;
		
		truncate table mktg_stage_tbls.gms_bzfc_cnst_fr_prfr_em_prfl_img;
		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records updated.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.gms_bzfc_cnst_fr_prfr_em_prfl) as integer)
			WHERE proc_name = 'ld_gms_bzfc_cnst_fr_prfr_em_prfl' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
	    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('ld_gms_bzfc_cnst_fr_prfr_em_prfl', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_gms_bzfc_cnst_fr_prfr_em_prfl' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
