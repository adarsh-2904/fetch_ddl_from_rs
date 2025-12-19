CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_bzfc_cdi_fr_prfr_email_profile()
 LANGUAGE plpgsql
AS $$
/*
Created by: Majeed Mohammad
Created on:  04/28/2021
Purpose: This macro instantiates the view mktg_ops_vws.gms_bzfc_cdi_fr_prfr_email_profile 

Modified By: Michael Andrien
Modified Date: 11/01/2022
Purpose: Added the Adobe Spam Reject attributes and changed the insert into statement from a 'select * from..' to a fully qualified select listing each column in the table/view.

Modified By: Michael Andrien
Modified Date: 11/08/2022
Purpose:  Added section for Validity Email Validation Return file checks and modified ok_to_email_flg logic to include Validity Valid email verification.

Modified By: Michael Andrien
Modified Date: 11/22/2022
Purpose: Added the bad domain check.  The suspect domain table will be manually maintained and monitored periodically for spam traps.
The long term plan is to add the bad domains to the Stuart domain validation process to set the email assessment codes to a not usable status.

Modified By: Michael Andrien
Modified Date: 12/12/2023
Purpose: Added the recipient table join to include the iblacklistemail_fr attribute, which is reference in the gms_bzfc_cdi_fr_prfr_email_profile view 
when setting the ok_to_email_flg Y/N value.

Modified By: Michael Andrien
Modified Date: 01/17/2024
Purpose - Added the ack_email_ok_flg attribute to the profile table.

Modified By: Majeed Mohammad
Modified Date: 01/22/2024
Purpose : Updated the view to use the new src view mktg_ops_vws.gms_bzfc_cdi_fr_prfr_email_profile_src
*/ 
/* Below comment is for the view mktg_ops_vws.gms_bzfc_cdi_fr_prfr_email_profile_src which was used to be a seperate file in teradata but in redshift it has been incorporated to the stored procedure*/
/* ---------------------------------------------------------------------------------------------------------------------------

Created by: Majeed Mohammad
Created date: 2014-Jul-23
Purpose: This view selects the distinct email addresses from the preferred summary profile and sets the email opt out flag,bounce counts/dates from convio & aprimo

2014 -Jul-31 - Modified by Michael Andrien - 
                                                                                                a)Removed the Convio Soft Bounce checks from the ok to email flag logic from 
                                                                                                (em_bncd.aprm_soft_bounce_cnt + cnvo_soft_bounce_cnt)>3  to (em_bncd.aprm_soft_bounce_cnt)>3
                                                                                                b) Renamed email_unsub_flg to ok_to_email_flg.
2014-12-19 - Modiified by Michael Andrien      
	Added logic for Global email and email Domain opt outs              
	
2015-02-26 - Modified by Michael Andrien
                     Purpose:  Added logic to suppress international emails by setting the ok to email flag to no when the EM CNST State code = XX.  
                     			    Added logic and indicators to include the CDI and TA email opt-out.                                                                                                             
 2015-05-06 - Modified by Michael Andrien
                     Purpose:  Updated column appeal no email ind column names in the CDI contact pref section to match column name changes in the view.                                                                                                             

 2015-07-22 - Modified by Michael Andrien
                     Purpose:  Commented the CDI and TA email opts from setting the ok to email flg to N.  This was causing issues with MAP lists.  Eric Livingston
									and Mike Andrien discussed this and decided to remove these from the flg logic.  I Kept the email opt out count columns to audit purposes.                                                                                                         
 
 2015-10-07 - Modified by Michael Andrien
 					Purpose: Added United Way Suppressions.  Currently, this included the 25R16 Region.  We set the ok_to_email_flg = N if the 
 									chatper affiliation for the donor is withing the 25R16 region.
 2016-12-26 - Modified by Michael Andrien
 					Purpose: 	Removed the United Way Suppression for region 25R16 as per request by Eric Livingston.
  
  2016-04-18   Modified by Mike Andrien 
  						Purpose: added union all statements to the pick up the the unsubscribe data from the 2 additional Aprimo Unsubsribe tables
  
  2016-06-15   Modified by Mike Andrien 
  						Purpose: Modified the Aprimo unsubscribe logic section to limit the unsubscribes from the Aprimo preference center lite table to the records where the contact_pref = 'all'.  
  										Also added an additional query to the Aprimo Pref Center Lite table to set the Newsletter Only and Disaster Communications Only suppression group indicators.  Records
  										with the contact pref = 'all' will trigger the ok_to_email_flg to be set to 'N'.  If the contact pref is equal to 'disaster' or 'newsletter', then the appropriate indicators are set.
  										Lastly, added the aprm_dstr_only_cnt, aprm_first_dstr_only_dt, aprm_last_dstr_only_dt and aprm_newsltr_only_cnt, aprm_first_newsltr_only_dt, aprm_last_newsltr_only_dt columns to the view.
 
    2016-12-23  Modified by Mike Andrien 
  						Purpose:  1. Altered the soft bounce check in the 'ok_to_email_flg' logic to reference the aprm_total_soft_bounce_cnt rather theaprm_soft_bounce_cnt attribute.  The aprm_total_soft_bounce_cnt
  										attribute includes technical, blocked and unknown bounce types.  
  										2.  Changed the hard bounce logic from case when (em_bncd.aprm_hard_bounce_cnt + cnvo_hard_bounce_cnt) > 0
  										to case when em_bncd.aprm_hard_bounce_cnt > 0 or  cnvo_hard_bounce_cnt > 0
  										3. Added the 501 tables to the bounce and fbl sections.

   04/21/2017 Modified by Mike Andrien 
  						Purpose:  Added Adobe unsubscribes to the profile and to the ok_to_email_flg logic.				
  	
  	05/06/2017 Modified by: Mike Andrien
  						Purpose:  Added Adobe bounce and Convio Reactivation details.  Also commented out the TA/CDI opt-outs
  						
Modified by: Majeed Mohammad
Modified on: 09/19/2017
Purpose:  Changed the view to use the table mktg_ops_tbls.cnst_cdi_smry_fr_prfr instead of the view mktg_ops_vws.cnst_cdi_smry_fr_prfr

Modified by: Mike Andrien 
Modified on: 10/10/2017
Purpose:  Added Email Stats: First and last email sent, opened and link clicked.

Modified by: Mike Andrien 
Modified on: 12/04/2017
Purpose:  Change Aprimo unsub and bounce query sections - changed UNIONs to UNION ALLs and added and outer query to both query sections to ensure the queries
				return one row per email address.  I discovered the view was returning 2 row for email addresses that had bounce and unsub rows in each parts of the unions.  Also changed the following:
				1.  Changed the Adobe sent, open, link click, section to a UNION ALL.
				2. changed the global opt out query to a select distinct to eliminate duplicates
 
 Modified by: Mike Andrien 
Modified on: 08/05/2019
Purpose: Fixed an issue with the Adobe Bounce metadata count attributes.  The count attributes in the final select were pointing to the Arpimo Bounce attributes.  NOTE: The summary attributes referenced
to set the 'ok_to_email_flg' were referencing the correct Adobe bounce attritubes so this did not impact the ok_to_email_flg value.
  
 Modified By: Michael Andrien
Modified Date: 02/29/2020
Purpose: Created GMS version of the view to reference the new GMS FR profiles tables and views

 Modified By: Michael Andrien
Modified Date: 10/29/2020
Purpose: Modified the  Global Email Domain Opt-Out join to limit the domain selection to domains that have not be end dated.

 Modified By: Michael Andrien
Modified Date: 12/23/2020
Purpose: Added Adobe Disaster Only and Newsletter Only Email opt-down query segment to capture the firts and last opt-down dates as well as the disaster only and newletter only indicators from the Adobe subscription table

 Modified By: Michael Andrien
Modified Date: 03/19/2021
Purpose:  Added the 'reopt' LEFT JOIN and the new attributes listed below to capture the Adobe re-opt in link click details.  Also, updated the logic for setting the 'Ok to Email Flag'' to evaluate the compare the Convio, Aprimo and Adobe unsub and opt out
dates to the re-opt in last clicked 'Yes' date to ensure the opt out data is greater than the re-opt in date.
		-- Email Re-opt in attributes
		reopt.yes_reopt_in_cnt, 
		reopt.no_reopt_in_cnt, 
		cast(reopt.first_yes_link_click_dt as date format 'mm/dd/yyyy') as first_yes_link_click_dt, 
		cast(reopt.last_yes_link_click_dt as date format 'mm/dd/yyyy') as last_yes_link_click_dt, 
		cast(reopt.first_no_link_click_dt as date format 'mm/dd/yyyy') first_no_link_click_dt, 
		cast(reopt.last_no_link_click_dt as date format 'mm/dd/yyyy') last_no_link_click_dt

 Modified By: Michael Andrien
Modified Date: 03/19/2021
Purpose:  Modified the email opt-in query to properly include all valide deliveries (where email_intrctn_typ_id = 1 and d.slabel like '%Resubscribe%Opt In%' and d.istate = 95 and d.istatus = 5 and substr(d.sinternalname, 1, 3) <> 'FCP').  The 
delivery will change with each opt-in email send so we needed to add wildcard logic on the delivery label.

 Modified By: Michael Andrien
Modified Date: 04/09/2021
Purpose:  Changed the driving table from which the email addresses for the email profile are pulled.  The view originally selected the distinct em_cnst_email_addr from the FR preferred view (gms_cnst_cdi_smry_fr_prfr), but
this limited the email addresses for which we have the summarize email interaction details to the current email addresses reference in the FR preferred view. The view now pulls the emails from the CDI email view (arc_mdm_vws.bzfc_cnst_email) to ensure we 
have an email profile for all emaii addresses that have been referenced in our system.  We reference this view in the ld_gms_cnst_cdi_smry_fr_prfr macro to help evaluate whether to override the ranked email with the most recent email append address.
 
 Modified By: Michael Andrien
Modified Date: 12/08/2021
Purpose:  Added convio opt in date to the convio_tbls.cnvo_cnst table and added the max(cnvo_email_opt_in_dt) attribute to the Convio opt our/bounce section below.  Also, inserted
a Convio Reactivation record for Ashley McKittrick 'ashley.mckittrick@redcross.org'' email address and cnvo_cnst_id = 14023635.  Lastly, modified the Convio opt our portion
of the Ok to Email Flag logic to ensure both the cnvo_opt_out_cnt > 0 and the newly added cnvo_opt_in_dt attribute is null.
or (cnvo_opt_out_cnt > 0 and cnvo_email_opt_in_dt is null))

Modified By: Michael Andrien
Modified Date: 02/11/2022
Purpose:  Added the case statement to the lines below in the email open section in response to changes in the way iOS email opens are record.  We've added code to the
fact email interaction summary macro to set the email open indicator to 0 when an email recipient has 10 consecutive open email events without a single email link click event.  We di this because changes
to the iOS open policy were inflating email engagement statistics.
	min(case when email_open_ind = 1 then first_email_open_dt end) as first_em_open_dt,
	max(case when email_open_ind = 1 then last_email_open_dt end) as last_em_open_dt,

Modified By: Michael Andrien
Modified Date: 02/18/2022
Purpose:  Modified the prfr join below - added the UNION to include the distinct email address from our email append view.  The email profile was missing
rows for these email addresses because they are not loaded into the CDI email table (rc_mdm_vws.bzfc_cnst_email)
(
	select distinct trim(cnst_email_addr )
	from arc_mdm_vws.bzfc_cnst_email
	union
	select distinct trim(cnst_email)
	from mktg_ops_vws.bzfc_email_append
) prfr (email_addr)

Modified By: Michael Andrien
Modified Date: 11/01/2022
Purpose:  Added Adobe Spam Reject Section and modified ok_to_email_flg logic to include spam reject verification.

Modified By: Michael Andrien
Modified Date: 11/08/2022
Purpose:  Added section for Validity Email Validation Return file checks and modified ok_to_email_flg logic to include Validity Valid email verification.

Modified By: Michael Andrien
Modified Date: 11/22/2022
Purpose: Added the bad domain check.  The suspect domain table will be manually maintained and monitored periodically for spam traps.
The long term plan is to add the bad domains to the Stuart domain validation process to set the email assessment codes to a not usable status.

Modified By: Michael Andrien
Modified Date: 11/15/2023
Purpose: Modified the qualify clause on the validity_status join to include the valdtn_status in the order_by clause.  This prioritizes invalid status values over valid status in 
cases where we have duplicate rows in the table.
	qualify row_number() over (partition by email_addr  order by valdtn_dt desc, valdtn_status) = 1

Modified By: Michael Andrien
Modified Date: 12/12/2023
Purpose: Added logic to include Adobe Campaign blacklisted FR reciptients and included this in the ok_to_email_flg logic.

Modified By: Michael Andrien
Modified Date: 12/13/2023
Purpose: Commented our the blacklist attribute from the ok_to_email_flg logic until team can complete updates to the recipient table to update the blacklist value
-- or zeroifnull(bl.iblacklistemail_fr) = 1

Modified By: Michael Andrien
Modified Date: 01/17/2024
Purpose - Added the ack_email_ok_flg attribute and case statement to set the flag to 'Y' or 'N'.
*/
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_bzfc_cdi_fr_prfr_email_profile', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		-- Truncate staging table
        TRUNCATE TABLE mktg_stage_tbls.gms_bzfc_cdi_fr_prfr_email_profile_stg;

		INSERT INTO mktg_stage_tbls.gms_bzfc_cdi_fr_prfr_email_profile_stg (
			email_addr, ok_to_email_flg, 
			ack_email_ok_flg,
			cnvo_reactvtn_flg, total_bounce_cnt,
			aprm_total_bounce_cnt, aprm_hard_bounce_cnt, aprm_soft_bounce_cnt,
			aprm_block_bounce_cnt, aprm_technical_bounce_cnt, aprm_unknown_bounce_cnt,
			aprm_total_soft_bounce_cnt, aprm_fbl_cnt, aprm_unsbscrb_cnt,
			aprm_first_unsbscrb_dt, aprm_last_unsbscrb_dt, aprm_dstr_only_cnt,
			aprm_dstr_only_ind, aprm_first_dstr_only_dt, aprm_last_dstr_only_dt,
			aprm_newsltr_only_cnt, aprm_newsltr_only_ind, aprm_first_newsltr_only_dt,
			aprm_last_newsltr_only_dt, adb_first_newsltr_only_dt, adb_last_newsltr_only_dt,
			adb_first_dstr_only_dt, adb_last_dstr_only_dt, adb_newsltr_only_ind,
			adb_dstr_only_ind, adb_newsltr_only_cnt, adb_dstr_only_cnt, cnvo_opt_out_cnt,
			cnvo_first_opt_out_dt, cnvo_last_opt_out_dt, cnvo_hard_bounce_cnt,
			cnvo_soft_bounce_cnt, cnvo_reactvtn_start_dt, cnvo_reactvtn_end_dt,
			global_domain_opt_out_ind, global_opt_out_ind, intl_addr_ind,
			untd_way_blkout_ind, adb_unsbscrb_ind, adb_unsbscrb_click_cnt,
			adb_first_unsbscrb_dt, adb_last_unsbscrb_dt, adb_total_bounce_cnt,
			adb_hard_bounce_cnt, adb_soft_bounce_cnt, adb_fbl_cnt, adb_first_bounce_dt,
			adb_last_bounce_dt, first_em_sent_dt, last_em_sent_dt, first_em_open_dt,
			last_em_open_dt, first_em_link_click_dt, last_em_link_click_dt,
			yes_reopt_in_cnt, no_reopt_in_cnt, first_yes_link_click_dt, last_yes_link_click_dt,
			first_no_link_click_dt, last_no_link_click_dt, first_spam_rejct_dt,
			last_spam_rejct_dt, spam_rejct_cnt,
			valdtn_status, valdtn_dt, bad_domain_ind, iblacklistemail_fr
		)
		WITH react AS (
			SELECT 
				email AS email_addr,
				reactvtn_start_dt AS cnvo_reactvtn_start_dt,
				reactvtn_end_dt AS cnvo_reactvtn_end_dt,
				ROW_NUMBER() OVER (PARTITION BY email ORDER BY dw_trans_ts DESC) AS rn
			FROM mktg_ops_tbls.cnvo_reactivation_list
		),
		validity_status AS (
			SELECT 
				email_addr,
				valdtn_status,
				valdtn_dt,
				ROW_NUMBER() OVER (PARTITION BY email_addr ORDER BY valdtn_dt DESC, valdtn_status) AS rn
			FROM mktg_ops_tbls.vaidity_email_valdtn
		),
		ranked_data AS (
		SELECT
			prfr.email_addr,
			CASE WHEN em_bncd.aprm_hard_bounce_cnt > 0 
				OR cnvo_hard_bounce_cnt > 0 
				OR adbbnc.adb_hard_bounce_cnt > 0
				OR (em_bncd.aprm_total_soft_bounce_cnt) > 3 
				OR adbbnc.adb_soft_bounce_cnt > 3
				OR fbl_cnt > 0
				OR adb_fbl_cnt > 0
				OR dmn.domain_dsc IS NOT NULL 
				OR gbl_opt_out.global_opt_out_ind > 0
				OR intl.intl_addr_ind = 1
				OR ((adb_unsub.unsbscrb_ind = 1 
					 OR unsub.aprm_unsbscrb_cnt > 0 
					 OR (cnvo_opt_out_cnt > 0 AND cnvo_email_opt_in_dt IS NULL))  
					AND (last_yes_link_click_dt IS NULL 
						 OR NULLIF(
							 GREATEST(
								 COALESCE(last_unsbscrb_dt, DATE '0001-01-01'),
								 COALESCE(aprm_last_unsbscrb_dt, DATE '0001-01-01'),
								 COALESCE(cnvo_last_opt_out_dt, DATE '0001-01-01')
							 ), 
							 DATE '0001-01-01'
						 ) > last_yes_link_click_dt))
				OR uw.untd_way_blkout_ind = 1
				OR spam_rejct_cnt > 0
				OR COALESCE(validity_status.valdtn_status, 'Valid: Valid') <> 'Valid: Valid' 
				OR COALESCE(baddmn.bad_domain_ind, 0) = 1
				THEN 'N' 
				ELSE 'Y' 
			END AS ok_to_email_flg,
				
			CASE WHEN em_bncd.aprm_hard_bounce_cnt > 0 
				OR cnvo_hard_bounce_cnt > 0 
				OR adbbnc.adb_hard_bounce_cnt > 0
				OR em_bncd.aprm_total_soft_bounce_cnt > 3
				OR adbbnc.adb_soft_bounce_cnt > 3
				OR fbl_cnt > 0  
				OR adb_fbl_cnt > 0
				OR dmn.domain_dsc IS NOT NULL 
				OR intl.intl_addr_ind = 1
				OR spam_rejct_cnt > 0
				OR COALESCE(validity_status.valdtn_status, 'Valid: Valid') <> 'Valid: Valid' 
				OR COALESCE(baddmn.bad_domain_ind, 0) = 1
				THEN 'N' ELSE 'Y' END AS ack_email_ok_flg,
				
			CASE WHEN (cnvo_reactvtn_start_dt IS NULL AND cnvo_reactvtn_end_dt IS NULL) 
				OR cnvo_reactvtn_end_dt < CURRENT_DATE 
				THEN 'N' ELSE 'Y' END AS cnvo_reactvtn_flg, --this one
				
			COALESCE(aprm_total_bounce_cnt + cnvo_hard_bounce_cnt + cnvo_soft_bounce_cnt + adb_total_bounce_cnt, 0) AS total_bounce_cnt, 
			COALESCE(em_bncd.aprm_total_bounce_cnt, 0) AS aprm_total_bounce_cnt, 
			COALESCE(em_bncd.aprm_hard_bounce_cnt, 0) AS aprm_hard_bounce_cnt, 
			COALESCE(em_bncd.aprm_soft_bounce_cnt, 0) AS aprm_soft_bounce_cnt, 
			COALESCE(em_bncd.aprm_block_bounce_cnt, 0) AS aprm_block_bounce_cnt, 
			COALESCE(em_bncd.aprm_technical_bounce_cnt, 0) AS aprm_technical_bounce_cnt, 
			COALESCE(em_bncd.aprm_unknown_bounce_cnt, 0) AS aprm_unknown_bounce_cnt, 
			COALESCE(em_bncd.aprm_total_soft_bounce_cnt, 0) AS aprm_total_soft_bounce_cnt, 
			COALESCE(em_fbl.fbl_cnt, 0) AS aprm_fbl_cnt, 
			COALESCE(unsub.aprm_unsbscrb_cnt, 0) AS aprm_unsbscrb_cnt, 
			unsub.aprm_first_unsbscrb_dt, 
			unsub.aprm_last_unsbscrb_dt, 
			COALESCE(dstr_only_ind.aprm_dstr_only_cnt, 0) AS aprm_dstr_only_cnt, 
			CASE WHEN COALESCE(dstr_only_ind.aprm_dstr_only_cnt, 0) > 0 THEN 1 ELSE 0 END AS aprm_dstr_only_ind,
			dstr_only_ind.aprm_first_dstr_only_dt, 
			dstr_only_ind.aprm_last_dstr_only_dt, 
			COALESCE(newsltr_only_ind.aprm_newsltr_only_cnt, 0) AS aprm_newsltr_only_cnt, 
			CASE WHEN COALESCE(newsltr_only_ind.aprm_newsltr_only_cnt, 0) > 0 THEN 1 ELSE 0 END AS aprm_newsltr_only_ind,
			newsltr_only_ind.aprm_first_newsltr_only_dt, 
			newsltr_only_ind.aprm_last_newsltr_only_dt, 
			adb_first_newsltr_only_dt, 
			adb_last_newsltr_only_dt, 
			adb_first_dstr_only_dt, 
			adb_last_dstr_only_dt,
			COALESCE(CASE WHEN adb_opt_dwn.adb_newsltr_only_cnt > 0 THEN 1 ELSE 0 END, 0) AS adb_newsltr_only_ind,
			COALESCE(CASE WHEN adb_opt_dwn.adb_dstr_only_cnt > 0 THEN 1 ELSE 0 END, 0) AS adb_dstr_only_ind,
			adb_opt_dwn.adb_newsltr_only_cnt, 
			adb_opt_dwn.adb_dstr_only_cnt,
			COALESCE(cnvo_opt_out_cnt, 0) AS cnvo_opt_out_cnt,
			cnvo_first_opt_out_dt,  
			cnvo_last_opt_out_dt,  
			COALESCE(cnvo_hard_bounce_cnt, 0) AS cnvo_hard_bounce_cnt, 
			COALESCE(cnvo_soft_bounce_cnt, 0) AS cnvo_soft_bounce_cnt,
			cnvo_reactvtn_start_dt,  --this one
			cnvo_reactvtn_end_dt, --this one
			CASE WHEN dmn.domain_dsc IS NULL THEN 0 ELSE 1 END AS global_domain_opt_out_ind,
			COALESCE(gbl_opt_out.global_opt_out_ind, 0) AS global_opt_out_ind,
			COALESCE(intl.intl_addr_ind, 0) AS intl_addr_ind,
			COALESCE(uw.untd_way_blkout_ind, 0) AS untd_way_blkout_ind,
			COALESCE(adb_unsub.unsbscrb_ind, 0) AS adb_unsbscrb_ind,
			COALESCE(adb_unsub.unsbscrb_click_cnt, 0) AS adb_unsbscrb_click_cnt,
			first_unsbscrb_dt AS adb_first_unsbscrb_dt,
			last_unsbscrb_dt AS adb_last_unsbscrb_dt,
			COALESCE(adbbnc.adb_total_bounce_cnt, 0) AS adb_total_bounce_cnt, 
			COALESCE(adbbnc.adb_hard_bounce_cnt, 0) AS adb_hard_bounce_cnt, 
			COALESCE(adbbnc.adb_soft_bounce_cnt, 0) AS adb_soft_bounce_cnt, 
			COALESCE(adbbnc.adb_fbl_cnt, 0) AS adb_fbl_cnt, 
			adb_first_bounce_dt, 
			adb_last_bounce_dt,
			em_stats.first_em_sent_dt, 
			em_stats.last_em_sent_dt, 
			em_stats.first_em_open_dt, 
			em_stats.last_em_open_dt, 
			em_stats.first_em_link_click_dt, 
			em_stats.last_em_link_click_dt,
			reopt.yes_reopt_in_cnt, 
			reopt.no_reopt_in_cnt, 
			reopt.first_yes_link_click_dt, 
			reopt.last_yes_link_click_dt, 
			reopt.first_no_link_click_dt, 
			reopt.last_no_link_click_dt,
			adb_spam_rejct.first_spam_rejct_dt, 
			adb_spam_rejct.last_spam_rejct_dt, 
			COALESCE(adb_spam_rejct.spam_rejct_cnt, 0) AS spam_rejct_cnt,
			validity_status.valdtn_status, 
			validity_status.valdtn_dt,
			COALESCE(baddmn.bad_domain_ind, 0) AS bad_domain_ind, 
			COALESCE(bl.iblacklistemail_fr, 0) AS iblacklistemail_fr

		FROM 
		(
			SELECT DISTINCT TRIM(cnst_email_addr) AS email_addr
			FROM eda.arc_mdm_vws.bzfc_cnst_email
			UNION
			SELECT DISTINCT TRIM(cnst_email) AS email_addr
			FROM mktg_ops_vws.bzfc_email_append
		) prfr

		LEFT JOIN 
		(
			SELECT
				email_addr, 
				SUM(aprm_total_bounce_cnt) AS aprm_total_bounce_cnt, 
				SUM(aprm_hard_bounce_cnt) AS aprm_hard_bounce_cnt,
				SUM(aprm_soft_bounce_cnt) AS aprm_soft_bounce_cnt,
				SUM(aprm_block_bounce_cnt) AS aprm_block_bounce_cnt,
				SUM(aprm_technical_bounce_cnt) AS aprm_technical_bounce_cnt,
				SUM(aprm_unknown_bounce_cnt) AS aprm_unknown_bounce_cnt,
				SUM(aprm_total_soft_bounce_cnt) AS aprm_total_soft_bounce_cnt
			FROM
			(
				SELECT
					b.to_email AS email_addr, 
					COUNT(a.email_id) AS aprm_total_bounce_cnt, 
					SUM(CASE WHEN a.bncd_ctgy_id = 1 THEN 1 ELSE 0 END) AS aprm_hard_bounce_cnt,
					SUM(CASE WHEN a.bncd_ctgy_id = 2 THEN 1 ELSE 0 END) AS aprm_soft_bounce_cnt,
					SUM(CASE WHEN a.bncd_ctgy_id = 3 THEN 1 ELSE 0 END) AS aprm_block_bounce_cnt,
					SUM(CASE WHEN a.bncd_ctgy_id = 4 THEN 1 ELSE 0 END) AS aprm_technical_bounce_cnt,
					SUM(CASE WHEN a.bncd_ctgy_id = 5 THEN 1 ELSE 0 END) AS aprm_unknown_bounce_cnt,
					SUM(CASE WHEN a.bncd_ctgy_id BETWEEN 2 AND 5 THEN 1 ELSE 0 END) AS aprm_total_soft_bounce_cnt
				FROM mktg_ops_vws.bz_aprm_email_bncd a
				LEFT JOIN mktg_ops_vws.bz_aprm_email_sent b 
					ON a.cnst_mstr_id = b.cnst_mstr_id 
					AND a.EMAIL_ID = b.EMAIL_ID        
				GROUP BY 1
			) emb
			GROUP BY 1
		) em_bncd ON prfr.email_addr = em_bncd.email_addr

		LEFT JOIN
		(
			SELECT 
				email_addr,
				SUM(fbl_cnt) AS fbl_cnt
			FROM 
			(
				SELECT 
					b.to_email AS email_addr,
					COUNT(a.email_id) AS fbl_cnt
				FROM mktg_ops_vws.bz_aprm_email_remove a
				LEFT JOIN mktg_ops_vws.bz_aprm_email_sent b 
					ON a.cnst_mstr_id = b.cnst_mstr_id 
					AND a.EMAIL_ID = b.EMAIL_ID  
				WHERE a.abstract = 'feedback loop opt-out'
				GROUP BY 1
			) emfbl
			GROUP BY 1
		) em_fbl ON prfr.email_addr = em_fbl.email_addr

		LEFT JOIN 
		(
			SELECT 
				email_addr,
				SUM(aprm_unsbscrb_cnt) AS aprm_unsbscrb_cnt,
				MIN(aprm_first_unsbscrb_dt) AS aprm_first_unsbscrb_dt,
				MAX(aprm_last_unsbscrb_dt) AS aprm_last_unsbscrb_dt
			FROM
			(
				SELECT
					email_addr,
					COUNT(DISTINCT audience_mbr_id || hist_rec_id) AS aprm_unsbscrb_cnt, 
					MIN(hist_rec_ts) AS aprm_first_unsbscrb_dt,
					MAX(hist_rec_ts) AS aprm_last_unsbscrb_dt
				FROM mktg_ops_vws.bz_aprm_wb_apnd_prfrnc_cntr
				GROUP BY 1
			 
				UNION ALL
			  
				SELECT   
					email_addr,
					COUNT(DISTINCT audience_member_id || hist_rec_id) AS aprm_unsbscrb_cnt,
					MIN(hist_rec_ts::DATE) AS aprm_first_unsbscrb_dt,
					MAX(hist_rec_ts::DATE) AS aprm_last_unsbscrb_dt
				FROM mktg_ops_vws.bz_aprm_wb_apnd_unsubs_rplc
				GROUP BY 1
				
				UNION ALL 
				
				SELECT   
					email_addr,
					COUNT(DISTINCT audience_member_id || hist_rec_id) AS aprm_unsbscrb_cnt,
					MIN(hist_rec_ts::DATE) AS aprm_first_unsbscrb_dt,
					MAX(hist_rec_ts::DATE) AS aprm_last_unsbscrb_dt
				FROM mktg_ops_vws.bz_aprm_wb_rplc_fr_prf_cntr_lt
				WHERE contact_pref = 'all'
				GROUP BY 1
			) unsub_stg
			GROUP BY 1
		) unsub ON COLLATE(prfr.email_addr::text, 'CASE_INSENSITIVE') = COLLATE(unsub.email_addr::text, 'CASE_INSENSITIVE')

		LEFT JOIN 
		(
			SELECT 
				cnvo_prim_email AS email_acct,
				COUNT(cnvo_cnst_id) AS cnvo_opt_out_cnt,
				MIN(cnvo_email_opt_out_ts) AS cnvo_first_opt_out_dt,
				MAX(cnvo_email_opt_out_ts) AS cnvo_last_opt_out_dt,
				SUM(cnvo_hard_bounce_cnt) AS cnvo_hard_bounce_cnt,
				SUM(cnvo_soft_bounce_cnt) AS cnvo_soft_bounce_cnt,
				MAX(cnvo_email_opt_in_dt) AS cnvo_email_opt_in_dt
			FROM mktg_ops_vws.cnvo_cnst
			WHERE cnvo_accepts_email_ind = 0 OR cnvo_email_stat_cd = 3
			GROUP BY 1
		) cnvo ON COLLATE(prfr.email_addr::text, 'CASE_INSENSITIVE') = COLLATE(cnvo.email_acct::text, 'CASE_INSENSITIVE')

		LEFT JOIN 
		(
			SELECT domain_dsc
			FROM mktg_ops_tbls.global_suprs_domain
			WHERE suprs_end_dt > CURRENT_DATE
		) dmn ON SPLIT_PART(prfr.email_addr, '@', 2) = dmn.domain_dsc

		LEFT JOIN 
		(
			SELECT DISTINCT email_addr, 1 AS global_opt_out_ind
			FROM mktg_ops_tbls.global_suprs_email
		) gbl_opt_out ON COLLATE(prfr.email_addr::text, 'CASE_INSENSITIVE') = COLLATE(gbl_opt_out.email_addr::text, 'CASE_INSENSITIVE')

		LEFT JOIN       
		(
			SELECT DISTINCT em_cnst_email, 1 AS intl_addr_ind
			FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr
			WHERE (UPPER(dm_cnst_st_cd) = 'XX' OR UPPER(em_cnst_st_cd) = 'XX') 
				AND (dm_cnst_zip_5_cd = '00000' OR TRIM(dm_cnst_zip_5_cd) = '' OR dm_cnst_zip_5_cd IS NULL
				OR em_cnst_zip_5_cd = '00000' OR TRIM(em_cnst_zip_5_cd) = '' OR em_cnst_zip_5_cd IS NULL)
		) intl ON COLLATE(prfr.email_addr::text, 'CASE_INSENSITIVE') = COLLATE(intl.em_cnst_email::text, 'CASE_INSENSITIVE')

		LEFT JOIN  
		(
			SELECT DISTINCT em_cnst_email, 1 AS untd_way_blkout_ind
			FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr a
			LEFT JOIN mktg_ops_vws.dim_unit b ON a.unit_key = b.unit_key
			WHERE b.cs_region_cd = '99R99' AND em_cnst_email IS NOT NULL
		) uw ON COLLATE(prfr.email_addr::text, 'CASE_INSENSITIVE') = COLLATE(uw.em_cnst_email::text, 'CASE_INSENSITIVE')


		LEFT JOIN 
		(
			SELECT   
				email_addr,
				COUNT(DISTINCT audience_member_id || hist_rec_id) AS aprm_dstr_only_cnt,
				MIN(hist_rec_ts::DATE) AS aprm_first_dstr_only_dt,
				MAX(hist_rec_ts::DATE) AS aprm_last_dstr_only_dt
			FROM mktg_ops_vws.bz_aprm_wb_rplc_fr_prf_cntr_lt
			WHERE contact_pref = 'disaster'
			GROUP BY 1
		) dstr_only_ind ON COLLATE(prfr.email_addr::text, 'CASE_INSENSITIVE') = COLLATE(dstr_only_ind.email_addr::text, 'CASE_INSENSITIVE')

		LEFT JOIN 
		(
			SELECT   
				email_addr,
				COUNT(DISTINCT audience_member_id || hist_rec_id) AS aprm_newsltr_only_cnt,
				MIN(hist_rec_ts::DATE) AS aprm_first_newsltr_only_dt,
				MAX(hist_rec_ts::DATE) AS aprm_last_newsltr_only_dt
			FROM mktg_ops_vws.bz_aprm_wb_rplc_fr_prf_cntr_lt
			WHERE contact_pref = 'newsletter'
			GROUP BY 1
		) newsltr_only_ind ON COLLATE(prfr.email_addr::text, 'CASE_INSENSITIVE') = COLLATE(newsltr_only_ind.email_addr::text, 'CASE_INSENSITIVE')

		LEFT JOIN 
		(
			SELECT 
				b.sfr_em_email AS email_addr, 
				MIN(CASE WHEN c.sLabel = 'Newsletter' THEN a.tsCreated::DATE ELSE NULL END) AS adb_first_newsltr_only_dt,
				MAX(CASE WHEN c.sLabel = 'Newsletter' THEN a.tsCreated::DATE ELSE NULL END) AS adb_last_newsltr_only_dt,
				MIN(CASE WHEN c.sLabel = 'Disaster Notifications' THEN a.tsCreated::DATE ELSE NULL END) AS adb_first_dstr_only_dt,
				MAX(CASE WHEN c.sLabel = 'Disaster Notifications' THEN a.tsCreated::DATE ELSE NULL END) AS adb_last_dstr_only_dt,
				SUM(CASE WHEN c.sLabel = 'Newsletter' THEN 1 ELSE 0 END) AS adb_newsltr_only_cnt,
				SUM(CASE WHEN c.sLabel = 'Disaster Notifications' THEN 1 ELSE 0 END) AS adb_dstr_only_cnt
			FROM mktg_ops_vws.bz_adb_nmssubscription a
			LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient b ON a.irecipientid = b.irecipientid
			LEFT JOIN mktg_ops_vws.bz_adb_nmsservice c ON a.iServiceId = c.iServiceId
			GROUP BY 1
		) adb_opt_dwn ON adb_opt_dwn.email_addr = prfr.email_addr

		LEFT JOIN 
		(
			SELECT 
				email_addr,
				SUM(unsbscrb_click_cnt) AS unsbscrb_click_cnt,
				MAX(unsbscrb_ind) AS unsbscrb_ind,
				MIN(first_unsbscrb_dt) AS first_unsbscrb_dt, 
				MAX(last_unsbscrb_dt) AS last_unsbscrb_dt
			FROM 
			(
				SELECT 
					saddress AS email_addr,
					COUNT(*) AS unsbscrb_click_cnt, 
					MAX(r.iblacklist) AS unsbscrb_ind, 
					MIN(tslog) AS first_unsbscrb_dt, 
					MAX(tslog) AS last_unsbscrb_dt
				FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
				LEFT JOIN mktg_ops_tbls.adb_nmsrecipient r ON r.irecipientid = bl.irecipientid
				LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl 
					ON r.irecipientid = tl.irecipientid 
					AND bl.ibroadlogid = tl.ibroadlogid 
					AND bl.ideliveryid = tl.ideliveryid
				LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
				LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
				LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
				WHERE email_intrctn_typ_id = 3 
					AND d.istatus = 5 
					AND isuccess > 0 
				GROUP BY 1
				
				UNION ALL
							  
				SELECT 
					saddress AS email_addr,
					COUNT(*) AS unsbscrb_click_cnt, 
					MAX(a.iBlackListEmail_fr) AS unsbscrb_ind, 
					MIN(DATE_TRUNC('second', a.tsLastModified::TIMESTAMP)) AS first_unsbscrb_dt,
					MAX(DATE_TRUNC('second', a.tsLastModified::TIMESTAMP)) AS last_unsbscrb_dt 
				FROM mktg_ops_tbls.adb_arcprefchangefr a
				LEFT JOIN mktg_ops_tbls.adb_nmsbroadlogrcp bl 
					ON a.iRecipientId = bl.iRecipientId 
					AND a.iDeliveryId = bl.iDeliveryId
				LEFT JOIN mktg_ops_tbls.adb_nmsrecipient r ON r.irecipientid = bl.irecipientid
				LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = a.ideliveryid
				GROUP BY 1
			) a 
			GROUP BY 1
		) adb_unsub ON adb_unsub.email_addr = prfr.email_addr

		LEFT JOIN 
		(
			SELECT 
				saddress AS email_addr,  
				SUM(CASE WHEN a.iquarantinereason = 8 THEN 1 ELSE 0 END) AS adb_fbl_cnt,
				SUM(CASE WHEN a.iquarantinereason IN (0,1,2,3,4,20) THEN 1 ELSE 0 END) AS adb_hard_bounce_cnt,
				SUM(CASE WHEN a.iquarantinereason IN (5,6,25) THEN 1 ELSE 0 END) AS adb_soft_bounce_cnt,
				COUNT(*) AS adb_total_bounce_cnt,
				MIN(a.tscreated) AS adb_first_bounce_dt,
				MAX(a.tscreated) AS adb_last_bounce_dt
			FROM mktg_ops_tbls.adb_nmsaddress a
			GROUP BY 1
		) adbbnc ON COLLATE(prfr.email_addr::text, 'CASE_INSENSITIVE') = COLLATE(adbbnc.email_addr::text, 'CASE_INSENSITIVE')

		LEFT JOIN react ON react.email_addr = prfr.email_addr AND react.rn = 1

		LEFT JOIN 
		(
			SELECT
				email_addr,
				MIN(first_em_sent_dt) AS first_em_sent_dt, 
				MAX(last_em_sent_dt) AS last_em_sent_dt,
				MIN(first_em_open_dt) AS first_em_open_dt,
				MAX(last_em_open_dt) AS last_em_open_dt,
				MIN(first_em_link_click_dt) AS first_em_link_click_dt,
				MAX(last_em_link_click_dt) AS last_em_link_click_dt	
			FROM 
			(
				SELECT 
					email_addr,
					MIN(intrctn_dt) AS first_em_sent_dt, 
					MAX(intrctn_dt) AS last_em_sent_dt,
					MIN(CASE WHEN email_open_ind = 1 THEN first_email_open_dt END) AS first_em_open_dt,
					MAX(CASE WHEN email_open_ind = 1 THEN last_email_open_dt END) AS last_em_open_dt,
					MIN(first_link_click_dt) AS first_em_link_click_dt,
					MAX(last_link_click_dt) AS last_em_link_click_dt	
				FROM mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry
				WHERE email_sent_ind = 1
				GROUP BY 1
				
				UNION ALL 
				
				SELECT 
					to_email AS email_addr,
					MIN(sent_dt) AS first_em_sent_dt, 
					MAX(sent_dt) AS last_em_sent_dt,
					MIN(open_tracking_hist_rec_ts::DATE) AS first_em_open_dt,
					MAX(open_tracking_hist_rec_ts::DATE) AS last_em_open_dt,
					MIN(first_link_click_dt) AS first_em_link_click_dt,
					MAX(last_link_click_dt) AS last_em_link_click_dt	
				FROM mktg_ops_vws.bzfc_fact_interaction_em_smry
				WHERE delivered_ind = 1
				GROUP BY 1
			) a
			GROUP BY 1
		) em_stats ON em_stats.email_addr = prfr.email_addr

		LEFT JOIN 
		(
			SELECT 
				bl.saddress AS email_addr,
				SUM(CASE WHEN SUBSTRING(tu.slabel, 1, 3) = 'Yes' THEN 1 ELSE 0 END) AS yes_reopt_in_cnt,
				SUM(CASE WHEN SUBSTRING(tu.slabel, 1, 2) = 'No' THEN 1 ELSE 0 END) AS no_reopt_in_cnt,
				MIN(CASE WHEN SUBSTRING(tu.slabel, 1, 3) = 'Yes' THEN tl.tslog ELSE NULL END) AS first_yes_link_click_dt,
				MAX(CASE WHEN SUBSTRING(tu.slabel, 1, 3) = 'Yes' THEN tl.tslog ELSE NULL END) AS last_yes_link_click_dt,
				MIN(CASE WHEN SUBSTRING(tu.slabel, 1, 2) = 'No' THEN tl.tslog ELSE NULL END) AS first_no_link_click_dt,
				MAX(CASE WHEN SUBSTRING(tu.slabel, 1, 2) = 'No' THEN tl.tslog ELSE NULL END) AS last_no_link_click_dt	
			FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
			LEFT JOIN mktg_ops_tbls.adb_nmsrecipient r ON r.irecipientid = bl.irecipientid
			LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl 
				ON r.irecipientid = tl.irecipientid 
				AND bl.ibroadlogid = tl.ibroadlogid 
				AND bl.ideliveryid = tl.ideliveryid
			LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
			LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
			LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
			WHERE email_intrctn_typ_id = 1 
				AND d.slabel LIKE '%Resubscribe%Opt In%' 
				AND d.istate = 95 
				AND d.istatus = 5 
				AND SUBSTRING(d.sinternalname, 1, 3) <> 'FCP'
			GROUP BY 1
		) reopt ON prfr.email_addr = reopt.email_addr

		LEFT JOIN 
		(
			SELECT 
				TRIM(b.saddress) AS email_addr, 
				MIN(a.tsLastModified) AS first_spam_rejct_dt, 
				MAX(a.tsLastModified) AS last_spam_rejct_dt, 
				COUNT(*) AS spam_rejct_cnt
			FROM mktg_ops_tbls.adb_nmsbroadlogmsg a
			LEFT JOIN mktg_ops_tbls.adb_nmsbroadlogrcp b ON a.iBroadLogMsgId = b.ibroadlogid
			LEFT JOIN mktg_ops_tbls.adb_nmsrecipient c ON b.irecipientid = c.irecipientid
			WHERE a.iFailureType = 3 
				AND b.saddress IS NOT NULL
			GROUP BY 1
		) adb_spam_rejct ON prfr.email_addr = adb_spam_rejct.email_addr

		LEFT JOIN validity_status ON prfr.email_addr = validity_status.email_addr AND validity_status.rn = 1

		LEFT JOIN 
		(
			SELECT 
				DISTINCT cnst_email_addr AS email_addr,
				1 AS bad_domain_ind
			FROM eda.arc_mdm_vws.bzfc_cnst_email
			WHERE assessmnt_ctg IN ('Validated', 'Use With Caution')
				AND cnst_email_addr IS NOT NULL 
				AND SPLIT_PART(cnst_email_addr, '@', 2) IN (
					SELECT bad_domain
					FROM mktg_ops_tbls.suspect_domains
				)
		) baddmn ON prfr.email_addr = baddmn.email_addr

		LEFT JOIN 
		(
			SELECT 
				sfr_em_email AS email_addr,
				iblacklistemail_fr
			FROM mktg_ops_vws.bz_adb_nmsrecipient	
			WHERE iblacklistemail_fr = 1 
				AND sfr_em_email IS NOT NULL
		) bl ON prfr.email_addr = bl.email_addr
		)
		
		SELECT 
			email_addr, ok_to_email_flg, 
			ack_email_ok_flg,
			cnvo_reactvtn_flg, total_bounce_cnt,
			aprm_total_bounce_cnt, aprm_hard_bounce_cnt, aprm_soft_bounce_cnt,
			aprm_block_bounce_cnt, aprm_technical_bounce_cnt, aprm_unknown_bounce_cnt,
			aprm_total_soft_bounce_cnt, aprm_fbl_cnt, aprm_unsbscrb_cnt,
			aprm_first_unsbscrb_dt, aprm_last_unsbscrb_dt, aprm_dstr_only_cnt,
			aprm_dstr_only_ind, aprm_first_dstr_only_dt, aprm_last_dstr_only_dt,
			aprm_newsltr_only_cnt, aprm_newsltr_only_ind, aprm_first_newsltr_only_dt,
			aprm_last_newsltr_only_dt, adb_first_newsltr_only_dt, adb_last_newsltr_only_dt,
			adb_first_dstr_only_dt, adb_last_dstr_only_dt, adb_newsltr_only_ind,
			adb_dstr_only_ind, adb_newsltr_only_cnt, adb_dstr_only_cnt, cnvo_opt_out_cnt,
			cnvo_first_opt_out_dt, cnvo_last_opt_out_dt, cnvo_hard_bounce_cnt,
			cnvo_soft_bounce_cnt, cnvo_reactvtn_start_dt, cnvo_reactvtn_end_dt,
			global_domain_opt_out_ind, global_opt_out_ind, intl_addr_ind,
			untd_way_blkout_ind, adb_unsbscrb_ind, adb_unsbscrb_click_cnt,
			adb_first_unsbscrb_dt, adb_last_unsbscrb_dt, adb_total_bounce_cnt,
			adb_hard_bounce_cnt, adb_soft_bounce_cnt, adb_fbl_cnt, adb_first_bounce_dt,
			adb_last_bounce_dt, first_em_sent_dt, last_em_sent_dt, first_em_open_dt,
			last_em_open_dt, first_em_link_click_dt, last_em_link_click_dt,
			yes_reopt_in_cnt, no_reopt_in_cnt, first_yes_link_click_dt, last_yes_link_click_dt,
			first_no_link_click_dt, last_no_link_click_dt, first_spam_rejct_dt,
			last_spam_rejct_dt, spam_rejct_cnt,
			valdtn_status, valdtn_dt, bad_domain_ind, iblacklistemail_fr
		FROM ranked_data;
		
		-- Only proceed to target table if staging was successful
        TRUNCATE TABLE mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile;
        
        -- Insert data from staging to target
        INSERT INTO mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile
        SELECT * FROM mktg_stage_tbls.gms_bzfc_cdi_fr_prfr_email_profile_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log 
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile) as INTEGER)
        WHERE proc_name = 'ld_gms_bzfc_cdi_fr_prfr_email_profile' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_gms_bzfc_cdi_fr_prfr_email_profile: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_gms_bzfc_cdi_fr_prfr_email_profile', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
