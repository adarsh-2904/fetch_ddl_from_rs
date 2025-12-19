CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_bzfc_adb_fact_donation()
 LANGUAGE plpgsql
AS $$
	
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 04/13/2017
Purpose: The purpose of this macro is to load an instantiated table that combines FR Gift Transactions from mktg_ops_vws.arc_fr_txn with 
                                                                the instantiated interaction table and other Adobe campaign reference tables to set the derived campaign attribution attributes.
                                                               The instantiated table improves query performance in the CE reporting universe and makes it much easier for analysts to analyze
                                                                direct and indirect / targeted and non-targeted campaign attribution attributes.

Modified by Michael Andrien
Modified Date 5/31/2017
Purpose:  Added email segmentation and active email segemtation attributes to the Targeted email section. 
                                                                Added rpt_cell_cd_key to the targeted and indirect direct mail sections so we can use dim_rpt_cell_cd as a shared dimesion across
                                                                Aprimo and Adobe interactions and fact donation tables (fact_donation, adb_fact_donation, fact_interaction_all and fact_dmail_interactions)

Modified by Michael Andrien
Modified Date 6/06/2017
Purpose:  Added the  Qualify statement to the end of the query to eliminate duplicate rows
                                                                QUALIFY ROW_NUMBER() OVER (PARTITION BY txn.trans_id ORDER BY   dlv.sent_noseed_cnt DESC) = 1 -- 
                                                                This QUALIFY statement ensures that we attribute only one interaction row to a gift transaction and that we select the interaction with the 
                                                                highest noseed sent count from the delivery.  Some campaigns have more than one delivery with the same source code, which was causing dups in the fact table.

Modified by Michael Andrien
Modified Date 6/08/2017
Purpose:  Added intrctn_rpt_cell_cd_key

Modified by Michael Andrien
Modified Date 6/16/2017
Purpose:  Added file cd and motivation code attributes for direct mail targeted direct and indirect sections as well as the summary interaction sections.  Also,
                                                                added email segement key to email direct and indirect sections and interaction summary section.

Modified by Michael Andrien
Modified Date 6/26/2017
Purpose: Added delivery name <> 'FCP constraint to dim_delivery join and added mktg_ops_vws.rr_rqq_rql_file_xref  to derive the file_cd for non-targeted dircect mail.  Added logic for email launch date on non-tgt emails.

Modified by Michael Andrien
Modified Date 7/12/2017
Purpose: Fixed logic in emld join to exclude 'FCP deliveries the 6/26 update had = 'FCP' rather than <> 'FCP'.

Modified by Michael Andrien
Modified Date 9/02/2017
Purpose:  Changed intrctn_dt date logic to reference emld.email_launch_dt.  Also changed            logic for non-targeted section of email launch date;
                                                                from When - intrctn_atrbtn_typ_cd = 'NTDM' or intrctn_atrbtn_typ_cd = 'NTEM'  to when  intrctn_atrbtn_typ_cd = 'NTEM' then emld.email_launch_dt  

Modified by Michael Andrien
Modified Date 9/05/2017
Purpose:  Updated the logic for the fact_donation_intrctn_dt attribute in the summary attributes section to correct issues with the non-targeted and indirect email interactions.

Modified by Majeed Mohammad
Modified Date 9/19/2017
Purpose:  Updated the macro logic to use TEMP table for better macro performance. 

Modified by Michael Andrien
Modified Date 10/20/2017
Purpose:  Added alt_trans_id from the TXN table.

Modified by Michael Andrien
Modified Date 11/30/2017
Purpose: Added where cnst_mstr_id <> 0  constraint to insert into  mktg_stage_tbls.bzfc_fact_email_interaction_tmp select * from mktg_ops_vws.bzfc_fact_email_interaction where cnst_mstr_id <> 0 ; 
                                                                statements to address skewing issue.  Also, dropped and recreated mktg_stage_tbls.are_fr_txn_tmp to change the UPI to trans_id to aviod skewing on the table copy.

Modified by Michael Andrien
Modified Date 02/19/2018
Purpose: Added  referral_source, referral_medium, referral_campaign and referral_device from the Google Analytics txn table (bz_google_analytics_txn).  The MODS Market Analysis team requested to 
                                                                have these attributes added to the donation table to allow them to identify and exclude gifts that originated from 'Organic' search (Google Analyitics Medium attribute) from the indirect attribution.  I'm 
                                                                starting by adding the attributes to the txn section of the donation record.  We'll add rules to the email indirect attribution sections after reviewing the data.

 Modified by Michael Andrien
Modified Date 04/03/2018
Purpose: Added logic the the email queries to included the Giving Day source codes 'ADA' and 'ADC'

Modified by Michael Andrien
Modified Date: 6/8/2018
Purpose:  Added 'and coalesce(exclude_rptng_ind,0) = 0 ' to the email launch date query to eliminate test deliveries from the reporting results.

Modified by Michael Andrien
Modified Date: 6/8/2018
Purpose:  Added fr_trans_cnst_zip_cd

Modified by Michael Andrien
Modified Date: 12/4/2018
Purpose:  Added subsrc_cd to the arc_fr_txn to bz_dim_delivery join.  

Modified by Majeed Mohammad
Modified Date: 12/20/2018
Purpose:  Changed all the comments from -- to the standard form 

Modified by Michael Andrien
Modified Date: 12/30/2018
Purpose: Added trans_fund_cd and trans_fund_dsc

Modified by Michael Andrien
Modified Date: 02/07/2019
Purpose: Added the trans_email_segmnt_key attribute to the table.  We pull this from the gift transaction table (arc_fr_txn).  This attribute reflects the email segment assignment at the gift level.  
                                                                The email segment is determined by evaluating the gift details from the prior gift to the current gift.  This logic is 
                                                found in the mktg_ops_tbls.ld_bz_arc_fr_txn_segmnt macro.

Modified by Michael Andrien
Modified Date: 02/12/2019
Purpose:  Modified the emsmry join which links the txn to to the email interaction summary table to get the email segment.code.  The join was modified to join the tables either through the master id or the email address  or the address locator key.  
                                                                We expanded the join from having just the src_cd and cnst_mstr_id because we found a high percentage of time the master id from the interaction record is different from the transaction master id but the email address or address of the 
                                                                two master id accounts is the same.  We want to link the TXN with the interaction and consider this a targeted, direct attribution.  Also, the joins were expended because the email segment code was getting set to Unknown in more the 50% of the records.
                                                                ( 
                                                                select a.cnst_mstr_id, src_cd, em_cnst_email, dm_locator_addr_key
                                                                from mktg_ops_vws.bzfc_fact_email_intrctn_smry_tmp a
                                                                left join mktg_ops_vws.cnst_cdi_smry_fr_prfr b on a.cnst_mstr_id = b.cnst_mstr_id 
                ) emsmry (cnst_mstr_id, src_cd, email_segmnt_key, em_cnst_email, dm_locator_addr_key) on emsmry.src_cd = txn.gift_src_cd and (frp.em_cnst_email = emsmry.em_cnst_email or frp.dm_locator_addr_key = emsmry.dm_locator_addr_key)

Modified by Michael Andrien and Majeed
Modified Date: 02/19/2019
Purpose: Created the  mktg_stage_tbls.bzfc_fiemd_in_tmp  and  mktg_stage_tbls.bzfc_fiemd_out_tmp stage tables to help optimize the email interaction - direct attribution queries and fiemd join in the main insert query.

Modified By:            Michael Andrien
Modified Date:         6/21/2019
Purpose: Updated the mktg_ops_vws.rr_rqq_rql_file_xref  join attribute from aprm_src_cd to src_cd to correspond with the underlying table change.

Modified By:            Michael Andrien
Modified Date:         05/07/2020
Purpose: Updated the non-targeted direct join logic for the interaction date details to reference intrctn_dt attribute from the mktg_ops_vws.dim_src_2_intrctn_brdg view by joining txn.campgn_src_key to the src_key in the bridge table.
We then use the intrctn_dt from the srib join to get the intrctn date key from the join below.  Also, updated the bz_google_analytics_txn join to use the bz_digital_analytics_txn view, which combines the Google and Adobe Analytics txn data.
                --  left join dw_common_vws.dim_calendar cal on cal.calendar_dt = srib.intrctn_dt
                
Modified By:            Michael Andrien
Modified Date:         05/11/2020
Purpose:  Corrected the frp join below to reference gms_cnst_cdi_smry_fr_prfr rather than the old DDCOE join (cnst_cdi_smry_fr_prfr).  Also, updated the 'ga' join  to join on txn.rco_dntn_id rather than txn.alt_trans_id.
                                from
                                mktg_stage_tbls.gms_arc_fr_txn_tmp as txn
                                left join mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr frp on txn.cnst_mstr_id = frp.cnst_mstr_id 
                                left join mktg_ops_vws.bz_digital_analytics_txn ga on txn.rco_dntn_id = ga.prch_id
                                
Modified By:            Michael Andrien - coded by Greg Seaberg
Modified Date:         05/27/2020
Purpose:  Changed the dmail interaction joins to dmail_intrctn_norm
                                Added drop date & drop date key for DM acquisition campaigns
                                Added drop number for DM acquisition campaigns
                                Updated interaction date key for INEM
                                Added online channel code to identify initial vs. recurring sustaining donations
                                Excluded PG campaigns from consideration for email attribution 
                                Added exclusions on last touch channel to remove search transactions from consideration for indirect email / DM attribution 
								
Modified By:            Michael Andrien
Modified Date:         06/25/2020
Purpose:  Modified the logic for 'NTDM' then txn.gift_src_cd - the old code had this set to NULL
  case when intrctn_atrbtn_typ_cd = 'INEM' then   NULL
                                                   when intrctn_atrbtn_typ_cd = 'INDM' then  indrct_dm_motivtn_cd
                                                   when intrctn_atrbtn_typ_cd = 'NTDM' then txn.gift_src_cd
												   when intrctn_atrbtn_typ_cd = 'NTEM' then NULL
                                                   when intrctn_atrbtn_typ_cd = 'TDDM' then tgt_dm_motivtn_cd                                         
                                                   when intrctn_atrbtn_typ_cd = 'TDEM' then NULL
                                                   else NULL
                end 
                as  intrctn_motivtn_cd,
				
	Modified by Michael Andrien
	Modified Date: 04/21/2022
	Purpose: Added trans_fund_key to the gms_bzfc_adb_fact_donation table.
	
	Modified by Michael Andrien
	Modified Date: 05/16/2022
	Purpose: 	Modified the where clauses on the 3 stage table load processes and the gms_bzfc_adb_fact_donation DELETE process to limit the loads and delete to gift transaction dates >= the prior 12 months whereas the original load processes
	included gift transactions from 07/01/2016' (dntn_gift_dt >= '07/01/2016').  This changes the load process from the truncate and reload process to an incremental load process. We'll always delete and reload 12 months worth of transactional data.

	Modified by Michael Andrien
	Modified Date: 06/22/2022
	Purpose: 	
		Modified the join logic:
			Changed the join 'on' logic for the  rr_rqq_rql_file_xref xref  view join from to join on the txn.campgn_src_cd rather than the txn.gift_src_cd
			Added 'and txn.campgn.src_cd = fi.src_cd' to the mktg_ops_vws.bzfc_fact_dmail_intrctn_norm fi  join in the Direct Mail and PG Interactions join section
		Modified the date offsets for the temp tables and the main table load qualifier
			Changed the date offset in the mktg_stage_tbls.gms_arc_fr_txn_tmp load from 12 months to 13 months
			Changed the date offset in the  mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp tqable load from 13 months to 14 months
			Changed the date offset in the mktg_ops_tbls.gms_bzfc_adb_fact_donation load from 11 months to 12 months

	Modified by: Greg & Majeed Mohammad
	Modified Date: 09/21/2022
	Purpose: 	 Add logic to integrate indirect display viewthrough (IDVT) to attribution logic by joining to mktg_ops_vws.actvty_vwthrgh (View through table)     

	Modified by: Majeed Mohammad
	Modified Date: 08/01/2023
	Purpose: 	Converted the join to the bz_dim_delivery into a subquery DLV. The previous join was returning 1:M and was causing the spool error. The original query had a qualify at the end of the INSERT to partition on giftran_key but sorted by dlv.sent_noseed_cnt descending. So, i add this in the subquery to partition on src_cd and subsrc_cd and sorted by sent_noseed_cnt 
	
		Modified by: Majeed Mohammad
	Modified Date: 08/02/2023
	Purpose: 	Updated the subquery for DLV to add join to the TXN (alias txn1) to ensure the same joins were used for txn table. The join conditions and filters are exactly same as the earlier join 
------------------------------------------------------------------------------------------------------------------------------------ */	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
	v_deleted_count INT;
	--v_updated_count INT;
	v_inserted_count INT;
	

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_bzfc_adb_fact_donation', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN 


/*09/19/17: Majeed: Temp tables deleted and loaded */
TRUNCATE TABLE mktg_stage_tbls.gms_arc_fr_txn_tmp;

TRUNCATE TABLE mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp;

TRUNCATE TABLE mktg_stage_tbls.bzfc_fiemd_out_tmp;


 /* Run inserts into mktg_stage_stg to help optimize the 'targeted email attribution joins.  We include 3 inserts into the mktg_stage_tbls.bzfc_fiemd_out_tmp that join the txn to email interactions in different ways.  One on master id, one on email and one on mailing address
this helps to resolve issues where we interacted with someone that has multiple master ids and the transaction is linked to a different master id, so the txn to interaction jion on master id does not locate the interaction.  */

------------------------------------------------------------------------------------------------------------
-----------------------------------  INSERT 1   ------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

insert into mktg_stage_tbls.gms_arc_fr_txn_tmp select * from mktg_ops_tbls.gms_arc_fr_txn where dntn_gift_dt >= add_months(current_date,-13);  

------------------------------------------------------------------------------------------------------------
-----------------------------------  INSERT 2   ------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

insert into mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp
    select a.cnst_mstr_id, a.src_cd, a.subsrc_cd, b.em_cnst_email, b.dm_locator_addr_key, c.email_segmnt_key, a.src_key, a.delivery_key, a.campaign_key, a.recipient_key, a.intrctn_dt, c.email_launch_dt,active_email_segment_ind
   from mktg_ops_vws.bzfc_fact_email_interaction  a
    left join mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry c on a.cnst_mstr_id = c.cnst_mstr_id and a.src_cd = c.src_cd and a.intrctn_dt = c.intrctn_dt and a.delivery_key = c.delivery_key
    left join mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr b on a.cnst_mstr_id = b.cnst_mstr_id 
    where a.nk_intrctn_status_dsc = 'Sent' and  c.intrctn_status_key = 1 and a.intrctn_dt >= add_months(current_date,-14); 

------------------------------------------------------------------------------------------------------------
-----------------------------------  INSERT 3   ------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

insert into mktg_stage_tbls.bzfc_fiemd_out_tmp
select  txn.cnst_mstr_id,fiemd.cnst_mstr_id, fiemd.src_cd, fiemd.subsrc_cd, frp.em_cnst_email, frp.dm_locator_addr_key, fiemd.email_segmnt_key, fiemd.src_key, fiemd.delivery_key, fiemd.campaign_key, fiemd.recipient_key, fiemd.intrctn_dt, fiemd.email_launch_dt
from mktg_stage_tbls.gms_arc_fr_txn_tmp as txn
left join mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr frp on txn.cnst_mstr_id = frp.cnst_mstr_id 
left join mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp fiemd
                                on  txn.gift_src_key = fiemd.src_key 
            and txn.gift_sub_src_cd =  fiemd.subsrc_cd 
            and  (substring(txn.gift_src_cd,1,2) = 'RS' or substring(txn.gift_src_cd,1,3) in ('ADA','ADC')) 
            and txn.gift_src_cd  not in  ( 'RSG000000000','RSG00000E001','RSG00000E000'  ) /*  Include the sub-source code in the join for email campaigns  */
            where  (txn.cnst_mstr_id =  fiemd.cnst_mstr_id ) and txn.dntn_gift_dt >= add_months(current_date,-12); 

------------------------------------------------------------------------------------------------------------
-----------------------------------  INSERT 4   ------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

insert into mktg_stage_tbls.bzfc_fiemd_out_tmp
SELECT
    txn.cnst_mstr_id,
    fiemd.cnst_mstr_id,
    fiemd.src_cd,
    fiemd.subsrc_cd,
    frp_em_cnst_email,
    frp.dm_locator_addr_key,
    fiemd.email_segmnt_key,
    fiemd.src_key,
    fiemd.delivery_key,
    fiemd.campaign_key,
    fiemd.recipient_key,
    fiemd.intrctn_dt,
    fiemd.email_launch_dt
FROM mktg_stage_tbls.gms_arc_fr_txn_tmp AS txn
LEFT JOIN (select em_cnst_email::varchar as frp_em_cnst_email,cnst_mstr_id,dm_locator_addr_key  from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr)frp 
    ON txn.cnst_mstr_id = frp.cnst_mstr_id 
LEFT JOIN (select *,em_email_addr::varchar as fiemd_em_email_addr from mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp)fiemd 
    ON txn.gift_src_cd = fiemd.src_cd 
    AND txn.gift_sub_src_cd = fiemd.subsrc_cd 
    AND (LEFT(txn.gift_src_cd, 2) = 'RS' OR LEFT(txn.gift_src_cd, 3) IN ('ADA', 'ADC')) 
    AND txn.gift_src_cd NOT IN ('RSG000000000', 'RSG00000E001', 'RSG00000E000') 
    and frp_em_cnst_email is not null and fiemd_em_email_addr is not null
WHERE 
    txn.cnst_mstr_id <> fiemd.cnst_mstr_id 
    AND collate(coalesce(trim(frp_em_cnst_email),''),'cs') = collate(coalesce(TRIM(fiemd_em_email_addr),''),'cs')--cs:case-sensitive
    AND dntn_gift_dt >= DATEADD(month, -12, CURRENT_DATE);

------------------------------------------------------------------------------------------------------------
-----------------------------------  INSERT 5   ------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

insert into mktg_stage_tbls.bzfc_fiemd_out_tmp
SELECT
    txn.cnst_mstr_id,
    fiemd.cnst_mstr_id,
    fiemd.src_cd,
    fiemd.subsrc_cd,
    frp.em_cnst_email,
    frp.dm_locator_addr_key,
    fiemd.email_segmnt_key,
    fiemd.src_key,
    fiemd.delivery_key,
    fiemd.campaign_key,
    fiemd.recipient_key,
    fiemd.intrctn_dt,
    fiemd.email_launch_dt
FROM mktg_stage_tbls.gms_arc_fr_txn_tmp AS txn
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr AS frp 
    ON txn.cnst_mstr_id = frp.cnst_mstr_id 
LEFT JOIN mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp AS fiemd
    ON txn.gift_src_cd = fiemd.src_cd 
    AND txn.gift_sub_src_cd = fiemd.subsrc_cd 
    AND (LEFT(txn.gift_src_cd, 2) = 'RS' OR LEFT(txn.gift_src_cd, 3) IN ('ADA', 'ADC')) 
    AND txn.gift_src_cd NOT IN ('RSG000000000', 'RSG00000E001', 'RSG00000E000') /* Include the sub-source code in the join for email campaigns */
WHERE (txn.cnst_mstr_id <> fiemd.cnst_mstr_id 
    AND frp.dm_locator_addr_key = fiemd.dm_locator_addr_key)
    AND dntn_gift_dt >= DATEADD(month, -12, CURRENT_DATE);


------------------------------------------------------------------------------------------------------------
-----------------------------------  INSERT 6   ------------------------------------------------------------
----------------------/*  Now truncate and reload the mktg_ops_tbls.bzfc_adb_fact_donation table */
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
DELETE FROM mktg_ops_tbls.gms_bzfc_adb_fact_donation where dntn_gift_dt >=   add_months(current_date,-12);

-- Capture number of deleted rows
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
INSERT INTO mktg_ops_tbls.gms_bzfc_adb_fact_donation
with direct_fields as 
(
			SELECT
			  -- txn table fields
			  txn.alt_trans_id AS txn_alt_trans_id,
			  txn.arc_fr_txn_seq_num AS txn_arc_fr_txn_seq_num,
			  txn.campgn_src_cd AS txn_campgn_src_cd,
			  txn.campgn_src_key AS txn_campgn_src_key,
			  txn.channel_typ_key AS txn_channel_typ_key,
			  txn.cnst_mstr_id AS txn_cnst_mstr_id,
			  txn.fr_affl_unit_key AS txn_fr_affl_unit_key,
			  txn.fr_pmt_amt AS txn_fr_pmt_amt,
			  txn.gift_src_cd AS txn_gift_src_cd,
			  txn.gift_src_key AS txn_gift_src_key,
			  txn.gift_sub_src_cd AS txn_gift_sub_src_cd,
			  txn.giftran_key AS txn_giftran_key,
			  txn.dntn_gift_dt AS txn_dntn_gift_dt,
			  txn.dntn_gift_dt_key AS txn_dntn_gift_dt_key,
			  txn.orig_deposit_dt AS txn_orig_deposit_dt,
			  txn.orig_deposit_dt_key AS txn_orig_deposit_dt_key,
			  txn.deposit_dt AS txn_deposit_dt,
			  txn.deposit_dt_key AS txn_deposit_dt_key,
			  txn.recurring_ind AS txn_recurring_ind,
			  txn.recurng_start_dt AS txn_recurng_start_dt,
			  txn.online_channel_cd AS txn_online_channel_cd,
			  txn.soft_credit_ind AS txn_soft_credit_ind,
			  CAST(NULL AS VARCHAR(10)) AS txn_fr_trans_cnst_zip_cd,
			  txn.trans_fund_key AS txn_trans_fund_key,
			  txn.trans_fund_cd AS txn_trans_fund_cd,
			  txn.trans_fund_dsc AS txn_trans_fund_dsc,
			  txn.email_segmnt_key AS txn_email_segmnt_key,
			
			  -- fi table fields
			  fi.campaign_key AS fi_campaign_key,
			  fi.cnst_mstr_id AS fi_cnst_mstr_id,
			  fi.delivery_key AS fi_delivery_key,
			  fi.file_cd AS fi_file_cd,
			  fi.motivtn_cd AS fi_motivtn_cd,
			  fi.recipient_key AS fi_recipient_key,
			  fi.rpt_cell_cd_key AS fi_rpt_cell_cd_key,
			  fi.src_cd AS fi_src_cd,
			  fi.src_key AS fi_src_key,
			  fi.subsrc_cd AS fi_subsrc_cd,
			  fi.mail_drop_num AS fi_mail_drop_num,
			  fi.treatmnt_key AS fi_treatmnt_key,
			  fi.intrctn_dt as fi_intrctn_dt,
			
			  -- fiemd table fields
			  fiemd.campaign_key AS fiemd_campaign_key,
			  fiemd.cnst_mstr_id AS fiemd_cnst_mstr_id,
			  fiemd.delivery_key AS fiemd_delivery_key,
			  fiemd.email_launch_dt AS fiemd_email_launch_dt,
			  fiemd.email_segmnt_key AS fiemd_email_segmnt_key,
			  fiemd.src_cd AS fiemd_src_cd,
			  fiemd.src_key AS fiemd_src_key,
			  fiemd.subsrc_cd AS fiemd_subsrc_cd,
			  fiemd.recipient_key AS fiemd_recipient_key,
			
			  -- fiem table fields
			  fiem.cnst_mstr_id AS fiem_cnst_mstr_id,
			  fiem.recipient_key AS fiem_recipient_key,
			  fiem.email_launch_dt AS fiem_email_launch_dt,
			  fiem.email_segmnt_key AS fiem_email_segmnt_key,
			  fiem.indrct_em_attrbtn_cnt AS fiem_indrct_em_attrbtn_cnt,
			  fiem.intrctn_dt AS fiem_intrctn_dt,
			  fiem.intrctn_dt_key AS fiem_intrctn_dt_key,
			  fiem.src_cd AS fiem_src_cd,
			  fiem.src_key as fiem_src_key,
			  fiem.subsrc_cd AS fiem_subsrc_cd,
			  fiem.campaign_key AS fiem_campaign_key,
			  fiem.delivery_key AS fiem_delivery_key,
			  fiem.fund_key AS fiem_fund_key,
			  coalesce(fiem.intrctn_dt_key,0) as fiem_indrct_em_dt_key,
			
			  -- fidm table fields
			  fidm.cnst_mstr_id AS fidm_cnst_mstr_id,
			  fidm.recipient_key AS fidm_recipient_key,
			  fidm.campaign_key AS fidm_campaign_key,
			  fidm.drop_dt AS fidm_drop_dt,
			  fidm.drop_dt_key AS fidm_drop_dt_key,
			  fidm.file_cd AS fidm_file_cd,
			  fidm.fund_key AS fidm_fund_key,
			  fidm.indrct_dm_attrbtn_cnt AS fidm_indrct_dm_attrbtn_cnt,
			  fidm.indrct_rpt_cell_cd_key AS fidm_indrct_rpt_cell_cd_key,
			  fidm.intrctn_dt AS fidm_intrctn_dt,
			  fidm.intrctn_dt_key AS fidm_intrctn_dt_key,
			  fidm.mail_drop_num AS fidm_mail_drop_num,
			  fidm.motivtn_cd AS fidm_motivtn_cd,
			  fidm.src_cd AS fidm_src_cd,
			  fidm.src_key as fidm_src_key,
			  fidm.subsrc_cd AS fidm_subsrc_cd,
			  fidm.treatmnt_key AS fidm_treatmnt_key,
			  fidm.delivery_key AS fidm_delivery_key,
			
			  -- dlv table
			  dlv.delivery_key AS dlv_delivery_key,
			
			  -- cmpg table
			  cmpg.campgn_key AS cmpg_campgn_key,
			
			  -- sc_fnd table
			  sc_fnd.fund_key AS sc_fnd_fund_key,
			
			  -- srib table
			  srib.intrctn_dt AS srib_intrctn_dt,
			
			  -- cal table
			  cal.calendar_key AS cal_calendar_key,
			
			  -- scdd table
			  scdd.drop_dt AS scdd_drop_dt,
			  scdd.mail_drop_num AS scdd_mail_drop_num,
			
			  -- dd_cal table
			  dd_cal.calendar_key AS dd_cal_calendar_key,
			
			  -- fi_sc_fnd table
			  fi_sc_fnd.fund_key AS fi_sc_fnd_fund_key,
			
			  -- fi_cal table
			  fi_cal.calendar_dt AS fi_cal_calendar_dt,
			  fi_cal.calendar_key AS fi_cal_calendar_key,
			
			  -- fin_cal table
			  fin_cal.calendar_dt AS fin_cal_calendar_dt,
			  fin_cal.calendar_key AS fin_cal_calendar_key,
			
			  -- fiemd_sc_fnd table
			  fiemd_sc_fnd.fund_key AS fiemd_sc_fnd_fund_key,
			
			  -- fiemsd table
			  fiemsd.active_email_segment_ind AS fiemsd_active_email_segment_ind,
			
			  -- fiemd_cal table
			  fiemd_cal.calendar_dt AS fiemd_cal_calendar_dt,
			  fiemd_cal.calendar_key AS fiemd_cal_calendar_key,
			  
			  --first_donat table
			  first_donat.first_dntn_gift_dt as first_donat_first_dntn_gift_dt,
			  
			
			  -- emld table
			  emld.email_launch_dt AS emld_email_launch_dt,
			
			  -- ga table
			  ga.lst_touch_chnl AS ga_lst_touch_chnl,
			  ga.source1 AS ga_source1,
			  ga.medium1 AS ga_medium1,
			  ga.cid_dsc AS ga_cid_dsc,
			  ga.device AS ga_device,
			
			  -- vt table
			  vt.vwthrgh_rev AS vt_vwthrgh_rev,
			  
			  --vt_cal table
			  vt_cal.calendar_key as vt_cal_calendar_key,
			  
			  --xref table
			  xref.file_cd as xref_file_cd
			FROM
			
			/* Begin Join Definitions */
			
			/* We're using the Marketing FR TXN (FR Gift Transactions) as the driving table to derive the direct and indirect attribution interaction ids */
			mktg_stage_tbls.gms_arc_fr_txn_tmp as txn
			left join mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr frp on txn.cnst_mstr_id = frp.cnst_mstr_id 
			left join mktg_ops_vws.bz_digital_analytics_txn ga on txn.rco_dntn_id = ga.prch_id             /* rco_dntn_id now includes ATG order ID for transactions prior to 8/10/2018    */
			left join mktg_ops_vws.rr_rqq_rql_file_xref xref on xref.src_cd = txn.campgn_src_cd and xref.segmnt_cd = substring(txn.gift_src_cd,10,3)
			
			left join
			               (SELECT
								src_cd,
								MIN(delivery_start_dt)
							FROM mktg_ops_vws.bz_dim_delivery
							WHERE delivery_status_id = 5 
							  AND SUBSTRING(delivery_nm, 1, 3) <> 'FCP'
							  AND COALESCE(exclude_rptng_ind, 0) = 0
							GROUP BY src_cd) emld (src_cd, email_launch_dt) on txn.gift_src_cd = emld.src_cd
			                /*
			                (select
			                src_cd,
			                delivery_key,
			                email_launch_dt
			                from mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry where src_cd is not null and delivery_key is not null and email_launch_dt is not null
			                group by 1,2,3) emld (src_cd, delivery_key, email_launch_dt)
			                */
			left join (select dlv.src_cd,dlv.subsrc_cd, dlv.campgn_key, dlv.delivery_key, sent_noseed_cnt,dlv.delivery_nm from mktg_ops_vws.bz_dim_delivery  dlv 
								  inner join mktg_stage_tbls.gms_arc_fr_txn_tmp as txn1 on 
								  txn1.campgn_src_cd = dlv.src_cd  and  txn1.gift_sub_src_cd = dlv.subsrc_cd  and  delivery_status_id = 5 
								  and  (substring(txn1.campgn_src_cd,1,2) = 'RS' or substring(txn1.campgn_src_cd,1,3) in ('ADA','ADC')) and substring(dlv.delivery_nm,1,3) <> 'FCP' 
								  and txn1.gift_src_cd  not in  ( 'RSG000000000','RSG00000E001','RSG00000E000'  )
									AND txn1.gift_src_cd IS NOT NULL	
									/*  Include the sub-source code in the join for email campaigns -- delivery join for direct/non-targeted attribution */
								QUALIFY ROW_NUMBER() OVER (PARTITION BY dlv.src_cd, dlv.subsrc_cd ORDER BY   dlv.sent_noseed_cnt DESC ) = 1)   dlv  
					on txn.campgn_src_cd = dlv.src_cd  and  txn.gift_sub_src_cd = dlv.subsrc_cd  
			
			left join mktg_ops_vws.bz_dim_campgn  cmpg on cmpg.campgn_key = dlv.campgn_key /*  segmentation join for direct/non-targeted attribution */
			left join mktg_ops_vws.gmpbzal_dim_src  sc on txn.campgn_src_key = sc.src_key --and txn.dntn_gift_dt between cast(sc.row_eff_from_ts as date format 'mm/dd/yyyy') and cast(sc.row_eff_to_ts as date format 'mm/dd/yyyy')   /*  source code  join for direct/non-targeted attribution */
			left join mktg_ops_vws.dim_src_2_intrctn_brdg srib on srib.src_key = txn.campgn_src_key
			left join mktg_ops_vws.gmpbzal_dim_fund  sc_fnd on sc.fund_cd = sc_fnd.fund_cd   /*  source code fund code  join for direct/targeted email Interaction' */
			left join (SELECT
							src_cd, 
							MIN(intrctn_dt)
						FROM mktg_ops_vws.bzfc_fact_dmail_interaction
						GROUP BY src_cd) as scmd (src_cd, mail_dt) on scmd.src_cd = txn.campgn_src_cd
						left join (select src_cd, motivtn_cd, intrctn_dt, mail_drop_num from mktg_ops_vws.bzfc_fact_dmail_intrctn_norm group by 1,2,3,4) as scdd (src_cd, motivtn_cd, drop_dt, mail_drop_num) on scdd.motivtn_cd = txn.gift_src_cd
			/*  The next joins are for Direct/Targeted  Email Interactions  */
			left join mktg_stage_tbls.bzfc_fiemd_out_tmp fiemd on txn.cnst_mstr_id = fiemd.cnst_mstr_id and  txn.campgn_src_key = fiemd.src_key and txn.gift_sub_src_cd =  fiemd.subsrc_cd and  (substring(txn.campgn_src_cd,1,2) = 'RS' or substring(txn.campgn_src_cd,1,3) in ('ADA','ADC')) 
			                                                                and txn.gift_src_cd  not in  ( 'RSG000000000','RSG00000E001','RSG00000E000'  ) 
																			AND txn.gift_src_cd IS NOT NULL--Hitansu: added for null condition check
			
			
			left join mktg_ops_vws.gmpbzal_dim_src  fiemd_sc on fiemd_sc.src_key=fiemd.src_key --and txn.dntn_gift_dt between cast(fiemd_sc.row_eff_from_ts as date format 'mm/dd/yyyy') and cast(fiemd_sc.row_eff_to_ts as date format 'mm/dd/yyyy')    /*  source code  join for direct/targeted email interactions */
			left join mktg_ops_vws.gmpbzal_dim_fund  fiemd_sc_fnd on fiemd_sc.fund_cd = fiemd_sc_fnd.fund_cd   /*  source code fund cod  join for direct/targeted email Interaction' */
			left join mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp fiemsd          on txn.cnst_mstr_id = fiemsd.cnst_mstr_id  and txn.campgn_src_cd = fiemsd.src_cd and txn.gift_sub_src_cd =  fiemsd.subsrc_cd and  (substring(txn.campgn_src_cd,1,2) = 'RS' or substring(txn.campgn_src_cd,1,3) in ('ADA','ADC')) and 
			txn.gift_src_cd  not in  ( 'RSG000000000','RSG00000E001','RSG00000E000'  ) AND txn.gift_src_cd IS NOT NULL
			/*  Include the sub-source code in the join for email campaigns  */
			
			
			/* The next join addresses 'Indirect email Interaction' links'for email campaigns */
			left join  /*  The sub-query below ensures that we attribute only one indirect email to a gift transaction and that we select the interaction with the  most recent indirect email sent date */
			                (select 
			                        txn.cnst_mstr_id,
			                        fiem.recipient_key,
			                        txn.giftran_key,
			                        /* Indirect Email Attribution Columns */
			                        fiem.delivery_key,
			                        fiem.campaign_key,
			                        fiem_sc_fnd.fund_key,
			                        fiem_sc.src_key,
			                        fiem.src_cd,
			                        fiem.subsrc_cd,
			                        fiem.intrctn_dt,
			                        fiem_cal.calendar_key as  intrctn_dt_key,
			                        fiem.email_launch_dt,
			                        fiem.email_segmnt_key,
			                        ROW_NUMBER() OVER (PARTITION BY txn.giftran_key ORDER BY   fiem.intrctn_dt) as trans_em_cnt  /*  This column captures the number of indirect emails campaigns attributed to a gift. */
			                from mktg_stage_tbls.gms_arc_fr_txn_tmp txn
			                /* The next join addresses 'Indirect email Interaction' links'for email campaigns */
			JOIN mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp fiem
									  ON (
											txn.recurring_ind <> 1 
											OR (
												txn.recurring_ind = 1 
												AND txn.recurng_start_dt > fiem.intrctn_dt 
												AND txn.recurng_start_dt = txn.dntn_gift_dt
											)
										 )  /* attribute the first recurring gift if the recurring start date is greater than the interaction date. */
									  AND fiem.cnst_mstr_id = txn.cnst_mstr_id 
									  AND txn.dntn_gift_dt >= CAST(fiem.intrctn_dt AS DATE) 
									  AND txn.dntn_gift_dt <= DATEADD(day, 4, CAST(fiem.intrctn_dt AS DATE))
			                and txn.gift_src_cd  IN  ( 'RSG000000000','RSG00000E001','RSG00000E000' )
			                                                                /* The source code in the join above are  the ATG online source codes. If a donor was targeted through an email then goes online and donates in ATG then we count this as an indirect donation. */
			                left join mktg_ops_vws.gmpbzal_dim_src  fiem_sc on fiem_sc.src_key=fiem.src_key-- and txn.dntn_gift_dt between cast(fiem_sc.row_eff_from_ts as date format 'mm/dd/yyyy') and cast(fiem_sc.row_eff_to_ts as date format 'mm/dd/yyyy')     /*  source code  join for Indirect email Interaction' */
			                left join mktg_ops_vws.gmpbzal_dim_fund  fiem_sc_fnd on fiem_sc.fund_cd = fiem_sc_fnd.fund_cd   /*  source code fund cod  join for Indirect email Interaction' */
			LEFT JOIN eda.dw_common_vws.dim_calendar fiem_cal
							  ON fiem_cal.calendar_dt = fiem.intrctn_dt
							WHERE txn.dntn_gift_dt >= DATE '2016-07-01'
			                QUALIFY ROW_NUMBER() OVER (PARTITION BY txn.giftran_key ORDER BY   fiem.intrctn_dt DESC) = 1   /*  This QUALIFY statement ensures that we attribute only one indirect email to a gift transaction and that we select the interaction with the  most recent indirect email sent date */
			                ) fiem ( cnst_mstr_id, recipient_key, giftran_key, delivery_key, campaign_key, fund_key,  src_key, src_cd, subsrc_cd, intrctn_dt, intrctn_dt_key, email_launch_dt, email_segmnt_key, indrct_em_attrbtn_cnt) 
			                ON txn.cnst_mstr_id = fiem.cnst_mstr_id and txn.giftran_key = fiem.giftran_key
			
			/* The next joins are for Direct/Targeted  Direct Mail  and PG Interactions */
			                left join mktg_ops_vws.bzfc_fact_dmail_intrctn_norm fi  /*  This join to bzfc_fact_interaction_all is used to determine the direct/targeted interaction */
			                                on txn.cnst_mstr_id = fi.cnst_mstr_id  and txn.gift_src_cd = fi.motivtn_cd and  substring(txn.campgn_src_cd,1,2)  in ('RR', 'RQ', 'AP', 'XP') and txn.campgn_src_cd = fi.src_cd   /*  remove XP */
			                left join mktg_ops_vws.gmpbzal_dim_src  fi_sc on fi_sc.src_key=fi.src_key --and txn.dntn_gift_dt between cast(fi_sc.row_eff_from_ts as date format 'mm/dd/yyyy') and cast(fi_sc.row_eff_to_ts as date format 'mm/dd/yyyy')    /*  source code  join for direct/targeted interactions */
			                left join mktg_ops_vws.gmpbzal_dim_fund  fi_sc_fnd on fi_sc.fund_cd = fi_sc_fnd.fund_cd   /*  source code fund cod  join for direct/targeted interactions */
			                left join mktg_ops_vws.dim_src_2_intrctn_brdg dmdt on fi.src_key = dmdt.src_key
			
			left join  /*  The sub-query below ensures that we attribute only one indirect direct mail to a gift transaction and that we select the interaction with the  most recent indirect mail sent date */
			                (select 
			                 txn.cnst_mstr_id,
			                fidm.recipient_key,
			                txn.giftran_key,
			                /* Indirect Direct Mail Attribution Columns */
			                fidm.delivery_key as indrct_dm_delivery_key,
			                fidm.campaign_key as indrct_dm_campaign_key ,
			                fidm.treatmnt_key as indrct_dm_treatmnt_key,
			                fidm_sc_fnd.fund_key as indrct_dm_fund_key,
			                                                                fidm_sc.src_key as indrct_dm_src_key,
			                 fidm.src_cd as indrct_dm_src_cd,
			                fidm.subsrc_cd as indrct_dm_subsrc_cd,
			                fidm.file_cd as indrct_dm_file_cd,  /*  Acquisition File Code */
			                fidm.motivtn_cd as indrct_dm_motivtn_cd,
			                fidm.rpt_cell_cd_key as indrct_rpt_cell_cd_key,
			                scbr.intrctn_dt as  indrct_dm_mailed_dt,
			                fidm_cal.calendar_key as  indrct_dm_mailed_dt_key,
			                fidm.intrctn_dt as indrct_dm_drop_dt,
			                coalesce(fdmn_cal.calendar_key,0) as indrct_dm_drop_dt_key,
			                 fidm.mail_drop_num as indrct_dm_mail_drop_num,
			/*              fidm.file_cd, -- Acquisition File Code */
			                ROW_NUMBER() OVER (PARTITION BY txn.giftran_key ORDER BY   fidm.intrctn_dt) as trans_dm_cnt  /*  This column captures the number of indirect emails campaigns attributed to a gift. */
			                from mktg_stage_tbls.gms_arc_fr_txn_tmp txn
			/* The next joins address the Indirect Direct Mail' links for direct mail campaigns */
			/* changed join to dmail_intrctn_norm May 2020*/
			                join  mktg_ops_vws.bzfc_fact_dmail_intrctn_norm  fidm  on  (txn.recurring_ind<> 1 or (txn.recurring_ind = 1 and txn.recurng_start_dt > fidm.intrctn_dt and txn.recurng_start_dt = txn.dntn_gift_dt))  /*  attribute the first recurring gift if the recurring start date is greater than the interaction date. */
			                AND fidm.cnst_mstr_id = txn.cnst_mstr_id
							AND txn.dntn_gift_dt >= DATEADD(day, 5, CAST(fidm.intrctn_dt AS DATE))
							AND txn.dntn_gift_dt <= DATEADD(day, 35, CAST(fidm.intrctn_dt AS DATE))
			                and txn.gift_src_cd  IN  ( 'RSG000000000','RSG00000E001','RSG00000E000'  )
			                left join mktg_ops_vws.gmpbzal_dim_src  fidm_sc on fidm_sc.src_key=fidm.src_key   /*  source code  join for indirect/targeted interactions */
			                left join mktg_ops_vws.gmpbzal_dim_fund  fidm_sc_fnd on fidm_sc.fund_cd = fidm_sc_fnd.fund_cd   /*  source code fund cod  join for indirect/targeted interactions */
			                left join mktg_ops_vws.dim_src_2_intrctn_brdg scbr on fidm.src_key = scbr.src_key             /*              source code join for initial mail date                 */
			               left join eda.dw_common_vws.dim_calendar fidm_cal on fidm_cal.calendar_dt = scbr.intrctn_dt
			               left join eda.dw_common_vws.dim_calendar fdmn_cal on fdmn_cal.calendar_dt = fidm.intrctn_dt
			               /*
			               left join mktg_ops_vws.dim_src_2_intrctn_brdg fibr on fidm.src_key = fibr.src_key
			               left join eda.dw_common_vws.dim_calendar fi_cal on fi_cal.calendar_dt = fibr.intrctn_dt
			               */
			                where  TO_DATE(txn.dntn_gift_dt, 'MM/DD/YYYY') >= DATEADD(month, -12, CURRENT_DATE)
			
			                QUALIFY ROW_NUMBER() OVER (PARTITION BY txn.giftran_key ORDER BY   fidm.intrctn_dt DESC) = 1  /*  This QUALIFY statement ensures that we attribute only one indirect direct mail to a gift transaction and that we select the interaction with the  most recent indirect email sent date */
			                ) fidm ( cnst_mstr_id, recipient_key, giftran_key, delivery_key, campaign_key, treatmnt_key, fund_key,  src_key, src_cd, subsrc_cd, file_cd, motivtn_cd, indrct_rpt_cell_cd_key, intrctn_dt, intrctn_dt_key, drop_dt, drop_dt_key, mail_drop_num,  indrct_dm_attrbtn_cnt) 
			                ON txn.cnst_mstr_id = fidm.cnst_mstr_id and txn.giftran_key = fidm.giftran_key
			
			/*  Joins to dim_calendar to add the date keys */
			left join eda.dw_common_vws.dim_calendar cal on cal.calendar_dt = srib.intrctn_dt --coalesce(sc.intrctn_dt, scmd.mail_dt) 
			--left join eda.dw_common_vws.dim_calendar ntem_cal on ntem_cal.calendar_dt = indrct_em_sent_dt
			--left join eda.dw_common_vws.dim_calendar ntdm_cal on ntdm_cal.calendar_dt = indrct_dm_mailed_dt
			left join eda.dw_common_vws.dim_calendar dd_cal on dd_cal.calendar_dt = scdd.drop_dt 
			left join eda.dw_common_vws.dim_calendar fin_cal on fin_cal.calendar_dt =  fi.intrctn_dt
			left join eda.dw_common_vws.dim_calendar fiemd_cal on fiemd_cal.calendar_dt = fiemd.intrctn_dt
			left join eda.dw_common_vws.dim_calendar fiem_cal on fiem_cal.calendar_dt = fiem.intrctn_dt
			left join eda.dw_common_vws.dim_calendar fidm_cal on fidm_cal.calendar_dt = fidm.intrctn_dt
			left join eda.dw_common_vws.dim_calendar fi_cal on fi_cal.calendar_dt = dmdt.intrctn_dt
			left join (select cnst_mstr_id, min(dntn_gift_dt) as first_dntn_gift_dt from mktg_stage_tbls.gms_arc_fr_txn_tmp   group by cnst_mstr_id)  first_donat 
			 on txn.cnst_mstr_id=first_donat.cnst_mstr_id and txn.dntn_gift_dt = first_donat.first_dntn_gift_dt
			 left join mktg_ops_vws.actvty_vwthrgh vt on txn.rco_dntn_id = vt.ord_val  /*display ad viewthrough*/
			left join eda.dw_common_vws.dim_calendar vt_cal on cast(vt.actvty_dt as date) = vt_cal.calendar_dt
			
			/* End of Join Definitions */
			where  CAST(txn.dntn_gift_dt AS DATE) >= DATEADD(month, -12, CURRENT_DATE) and txn.active_ind = 1 -- cast(txn.dntn_gift_dt as date format 'mm/dd/yyyy') >= '08/01/2016' 
			/*  This QUALIFY statement ensures that we attribute only one interaction row to a gift transaction and that we select the interaction with the highest noseed sent count from the delivery.  Some campaigns have more than one delivery with the same source code, which was causing dups in the fact table. */
			QUALIFY ROW_NUMBER() OVER (PARTITION BY txn.giftran_key ORDER BY   dlv.sent_noseed_cnt DESC, 
				case when fi.cnst_mstr_id is not null then fi.recipient_key
				when fiemd.cnst_mstr_id is not null then fiemd.recipient_key
				when fiem.cnst_mstr_id is not null then fiem.recipient_key 
				when fidm.cnst_mstr_id is not null then fidm.recipient_key 
				else 0
				end  DESC
				) = 1 ),
	
derived_fields as 
(
			select
			
			  *,
			  CAST(NULL AS BIGINT) AS unf_fr_cnst_key,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NOT NULL THEN fi_recipient_key
			    WHEN fiemd_cnst_mstr_id IS NOT NULL THEN fiemd_recipient_key 
			    WHEN fiem_cnst_mstr_id IS NOT NULL THEN fiem_recipient_key 
			    WHEN fidm_cnst_mstr_id IS NOT NULL THEN fidm_recipient_key
			    ELSE 0
			  END AS recipient_key,
			  

			  CASE 
			    WHEN txn_campgn_src_key IS NULL AND txn_campgn_src_cd = txn_gift_src_cd THEN txn_gift_src_key 
			    WHEN txn_campgn_src_key IS NULL AND txn_campgn_src_cd <> txn_gift_src_cd THEN 0
			    ELSE txn_campgn_src_key
			  END AS campgn_src_key, /* generic campaign source key */
			

			  NULL AS nk_ta_nm_id,
			
			  --txn_fr_affl_unit_key, /*10/28/2016: Majeed. Changed to use the column directly from the arc_fr_txn view as it is being calculated in the view now */
			  /*Disabled due to above logic  cast(txn.fr_affl_cd as integer) as fr_affl_unit_key, -- Chapter affiliation code - this is the same as the nk_ecode in dim_unit_merged  */
			
			  /* Set the Generation Segment Key */
			  CAST(0 AS INTEGER) AS gen_segmnt_key,
			
			  /* Non-Targeted/Direct Attribution Columns */
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN 1 
			    ELSE 0 
			  END AS non_tgt_gift_ind,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN txn_fr_pmt_amt 
			    ELSE 0 
			  END AS non_tgt_gift_amt,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 2) IN ('RQ', 'RR') THEN 1 
			    ELSE 0 
			  END AS non_tgt_dm_gift_ind,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 2) IN ('RQ', 'RR') THEN txn_fr_pmt_amt 
			    ELSE 0 
			  END AS non_tgt_dm_gift_amt,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 2) NOT IN ('RQ', 'RR') THEN 1 
			    ELSE 0 
			  END AS non_tgt_em_gift_ind,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 2) NOT IN ('RQ', 'RR') THEN txn_fr_pmt_amt 
			    ELSE 0 
			  END AS non_tgt_em_gift_amt,
			
			  COALESCE(
			    CASE 
			      WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			           AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			           AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN dlv_delivery_key 
			      ELSE 0 
			    END, 0
			  ) AS non_tgt_delivery_key,
			
			  COALESCE(
			    CASE 
			      WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			           AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			           AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN cmpg_campgn_key 
			      ELSE 0 
			    END, 0
			  ) AS non_tgt_campaign_key,
			
			  COALESCE(
			    CASE 
			      WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			           AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			           AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN 0 
			    END, 0
			  ) AS non_tgt_treatment_key,
			
			  COALESCE(
			    CASE 
			      WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			           AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			           AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN sc_fnd_fund_key 
			      ELSE 0 
			    END, 0
			  ) AS non_tgt_fund_key,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN txn_campgn_src_cd 
			  END AS non_tgt_src_cd,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN txn_gift_sub_src_cd 
			  END AS non_tgt_subsrc_cd,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN srib_intrctn_dt 
			  END AS non_tgt_intrctn_dt,
			
			  COALESCE(
			    CASE 
			      WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			           AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			           AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN cal_calendar_key 
			      ELSE 0 
			    END, 0
			  ) AS non_tgt_intrctn_dt_key,
			
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			         AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			         AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN scdd_drop_dt 
			  END AS non_tgt_drop_dt,
			
			  COALESCE(
			    CASE 
			      WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			           AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			           AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN dd_cal_calendar_key 
			      ELSE 0 
			    END, 0
			  ) AS non_tgt_drop_dt_key,
			
			  COALESCE(
			    CASE 
			      WHEN fi_cnst_mstr_id IS NULL AND fiemd_cnst_mstr_id IS NULL AND fiem_cnst_mstr_id IS NULL AND fidm_cnst_mstr_id IS NULL 
			           AND txn_gift_src_cd NOT IN ('RSG000000000','RSG00000E001','RSG00000E000') 
			           AND LEFT(txn_gift_src_cd, 1) IN ('A', 'R') THEN scdd_mail_drop_num 
			    END, 0
			  ) AS non_tgt_mail_drop_num,
			
			/* Targeted/Direct Mail Attribution Columns */
			 COALESCE(fi_delivery_key, 0) AS tgt_dm_delivery_key,
			COALESCE(fi_campaign_key, 0) AS tgt_dm_campaign_key,
			COALESCE(fi_treatmnt_key, 0) AS tgt_dm_treatment_key,
			COALESCE(fi_sc_fnd_fund_key, 0) AS tgt_dm_fund_key,
			
			fi_src_cd AS tgt_dm_src_cd,
			fi_subsrc_cd AS tgt_dm_subsrc_cd,
			fi_file_cd AS tgt_dm_file_cd,
			fi_motivtn_cd AS tgt_dm_motivtn_cd,
			fi_rpt_cell_cd_key AS tgt_dm_rpt_cell_cd_key,
			
			CASE 
			  WHEN fi_cnst_mstr_id IS NULL THEN 0 
			  ELSE 1 
			END AS tgt_dm_gift_ind,
			
			CASE 
			  WHEN fi_cnst_mstr_id IS NULL THEN 0 
			  ELSE txn_fr_pmt_amt 
			END AS tgt_dm_gift_amt,
			
			CASE 
			  WHEN fi_cnst_mstr_id IS NULL THEN NULL 
			  ELSE fi_cal_calendar_dt 
			END AS tgt_dm_intrctn_dt,
			
			COALESCE(
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL THEN 0 
			    ELSE fi_cal_calendar_key  
			  END, 0
			) AS tgt_dm_intrctn_dt_key,
			
			CASE 
			  WHEN fi_cnst_mstr_id IS NULL THEN NULL 
			  ELSE fin_cal_calendar_dt 
			END AS tgt_dm_drop_dt,
			
			COALESCE(
			  CASE 
			    WHEN fi_cnst_mstr_id IS NULL THEN 0 
			    ELSE fin_cal_calendar_key  
			  END, 0
			) AS tgt_dm_drop_dt_key,
			
			CASE 
			  WHEN fi_cnst_mstr_id IS NULL THEN NULL 
			  ELSE fi_mail_drop_num 
			END AS tgt_dm_mail_drop_num,
			
			/* Targeted/Direct Email Attribution Columns */
			COALESCE(fiemd_delivery_key, 0) AS tgt_em_delivery_key, 
			COALESCE(fiemd_campaign_key, 0) AS tgt_em_campaign_key,
			CAST(0 AS INTEGER) AS tgt_em_treatment_key,
			COALESCE(fiemd_sc_fnd_fund_key, 0) AS tgt_em_fund_key,
			
			fiemd_src_cd AS tgt_em_src_cd,
			fiemd_subsrc_cd AS tgt_em_subsrc_cd,
			fiemd_email_launch_dt AS tgt_em_email_launch_dt,
			fiemd_email_segmnt_key AS tgt_em_email_segmnt_key,
			COALESCE(fiemsd_active_email_segment_ind, 0) AS tgt_em_active_email_segment_ind,
			
			CASE 
			  WHEN fiemd_cnst_mstr_id IS NULL THEN 0 
			  ELSE 1 
			END AS tgt_em_gift_ind,
			
			CASE 
			  WHEN fiemd_cnst_mstr_id IS NULL THEN 0 
			  ELSE txn_fr_pmt_amt 
			END AS tgt_em_gift_amt,
			
			CASE 
			  WHEN fiemd_cnst_mstr_id IS NULL THEN NULL 
			  ELSE fiemd_cal_calendar_dt 
			END AS tgt_em_intrctn_dt,
			
			COALESCE(
			  CASE 
			    WHEN fiemd_cnst_mstr_id IS NULL THEN 0 
			    ELSE fiemd_cal_calendar_key 
			  END, 0
			) AS tgt_em_intrctn_dt_key,
			
			/* Indirect Email Attribution Columns */
			COALESCE(fiem_delivery_key, 0) AS indrct_em_delivery_key,
			COALESCE(fiem_campaign_key, 0) AS indrct_em_campaign_key,
			CAST(0 AS INTEGER) AS indrct_em_treatment_key,
			COALESCE(fiem_fund_key, 0) AS indrct_em_fund_key,
			
			CASE 
			  WHEN fiem_cnst_mstr_id IS NULL THEN 0 
			  ELSE 1 
			END AS indrct_em_donat_ind,
			
			fiem_src_cd AS indrct_em_src_cd,
			fiem_subsrc_cd AS indrct_em_subsrc_cd,
			fiem_intrctn_dt AS indrct_em_sent_dt,
			fiem_email_launch_dt AS indrct_em_email_launch_dt,
			fiem_email_segmnt_key AS indrct_em_email_segmnt_key,
			COALESCE(fiem_intrctn_dt_key, 0) AS indrct_em_dt_key,
			
			/* Indirect Direct Mail Attribution Columns */
			COALESCE(fidm_campaign_key, 0) AS indrct_dm_delivery_key,
			COALESCE(fidm_campaign_key, 0) AS indrct_dm_campaign_key,
			COALESCE(fidm_treatmnt_key, 0) AS indrct_dm_treatment_key,
			COALESCE(fidm_fund_key, 0) AS indrct_dm_fund_key,
			
			CASE 
			  WHEN fidm_cnst_mstr_id IS NULL THEN 0 
			  ELSE 1 
			END AS indrct_dm_donat_ind,
			fidm_src_cd AS indrct_dm_src_cd,
			fidm_subsrc_cd AS indrct_dm_subsrc_cd,
			fidm_file_cd AS indrct_dm_file_cd,
			fidm_motivtn_cd AS indrct_dm_motivtn_cd,
			--fidm_indrct_rpt_cell_cd_key,
			fidm_intrctn_dt AS indrct_dm_mailed_dt,
			COALESCE(fidm_intrctn_dt_key, 0) AS indrct_dm_mailed_dt_key,
			fidm_drop_dt AS indrct_dm_drop_dt,
			COALESCE(fidm_drop_dt_key, 0) AS indrct_dm_drop_dt_key,
			fidm_mail_drop_num AS indrct_mail_drop_num,
			
			
			CASE 
			  WHEN LEFT(txn_gift_src_cd, 3) = 'RQQ' AND fi_file_cd IS NULL AND fidm_file_cd IS NULL THEN 'RQL'  
			  WHEN LEFT(txn_gift_src_cd, 3) = 'RQQ' AND fi_file_cd IS NOT NULL AND fidm_file_cd IS NOT NULL THEN 'RQQ'  
			  WHEN LEFT(txn_gift_src_cd, 3) = 'RQL' THEN 'RQL'
			  WHEN LEFT(txn_gift_src_cd, 3) = 'RQD' THEN 'RQD'
			  WHEN LEFT(txn_gift_src_cd, 3) = 'RQP' THEN 'RQP'
			  WHEN LEFT(txn_gift_src_cd, 3) NOT IN ('RQQ', 'RQL', 'RQD', 'RQP') THEN 'NA' 
			END AS acqstn_typ_cd
	
	
	from direct_fields)--Hitansu:Execution time 2 mins
--select * from derived_fields;


,derived_derived_fields as (
		select *,
				CASE 
				  WHEN non_tgt_dm_gift_ind = 1 AND LEFT(non_tgt_src_cd, 2) IN ('RQ', 'RR') THEN 'NTDM'  /* Direct Mail : Non-Target Direct Attribution */
				  WHEN non_tgt_em_gift_ind = 1 AND LEFT(non_tgt_src_cd, 2) NOT IN ('RQ', 'RR', 'AP') THEN 'NTEM'  /* Email: Non-Target Direct Attribution - added exclusion for PG src cds */
				  WHEN tgt_em_gift_ind = 1 THEN 'TDEM'  /* Email - Targeted Direct Attribution */
				  WHEN tgt_dm_gift_ind = 1 THEN 'TDDM'  /* Direct Mail - Targeted Direct Attribution */
				  WHEN indrct_em_donat_ind = 1 AND (ga_lst_touch_chnl IS NULL OR ga_lst_touch_chnl NOT IN ('Paid Search','Natural Search','Organic Search','Display')) THEN 'INEM'
				  WHEN vt_vwthrgh_rev > 0 AND (ga_lst_touch_chnl IS NULL OR ga_lst_touch_chnl NOT IN ('Paid Search','Natural Search','Organic Search','Display')) THEN 'IDVT'
				  WHEN indrct_dm_donat_ind = 1 AND (ga_lst_touch_chnl IS NULL OR ga_lst_touch_chnl NOT IN ('Paid Search','Natural Search','Organic Search','Display')) THEN 'INDM'
				  WHEN indrct_dm_mailed_dt IS NOT NULL AND indrct_em_sent_dt IS NOT NULL AND indrct_dm_mailed_dt > indrct_em_sent_dt AND (ga_lst_touch_chnl IS NULL OR ga_lst_touch_chnl NOT IN ('Paid Search','Natural Search','Organic Search','Display')) THEN 'INDM'  /* Attribute to most recent interaction */
				  WHEN indrct_dm_mailed_dt IS NOT NULL AND indrct_em_sent_dt IS NOT NULL AND indrct_dm_mailed_dt <= indrct_em_sent_dt AND (ga_lst_touch_chnl IS NULL OR ga_lst_touch_chnl NOT IN ('Paid Search','Natural Search','Organic Search','Display')) THEN 'INEM'  /* Attribute to most recent interaction */
				  WHEN non_tgt_dm_gift_ind = 0 AND non_tgt_em_gift_ind = 0 AND tgt_dm_gift_ind = 0 AND indrct_em_donat_ind = 0 AND indrct_dm_donat_ind = 0 
					   OR ga_lst_touch_chnl IN ('Paid Search','Natural Search','Organic Search','Display') THEN 'NA' 
				END AS intrctn_atrbtn_typ_cd
				from derived_fields
)

		
			select 
			txn_cnst_mstr_id, 
			unf_fr_cnst_key, 
			recipient_key, txn_giftran_key, txn_arc_fr_txn_seq_num, txn_alt_trans_id, 
			txn_gift_src_key, txn_gift_src_cd, /*  gift source code */
			
			campgn_src_key, txn_campgn_src_cd, txn_gift_sub_src_cd, txn_channel_typ_key, 
			null as nk_ta_nm_id, txn_fr_affl_unit_key, gen_segmnt_key, non_tgt_gift_ind, non_tgt_gift_amt, non_tgt_dm_gift_ind, 
			non_tgt_dm_gift_amt, non_tgt_em_gift_ind, non_tgt_em_gift_amt, non_tgt_delivery_key, non_tgt_campaign_key, 
			non_tgt_treatment_key, non_tgt_fund_key, non_tgt_src_cd,

			non_tgt_subsrc_cd, non_tgt_intrctn_dt, non_tgt_intrctn_dt_key, non_tgt_drop_dt, non_tgt_drop_dt_key, non_tgt_mail_drop_num, 
			tgt_dm_delivery_key, tgt_dm_campaign_key, tgt_dm_treatment_key, tgt_dm_fund_key, tgt_dm_src_cd, tgt_dm_subsrc_cd, 
			tgt_dm_file_cd, tgt_dm_motivtn_cd, tgt_dm_rpt_cell_cd_key, tgt_dm_gift_ind, tgt_dm_gift_amt, tgt_dm_intrctn_dt, 
			tgt_dm_intrctn_dt_key, tgt_dm_drop_dt,

			tgt_dm_drop_dt_key, tgt_dm_mail_drop_num, tgt_em_delivery_key, tgt_em_campaign_key, tgt_em_treatment_key, tgt_em_fund_key, 
			tgt_em_src_cd, tgt_em_subsrc_cd, tgt_em_email_launch_dt, tgt_em_email_segmnt_key, tgt_em_active_email_segment_ind, 
			tgt_em_gift_ind, tgt_em_gift_amt, tgt_em_intrctn_dt, tgt_em_intrctn_dt_key, indrct_em_delivery_key, indrct_em_campaign_key, 
			indrct_em_treatment_key, indrct_em_fund_key, indrct_em_donat_ind, indrct_em_src_cd, indrct_em_subsrc_cd, indrct_em_sent_dt, 
			indrct_em_email_launch_dt, indrct_em_email_segmnt_key, indrct_em_dt_key, fiem_indrct_em_attrbtn_cnt, indrct_dm_delivery_key, 
			indrct_dm_campaign_key, indrct_dm_treatment_key, indrct_dm_fund_key, indrct_dm_donat_ind,
			
			CASE 
		  		WHEN indrct_em_donat_ind = 1 OR indrct_dm_donat_ind = 1 THEN 1 
		  		ELSE 0 
				END AS indrct_attrbtn_ind,
			
			indrct_dm_src_cd, indrct_dm_subsrc_cd, indrct_dm_file_cd, indrct_dm_motivtn_cd,
			fidm_indrct_rpt_cell_cd_key, indrct_dm_mailed_dt, indrct_dm_mailed_dt_key, indrct_dm_drop_dt,
			indrct_dm_drop_dt_key, indrct_mail_drop_num, fidm_indrct_dm_attrbtn_cnt,
			acqstn_typ_cd,
			
			case when indrct_em_donat_ind =1 and indrct_dm_donat_ind = 1 then 1 else 0 end as multi_indrct_attrib_ind,
			

			
			CASE
			  WHEN non_tgt_em_gift_ind = 1 AND LEFT(non_tgt_src_cd, 2) NOT IN ('RQ', 'RR', 'AP') THEN emld_email_launch_dt  /* Non-Targeted Email - added exclusion for PG src cds */
			  WHEN non_tgt_dm_gift_ind = 1 AND LEFT(non_tgt_src_cd, 2) IN ('RQ', 'RR') THEN non_tgt_intrctn_dt  /* Non-Targeted Direct Mail */
			  WHEN tgt_em_intrctn_dt IS NOT NULL OR tgt_dm_intrctn_dt IS NOT NULL THEN COALESCE(emld_email_launch_dt, tgt_dm_intrctn_dt)
			  WHEN indrct_em_sent_dt IS NOT NULL AND indrct_dm_mailed_dt IS NULL THEN indrct_em_sent_dt
			  WHEN indrct_dm_mailed_dt IS NOT NULL AND indrct_em_sent_dt IS NULL THEN indrct_dm_mailed_dt
			  WHEN indrct_dm_mailed_dt IS NOT NULL AND indrct_em_sent_dt IS NOT NULL AND indrct_dm_mailed_dt > indrct_em_sent_dt THEN indrct_dm_mailed_dt 
			  ELSE indrct_em_sent_dt 
			END AS fact_donation_intrctn_dt,
			
			intrctn_atrbtn_typ_cd,
			
		CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN fiem_indrct_em_dt_key  /* updated from cal.calendar_key */--referred as fiem.indrct_em_dt_key,fiem_cal.calendar_key
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_intrctn_dt_key
			  WHEN intrctn_atrbtn_typ_cd = 'NTDM' THEN cal_calendar_key
			  WHEN intrctn_atrbtn_typ_cd = 'NTEM' THEN cal_calendar_key
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_cal_calendar_key    
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN fiemd_cal_calendar_key     
			  WHEN intrctn_atrbtn_typ_cd = 'IDVT' THEN vt_cal_calendar_key                                                                                                                           
			  ELSE 0
			END AS intrctn_dt_key,
			                /* Interaction Attribution Delivery Key */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN fiem_delivery_key 
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_delivery_key
			  WHEN intrctn_atrbtn_typ_cd IN ('NTDM', 'NTEM') THEN dlv_delivery_key
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_delivery_key                                               
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN fiemd_delivery_key
			  ELSE 0
			END AS intrctn_delivery_key,
			
			/* Interaction Attribution Campaign Key */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN fiem_campaign_key 
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_campaign_key
			  WHEN intrctn_atrbtn_typ_cd = 'NTEM' THEN cmpg_campgn_key
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_campaign_key                                            
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN fiemd_campaign_key
			  ELSE 0
			END AS intrctn_campaign_key,
			
			/* Interaction Attribution Treatment Key */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN 0 
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_treatmnt_key
			  WHEN intrctn_atrbtn_typ_cd = 'NTD' THEN 0
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_treatmnt_key                                               
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN 0
			  ELSE 0
			END AS intrctn_treatment_key,
			
			/* Interaction Attribution Fund Key */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN fiem_fund_key 
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_fund_key
			  WHEN intrctn_atrbtn_typ_cd IN ('NTDM', 'NTEM') THEN sc_fnd_fund_key
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_sc_fnd_fund_key                                               
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN fiemd_sc_fnd_fund_key
			  ELSE 0
			END AS intrctn_fund_key,
			/* Interaction Attribution Indicator */
				CASE 
			  WHEN non_tgt_gift_ind = 1 
			    OR tgt_dm_gift_ind = 1 
			    OR tgt_em_gift_ind = 1 
			    OR indrct_em_donat_ind = 1 
			    OR indrct_dm_donat_ind = 1 THEN 1 
			  ELSE 0 
			END AS intrctn_attrbtn_ind,
			
			/* Interaction Attribution Source Key */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN fiem_src_key
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_src_key
			  WHEN intrctn_atrbtn_typ_cd IN ('NTDM', 'NTEM') THEN txn_campgn_src_key
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_src_key                                               
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN fiemd_src_key
			  ELSE 0
			END AS intrctn_src_key,
			
			/* Interaction Attribution Source Code */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN indrct_em_src_cd
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN indrct_dm_src_cd
			  WHEN intrctn_atrbtn_typ_cd IN ('NTDM', 'NTEM') THEN non_tgt_src_cd
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN tgt_dm_src_cd                                               
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN tgt_em_src_cd
			  ELSE 0::varchar--cast to avoid error:ERROR: CASE types integer and character varying cannot be matched
			END AS intrctn_src_cd,
			
			/* Interaction Attribution Sub Source Code */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN indrct_em_subsrc_cd
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN indrct_dm_subsrc_cd
			  WHEN intrctn_atrbtn_typ_cd IN ('NTDM', 'NTEM') THEN non_tgt_subsrc_cd
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN tgt_dm_subsrc_cd                                          
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN tgt_em_subsrc_cd
			  ELSE 0::varchar
			END AS intrctn_subsrc_cd,
			
			/* Interaction Attribution File Code */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN indrct_dm_file_cd
			  WHEN intrctn_atrbtn_typ_cd IN ('NTDM', 'NTEM') THEN xref_file_cd
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN tgt_dm_file_cd                                                
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN NULL
			  ELSE NULL
			END AS intrctn_file_cd,
			
			/* Interaction Attribution Motivation Code */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN indrct_dm_motivtn_cd
			  WHEN intrctn_atrbtn_typ_cd = 'NTDM' THEN txn_gift_src_cd
			  WHEN intrctn_atrbtn_typ_cd = 'NTEM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN tgt_dm_motivtn_cd                                         
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN NULL
			  ELSE NULL
			END AS intrctn_motivtn_cd,
			
			/* Interaction Attribution Report Cell Code (Direct Mail only) */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN 0
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_indrct_rpt_cell_cd_key
			  WHEN intrctn_atrbtn_typ_cd IN ('NTDM', 'NTEM') THEN 0
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_rpt_cell_cd_key                                          
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN 0
			  ELSE NULL
			END AS intrctn_rpt_cell_cd_key,
			
			/* Add interaction email launch date - applies to direct and indirect */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN indrct_em_email_launch_dt
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd = 'NTEM' THEN emld_email_launch_dt  /* 9/3/17 MTG removed NTDM from the WHEN clause */
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN NULL                             
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN tgt_em_email_launch_dt
			  ELSE NULL
			END AS intrctn_email_launch_dt,
			
			/* Add interaction email segment key - applies to direct and indirect */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN indrct_em_email_segmnt_key
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd IN ('NTDM', 'NTEM') THEN fiemd_email_segmnt_key
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN NULL                             
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN tgt_em_email_segmnt_key
			  ELSE NULL
			END AS intrctn_email_segmnt_key,
			
			/* Add DM drop date - applies to direct and indirect */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_drop_dt
			  WHEN intrctn_atrbtn_typ_cd = 'NTDM' THEN scdd_drop_dt
			  WHEN intrctn_atrbtn_typ_cd = 'NTEM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_intrctn_dt                        
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN NULL
			  ELSE NULL
			END AS intrctn_drop_dt,
			
			/* Add DM drop date key - applies to direct and indirect */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN 0
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_drop_dt_key
			  WHEN intrctn_atrbtn_typ_cd = 'NTDM' THEN dd_cal_calendar_key
			  WHEN intrctn_atrbtn_typ_cd = 'NTEM' THEN 0
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fin_cal_calendar_key                       
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN 0
			  ELSE 0
			END AS intrctn_drop_dt_key,
			
			/* Add DM drop number - applies to direct and indirect */
			CASE 
			  WHEN intrctn_atrbtn_typ_cd = 'INEM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd = 'INDM' THEN fidm_mail_drop_num
			  WHEN intrctn_atrbtn_typ_cd = 'NTDM' THEN scdd_mail_drop_num 
			  WHEN intrctn_atrbtn_typ_cd = 'NTEM' THEN NULL
			  WHEN intrctn_atrbtn_typ_cd = 'TDDM' THEN fi_mail_drop_num                       
			  WHEN intrctn_atrbtn_typ_cd = 'TDEM' THEN NULL
			  ELSE NULL
			END AS intrctn_mail_drop_num,
			
			/* Add Transaction Dates and Indicators */
		txn_fr_pmt_amt AS dntn_fr_pmt_amt,
		txn_dntn_gift_dt,
		txn_dntn_gift_dt_key,
		txn_orig_deposit_dt,
		txn_orig_deposit_dt_key,
		txn_deposit_dt,
		txn_deposit_dt_key,
		txn_recurring_ind,
		txn_recurng_start_dt,
		txn_online_channel_cd,
		txn_soft_credit_ind,
		CAST(NULL AS VARCHAR(10)) AS fr_trans_cnst_zip_cd,
		txn_trans_fund_key,
		txn_trans_fund_cd,
		txn_trans_fund_dsc,
		txn_email_segmnt_key AS trans_email_segmnt_key,

		/* Other Derived Columns */
		CASE 
		  WHEN non_tgt_gift_ind = 1 
			OR tgt_dm_gift_ind = 1 
			OR tgt_em_gift_ind = 1 
			OR indrct_em_donat_ind = 1 
			OR indrct_dm_donat_ind = 1 
		  THEN txn_dntn_gift_dt - fact_donation_intrctn_dt 
		  ELSE 0 
		END AS days_btwn_intrctn_txn_num,

		CASE 
		  WHEN first_donat_first_dntn_gift_dt IS NOT NULL THEN 1 
		  ELSE 0 
		END AS first_dntn_ind,

		ga_source1 AS ga_source,
		ga_medium1 AS ga_medium,
		ga_cid_dsc AS ga_campaign,
		ga_device AS ga_device,
		ga_lst_touch_chnl AS ga_lst_touch_chnl


from derived_derived_fields;

GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

/* Delete the data from the TEMP table for space utilization */
TRUNCATE TABLE mktg_stage_tbls.gms_arc_fr_txn_tmp;

TRUNCATE TABLE mktg_stage_tbls.bzfc_fact_email_intrctn_smry_tmp;

TRUNCATE TABLE mktg_stage_tbls.bzfc_fiemd_out_tmp;




--audit update	
	v_end_time := CURRENT_TIMESTAMP;
v_ok_message := 'Records Deleted:' || v_deleted_count::VARCHAR || ' || Inserted:' || v_inserted_count::VARCHAR;
UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=	v_deleted_count::int+v_inserted_count::int
        WHERE proc_name = 'ld_gms_bzfc_adb_fact_donation' AND task_name = 'Stored Procedure' AND start_time = v_start_time;


	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_gms_bzfc_adb_fact_donation', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;



$$
