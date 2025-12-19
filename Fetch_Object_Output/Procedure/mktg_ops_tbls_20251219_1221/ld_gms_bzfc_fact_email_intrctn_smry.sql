CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_bzfc_fact_email_intrctn_smry()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Majeed Mohammad
Created date: 01/23/2017
Purpose: To load the table  mktg_ops_tbls.bzfc_fact_email_intrctn_smry

Modified by Michael Andrien
Modified Date: 2/14/2017
Purpose: Added gen_segmnt_key, chan_typ_key columns

Modified by Michael Andrien
Modified Date: 3/302017
Purpose: Updated the unsub section to include unsub from the new Web App form captured in the adb_arcprefchangefr table.  This
                                                                replaces the link clicked method used by earlier campaign.  Both methods are Unioned in the query below to capture all unsubs for both method.
                                                                
Modified by Majeed Mohammad
Modified Date: 3/30/2017
Purpose: Added the cast to timestamp(0) in the union part of the sql. 

Modified by Michael Andrien
Modified Date: 3/30/2017
Purpose:  Added the mirror page metrics and updated the link clicked indicator to be set to 1 if  an unsubscribe link is clicked, a mirror page link is clicked or any other link within the email is clicked.  NOTE: The unsub and mirror page clicks also have their own counts and indicators.

Modified by Michael Andrien
Modified Date: 6/17/2017
Purpose: Added email launch date - this is only set for emails with a sent status code.  This returns for first email sent date for email campaigns that are sent through multiple deliveries over several days.

Modified by Michael Andrien
Modified Date: 11/27/2017
Purpose: Added an outer select to eliminate duplicates from the unsub UNION query.  Also added dlvry join and constraint below to remove test deliveries and limit 'Sent' deliveries.
				(where  substr(dlvry.delivery_nm,1,4) <> 'FCP_' --and a.nk_intrctn_status_dsc = 'Sent' )

Modified by Michael Andrien
Modified Date: 11/29/2017
Purpose: Added constraint to the query to eliminate email interaction records with the cnst_mstr_id = 0.  This was causing the macro to skew badly.   Also, added logic to derive the 
				email segment value for each interaction.  This logic was removed from the view and added to the macro.  This will make the view run much faster.

Modified by Michael Andrien
Modified Date: 12/06/2017
Purpose:  Changes the order by column from intrctn_dt to last_dntn_gift_dt on the PARTITION statement in the section that calculates the email segment.  Email segments were not
				correct in some cases.  This update fixes the issue.
				
Modified By: Michael Andrien
Modified Date: 03/03/2020
Purpose: Created GMS version of the view to reference the new GMS TXN view to calculate the email interaction segment attribute.

Modified By: Michael Andrien
Modified Date: 04/20/2020
Purpose: Added delete at the end of the macro to truncate the stage table.

Modified By: Majeed Mohammad
Modified Date: 04/21/2020
Purpose: Converted the comments from -- to / * /  format

Modified By: Michael Andrien
Modified Date: 05/15/2020
Purpose: Revised the email launch date logic to account for triggered campaign deliveries. Replaced emld.email_launch_dt with
   	case when dlvry.is_trigg_msg_ind = 1 then  fi.intrctn_dt else emld.email_launch_dt end

Modified By: Michael Andrien
Modified Date: 07/14/2021
Purpose: Removed the cnst_mstr_id from the on clause of all the joins to the Adobe Broadlog table for the email interaction sections (send, open, click, bounce, unsub, etc)

Modified By: Majeed Mohammad
Modified Date: 12/13/2021
Purpose: Changed the explicit SMALLINT conversion to INT for columns fr_distr_dntn_cnt and fr_mission_dntn_cnt columns in the UNION subquery 

Modified By: Michael Andrien
Modified Date: 02/10/2022
Purpose: Add an update to the end of the macro to apply updates to the email interaction summary table to account for the iOS open email issue.  We are setting the email_open_ind = 0 if the email recipient has 10 consecutive email open 
events without an email link click event.

Modified By: Michael Andrien
Modified Date: 02/16/2022
Purpose:   Based on feedback from Greg Seaberg - I changed the greater than '>' sign to a less than sign '<'' in the txns jions on clause below
) txns (cnst_mstr_id, gift_src_cd, dntn_dt, dntn_cnt, rev_amt)
      on ems.cnst_mstr_id = txns.cnst_mstr_id and ems.src_cd = txns.gift_src_cd and ems.email_launch_dt <= dntn_dt
	  
Modified By: Michael Andrien
Modified Date: 03/08/2022
Purpose: Added the line below to the emld join to exclude logically deleted rows from the deirved table.  Also, modified the Launch Date case statement
to use the fi.intrctn_dt for the 'RSG00100E018' and 'DistMktg'' source codes.

Modified by Greg Seaberg and Deployed by Michael Andrien
Modified Date: 06/22/2022
Purpose: Modified the case logic for setting the key and description values for the email segment (email_segment_key and email_segment_dsc).

Modified By: Majeed Mohammad
Modified Date: 8/22/2023
Purpose: Added the incremental logic to delete and load the data for only the last year. 

Modified By: Majeed Mohammad
Modified Date: 7/15/2024
Purpose:  Added the DISTINCT to the SELECT subquery in the UPDATE statement. This update was failing with the error  -  Failure 7547 Target row updated by multiple source rows.

Modified by Michael Andrien
Modified Date: 03/03/2025
Purpose: Added logic to include Sponsor survey email interactions for which the cnst_mstr_id = 0.  Updated the WHERE clause on the insert into select to include the 
source code check below.  Also, changed the incremental select logic from DATE - INTERVAL '1' YEAR to Add_Months(Current_Date,-12)
***WHERE  Substr(dlvry.delivery_nm,1,4) <> 'FCP_' AND (fi.src_cd = 'RSB00000EBSS' OR fi.cnst_mstr_id <> 0)

Modified by Michael Andrien
Modified Date: 03/07/2025
Purpose: Changed the macro insert, update, delete flow to load and update the interaction data where cnst_mstr_id <> 0 then load the sponsor 
survey interaction data, which has cnst_mstr_id = 0 after the other data has been loaded and updated.  This resolve the duplicate 'email_open_ind' update issue

Modified by:		Greg Seaberg
Implemented by:	Michael Andrien
Modified Date: 	07/15/2025
Purpose: 				Changed the link click indicator setting to ignore clicks happening 5 seconds before or after a click on the 'bot lure' pixel link
								Adds the following correlated subquery to the emlc subquery:
									AND NOT EXISTS (
										SELECT * FROM mktg_ops_tbls.adb_nmstrackinglogrcp tlr
										LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu1 ON tlr.iurlid = tu1.itrackingurlid
										WHERE tu1.ssource = 'https://www.redcross.org/donate/email/pixel.html'
											AND tl.ibroadlogid = tlr.ibroadlogid
											AND tl.tslog BETWEEN tlr.tslog - INTERVAL '5' SECOND AND tlr.tslog + INTERVAL '5' SECOND
										)

Modified by:		Greg Seaberg
Implemented by:	Michael Andrien
Modified Date: 	08/29/2025
Purpose: 				Modified the link click indicator setting to ignore clicks happening 12 seconds (previously 5 seconds) before or after a click on the 'bot lure' pixel link
								Modified the following correlated subquery in the emlc subquery:
									AND NOT EXISTS (
										SELECT * FROM mktg_ops_tbls.adb_nmstrackinglogrcp tlr
										LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu1 ON tlr.iurlid = tu1.itrackingurlid
										WHERE tu1.ssource = 'https://www.redcross.org/donate/email/pixel.html'
											AND tl.ibroadlogid = tlr.ibroadlogid
											AND tl.tslog BETWEEN tlr.tslog - INTERVAL '12' SECOND AND tlr.tslog + INTERVAL '12' SECOND
										)
Modified by:    Michael Andrien
Modified Date: 	10/06/2025
Purpose: 		While reviewing Mission Wired extract requirements, we realized the link click BOT Lure pixel code had been commented out.  We uncommented the code.						
 ------------------------------------------------------------------------------------------------------------------------------------ */

	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_gms_bzfc_fact_email_intrctn_smry', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN

truncate table mktg_stage_tbls.stg_gms_fact_email_intrctn_smry;

INSERT INTO mktg_stage_tbls.stg_gms_fact_email_intrctn_smry
(               cnst_mstr_id, orig_cnst_mstr_id, nk_recipient_id, recipient_zip_cd,
                                nk_intrctn_id, delivery_key, campaign_key, 
                                src_key, comnictn_src_key, gen_segmnt_key, chan_typ_key,
                                unit_key, nk_ecode, intrctn_status_key, src_cd, subsrc_cd, intrctn_dt_key,
                                intrctn_dt, email_addr, email_to_domain, email_launch_dt, email_sent_ind, email_failed_ind,
                                email_pending_ind, email_sent_cnt, email_failed_cnt, email_pending_cnt,
                                email_total_cnt, email_open_ind, email_open_cnt, first_email_open_dt,
                                last_email_open_dt, email_link_click_ind, distinct_url_click_ind,
                                email_link_click_cnt, distinct_url_click_cnt, first_link_click_dt,
                                last_link_click_dt, unsbscrb_ind, unsbscrb_click_cnt, first_unsbscrb_dt,
                                last_unsbscrb_dt, mirror_page_click_cnt,mirror_page_click_ind,
                                email_bounce_ind, fbl_ind, hard_bounce_ind, soft_bounce_ind, fbl_cnt, hard_bounce_cnt, 
                                soft_bounce_cnt, total_bounce_cnt, first_bounce_dt, last_bounce_dt)


SELECT 
                fi.cnst_mstr_id,
                fi.orig_cnst_mstr_id,
                fi.nk_recipient_id,
                fi.recipient_zip_cd,
                fi.nk_intrctn_id,
                fi.delivery_key,
                fi.campaign_key,
				fi.src_key,
                fi.comnictn_src_key AS comnictn_src_key, /*  3/3/20 NOTE: Need to rename to src_key */  
                fi.gen_segmnt_key,
               -- fi.channel_key,
                fi.chan_typ_key as channel_key,
                fi.unit_key,
                fi.nk_ecode,
                fi.intrctn_status_key,
                fi.src_cd,
                fi.subsrc_cd,
                fi.intrctn_dt_key,
                fi.intrctn_dt,
                fi.email_addr,
                fi.email_to_domain,
   /*  Email Launch Date */  
   				--case when dlvry.is_trigg_msg_ind = 1 then  fi.intrctn_dt else emld.email_launch_dt end as email_launch_dt,
				CASE WHEN dlvry.is_trigg_msg_ind = 1 THEN  fi.intrctn_dt
            		WHEN fi.src_cd IN ('RSG00100E018','DistMkt') THEN fi.intrctn_dt /*set email_launch_dt to fi.intrctn_dt for Distributed Marketing emails*/
            		ELSE emld.email_launch_dt
				end AS email_launch_dt,
  /*  Email Sent Metrics  */  
                CASE WHEN ems.email_sent_cnt > 0 THEN 1 ELSE 0 end AS email_sent_ind,
                CASE WHEN ems.email_failed_cnt > 0 THEN 1 ELSE 0 end AS email_failed_ind,
                CASE WHEN ems.email_pending_cnt > 0 THEN 1 ELSE 0 end AS email_pending_ind,
                coalesce(ems.email_sent_cnt,0) AS email_sent_cnt,
                coalesce(ems.email_failed_cnt,0) AS email_failed_cnt,
                coalesce(ems.email_pending_cnt,0) AS email_pending_cnt,
                coalesce(ems.email_total_cnt,0) AS email_total_cnt,
   /*  Email Open Metrics  */  
                CASE WHEN opn.email_open_cnt > 0 THEN 1 ELSE 0 end AS email_open_ind,
    coalesce(opn.email_open_cnt,0) AS email_open_cnt,
                first_email_open_dt, 
			    last_email_open_dt,
    /*  Email Link Clicked Metrics  */  
                CASE WHEN (emlc.link_click_cnt > 0 OR mirror_page_click_cnt > 0 OR  coalesce(unsbscrb_click_cnt,0) > 0) THEN 1 ELSE 0 end AS email_link_click_ind,  
                /*  The email link click indicator is set to 1 if  an unsubscribe link is clicked, a mirror page link is clicked or any other link within the email is clicked.  NOTE: The unsub and mirror page clicks also have their own counts and indicators. */  
                CASE WHEN emlc.distinct_url_click_cnt > 0 THEN 1 ELSE 0 end AS distinct_url_click_ind,
                coalesce(link_click_cnt,0) AS email_link_click_cnt,
                coalesce(distinct_url_click_cnt,0) AS distinct_url_click_cnt,
                first_link_click_dt,
                last_link_click_dt,
    /*  Email Unsubscribe Metrics */  
                CASE WHEN unsub.unsbscrb_click_cnt > 0 THEN 1 ELSE 0 end AS unsbscrb_ind,
                coalesce(unsbscrb_click_cnt,0) AS unsbscrb_click_cnt, 
                first_unsbscrb_dt, 
                last_unsbscrb_dt, 
 /*  Mirror Page Clicked Metrics  */  
 				coalesce(mplc.mirror_page_click_cnt,0) AS mirror_page_click_cnt,
 				CASE WHEN mirror_page_click_cnt > 0 THEN 1 ELSE 0 end AS mirror_page_click_ind,
    /*  Email Bounce Metrics  */  
                CASE WHEN total_bounce_cnt > 0 THEN 1 ELSE 0 end AS email_bounce_ind,
                CASE WHEN fbl_cnt > 0 THEN 1 ELSE 0 end AS fbl_ind,
                CASE WHEN hard_bounce_cnt > 0 THEN 1 ELSE 0 end AS hard_bounce_ind,
                CASE WHEN soft_bounce_cnt > 0 THEN 1 ELSE 0 end AS soft_bounce_ind,
                  coalesce(fbl_cnt,0) AS fbl_cnt, 
                  coalesce(hard_bounce_cnt,0) AS hard_bounce_cnt, 
                  coalesce(soft_bounce_cnt,0) AS soft_bounce_cnt, 
                  coalesce(total_bounce_cnt,0) AS total_bounce_cnt, 
                  first_bounce_dt, 
                  last_bounce_dt
FROM mktg_ops_vws.bzfc_fact_email_interaction fi
LEFT JOIN mktg_ops_vws.bz_dim_delivery dlvry ON fi.delivery_key = dlvry.delivery_key
LEFT JOIN 
(
	select src_key, src_cd from (
		SELECT src_key, src_cd, Row_Number() Over (PARTITION BY src_cd  ORDER BY  active_ind DESC, src_key DESC) as rn
		FROM eda.ufds_vws.gmpbzal_dim_src
	) as subqry
	 	where subqry.rn=1
	
)  src ON fi.src_cd = src.src_cd/*
				Now get the email launch date - first email sent date by source code
*/

LEFT JOIN 
(
	SELECT 
		scampaignsourcecode,
		Min(Cast(tsevent AS DATE )) AS email_launch_dt
	 FROM mktg_ops_vws.bz_adb_nmsbroadlogrcp a
	 LEFT JOIN  mktg_ops_vws.bz_adb_nmsdelivery b ON a.ideliveryid = b.ideliveryid
	 WHERE 
	 	Substring(b.sinternalname,1,4) <> 'FCP_' 
		AND a.istatus = 1 
		AND b.ihidemessageflag = 0  /*  email sent status code  */  
	 	AND b.row_stat_cd <> 'L'  /*remove logically deleted records*/
	 GROUP BY 1
) emld (src_cd, email_launch_dt) ON collate(emld.src_cd::text,'CASE_INSENSITIVE') = collate(fi.src_cd::text,'CASE_INSENSITIVE')

/*
                Now get the email sent/delivery stats
*/


LEFT JOIN 
(
                SELECT 
                    bl.ibroadlogid,
                    r.irecipientid,
                    bicnst_mstr_id, 
                    d.ideliveryid, 
                    CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
                    streatmentsubsourcecode, 
                    'Email Sent' AS email_intrctn_typ_dsc  ,  
                    Sum(CASE WHEN bl.istatus = 1 THEN 1 ELSE 0 end ) AS email_sent_cnt, 
                    Sum(CASE WHEN bl.istatus = 2 THEN 1 ELSE 0 end ) AS email_failed_cnt, 
                    Sum(CASE WHEN bl.istatus = 6 THEN 1 ELSE 0 end ) AS email_pending_cnt, 
                    Count(*) AS email_total_cnt
                FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
                LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
                LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = bl.ideliveryid
                GROUP BY 1,2,3,4,5,6,7
) ems (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, email_sent_cnt, email_failed_cnt, email_pending_cnt, email_total_cnt) 
                                ON ems.ibroadlogid = fi.nk_intrctn_id --and ems.cnst_mstr_id = fi.cnst_mstr_id

                                
/* Now Get the email open summary metrics */
LEFT JOIN 
(
SELECT 
    bl.ibroadlogid,
    r.irecipientid,
    bicnst_mstr_id, 
    d.ideliveryid, 
                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
    streatmentsubsourcecode, 
    email_intrctn_typ_dsc  ,     
    Count(*) AS open_cnt,
    Min(tl.tslog) AS first_email_open_dt,
    Max(tl.tslog) AS last_email_open_dt
FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl ON r.irecipientid = tl.irecipientid AND bl.ibroadlogid = tl.ibroadlogid AND bl.ideliveryid = tl.ideliveryid
LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
WHERE email_intrctn_typ_id = 2
GROUP BY  1,2,3,4,5,6,7
) opn (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, email_open_cnt, first_email_open_dt, last_email_open_dt) 
                ON opn.ibroadlogid = fi.nk_intrctn_id --and opn.cnst_mstr_id = fi.cnst_mstr_id
                                
/* Now Get the email link clicked summary metrics */
LEFT JOIN 
(
SELECT 
    bl.ibroadlogid,
    r.irecipientid,
    bicnst_mstr_id, 
    d.ideliveryid, 
                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
    streatmentsubsourcecode, 
    email_intrctn_typ_dsc,       
    Count(*) AS link_click_total_cnt,
    Count(DISTINCT itrackingurlid) AS distinct_url_click_cnt,
    Min(tl.tslog) AS first_link_click_dt,
    Max(tl.tslog) AS last_link_click_dt
                FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
                LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
                LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl ON r.irecipientid = tl.irecipientid AND bl.ibroadlogid = tl.ibroadlogid AND bl.ideliveryid = tl.ideliveryid
                LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
                LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
                LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
                WHERE email_intrctn_typ_id = 1
					/*GS: subquery to exclude any link clicks occurring 5 seconds before or after a click on the 'bot lure' pixel link*/
					AND NOT EXISTS (
						SELECT * FROM mktg_ops_tbls.adb_nmstrackinglogrcp tlr
						LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu1 ON tlr.iurlid = tu1.itrackingurlid
						WHERE tu1.ssource = 'https://www.redcross.org/donate/email/pixel.html'
							AND tl.ibroadlogid = tlr.ibroadlogid
							AND tl.tslog BETWEEN tlr.tslog - INTERVAL '12' SECOND AND tlr.tslog + INTERVAL '12' SECOND
						)
                GROUP BY  1,2,3,4,5,6,7
) emlc (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, link_click_cnt,  distinct_url_click_cnt, first_link_click_dt, last_link_click_dt) 
                ON emlc.ibroadlogid = fi.nk_intrctn_id --and emlc.cnst_mstr_id = fi.cnst_mstr_id

                
/* Now Get the email  unsubscribe stats */
LEFT JOIN 
(
/*  The next select gets the unsubs from the nmstrackingurl table.  This was the original method for tracking unsubs.  We have both in the fact_email_interctn_smry table to make sure we capture all unsubs by campaign/delivery  */  
/*  11/27/17 MTA - Added the outer select to eliminate duplicates from the unsub UNION query  */  
		SELECT 
			ibroadlogid, 
			irecipientid, 
			cnst_mstr_id, 
			ideliveryid, 
			src_cd, 
			sub_src_cd, 
			email_intrctn_typ_dsc, 
			Sum(unsbscrb_click_cnt), 
			Max(unsbscrb_ind), 
			Min(first_unsbscrb_dt), 
			Max(last_unsbscrb_dt)
		FROM 
		(		
				SELECT 
                                bl.ibroadlogid,
                                r.irecipientid,
                                bicnst_mstr_id, 
                                d.ideliveryid, 
                                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
                                streatmentsubsourcecode, 
                                email_intrctn_typ_dsc  ,  
                                Count(*) AS unsbscrb_click_cnt, 
                                Max(r.iblacklist) AS unsbscrb_ind, 
                                Min(tslog) AS first_unsbscrb_dt, 
                                Max(tslog)AS last_unsbscrb_dt
                FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
                LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
                LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl ON r.irecipientid = tl.irecipientid AND bl.ibroadlogid = tl.ibroadlogid AND bl.ideliveryid = tl.ideliveryid
                LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
                LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
                LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
                WHERE email_intrctn_typ_id = 3 AND d.istatus = 5 AND isuccess > 0 /* and r.iblacklist = 1  */  
                GROUP BY  1,2,3,4,5,6,7
                
                UNION ALL
                
/*  The next select get the unsubscribes from the Unsub Web App.  This method replaced the original method for extracting unsubs from the link clicked record in the nmstrackingurl table.  */  
                SELECT 
                                bl.ibroadlogid,
                                r.irecipientid,
                                bicnst_mstr_id, 
                                d.ideliveryid, 
                                CASE WHEN d.scampaignsourcecode IS NOT NULL THEN d.scampaignsourcecode ELSE d.sdeliverycode end AS scampaignsourcecode, 
                                d.streatmentsubsourcecode, 
                                Cast('Opt-out' AS VARCHAR(28)) AS email_intrctn_typ_dsc  ,  
                                Count(*) AS unsbscrb_click_cnt, 
                                Max(a.iBlackListEmail_fr) AS unsbscrb_ind, 
                                                /*Added the explicit CAST to TIMESTAMP(0). The source fields are TIMESTAMP(6). */
                                Min(Cast(Cast(a.tsLastModified AS VARCHAR(19)) AS TIMESTAMP(0))) AS first_unsbscrb_dt,
                                Max(Cast(Cast(a.tsLastModified AS VARCHAR(19)) AS TIMESTAMP(0))) AS last_unsbscrb_dt 
                FROM mktg_ops_tbls.adb_arcprefchangefr a
                LEFT JOIN mktg_ops_tbls.adb_nmsbroadlogrcp bl ON a.iRecipientId = bl.iRecipientId AND a.iDeliveryId = bl.iDeliveryId
                LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
                LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = a.ideliveryid
                GROUP BY  1,2,3,4,5,6,7
		) unsub_union (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, unsbscrb_click_cnt, unsbscrb_ind, first_unsbscrb_dt, last_unsbscrb_dt) 
		GROUP BY 1,2,3,4,5,6,7
	) unsub (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, unsbscrb_click_cnt, unsbscrb_ind, first_unsbscrb_dt, last_unsbscrb_dt) 
                ON unsub.ibroadlogid = fi.nk_intrctn_id --and unsub.cnst_mstr_id = fi.cnst_mstr_id
                
 /* Now Get the mirror page link clicked summary metrics */
LEFT JOIN 
(
SELECT 
    bl.ibroadlogid,
    r.irecipientid,
    bicnst_mstr_id, 
    d.ideliveryid, 
    CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
    streatmentsubsourcecode, 
    email_intrctn_typ_dsc,       
    Count(*) AS mirror_page_click_cnt
FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl ON r.irecipientid = tl.irecipientid AND bl.ibroadlogid = tl.ibroadlogid AND bl.ideliveryid = tl.ideliveryid
LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
WHERE email_intrctn_typ_id = 6
GROUP BY  1,2,3,4,5,6,7
) mplc (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, mirror_page_click_cnt) 
                ON mplc.ibroadlogid = fi.nk_intrctn_id --and mplc.cnst_mstr_id = fi.cnst_mstr_id

/* Now Get the email bounce stats */

LEFT JOIN 
(
SELECT 
    bl.ibroadlogid,
    r.irecipientid,
    bicnst_mstr_id, 
    d.ideliveryid ,
                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
    streatmentsubsourcecode, 
    'Email-Bounce' AS email_intrctn_typ_dsc,
    Sum(CASE WHEN a.iquarantinereason = 8 THEN 1 ELSE 0 end) AS fbl_cnt,
                Sum(CASE WHEN a.iquarantinereason IN (0,1,2,3,4,20) THEN 1 ELSE 0 end) AS hard_bounce_cnt,
                Sum(CASE WHEN a.iquarantinereason IN (5,6,25) THEN 1 ELSE 0 end) AS soft_bounce_cnt,
    Count(*) AS total_bounce_cnt,
   Min(a.tscreated) AS first_bounce_dt,
   Max(a.tscreated) AS last_bounce_dt
FROM  mktg_ops_tbls.adb_nmsaddress a
LEFT JOIN mktg_ops_tbls.adb_nmsbroadlogrcp bl ON collate(a.ideliveryid::text,'CASE_INSENSITIVE') = collate(bl.ideliveryid::text,'CASE_INSENSITIVE') AND collate(a.saddress::text,'CASE_INSENSITIVE') = collate(bl.saddress::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_tbls.adb_nmsrecipient r ON collate(r.irecipientid::text,'CASE_INSENSITIVE') = collate(bl.irecipientid::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON collate(d.ideliveryid::text,'CASE_INSENSITIVE') = collate(a.ideliveryid::text,'CASE_INSENSITIVE')
GROUP BY 1,2,3,4,5,6,7
) bnc (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, fbl_cnt, hard_bounce_cnt, soft_bounce_cnt, total_bounce_cnt, first_bounce_dt, last_bounce_dt) 
                ON bnc.ibroadlogid = fi.nk_intrctn_id --and bnc.cnst_mstr_id = fi.cnst_mstr_id
WHERE Substring(dlvry.delivery_nm,1,4) <> 'FCP_' AND fi.cnst_mstr_id <> 0--(fi.src_cd = 'RSB00000EBSS' OR fi.cnst_mstr_id <> 0)
AND  fi.intrctn_dt > Add_Months(Current_Date,-12);      
/*DATE - INTERVAL '1' YEAR */
 /*Added this logic for incremental data to run for the last year only */  
/* and fi.nk_intrctn_status_dsc = 'Sent';   email sent status code  */ 

DELETE FROM mktg_ops_tbls.gms_bzfc_fact_email_intrctn_smry
 WHERE   intrctn_dt > Add_Months(Current_Date,-12);  /*Added this logic for incremental data to run for the last year only */  


INSERT INTO mktg_ops_tbls.gms_bzfc_fact_email_intrctn_smry
(               cnst_mstr_id, orig_cnst_mstr_id, nk_recipient_id, recipient_zip_cd,
                                nk_intrctn_id, delivery_key, campaign_key, 
                                src_key, gen_segmnt_key, chan_typ_key,
                                unit_key, nk_ecode, intrctn_status_key, src_cd, subsrc_cd, intrctn_dt_key,
                                intrctn_dt, email_addr, email_to_domain, email_launch_dt, email_sent_ind, email_failed_ind,
                                email_pending_ind, email_sent_cnt, email_failed_cnt, email_pending_cnt,
                                email_total_cnt, email_open_ind, email_open_cnt, first_email_open_dt,
                                last_email_open_dt, email_link_click_ind, distinct_url_click_ind,
                                email_link_click_cnt, distinct_url_click_cnt, first_link_click_dt,
                                last_link_click_dt, unsbscrb_ind, unsbscrb_click_cnt, first_unsbscrb_dt,
                                last_unsbscrb_dt, mirror_page_click_cnt,mirror_page_click_ind,
                                email_bounce_ind, fbl_ind, hard_bounce_ind, soft_bounce_ind, fbl_cnt, hard_bounce_cnt, 
                                soft_bounce_cnt, total_bounce_cnt, first_bounce_dt, last_bounce_dt,
                                last_dntn_gift_dt, email_segmnt_key, email_segmnt_dsc, active_email_segment_ind)
 
 SELECT 
	a.cnst_mstr_id, 
	orig_cnst_mstr_id, 
	nk_recipient_id, 
	recipient_zip_cd,
	a.nk_intrctn_id, 
	delivery_key, campaign_key, src_key,
	gen_segmnt_key , 
	chan_typ_key  AS channel_key, 
	unit_key, nk_ecode, intrctn_status_key, src_cd, subsrc_cd, intrctn_dt_key,
	a.intrctn_dt, email_addr, email_to_domain, email_launch_dt, email_sent_ind, email_failed_ind,
	email_pending_ind, email_sent_cnt, email_failed_cnt, email_pending_cnt,
	email_total_cnt, email_open_ind, email_open_cnt, first_email_open_dt,
	last_email_open_dt, email_link_click_ind, distinct_url_click_ind,
	email_link_click_cnt, distinct_url_click_cnt, first_link_click_dt,
	last_link_click_dt, unsbscrb_ind, unsbscrb_click_cnt, first_unsbscrb_dt,
	last_unsbscrb_dt, mirror_page_click_cnt,mirror_page_click_ind,
	email_bounce_ind, fbl_ind, hard_bounce_ind,
	soft_bounce_ind, fbl_cnt, hard_bounce_cnt, soft_bounce_cnt, total_bounce_cnt,
	first_bounce_dt, last_bounce_dt, 
/*  The fields below this line were derived by the derived table 'b' join 		  */  
	 b.last_dntn_gift_dt,
	 b.email_segmnt_key,
	 b.email_segmnt_dsc, 
	 b.active_email_segment_ind
FROM mktg_stage_tbls.stg_gms_fact_email_intrctn_smry a
LEFT JOIN 
(
	SELECT
		cnst_mstr_id,
		nk_intrctn_id,
		intrctn_dt,
		last_dntn_gift_dt,
	    CASE 
	          WHEN last_dntn_gift_dt IS NULL THEN 4
	          WHEN Add_Months(last_dntn_gift_dt,12) > intrctn_dt AND fr_mission_dntn_cnt > 0 THEN 2
	          WHEN Add_Months(last_dntn_gift_dt,12) > intrctn_dt AND fr_distr_dntn_cnt > 0 AND fr_mission_dntn_cnt = 0 THEN 3
	          WHEN Add_Months(last_dntn_gift_dt,24) > intrctn_dt THEN 8
	          WHEN Add_Months(last_dntn_gift_dt,36) > intrctn_dt THEN 9
	          WHEN Add_Months(last_dntn_gift_dt,36) <= intrctn_dt THEN 10
	          /*when intrctn_dt - last_dntn_gift_dt >= 365 then 1
	          when  intrctn_dt - last_dntn_gift_dt < 365 and fr_mission_dntn_cnt > 0 then 2
	          when  intrctn_dt - last_dntn_gift_dt < 365 and fr_distr_dntn_cnt > 0 and fr_mission_dntn_cnt = 0  then 3
	          when last_dntn_gift_dt is null  then 4*/
	          ELSE 0
	    end AS email_segment_key,
	    CASE  
	          WHEN last_dntn_gift_dt IS NULL THEN 'Prospect Donor'
	          WHEN Add_Months(last_dntn_gift_dt,12) > intrctn_dt AND fr_mission_dntn_cnt > 0 THEN 'Active Email Mission'
	          WHEN Add_Months(last_dntn_gift_dt,12) > intrctn_dt AND fr_distr_dntn_cnt > 0 AND fr_mission_dntn_cnt = 0 THEN 'Active Email Disaster'
	          WHEN Add_Months(last_dntn_gift_dt,24) > intrctn_dt THEN 'Lapsed Email 13 to 24 Months'
	          WHEN Add_Months(last_dntn_gift_dt,36) > intrctn_dt THEN 'Lapsed Email 25 to 36 Months'
	          WHEN Add_Months(last_dntn_gift_dt,36) <= intrctn_dt THEN 'Lapsed Email 37+ Months'
	          /*when intrctn_dt - last_dntn_gift_dt >= 365 then 'Lapsed Email'
	          when  intrctn_dt - last_dntn_gift_dt < 365 and fr_mission_dntn_cnt > 0 then 'Active Email Mission'
	          when  intrctn_dt - last_dntn_gift_dt < 365 and fr_distr_dntn_cnt > 0 and fr_mission_dntn_cnt = 0  then 'Active Email Disaster'
	          when last_dntn_gift_dt is null  then 'Prospect Donor'*/
	    end AS email_segment_dsc,
		CASE WHEN  intrctn_dt - last_dntn_gift_dt < 365 THEN 1 ELSE 0 end AS active_email_segment_ind
	FROM
	(
		SELECT 
			 a.cnst_mstr_id, 
			 a.nk_intrctn_id,
			 a.intrctn_dt,
			Cast( Max(b.dntn_gift_dt) AS DATE) AS dntn_gift_dt,
			Cast( Sum (CASE WHEN intrctn_dt - dntn_gift_dt < 365 AND fr_distr_dntn_ind = 1 THEN 1 ELSE 0 end) AS INT) AS fr_distr_dntn_cnt,
			Cast(Sum (CASE WHEN intrctn_dt - dntn_gift_dt < 365 AND fr_distr_dntn_ind = 0 THEN 1 ELSE 0 end) AS INT) AS fr_mission_dntn_cnt
		FROM mktg_stage_tbls.stg_gms_fact_email_intrctn_smry a		 
		LEFT JOIN mktg_ops_vws.gms_arc_fr_txn b ON a.cnst_mstr_id = b.cnst_mstr_id
		WHERE b.dntn_gift_dt < a.intrctn_dt
		GROUP BY 1,2,3
		
		UNION ALL
		
			SELECT 
			 a.cnst_mstr_id, 
			 a.nk_intrctn_id,
			 a.intrctn_dt,
			 Cast(NULL AS DATE) AS dntn_gift_dt,
			 Cast(0 AS INT) AS fr_distr_dntn_cnt,
			 Cast(0 AS INT) AS fr_mission_dntn_cnt
		FROM mktg_stage_tbls.stg_gms_fact_email_intrctn_smry a	
		WHERE cnst_mstr_id <> 0	 
	) txn (cnst_mstr_id,nk_intrctn_id, intrctn_dt, last_dntn_gift_dt, fr_distr_dntn_cnt, fr_mission_dntn_cnt)
	QUALIFY Row_Number() Over (PARTITION BY cnst_mstr_id,nk_intrctn_id ORDER BY  last_dntn_gift_dt DESC) = 1 /*  12/06/17 MTA changed order by to last_dntn_gift_dt from intrctn_dt  */  
) b (cnst_mstr_id,nk_intrctn_id, intrctn_dt, last_dntn_gift_dt,email_segmnt_key,email_segmnt_dsc, active_email_segment_ind) ON a.cnst_mstr_id = b.cnst_mstr_id AND a.nk_intrctn_id = b.nk_intrctn_id  ; 


UPDATE mktg_ops_tbls.gms_bzfc_fact_email_intrctn_smry

SET
  email_open_ind = 0
  
from
(
select distinct nk_intrctn_id

from (
SELECT  
    nk_intrctn_id,
     Max(consctv_seq_num) Over(PARTITION BY cnst_mstr_id) as mx
  FROM (
select cnst_mstr_id,nk_intrctn_id,
      src_cd,email_launch_dt,
      email_open_ind,
      email_link_click_ind,
      unsbscrb_ind,
      dntn_cnt,
      rev_amt,
      respns_ind,
      active_dnr_ind, /*identify donors with donations in the past 24 months as of email lauch date*/
      consctv_seq_num, /*count of consecutive emails with no change in open / click / donate status*/
      derived_device_class 
from (

SELECT 
      ems.cnst_mstr_id,ems.nk_intrctn_id,
      ems.src_cd,ems.email_launch_dt,
      ems.email_open_ind,
      ems.email_link_click_ind,
      ems.unsbscrb_ind,
      txns.dntn_cnt,
      txns.rev_amt,
      CASE WHEN txns.dntn_cnt > 0 THEN 1 ELSE 0 end AS respns_ind,
      CASE WHEN Add_Months(ems.last_dntn_gift_dt,24) >= ems.email_launch_dt THEN 1 ELSE 0 end AS active_dnr_ind, /*identify donors with donations in the past 24 months as of email lauch date*/
      Row_Number() Over (PARTITION BY ems.cnst_mstr_id, CASE WHEN ems.email_open_cnt > 0 THEN 1 ELSE 0 end, ems.email_link_click_ind, respns_ind, CASE WHEN Add_Months(ems.last_dntn_gift_dt,24) >= ems.email_launch_dt THEN 1 ELSE 0 end ORDER BY ems.email_launch_dt, ems.src_cd) AS consctv_seq_num, /*count of consecutive emails with no change in open / click / donate status*/
      Max(Coalesce(tlru.apple_oth_unk_key,0)) Over(PARTITION BY ems.cnst_mstr_id) AS derived_device_class, /*assigns the top value to a cmid based max value of apple device / os value, non-apple device / os value, unclear or null value*/
    Count(*) Over(PARTITION BY ems.cnst_mstr_id, ems.email_open_ind, ems.email_link_click_ind, respns_ind, active_dnr_ind 
        ORDER BY ems.cnst_mstr_id, ems.email_launch_dt, ems.src_cd
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cnt
      FROM mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry ems
    LEFT JOIN mktg_ops_vws.bz_dim_delivery dlv ON ems.delivery_key = dlv.delivery_key
    LEFT JOIN mktg_ops_vws.bz_dim_campgn cmp ON ems.campaign_key = cmp.campgn_key
    LEFT JOIN eda.dw_common_vws.dim_calendar cal ON ems.email_launch_dt = cal.calendar_dt
    LEFT JOIN (
    select src_cd, src_dsc 
    from (SELECT src_cd, src_dsc, Row_Number() Over(PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) as rn 
    FROM mktg_ops_vws.gmpbzal_dim_src) as subqry
    where subqry.rn=1
    ) src (src_cd, src_dsc) ON ems.src_cd = src.src_cd
    LEFT JOIN (/*derived table identifying operating system & device type (if known)*/
    select ibroadlogid, irecipientid,sosfamilly, sdevice,apple_oth_unk_key 
    from (
    	
    	 SELECT 
        tlr.ibroadlogid,
        tlr.irecipientid,
        ua.sosfamilly,
        ua.sdevice,
        CASE WHEN ua.sosfamilly = 'OS X / iOS (Apple)' THEN 2
          WHEN ua.sdevice IN ('iPhone','iPad','iPod') THEN 2
          WHEN ua.sosfamilly IN ('Google','Blackberry','Linux / Unix','Windows','Android') THEN 1
          WHEN ua.sdevice IN ('blackberry','nokia','android') THEN 1
          ELSE 0 end AS apple_oth_unk_key,
          Row_Number() Over (PARTITION BY tlr.ibroadlogid, tlr.irecipientid
        ORDER BY CASE WHEN ua.sosfamilly = 'OS X / iOS (Apple)' THEN 4
          WHEN ua.sdevice IN ('iPhone','iPad','iPod') THEN 3
          WHEN tlr.iuseragent <> 0 THEN 2     
          WHEN ua.sdevice IS NOT NULL THEN 1
          ELSE 0 end DESC, 
          tlr.tslog) as rn
	      FROM mktg_ops_vws.bz_adb_nmstrackinglogrcp tlr 
	      LEFT JOIN mktg_ops_vws.bz_adb_nmsuseragent ua ON tlr.iuseragent = ua.ihashkey
  
    	) as subqry
    	
    	where subqry.rn=1
   
      /*limit to one row per recipient per email, prioritizing known OS values over unknown*/
     ) tlru (ibroadlogid, irecipientid, sosfamilly, sdevice, apple_oth_unk_key)
      ON ems.nk_intrctn_id = tlru.ibroadlogid AND ems.nk_recipient_id = tlru.irecipientid 
      LEFT JOIN ( /*derived table of transactions tied to email source codes*/
      SELECT
        txn.cnst_mstr_id,
        txn.gift_src_cd,
        Min(txn.dntn_gift_dt) dntn_dt,
        Count(txn.giftran_key) dntn_cnt,
        Sum(txn.fr_pmt_amt) rev_amt 
      FROM mktg_ops_vws.gms_arc_fr_txn txn
      INNER JOIN mktg_ops_vws.bz_email_src_cd esrc ON txn.gift_src_cd = esrc.src_cd
      WHERE txn.dntn_gift_dt BETWEEN DATE '2021-10-01' AND Current_Date
        AND txn.fr_pmt_amt > 0
        AND txn.online_channel_cd = 'OD'
      GROUP BY 1,2
      ) txns (cnst_mstr_id, gift_src_cd, dntn_dt, dntn_cnt, rev_amt)
      
       ON ems.cnst_mstr_id = txns.cnst_mstr_id AND ems.src_cd = txns.gift_src_cd AND ems.email_launch_dt <= dntn_dt
    WHERE (ems.email_launch_dt BETWEEN DATE '2021-10-01' AND Current_Date 
        OR ems.first_email_open_dt BETWEEN DATE '2021-10-01' AND Current_Date)  /*limit to 10/1/2021 or later*/
      AND ems.email_sent_ind = 1 /*limit to successfully delivered emails*/
      AND (cmp.campgn_lob_nm = 'Consumer Fundraising' OR Right(dlv.subsrc_cd,3) = 'cfr')
      and  ems.email_open_ind = 1
      AND ems.email_link_click_ind = 0
      AND respns_ind = 0
     
      AND active_dnr_ind = 0

) as subqry
where derived_device_class <> 1 and cnt>=10
      
)opens (cnst_mstr_id, nk_intrctn_id, src_cd, email_launch_dt, email_open_ind, email_link_click_ind, unsbscrb_ind, dntn_cnt, rev_amt, respns_ind, active_dnr_ind, 
    consctv_seq_num, derived_device_class)

) as sq

where sq.mx>=10

)eou (nk_intrctn_id)

WHERE mktg_ops_tbls.gms_bzfc_fact_email_intrctn_smry.nk_intrctn_id = eou.nk_intrctn_id;


/* Now Cleanup Stage tables. */
truncate table mktg_stage_tbls.stg_gms_fact_email_intrctn_smry;



INSERT INTO mktg_stage_tbls.stg_gms_fact_email_intrctn_smry
(               cnst_mstr_id, orig_cnst_mstr_id, nk_recipient_id, recipient_zip_cd,
                                nk_intrctn_id, delivery_key, campaign_key, 
                                src_key, comnictn_src_key, gen_segmnt_key, chan_typ_key,
                                unit_key, nk_ecode, intrctn_status_key, src_cd, subsrc_cd, intrctn_dt_key,
                                intrctn_dt, email_addr, email_to_domain, email_launch_dt, email_sent_ind, email_failed_ind,
                                email_pending_ind, email_sent_cnt, email_failed_cnt, email_pending_cnt,
                                email_total_cnt, email_open_ind, email_open_cnt, first_email_open_dt,
                                last_email_open_dt, email_link_click_ind, distinct_url_click_ind,
                                email_link_click_cnt, distinct_url_click_cnt, first_link_click_dt,
                                last_link_click_dt, unsbscrb_ind, unsbscrb_click_cnt, first_unsbscrb_dt,
                                last_unsbscrb_dt, mirror_page_click_cnt,mirror_page_click_ind,
                                email_bounce_ind, fbl_ind, hard_bounce_ind, soft_bounce_ind, fbl_cnt, hard_bounce_cnt, 
                                soft_bounce_cnt, total_bounce_cnt, first_bounce_dt, last_bounce_dt)





SELECT 
                fi.cnst_mstr_id,
                fi.orig_cnst_mstr_id,
                fi.nk_recipient_id,
                fi.recipient_zip_cd,
                fi.nk_intrctn_id,
                fi.delivery_key,
                fi.campaign_key,
				fi.src_key,
                fi.comnictn_src_key AS comnictn_src_key, /*  3/3/20 NOTE: Need to rename to src_key */  
                fi.gen_segmnt_key,
                fi.chan_typ_key as channel_key,
                --fi.channel_key,
                fi.unit_key,
                fi.nk_ecode,
                fi.intrctn_status_key,
                fi.src_cd,
                fi.subsrc_cd,
                fi.intrctn_dt_key,
                fi.intrctn_dt,
                fi.email_addr,
                fi.email_to_domain,
   /*  Email Launch Date */  
   				--case when dlvry.is_trigg_msg_ind = 1 then  fi.intrctn_dt else emld.email_launch_dt end as email_launch_dt,
				CASE WHEN dlvry.is_trigg_msg_ind = 1 THEN  fi.intrctn_dt
            		WHEN fi.src_cd IN ('RSG00100E018','DistMkt') THEN fi.intrctn_dt /*set email_launch_dt to fi.intrctn_dt for Distributed Marketing emails*/
            		ELSE emld.email_launch_dt
				end AS email_launch_dt,
  /*  Email Sent Metrics  */  
                CASE WHEN ems.email_sent_cnt > 0 THEN 1 ELSE 0 end AS email_sent_ind,
                CASE WHEN ems.email_failed_cnt > 0 THEN 1 ELSE 0 end AS email_failed_ind,
                CASE WHEN ems.email_pending_cnt > 0 THEN 1 ELSE 0 end AS email_pending_ind,
                coalesce(ems.email_sent_cnt,0) AS email_sent_cnt,
                coalesce(ems.email_failed_cnt,0) AS email_failed_cnt,
                coalesce(ems.email_pending_cnt,0) AS email_pending_cnt,
                coalesce(ems.email_total_cnt,0) AS email_total_cnt,
   /*  Email Open Metrics  */  
                CASE WHEN opn.email_open_cnt > 0 THEN 1 ELSE 0 end AS email_open_ind,
   coalesce(opn.email_open_cnt,0) AS email_open_cnt,
                first_email_open_dt, 
			    last_email_open_dt,
    /*  Email Link Clicked Metrics  */  
                CASE WHEN (emlc.link_click_cnt > 0 OR mirror_page_click_cnt > 0 OR  coalesce(unsbscrb_click_cnt,0) > 0) THEN 1 ELSE 0 end AS email_link_click_ind,  
                /*  The email link click indicator is set to 1 if  an unsubscribe link is clicked, a mirror page link is clicked or any other link within the email is clicked.  NOTE: The unsub and mirror page clicks also have their own counts and indicators. */  
                CASE WHEN emlc.distinct_url_click_cnt > 0 THEN 1 ELSE 0 end AS distinct_url_click_ind,
                coalesce(link_click_cnt,0) AS email_link_click_cnt,
                coalesce(distinct_url_click_cnt,0) AS distinct_url_click_cnt,
                first_link_click_dt,
                last_link_click_dt,
    /*  Email Unsubscribe Metrics */  
                CASE WHEN unsub.unsbscrb_click_cnt > 0 THEN 1 ELSE 0 end AS unsbscrb_ind,
                coalesce(unsbscrb_click_cnt,0) AS unsbscrb_click_cnt, 
                first_unsbscrb_dt, 
                last_unsbscrb_dt, 
 /*  Mirror Page Clicked Metrics  */  
 				coalesce(mplc.mirror_page_click_cnt,0) AS mirror_page_click_cnt,
 				CASE WHEN mirror_page_click_cnt > 0 THEN 1 ELSE 0 end AS mirror_page_click_ind,
    /*  Email Bounce Metrics  */  
                CASE WHEN total_bounce_cnt > 0 THEN 1 ELSE 0 end AS email_bounce_ind,
                CASE WHEN fbl_cnt > 0 THEN 1 ELSE 0 end AS fbl_ind,
                CASE WHEN hard_bounce_cnt > 0 THEN 1 ELSE 0 end AS hard_bounce_ind,
                CASE WHEN soft_bounce_cnt > 0 THEN 1 ELSE 0 end AS soft_bounce_ind,
                  coalesce(fbl_cnt,0) AS fbl_cnt, 
                  coalesce(hard_bounce_cnt,0) AS hard_bounce_cnt, 
                  coalesce(soft_bounce_cnt,0) AS soft_bounce_cnt, 
                  coalesce(total_bounce_cnt,0) AS total_bounce_cnt, 
                  first_bounce_dt, 
                  last_bounce_dt

FROM mktg_ops_vws.bzfc_fact_email_interaction fi
LEFT JOIN mktg_ops_vws.bz_dim_delivery dlvry ON fi.delivery_key = dlvry.delivery_key
LEFT JOIN 
(
	select src_key, src_cd 
	from (
		SELECT src_key, src_cd,Row_Number() Over (PARTITION BY src_cd  ORDER BY  active_ind DESC, src_key DESC) as rn
	   FROM eda.ufds_vws.gmpbzal_dim_src
	) as subqry
   
	where rn=1
)  src ON collate(fi.src_cd::text,'CASE_INSENSITIVE') = collate(src.src_cd::text,'CASE_INSENSITIVE')/*
				Now get the email launch date - first email sent date by source code
*/

LEFT JOIN 
(
	SELECT 
		scampaignsourcecode,
		Min(Cast(tsevent AS DATE)) AS email_launch_dt
	 FROM mktg_ops_vws.bz_adb_nmsbroadlogrcp a
	 LEFT JOIN  mktg_ops_vws.bz_adb_nmsdelivery b ON a.ideliveryid = b.ideliveryid
	 WHERE 
	 	Substring(b.sinternalname,1,4) <> 'FCP_' 
		AND a.istatus = 1 
		AND b.ihidemessageflag = 0  /*  email sent status code  */  
	 	AND b.row_stat_cd <> 'L'  /*remove logically deleted records*/
	 GROUP BY 1
) emld (src_cd, email_launch_dt) ON collate(emld.src_cd::text,'CASE_INSENSITIVE') = collate(fi.src_cd::text,'CASE_INSENSITIVE')

/*
                Now get the email sent/delivery stats
*/

LEFT JOIN 
(
                SELECT 
                    bl.ibroadlogid,
                    r.irecipientid,
                    bicnst_mstr_id, 
                    d.ideliveryid, 
                    CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
                    streatmentsubsourcecode, 
                    'Email Sent' AS email_intrctn_typ_dsc  ,  
                    Sum(CASE WHEN bl.istatus = 1 THEN 1 ELSE 0 end ) AS email_sent_cnt, 
                    Sum(CASE WHEN bl.istatus = 2 THEN 1 ELSE 0 end ) AS email_failed_cnt, 
                    Sum(CASE WHEN bl.istatus = 6 THEN 1 ELSE 0 end ) AS email_pending_cnt, 
                    Count(*) AS email_total_cnt
                FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
                LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
                LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = bl.ideliveryid
                GROUP BY 1,2,3,4,5,6,7
) ems (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, email_sent_cnt, email_failed_cnt, email_pending_cnt, email_total_cnt) 
                                ON ems.ibroadlogid = fi.nk_intrctn_id --and ems.cnst_mstr_id = fi.cnst_mstr_id

/* Now Get the email open summary metrics */
LEFT JOIN 
(
SELECT 
    bl.ibroadlogid,
    r.irecipientid,
    bicnst_mstr_id, 
    d.ideliveryid, 
                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
    streatmentsubsourcecode, 
    email_intrctn_typ_dsc  ,     
    Count(*) AS open_cnt,
    Min(tl.tslog) AS first_email_open_dt,
    Max(tl.tslog) AS last_email_open_dt
FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl ON r.irecipientid = tl.irecipientid AND bl.ibroadlogid = tl.ibroadlogid AND bl.ideliveryid = tl.ideliveryid
LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
WHERE email_intrctn_typ_id = 2
GROUP BY  1,2,3,4,5,6,7
) opn (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, email_open_cnt, first_email_open_dt, last_email_open_dt) 
                ON opn.ibroadlogid = fi.nk_intrctn_id --and opn.cnst_mstr_id = fi.cnst_mstr_id

/* Now Get the email link clicked summary metrics */
LEFT JOIN 
(
SELECT 
    bl.ibroadlogid,
    r.irecipientid,
    bicnst_mstr_id, 
    d.ideliveryid, 
                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
    streatmentsubsourcecode, 
    email_intrctn_typ_dsc,       
    Count(*) AS link_click_total_cnt,
    Count(DISTINCT itrackingurlid) AS distinct_url_click_cnt,
    Min(tl.tslog) AS first_link_click_dt,
    Max(tl.tslog) AS last_link_click_dt
                FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
                LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
                LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl ON r.irecipientid = tl.irecipientid AND bl.ibroadlogid = tl.ibroadlogid AND bl.ideliveryid = tl.ideliveryid
                LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
                LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
                LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
                WHERE email_intrctn_typ_id = 1
                GROUP BY  1,2,3,4,5,6,7
) emlc (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, link_click_cnt,  distinct_url_click_cnt, first_link_click_dt, last_link_click_dt) 
                ON emlc.ibroadlogid = fi.nk_intrctn_id --and emlc.cnst_mstr_id = fi.cnst_mstr_id

/* Now Get the email  unsubscribe stats */
LEFT JOIN 
(
/*  The next select gets the unsubs from the nmstrackingurl table.  This was the original method for tracking unsubs.  We have both in the fact_email_interctn_smry table to make sure we capture all unsubs by campaign/delivery  */  
/*  11/27/17 MTA - Added the outer select to eliminate duplicates from the unsub UNION query  */  
		SELECT 
			ibroadlogid, 
			irecipientid, 
			cnst_mstr_id, 
			ideliveryid, 
			src_cd, 
			sub_src_cd, 
			email_intrctn_typ_dsc, 
			Sum(unsbscrb_click_cnt), 
			Max(unsbscrb_ind), 
			Min(first_unsbscrb_dt), 
			Max(last_unsbscrb_dt)
		FROM 
		(		
				SELECT 
                                bl.ibroadlogid,
                                r.irecipientid,
                                bicnst_mstr_id, 
                                d.ideliveryid, 
                                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
                                streatmentsubsourcecode, 
                                email_intrctn_typ_dsc  ,  
                                Count(*) AS unsbscrb_click_cnt, 
                                Max(r.iblacklist) AS unsbscrb_ind, 
                                Min(tslog) AS first_unsbscrb_dt, 
                                Max(tslog)AS last_unsbscrb_dt
                FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
                LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
                LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl ON r.irecipientid = tl.irecipientid AND bl.ibroadlogid = tl.ibroadlogid AND bl.ideliveryid = tl.ideliveryid
                LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
                LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
                LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
                WHERE email_intrctn_typ_id = 3 AND d.istatus = 5 AND isuccess > 0 /* and r.iblacklist = 1  */  
                GROUP BY  1,2,3,4,5,6,7
                
                UNION ALL
                
/*  The next select get the unsubscribes from the Unsub Web App.  This method replaced the original method for extracting unsubs from the link clicked record in the nmstrackingurl table.  */  
                SELECT 
                                bl.ibroadlogid,
                                r.irecipientid,
                                bicnst_mstr_id, 
                                d.ideliveryid, 
                                CASE WHEN d.scampaignsourcecode IS NOT NULL THEN d.scampaignsourcecode ELSE d.sdeliverycode end AS scampaignsourcecode, 
                                d.streatmentsubsourcecode, 
                                Cast('Opt-out' AS VARCHAR(28)) AS email_intrctn_typ_dsc  ,  
                                Count(*) AS unsbscrb_click_cnt, 
                                Max(a.iBlackListEmail_fr) AS unsbscrb_ind, 
                                                /*Added the explicit CAST to TIMESTAMP(0). The source fields are TIMESTAMP(6). */
                                Min(Cast(Cast(a.tsLastModified AS VARCHAR(19)) AS TIMESTAMP(0))) AS first_unsbscrb_dt,
                                Max(Cast(Cast(a.tsLastModified AS VARCHAR(19)) AS TIMESTAMP(0))) AS last_unsbscrb_dt 
                FROM mktg_ops_tbls.adb_arcprefchangefr a
                LEFT JOIN mktg_ops_tbls.adb_nmsbroadlogrcp bl ON a.iRecipientId = bl.iRecipientId AND a.iDeliveryId = bl.iDeliveryId
                LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
                LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = a.ideliveryid
                GROUP BY  1,2,3,4,5,6,7
		) unsub_union (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, unsbscrb_click_cnt, unsbscrb_ind, first_unsbscrb_dt, last_unsbscrb_dt) 
		GROUP BY 1,2,3,4,5,6,7
	) unsub (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, unsbscrb_click_cnt, unsbscrb_ind, first_unsbscrb_dt, last_unsbscrb_dt) 
                ON unsub.ibroadlogid = fi.nk_intrctn_id --and unsub.cnst_mstr_id = fi.cnst_mstr_id

/* Now Get the mirror page link clicked summary metrics */
LEFT JOIN 
(
SELECT 
    bl.ibroadlogid,
    r.irecipientid,
    bicnst_mstr_id, 
    d.ideliveryid, 
                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
    streatmentsubsourcecode, 
    email_intrctn_typ_dsc,       
    Count(*) AS mirror_page_click_cnt
FROM mktg_ops_tbls.adb_nmsbroadlogrcp bl
LEFT JOIN  mktg_ops_tbls.adb_nmsrecipient r  ON r.irecipientid = bl.irecipientid
LEFT JOIN mktg_ops_tbls.adb_nmstrackinglogrcp tl ON r.irecipientid = tl.irecipientid AND bl.ibroadlogid = tl.ibroadlogid AND bl.ideliveryid = tl.ideliveryid
LEFT JOIN mktg_ops_tbls.adb_nmstrackingurl tu ON tl.iurlid = tu.itrackingurlid
LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON d.ideliveryid = tl.ideliveryid
LEFT JOIN mktg_ops_vws.bz_dim_email_intrctn_typ dc ON tu.itype = dc.email_intrctn_typ_id
WHERE email_intrctn_typ_id = 6
GROUP BY  1,2,3,4,5,6,7
) mplc (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, mirror_page_click_cnt) 
                ON mplc.ibroadlogid = fi.nk_intrctn_id --and mplc.cnst_mstr_id = fi.cnst_mstr_id

/* Now Get the email bounce stats */

LEFT JOIN 
(
SELECT 
    bl.ibroadlogid,
    r.irecipientid,
    bicnst_mstr_id, 
    d.ideliveryid ,
                CASE WHEN scampaignsourcecode IS NOT NULL THEN scampaignsourcecode ELSE sdeliverycode end AS scampaignsourcecode, 
    streatmentsubsourcecode, 
    'Email-Bounce' AS email_intrctn_typ_dsc,
    Sum(CASE WHEN a.iquarantinereason = 8 THEN 1 ELSE 0 end) AS fbl_cnt,
                Sum(CASE WHEN a.iquarantinereason IN (0,1,2,3,4,20) THEN 1 ELSE 0 end) AS hard_bounce_cnt,
                Sum(CASE WHEN a.iquarantinereason IN (5,6,25) THEN 1 ELSE 0 end) AS soft_bounce_cnt,
    Count(*) AS total_bounce_cnt,
   Min(a.tscreated) AS first_bounce_dt,
   Max(a.tscreated) AS last_bounce_dt
FROM  mktg_ops_tbls.adb_nmsaddress a
LEFT JOIN mktg_ops_tbls.adb_nmsbroadlogrcp bl ON collate(a.ideliveryid::text,'CASE_INSENSITIVE') = collate(bl.ideliveryid::text,'CASE_INSENSITIVE') AND collate(a.saddress::text,'CASE_INSENSITIVE') = collate(bl.saddress::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_tbls.adb_nmsrecipient r ON collate(r.irecipientid::text,'CASE_INSENSITIVE') = collate(bl.irecipientid::text,'CASE_INSENSITIVE')
LEFT JOIN mktg_ops_tbls.adb_nmsdelivery d ON collate(d.ideliveryid::text,'CASE_INSENSITIVE') = collate(a.ideliveryid::text,'CASE_INSENSITIVE')
GROUP BY 1,2,3,4,5,6,7
) bnc (ibroadlogid, irecipientid, cnst_mstr_id, ideliveryid, src_cd, sub_src_cd, email_intrctn_typ_dsc, fbl_cnt, hard_bounce_cnt, soft_bounce_cnt, total_bounce_cnt, first_bounce_dt, last_bounce_dt) 
                ON bnc.ibroadlogid = fi.nk_intrctn_id --and bnc.cnst_mstr_id = fi.cnst_mstr_id
WHERE Substring(dlvry.delivery_nm,1,4) <> 'FCP_' AND collate(fi.src_cd::text,'CASE_INSENSITIVE') = 'RSB00000EBSS';



DELETE FROM mktg_ops_tbls.gms_bzfc_fact_email_intrctn_smry
 WHERE   src_cd = 'RSB00000EBSS'; 
    


INSERT INTO mktg_ops_tbls.gms_bzfc_fact_email_intrctn_smry
(               cnst_mstr_id, orig_cnst_mstr_id, nk_recipient_id, recipient_zip_cd,
                                nk_intrctn_id, delivery_key, campaign_key, 
                                src_key, gen_segmnt_key, chan_typ_key,
                                unit_key, nk_ecode, intrctn_status_key, src_cd, subsrc_cd, intrctn_dt_key,
                                intrctn_dt, email_addr, email_to_domain, email_launch_dt, email_sent_ind, email_failed_ind,
                                email_pending_ind, email_sent_cnt, email_failed_cnt, email_pending_cnt,
                                email_total_cnt, email_open_ind, email_open_cnt, first_email_open_dt,
                                last_email_open_dt, email_link_click_ind, distinct_url_click_ind,
                                email_link_click_cnt, distinct_url_click_cnt, first_link_click_dt,
                                last_link_click_dt, unsbscrb_ind, unsbscrb_click_cnt, first_unsbscrb_dt,
                                last_unsbscrb_dt, mirror_page_click_cnt,mirror_page_click_ind,
                                email_bounce_ind, fbl_ind, hard_bounce_ind, soft_bounce_ind, fbl_cnt, hard_bounce_cnt, 
                                soft_bounce_cnt, total_bounce_cnt, first_bounce_dt, last_bounce_dt,
                                last_dntn_gift_dt, email_segmnt_key, email_segmnt_dsc, active_email_segment_ind)
                                
SELECT 
	a.cnst_mstr_id, 
	orig_cnst_mstr_id, 
	nk_recipient_id, 
	recipient_zip_cd,
	a.nk_intrctn_id, 
	delivery_key, campaign_key, src_key,
	gen_segmnt_key , 
	chan_typ_key  AS channel_key, 
	unit_key, nk_ecode, intrctn_status_key, src_cd, subsrc_cd, intrctn_dt_key,
	a.intrctn_dt, email_addr, email_to_domain, email_launch_dt, email_sent_ind, email_failed_ind,
	email_pending_ind, email_sent_cnt, email_failed_cnt, email_pending_cnt,
	email_total_cnt, email_open_ind, email_open_cnt, first_email_open_dt,
	last_email_open_dt, email_link_click_ind, distinct_url_click_ind,
	email_link_click_cnt, distinct_url_click_cnt, first_link_click_dt,
	last_link_click_dt, unsbscrb_ind, unsbscrb_click_cnt, first_unsbscrb_dt,
	last_unsbscrb_dt, mirror_page_click_cnt,mirror_page_click_ind,
	email_bounce_ind, fbl_ind, hard_bounce_ind,
	soft_bounce_ind, fbl_cnt, hard_bounce_cnt, soft_bounce_cnt, total_bounce_cnt,
	first_bounce_dt, last_bounce_dt, 
/*  The fields below this line were derived by the derived table 'b' join 		  */  
	 b.last_dntn_gift_dt,
	 b.email_segmnt_key,
	 b.email_segmnt_dsc, 
	 b.active_email_segment_ind
FROM mktg_stage_tbls.stg_gms_fact_email_intrctn_smry a
LEFT JOIN 
(
	SELECT
		cnst_mstr_id,
		nk_intrctn_id,
		intrctn_dt,
		last_dntn_gift_dt,
	    CASE 
	          WHEN last_dntn_gift_dt IS NULL THEN 4
	          WHEN Add_Months(last_dntn_gift_dt,12) > intrctn_dt AND fr_mission_dntn_cnt > 0 THEN 2
	          WHEN Add_Months(last_dntn_gift_dt,12) > intrctn_dt AND fr_distr_dntn_cnt > 0 AND fr_mission_dntn_cnt = 0 THEN 3
	          WHEN Add_Months(last_dntn_gift_dt,24) > intrctn_dt THEN 8
	          WHEN Add_Months(last_dntn_gift_dt,36) > intrctn_dt THEN 9
	          WHEN Add_Months(last_dntn_gift_dt,36) <= intrctn_dt THEN 10
	          /*when intrctn_dt - last_dntn_gift_dt >= 365 then 1
	          when  intrctn_dt - last_dntn_gift_dt < 365 and fr_mission_dntn_cnt > 0 then 2
	          when  intrctn_dt - last_dntn_gift_dt < 365 and fr_distr_dntn_cnt > 0 and fr_mission_dntn_cnt = 0  then 3
	          when last_dntn_gift_dt is null  then 4*/
	          ELSE 0
	    end AS email_segment_key,
	    CASE  
	          WHEN last_dntn_gift_dt IS NULL THEN 'Prospect Donor'
	          WHEN Add_Months(last_dntn_gift_dt,12) > intrctn_dt AND fr_mission_dntn_cnt > 0 THEN 'Active Email Mission'
	          WHEN Add_Months(last_dntn_gift_dt,12) > intrctn_dt AND fr_distr_dntn_cnt > 0 AND fr_mission_dntn_cnt = 0 THEN 'Active Email Disaster'
	          WHEN Add_Months(last_dntn_gift_dt,24) > intrctn_dt THEN 'Lapsed Email 13 to 24 Months'
	          WHEN Add_Months(last_dntn_gift_dt,36) > intrctn_dt THEN 'Lapsed Email 25 to 36 Months'
	          WHEN Add_Months(last_dntn_gift_dt,36) <= intrctn_dt THEN 'Lapsed Email 37+ Months'
	          /*when intrctn_dt - last_dntn_gift_dt >= 365 then 'Lapsed Email'
	          when  intrctn_dt - last_dntn_gift_dt < 365 and fr_mission_dntn_cnt > 0 then 'Active Email Mission'
	          when  intrctn_dt - last_dntn_gift_dt < 365 and fr_distr_dntn_cnt > 0 and fr_mission_dntn_cnt = 0  then 'Active Email Disaster'
	          when last_dntn_gift_dt is null  then 'Prospect Donor'*/
	    end AS email_segment_dsc,
		CASE WHEN  intrctn_dt - last_dntn_gift_dt < 365 THEN 1 ELSE 0 end AS active_email_segment_ind
	FROM
	(
		SELECT 
			 a.cnst_mstr_id, 
			 a.nk_intrctn_id,
			 a.intrctn_dt,
			Cast( Max(b.dntn_gift_dt) AS DATE ) AS dntn_gift_dt,
			Cast( Sum (CASE WHEN intrctn_dt - dntn_gift_dt < 365 AND fr_distr_dntn_ind = 1 THEN 1 ELSE 0 end) AS INT) AS fr_distr_dntn_cnt,
			Cast(Sum (CASE WHEN intrctn_dt - dntn_gift_dt < 365 AND fr_distr_dntn_ind = 0 THEN 1 ELSE 0 end) AS INT) AS fr_mission_dntn_cnt
		FROM mktg_stage_tbls.stg_gms_fact_email_intrctn_smry a		 
		LEFT JOIN mktg_ops_vws.gms_arc_fr_txn b ON a.cnst_mstr_id = b.cnst_mstr_id
		WHERE b.dntn_gift_dt < a.intrctn_dt
		GROUP BY 1,2,3
		
		UNION ALL
		
			SELECT 
			 a.cnst_mstr_id, 
			 a.nk_intrctn_id,
			 a.intrctn_dt,
			 Cast(NULL AS DATE) AS dntn_gift_dt,
			 Cast(0 AS INT) AS fr_distr_dntn_cnt,
			 Cast(0 AS INT) AS fr_mission_dntn_cnt
		FROM mktg_stage_tbls.stg_gms_fact_email_intrctn_smry a	
		WHERE src_cd = 'RSB00000EBSS' 
	) txn (cnst_mstr_id,nk_intrctn_id, intrctn_dt, last_dntn_gift_dt, fr_distr_dntn_cnt, fr_mission_dntn_cnt)
	QUALIFY Row_Number() Over (PARTITION BY cnst_mstr_id,nk_intrctn_id ORDER BY  last_dntn_gift_dt DESC) = 1 /*  12/06/17 MTA changed order by to last_dntn_gift_dt from intrctn_dt  */  
) b (cnst_mstr_id,nk_intrctn_id, intrctn_dt, last_dntn_gift_dt,email_segmnt_key,email_segmnt_dsc, active_email_segment_ind) ON a.cnst_mstr_id = b.cnst_mstr_id AND a.nk_intrctn_id = b.nk_intrctn_id; 

    

 
truncate table mktg_stage_tbls.stg_gms_fact_email_intrctn_smry;
    
    
    
    
    
    

		---audit_log update------
        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE mods_bi.etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.gms_bzfc_fact_email_intrctn_smry) as INTEGER)
        WHERE proc_name = 'ld_gms_bzfc_fact_email_intrctn_smry' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_gms_bzfc_fact_email_intrctn_smry: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_gms_bzfc_fact_email_intrctn_smry', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
