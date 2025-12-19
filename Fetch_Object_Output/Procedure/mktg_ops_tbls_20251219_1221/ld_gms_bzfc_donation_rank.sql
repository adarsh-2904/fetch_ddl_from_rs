CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_bzfc_donation_rank()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Majeed Mohammad
Created date: 06/12/2010
Purpose: To populate the table that gives the one cnst per giiftran_key 

Purpose: This macro contains the rules for selecting the best master id to send for donations that are associated with more than one cnst_mstr_id.  For donations that are linked to more than one constituent, the marco select the record associated with the most active master id to
the gms_bzfc_donation_ranking table .  The macro and resulting table are limited to donations the occured on or after  '01/01/2010''.

 	When linking the DM interactions to the transactions, I limited the join selection the DM interaction on or after '11/15/2009'.  In other words, I go back a little more and 35 days from the point at which we start the transactions
 	Likewise, I limit the email open and sent interaction queries to 12/1/2009   at least 30 days before the transaction data set.
 	I didn't select the distinct open and sent counts by delivery   this adds complexity to the query.  I thought we can test the results before I consider adding this logic.
 	For the transaction count, I built a query that sums the gifts prior to the current gift and limit the gift candidates to gifts occurring on or after 1/1/2009.  This might not be the best approach, but thought we should take a look at the results first.  I can change this to simple sum for the entire time period.
 	I noticed some gifts linked to master ids where the gift counts our huge.  I've seen this before and believe these are chapters that send many gifts per month and are records as donors and assigned master ids.

Modified By;	Michael Andrien
Modified Date:	08/06/2020
Purpose:	Modified the rank query to optimize the insert statement.  Added the steps to truncate and reload the txn stage table (mktg_stage_tbls.stg_gms_arc_multi_cnst_txn), which contains the TXN details required for the ranking the gifts that have more than one cnst linked to the gift for the 
purpose of assigning a primary gift indicator in the TXN based on the cnst master id that has the more recent and mor frequent gift interactions.

Modified By;	Michael Andrien
Modified Date:	08/28/2020
Purpose:	Added the a.cnst_mstr_id to the Partition/Qualifier ranking to address scenarios when the details for the cnsts are the same.  We added the cnst_mstr_id rank to take the oldest master id over the newer.  This should ensure better consistency in the 
rank results.
*/	
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_bzfc_donation_rank', 'Stored Procedure', 'Inprogress', v_start_time);


begin
/* Truncate the  Multi-Constituent TXN Stage table and reload to capture the current multi-constituent gift ids */
truncate table mktg_stage_tbls.stg_gms_arc_multi_cnst_txn;

/* Now Load the Multi-Constituent TXN Stage table.  This table captures the GMS gift ids for the gifts that are linked to more than one constituent.  The table is reference in the gifr ranking rules macro query 
to assign one constituent as the primary constituent on the gift.
*/
insert into mktg_stage_tbls.stg_gms_arc_multi_cnst_txn
	select
	  cnst_mstr_id,
      giftran_key,
      nk_gift_id,
      campgn_src_cd,
      gift_src_cd,
      dntn_gift_dt,
	  online_channel_cd
	from mktg_ops_vws.gms_arc_fr_txn
	where nk_gift_id in 
	(
	    select nk_gift_id
	    from mktg_ops_vws.gms_arc_fr_txn
	    group by 1
	    having count(*) > 1
	);


truncate table mktg_ops_tbls.gms_bzfc_donation_rank;

insert into mktg_ops_tbls.gms_bzfc_donation_rank
with rank_donation_cte as (
select 
    a.giftran_key,
    a.nk_gift_id, 
    a.campgn_src_cd, 
    a.gift_src_cd,
    a.cnst_mstr_id, 
    a.dntn_gift_dt,
    dm_dir.mailed_ind,
    em_dir.email_link_click_ind,
    em_dir.email_open_ind,
    em_dir.email_sent_ind,
    dm.dm_sent_cnt,
    emo.email_open_cnt,
    ems.email_sent_cnt,
    emo.email_open_cnt + ems.email_sent_cnt as email_intrctn_cnt,
    txn.gift_cnt,
    txn.rco_gift_cnt,
    row_number() over (partition by a.nk_gift_id
           order by dm_dir.mailed_ind desc,  em_dir.email_link_click_ind desc, em_dir.email_open_ind desc, em_dir.email_sent_ind desc, 
           dm.dm_sent_cnt desc, emo.email_open_cnt desc, ems.email_sent_cnt desc, txn.rco_gift_cnt desc, txn.gift_cnt  desc, a.cnst_mstr_id) as rn
           
from  mktg_stage_tbls.stg_gms_arc_multi_cnst_txn a

left join
(

/* Now get direct mail sends matching the motivation code and cnst_mstr_id of the gift */
select a.giftran_key, a.nk_gift_id, a.campgn_src_cd, a.gift_src_cd, a.cnst_mstr_id, dntn_gift_dt, mailed_ind
from  mktg_stage_tbls.stg_gms_arc_multi_cnst_txn a
left join 
(
        select cnst_mstr_id, src_cd, motivtn_cd, mailed_ind, intrctn_dt
        from mktg_ops_vws.bzfc_fact_dmail_intrctn_norm
        where mailed_ind = 1
) dm on a.cnst_mstr_id = dm.cnst_mstr_id and a.gift_src_cd = dm.motivtn_cd


) dm_dir (giftran_key, nk_gift_id, campgn_src_cd, gift_src_cd, cnst_mstr_id, dntn_gift_dt, mailed_ind) on a.nk_gift_id = dm_dir.nk_gift_id and a.cnst_mstr_id = dm_dir.cnst_mstr_id

left join
(

/* Now get email sends matching the source code and cnst_mstr_id of the gift */
select a.giftran_key, a.nk_gift_id, a.campgn_src_cd,  a.cnst_mstr_id, dntn_gift_dt, email_sent_ind, email_open_ind, email_link_click_ind
from mktg_stage_tbls.stg_gms_arc_multi_cnst_txn a
left join 
(
        select cnst_mstr_id, src_cd, email_sent_ind, email_open_ind, email_link_click_ind, email_launch_dt
        from mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry
        where email_sent_ind = 1
) em on a.cnst_mstr_id = em.cnst_mstr_id and a.campgn_src_cd = em.src_cd


) em_dir (giftran_key, nk_gift_id, campgn_src_cd,  cnst_mstr_id, dntn_gift_dt, email_sent_ind, email_open_ind, email_link_click_ind) on a.nk_gift_id = em_dir.nk_gift_id and a.cnst_mstr_id = em_dir.cnst_mstr_id

left join
(
/* Now Get the Direct Mail summary metrics */

select a.giftran_key, a.nk_gift_id, a.campgn_src_cd, a.cnst_mstr_id, dntn_gift_dt, count(dmi.cnst_mstr_id)
from mktg_stage_tbls.stg_gms_arc_multi_cnst_txn a
left join 
(
        select cnst_mstr_id, src_cd, intrctn_dt
        from mktg_ops_vws.bzfc_fact_dmail_intrctn_norm
        where mailed_ind = 1
    ) dmi on a.cnst_mstr_id = dmi.cnst_mstr_id and a.dntn_gift_dt >= cast(dmi.intrctn_dt as date)+5 and a.dntn_gift_dt <= cast(dmi.intrctn_dt as date) +35
        group by 1,2,3,4,5

) dm  (giftran_key, nk_gift_id, campgn_src_cd, cnst_mstr_id, dntn_gift_dt, dm_sent_cnt) on a.nk_gift_id = dm.nk_gift_id and a.cnst_mstr_id = dm.cnst_mstr_id

left join 
(
/* Now Get the email open summary metrics */

    select a.giftran_key, a.nk_gift_id, a.campgn_src_cd, a.cnst_mstr_id, a.dntn_gift_dt, count(distinct emo.ideliveryid)
    from mktg_stage_tbls.stg_gms_arc_multi_cnst_txn a
    left join 
    (
        select 
            bicnst_mstr_id, 
            d.ideliveryid,
            email_intrctn_typ_dsc  ,     
            tl.tslog as email_open_dt
        from mktg_ops_tbls.adb_nmsbroadlogrcp bl
        left join  mktg_ops_tbls.adb_nmsrecipient r  on r.irecipientid = bl.irecipientid
        left join mktg_ops_tbls.adb_nmstrackinglogrcp tl on r.irecipientid = tl.irecipientid and bl.ibroadlogid = tl.ibroadlogid and bl.ideliveryid = tl.ideliveryid
        left join mktg_ops_tbls.adb_nmstrackingurl tu on tl.iurlid = tu.itrackingurlid
        left join mktg_ops_tbls.adb_nmsdelivery d on d.ideliveryid = tl.ideliveryid
        left join mktg_ops_vws.bz_dim_email_intrctn_typ dc on tu.itype = dc.email_intrctn_typ_id
        where email_intrctn_typ_id = 2 and  cast(tl.tslog as date) >= to_date('12/01/2009', 'mm/dd/yyyy')
    ) emo ( cnst_mstr_id,ideliveryid, email_intrctn_typ_dsc, email_open_dt) on emo.cnst_mstr_id = a.cnst_mstr_id and a.dntn_gift_dt >= cast(emo.email_open_dt as date) and a.dntn_gift_dt <= cast(emo.email_open_dt as date) +30
        group by 1,2,3,4,5


) emo (giftran_key, nk_gift_id, campgn_src_cd, cnst_mstr_id, dntn_gift_dt, email_open_cnt) on a.nk_gift_id = emo.nk_gift_id and a.cnst_mstr_id = emo.cnst_mstr_id

left join
(
    /* Now get the email sent/delivery stats */

    select a.giftran_key, a.nk_gift_id, a.campgn_src_cd, a.cnst_mstr_id, a.dntn_gift_dt, count(distinct ems.ideliveryid)
    from mktg_stage_tbls.stg_gms_arc_multi_cnst_txn a
    left join 
    (
        select 
            bicnst_mstr_id, 
            d.ideliveryid,
            'Email Sent' as email_intrctn_typ_dsc  , 
            to_date(bl.tsevent,'mm/dd/yyyy') as email_sent_dt
        from mktg_ops_tbls.adb_nmsbroadlogrcp bl
        left join  mktg_ops_tbls.adb_nmsrecipient r  on r.irecipientid = bl.irecipientid
        left join mktg_ops_tbls.adb_nmsdelivery d on d.ideliveryid = bl.ideliveryid
        where bl.istatus = 1
    ) ems (cnst_mstr_id, ideliveryid, email_intrctn_typ_dsc, email_sent_dt) on ems.cnst_mstr_id = a.cnst_mstr_id and a.dntn_gift_dt >= cast(ems.email_sent_dt as date) and a.dntn_gift_dt <= cast(ems.email_sent_dt as date) +30
group by 1,2,3,4,5


) ems  (giftran_key, nk_gift_id, campgn_src_cd, cnst_mstr_id, dntn_gift_dt, email_sent_cnt) on a.nk_gift_id = ems.nk_gift_id and a.cnst_mstr_id = ems.cnst_mstr_id

/* Now get the gift transaction counts.  The join below calculate the gift counts for the cnst gift from TXN2 that occurred prior to the TXN1 gift */

left join 
(

with txn1 as (
select 
            giftran_key,
            nk_gift_id,
            cnst_mstr_id, 
             dntn_gift_dt
        from mktg_stage_tbls.stg_gms_arc_multi_cnst_txn a
		where dntn_gift_dt >= '01/01/2010'
    
),
txn2 as (
select 
            giftran_key,
            nk_gift_id,
            cnst_mstr_id, 
             dntn_gift_dt,
            case when online_channel_cd = 'OD' then 1 else 0 end as rco_dntn_ind
        from mktg_stage_tbls.stg_gms_arc_multi_cnst_txn a
		where dntn_gift_dt >= '01/01/2009'
)
select 
        txn1.giftran_key,
        txn1.nk_gift_id,
        txn1.cnst_mstr_id, 
        txn1.dntn_gift_dt, 
        sum(case when  txn1.dntn_gift_dt  > txn2.dntn_gift_dt then 1 else 0 end) as txn_cnt,
        sum(case when  txn1.dntn_gift_dt  > txn2.dntn_gift_dt then rco_dntn_ind end) as rco_txn_cnt
    from txn1 left join  txn2  on txn1.cnst_mstr_id = txn2.cnst_mstr_id and txn1.dntn_gift_dt > txn2.dntn_gift_dt
   group by 1,2,3,4


) txn (giftran_key, nk_gift_id, cnst_mstr_id, dntn_gift_dt, gift_cnt, rco_gift_cnt) on a.nk_gift_id = txn.nk_gift_id and a.cnst_mstr_id = txn.cnst_mstr_id 




)

select giftran_key,
    nk_gift_id, 
    campgn_src_cd, 
    gift_src_cd,
    cnst_mstr_id, 
    dntn_gift_dt,
    mailed_ind,
    email_link_click_ind,
    email_open_ind,
    email_sent_ind,
    dm_sent_cnt,
    email_open_cnt,
    email_sent_cnt,
    email_open_cnt + email_sent_cnt as email_intrctn_cnt,
    gift_cnt,
    rco_gift_cnt 
from rank_donation_cte where rn=1;
	
	--audit update	
	v_end_time := GETDATE();
	v_ok_message = cast((select count(*) from mktg_ops_tbls.gms_bzfc_donation_rank) as nvarchar)+ ' Records inserted.';
        UPDATE mods_bi.etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_gms_bzfc_donation_rank' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_gms_bzfc_donation_rank', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;





$$
