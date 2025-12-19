CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_cnst_cdi_phss_em_prfl()
 LANGUAGE plpgsql
AS $$

/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 2015--05-27
Purpose: The purpose of this macro is to create an instantiated CDI PHSS Preferred email profile table.
				The macro reads the Staywell subscriber and unsubscribe tables loaded from files sent to us
				from Staywell.  The PHSS email profile will evolve over time to include Aprimo unsubscribe and feedback
				loop (FBL) complaints.  The table loaded by this macro feeds the Aprimo view referenced in the Aprimo
				ARC Enterprise universe and is used to apply email suppression logic.  The table is also the source for the Campaign 
				Effectiveness (CE) Webi universe view found in the mktg_ops_vws database and supports CE reportng.

Updated by: Michael Andrien
Update date: 01/16/2018
Purpose: 	Added sections and new attributes for Mail Chimp, SalesForce CRM (PHSF) and SalesForce Mktg Cloud.  Updated the  ok_to_email logic based on the rules below, provided by the PHSS data team. 
				

Updated by: Michael Andrien
Update date: 08/07/2018
Purpose: Change the hard bounce count settings from 3 to 1 for the ok_to_email_flg = 'N'
	
						SW	MC	PHSF	MCL	UNK	DISPOSITION
Do Not Email					x												IF do_not_email_c = 1 THEN 'N'  -- (phsf.phsf_do_not_email_ind = 1)
Opt-Out							x					x							IF has_opted_out_of_email = 1 OR unk_opt_out = 1 THEN 'N'
Unsub Counts	x		x					x									IF sw_unsubscrb_cnt >=1 OR mc_unsubscrb_cnt >=1 OR mcl_unsubscrb_cnt >=1 THEN 'N'
Hard Bounces	x		x		x		x										IF sw_bounce_cnt >=3 OR mc_bounce_cnt >=1 OR phsf_hard_bounce_cnt >= 3 OR mcl_block_bounce_cnt >=1 OR mcl_hard_bounce_cnt >=3 THEN 'N'
Soft Bounces								x									IF mcl_total_soft_bounce_cnt >=3 THEN 'N'
Status Change 							x									See notes below

Updated by: Michael Andrien
Update date: 11/09/2022
Purpose: Updated the SFMC bounce and unsubscribe table references.  The table and column names were change by the TS team that manages the data.  Also added the Adobe spam reject
and the Validity email validation joins and updated the ok_to_email_flg logic to account for these changes.

Modified By: Michael Andrien
Modified Date: 11/23/2022
Purpose: Added the bad domain check.  The suspect domain table will be manually maintained and monitored periodically for spam traps.
The long term plan is to add the bad domains to the Stuart domain validation process to set the email assessment codes to a not usable status.
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_cnst_cdi_phss_em_prfl', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN

	TRUNCATE TABLE mktg_ops_tbls.bzfc_cnst_cdi_phss_email_prfl;

insert into mktg_ops_tbls.bzfc_cnst_cdi_phss_email_prfl 
SELECT 
    prfr.cnst_mstr_id,
    prfr.email_addr, 
    CASE 
        WHEN (COALESCE(sw_subscrb.unsubscrb_status_cnt, 0) + COALESCE(sw_unsubscrb.unsubscrb_cnt, 0) > 0) OR -- Staywell checks
             (sw_subscrb.bounce_cnt >= 3 OR sw_subscrb.no_email_cnt > 0) OR -- Staywell checks
             phsf.phsf_do_not_email_ind = 1 OR -- dnc checks
             (unk_optout.unk_opt_out_ind = 1 OR phsf.phsf_opt_out_ind = 1) OR -- opt-out checks
             (mc_unsub.mc_unsubscrb_cnt >= 1 OR sfmc_unsub.sfmc_unsubscrb_cnt >= 1) OR -- unsubscribe checks
             (mc_bnc.mc_bounce_cnt >= 1 OR phsf.phsf_hard_bounce_cnt >= 1 OR sfmc_hrd_bnc.email_addr IS NOT NULL) OR -- Hard bounce checks
             spam_rejct_cnt > 0 OR
             COALESCE(validity_status.valdtn_status, 'Valid: Valid') <> 'Valid: Valid' OR
             COALESCE(baddmn.bad_domain_ind, 0) = 1
        THEN 'N' ELSE 'Y' 
    END AS ok_to_email_flg,

    (COALESCE(sw_subscrb.unsubscrb_status_cnt, 0) + COALESCE(sw_unsubscrb.unsubscrb_cnt, 0)) AS sw_unsubscrb_cnt,
    CASE 
        WHEN (COALESCE(sw_subscrb.unsubscrb_status_cnt, 0) + COALESCE(sw_unsubscrb.unsubscrb_cnt, 0)) > 0 THEN 'Y' ELSE 'N' 
    END AS sw_unsubscrb_flg,

    COALESCE(sw_subscrb.bounce_cnt, 0) AS sw_bounce_cnt,
    CASE WHEN sw_subscrb.bounce_cnt > 0 THEN 'Y' ELSE 'N' END AS sw_bounce_flg,

    COALESCE(mc_bnc.mc_bounce_cnt, 0) AS mc_bounce_cnt,
    COALESCE(mc_unsub.mc_unsubscrb_cnt, 0) AS mc_unsubscrb_cnt,
    COALESCE(phsf.phsf_do_not_email_ind, 0) AS phsf_do_not_email_ind,
    CASE WHEN COALESCE(phsf.phsf_do_not_email_ind, 0) = 1 THEN 1 ELSE 0 END AS phsf_opt_out_ind,
    COALESCE(phsf.phsf_hard_bounce_cnt, 0) AS phsf_hard_bounce_cnt,
    phsf.phsf_first_bounce_dt AS phsf_first_bounce_dt,
    phsf.phsf_last_bounce_dt AS phsf_last_bounce_dt,
    phsf.phsf_first_bounce_reason AS phsf_first_bounce_reason,
    phsf.phsf_last_bounce_reason AS phsf_last_bounce_reason,

    /* SFMC bounce fields - commented out as in original */
    /*
    COALESCE(sfmc_bnc.sfmc_total_bounce_cnt, 0) AS sfmc_total_bounce_cnt,
    COALESCE(sfmc_bnc.sfmc_block_bounce_cnt, 0) AS sfmc_block_bounce_cnt,
    COALESCE(sfmc_bnc.sfmc_hard_bounce_cnt, 0) AS sfmc_hard_bounce_cnt,
    COALESCE(sfmc_bnc.sfmc_soft_bounce_cnt, 0) AS sfmc_soft_bounce_cnt,
    COALESCE(sfmc_bnc.sfmc_technical_bounce_cnt, 0) AS sfmc_technical_bounce_cnt,
    COALESCE(sfmc_bnc.sfmc_unknown_bounce_cnt, 0) AS sfmc_unknown_bounce_cnt,
    COALESCE(sfmc_bnc.sfmc_total_soft_bounce_cnt, 0) AS sfmc_total_soft_bounce_cnt,
    sfmc_first_bnc.sfmc_first_bounce_reason,
    sfmc_last_bnc.sfmc_last_bounce_reason,
    sfmc_first_bnc.sfmc_first_bounce_dt,
    sfmc_last_bnc.sfmc_last_bounce_dt,
    */

    COALESCE(sfmc_hrd_bnc.sfmc_total_bounce_cnt, 0) AS sfmc_total_bounce_cnt,
    0 AS sfmc_block_bounce_cnt,
    COALESCE(sfmc_hrd_bnc.sfmc_hard_bounce_cnt, 0) AS sfmc_hard_bounce_cnt,
    0 AS sfmc_soft_bounce_cnt,
    0 AS sfmc_technical_bounce_cnt,
    0 AS sfmc_unknown_bounce_cnt,
    0 AS sfmc_total_soft_bounce_cnt,
    NULL AS sfmc_first_bounce_reason,
    NULL AS sfmc_last_bounce_reason,
    NULL AS sfmc_first_bounce_dt,
    NULL AS sfmc_last_bounce_dt,

    COALESCE(sfmc_unsub.sfmc_unsubscrb_cnt, 0) AS sfmc_unsubscrb_cnt,
    NULL AS sfmc_first_unsubscrb_dt,
    NULL AS sfmc_last_unsubscrb_dt,
    0 AS sfmc_unsubscrb_click_cnt,
    0 AS unk_opt_out_ind,

    first_spam_rejct_dt,
    last_spam_rejct_dt,
    spam_rejct_cnt,
    valdtn_status,
    valdtn_dt,
    baddmn.bad_domain_ind,
    CURRENT_DATE AS profile_last_update_dt

from 
(
	select 
		cnst_mstr_id,
		em_cnst_email
	from mktg_ops_vws.cnst_cdi_smry_phss_prfr a
	where a.em_cnst_email is not null--Hitansu:email is always null,vw is direct select no condn
) prfr (cnst_mstr_id, email_addr)
left join 
/* Get bounced, unsubscribe and active status details from the Staywell email subscriber table. */
(
SELECT 
    email_addr, 
    COALESCE(SUM(CASE WHEN email_stat = 'Unsubscrib' THEN 1 ELSE 0 END), 0) AS unsubscrb_status_cnt,
    COALESCE(SUM(CASE WHEN email_stat = 'Bounced' THEN 1 ELSE 0 END), 0) AS bounce_cnt,
    COALESCE(SUM(CASE 
        WHEN email_stat IN ('Held', 'Bounced', 'Unsubscrib') THEN 1 
        WHEN email_stat = 'Active' THEN 0 
        ELSE 0 END), 0) AS no_email_cnt
FROM mktg_ops_tbls.sw_email_subscrb
GROUP BY email_addr--Hitansu: works fine, tested

) sw_subscrb(email_addr, unsubscrb_status_cnt, bounce_cnt, no_email_cnt) on prfr.email_addr = sw_subscrb.email_addr

left join 

/*  Get the unsubscribe counts from the Staywell unsubscribe table */
(
SELECT 
email_addr,
COUNT(subscr_key) AS unsubscrb_cnt
FROM mktg_ops_tbls.sw_email_unsubscrb
GROUP BY email_addr
) sw_unsubscrb (email_addr, unsubscrb_cnt) on prfr.email_addr = sw_unsubscrb.email_addr

left join 

/* Now get the Mail Chimp email  unsub data */
(
	select 
		email_addr,
		count(*) as mc_unsubscrb_cnt
	from mktg_ops_tbls.utl_mc_unsubs
	group by 1
) mc_unsub ( email_addr, mc_unsubscrb_cnt) on prfr.email_addr = mc_unsub.email_addr

left join 

/* Now get the Mail Chimp email bounce data */
(
SELECT 
    email_addr,
    COUNT(*) AS mc_bounce_cnt
FROM mktg_ops_tbls.utl_mc_bounces
GROUP BY email_addr

) mc_bnc ( email_addr, mc_bounce_cnt) on prfr.email_addr = mc_bnc.email_addr

left join 

/* Now get the SalesForce CRM (PHSF) opt out and bounce data */

(SELECT
    contact.email_addr,
    contact.phsf_do_not_email_ind,
    contact.phsf_opt_out_ind,
    contact.phsf_first_bounce_dt, 
    contact.phsf_last_bounce_dt,
    COALESCE(contact.phsf_hard_bnc_cnt, 0) as phsf_hard_bnc_cnt,
    phsf_br_first.phsf_first_bounce_reason,
    phsf_br_last.phsf_last_bounce_reason
FROM 
    (
        SELECT
            email,
            MAX(COALESCE(do_not_email_c, 0)) AS phsf_do_not_email_ind,
            MAX(COALESCE(has_opted_out_of_email, 0)) AS phsf_opt_out_ind,
            MIN(email_bounced_date) AS phsf_first_bounce_dt,
            MAX(email_bounced_date) AS phsf_last_bounce_dt,
            COUNT(DISTINCT email_bounced_date) AS phsf_hard_bnc_cnt
        FROM eda.phss_vws.dim_phss_sf_contact
        WHERE email IS NOT NULL
        GROUP BY email
    ) contact (email_addr, phsf_do_not_email_ind, phsf_opt_out_ind, phsf_first_bounce_dt, phsf_last_bounce_dt, phsf_hard_bnc_cnt)

LEFT JOIN 
    (
        SELECT email, email_bounced_reason
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY email ORDER BY email_bounced_date ASC) AS rn
            FROM eda.phss_vws.dim_phss_sf_contact
            WHERE email IS NOT NULL
        ) sub
        WHERE rn = 1
    ) phsf_br_first (email_addr, phsf_first_bounce_reason)
    ON contact.email_addr = phsf_br_first.email_addr

LEFT JOIN 
    (
        SELECT email, email_bounced_reason
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY email ORDER BY email_bounced_date DESC) AS rn
            FROM eda.phss_vws.dim_phss_sf_contact
            WHERE email IS NOT NULL
        ) sub
        WHERE rn = 1
    ) phsf_br_last (email_addr, phsf_last_bounce_reason)
    ON contact.email_addr = phsf_br_last.email_addr --Hitansu: working fine
) phsf (email_addr, phsf_do_not_email_ind, phsf_opt_out_ind, phsf_first_bounce_dt, phsf_last_bounce_dt, phsf_hard_bounce_cnt, phsf_first_bounce_reason, phsf_last_bounce_reason)  on  prfr.email_addr = phsf.email_addr

left join 

/* Now get the SalesForce Marketing Cloud bounce data - NOTE, the TS team change the bounce table and only tracks the bounce email */
/*
(
	select 
		email_address,
		sum(case when email_addr = 'Block bounce' then 1 else 0 end) as sfmc_block_bounce_cnt,
		sum(case when bounce_category = 'Hard bounce' then 1 else 0 end) as sfmc_hard_bounce_cnt,
		sum(case when bounce_category = 'Soft bounce' then 1 else 0 end) as sfmc_soft_bounce_cnt,
		sum(case when bounce_category = 'Technical/Other bounce' then 1 else 0 end) as sfmc_technical_bounce_cnt,
		sum(case when bounce_category = 'Unknown bounce' then 1 else 0 end) as sfmc_unknown_bounce_cnt,
		sfmc_soft_bounce_cnt as sfmc_total_soft_bounce_cnt, -- wasn't sure how to set this variable - seems redundant.
		sum(case when bounce_category is not null then 1 else 0 end) as sfmc_total_bounce_cnt
	from data_lab_phss_tbls.utl_mcl_bounces
	group by 1
) sfmc_bnc (email_addr, sfmc_block_bounce_cnt, sfmc_hard_bounce_cnt, sfmc_soft_bounce_cnt, sfmc_technical_bounce_cnt, sfmc_unknown_bounce_cnt, sfmc_total_soft_bounce_cnt, sfmc_total_bounce_cnt) on prfr.email_addr = sfmc_bnc.email_addr

left join */
/* now get the first email bounce date and reason from the SalesForce Mktg Cloud data */
/*
(
	select
		email_address,
		event_date, 
		bounce_reason 
	from data_lab_phss_tbls.utl_mcl_bounces
	qualify row_number() over (partition by email_address order by event_date asc ) = 1
) sfmc_first_bnc (email_addr, sfmc_first_bounce_dt,sfmc_first_bounce_reason) on prfr. email_addr = sfmc_first_bnc.email_addr
 
left join */
/* now get the last email bounce date and reason from the SalesForce Mktg Cloud data */
/* NOTE: Had to replace the original query because the TS team changed the table name and removed attributes
(
	select
		email_address,
		event_date, 
		bounce_reason 
	from data_lab_phss_tbls.utl_mcl_bounces
	qualify row_number() over (partition by email_address order by event_date asc ) = 1
) sfmc_last_bnc (email_addr, sfmc_last_bounce_dt,sfmc_last_bounce_reason) on prfr. email_addr = sfmc_last_bnc.email_addr
*/
(
	select
		email,
		1 as sfmc_hard_bounce_cnt,
		1 as sfmc_total_bounce_cnt
	from mktg_ops_tbls.utl_mcl_hard_bounces
) sfmc_hrd_bnc (email_addr, sfmc_hard_bounce_cnt, sfmc_total_bounce_cnt) on prfr. email_addr = sfmc_hrd_bnc.email_addr
left join 
/* now get the SalesForce Mktg Cloud unsubcribe data */
(
/*
	select
		email_address,
		min(event_date),
		max(event_date), 
		count(distinct(list_id)),
		count(distinct(batch_id))
	from data_lab_phss_tbls.utl_mcl_unsubs
	group by 1
	*/
	select 
		email_addr,
		1 as sfmc_unsubscrb_cnt
	from mktg_ops_tbls.utl_mc_unsubs
) sfmc_unsub (email_addr, sfmc_unsubscrb_cnt) on prfr. email_addr = sfmc_unsub.email_addr --(email_addr, sfmc_first_unsubscrb_dt,sfmc_last_unsubscrb_dt,sfmc_unsubscrb_cnt, sfmc_unsubscrb_click_cnt) 

left join 
/* now get the Angry Client data to set unknown opt-outs */
(
	select 
		distinct contact_email,
		1 as unk_opt_out_ind
	from mktg_ops_tbls.utl_angry_client--Hitansu: working fine
) unk_optout (email_addr, unk_opt_out_ind) on prfr.email_addr = unk_optout.email_addr

/* Now get the Adobe Spam Reject email addresses from the adb_nmsbroadlogmsg table */
left join 
(
SELECT 
    TRIM(b.saddress), 
    CAST(MIN(a.tsLastModified) AS DATE) AS first_spam_rejct_dt, 
    CAST(MAX(a.tsLastModified) AS DATE) AS last_spam_rejct_dt, 
    COUNT(*) AS spam_rejct_cnt
FROM mktg_ops_tbls.adb_nmsbroadlogmsg a
LEFT JOIN mktg_ops_tbls.adb_nmsbroadlogrcp b 
    ON a.iBroadLogMsgId = b.ibroadlogid
LEFT JOIN mktg_ops_tbls.adb_nmsrecipient c 
    ON b.irecipientid = c.irecipientid
WHERE a.iFailureType = 3 
  AND COALESCE(b.saddress, NULL) IS NOT NULL
GROUP BY TRIM(b.saddress)--Hitansu: no data, sytax correct

) adb_spam_rejct (email_addr, first_spam_rejct_dt, last_spam_rejct_dt, spam_rejct_cnt) on prfr.email_addr = adb_spam_rejct.email_addr

/* Now check the Validity Email Validation return file table check for invalid email addresses */
left join 
(
SELECT 
    email_addr,
    valdtn_status,
    CAST(valdtn_dt AS DATE) AS valdtn_dt
FROM mktg_ops_tbls.vaidity_email_valdtn
WHERE email_addr IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY email_addr ORDER BY valdtn_dt DESC) = 1
							--Hitansu: tested, no data
) validity_status (email_addr, valdtn_status, valdtn_dt) on prfr.email_addr = validity_status.email_addr

/* Now run the Bad/Suspect Domain Check*/
left join 
(
SELECT 
    DISTINCT
    cnst_email_addr,
    1 AS bad_domain_ind
FROM eda.arc_mdm_vws.bzfc_cnst_email
WHERE 
    assessmnt_ctg IN ('Validated', 'Use With Caution')
    AND cnst_email_addr IS NOT NULL
    AND SUBSTRING(cnst_email_addr, POSITION('@' IN cnst_email_addr) + 1) IN (
        SELECT bad_domain
        FROM mktg_ops_tbls.suspect_domains
    )

) baddmn (email_addr, bad_domain_ind) on prfr.email_addr = baddmn.email_addr;

	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='Records Inserted';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.bzfc_cnst_cdi_phss_email_prfl) as integer)
        WHERE proc_name = 'ld_bzfc_cnst_cdi_phss_em_prfl' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bzfc_cnst_cdi_phss_em_prfl', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
