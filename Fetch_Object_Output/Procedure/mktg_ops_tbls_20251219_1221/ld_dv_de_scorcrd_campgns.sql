CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dv_de_scorcrd_campgns()
 LANGUAGE plpgsql
AS $$
/*Created by: Majeed Mohammad
 Created on: 4/13/2017
 Purpose: To load the table mktg_ops_tbls.dv_de_scorcrd_campgns for the data visualization report
 
 Updated by: Majeed Mohammad
 Update on: 4/18/2017
 Purpose:  Added the cast to the decimal in the second union
 
  Updated by: Majeed Mohammad
 Update on: 7/18/2017
 Purpose: Updated the logic to calculate the to_contcts columns and also avg_tch_pnts
 
   Updated by: Majeed Mohammad
 Update on: 01/10/2018
 Purpose: Hardcoded the date filter for wave_launch_dt to 01/01/2017 based on email from Robert on 1/9/2018
 
 Updated By: Michael Andrien
 Updated On:  11/25/2019
 Purpose:  Added Life Stage Description to the bio scorecard grain and reworked the macro to calculate the total and net contact values as well as the average touch point attribute values in the insert/select.  This 
 				enabled me to eliminated the updates within the macro.
				
Updated By: Michael Andrien
 Updated On:  12/23/2019
 Purpose:  	Modified macro from a truncate and load script to limit the trunc and load to the current month.  This will preserve the monthly lifestage contact metric from month to month and 
 enable the business to assess lifestage contact metric snapshots over time. The macro runs daily and deletes and reloads the current month so monthly view will be present on the first day of the month 
 and the last day of the month reflects the final metrics for the month.  If we ran this as a full table truncate and load the life stage for a give donor would reflect the donor's current lifestage value, which skews metrics over time.
 
 Updated By: Michael Andrien
 Updated On:  01/02/2020
 Purpose:  Modified the date logic to 0 pad the month when the month is less the 10 (Oct).  The macro failed when we rolled over to Jan due to an invalid date format issue, which was caused by to single digit date.  Added
 the new month format below
 	case when extract(month from current_date) < 10 then '0'|| trim(extract(month from current_date)) else extract(month from current_date) end
 	
  Updated By: Majeed Mohammad
 Updated On:  10/01/2020
 Purpose:  	Updated this calcuation for date 
 	cast(trim(extract(year from current_date))||'-'|| case when extract(month from current_date) < 10 then '0'|| trim(extract(month from current_date)) else extract(month from current_date) end  ||'-01' as date format 'yyyy-mm-dd')
 	with  trunc(current_date, 'MM') . 
 	This calculation failed on 10/01/2020 because the function was missing the TRIM for the else part of the month and this caused extra spaces. This resulted in invalid date error. 
 */	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dv_de_scorcrd_campgns', 'Stored Procedure', 'Inprogress', v_start_time);


begin

delete  from mktg_ops_tbls.dv_de_scorcrd_campgns
where scr_mnth = DATE_TRUNC('month', CURRENT_DATE);

insert into mktg_ops_tbls.dv_de_scorcrd_campgns
(  		chanl, 
		scr_mnth, 
		life_stage_dsc,
		tot_contcts, 
		del_contcts,
		net_contcts,
		distnct_contcts, 
		avg_tch_pnts, 
		dw_trans_ts, 
		row_stat_cd, 
		appl_src_cd, 
		load_id
)

 select
 		chanl, 
		scr_mnth, 
		life_stage_dsc,
		tot_contcts, 
		del_contcts,
		net_contcts,
		distnct_contcts, 
		COALESCE(CAST(net_contcts::DECIMAL(13,2) / NULLIF(distnct_contcts, 0)::DECIMAL(13,2) AS DECIMAL(13,2)),0) AS avg_tch_pnts,
		--zeroifnull(cast(cast(net_contcts as decimal(13,2))/cast(distnct_contcts as decimal(13,2)) as decimal(13,2))) as avg_tch_pnts,
		dw_trans_ts, 
		row_stat_cd, 
		appl_src_cd, 
		load_id
 from 
 (
	 SELECT
	  map_chan as chanl,
		DATE_TRUNC('month', wave_launch_dt) as scr_mnth,/*Gets the first date of the Month */
	 	case when last_donation_dt <= current_date AND last_donation_dt >= ADD_MONTHS(current_date, -12) THEN 'Active Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -12) AND last_donation_dt >= ADD_MONTHS(current_date, -24) THEN 'Inactive Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -24) AND last_donation_dt >= ADD_MONTHS(current_date, -48) THEN 'Lapsed Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -48) AND last_donation_dt >= ADD_MONTHS(current_date, -60) THEN 'Moderately Lapsed Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -60) AND last_donation_dt >= ADD_MONTHS(current_date, -120) THEN 'Deeply Lapsed Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -120) THEN 'Extended Lapse Donor' 
				else 'No Productive Donat'
		end as life_stage_dsc,
		count(b.ssi_cntct_id) as tot_contcts,
		sum(case when b.multi_opp_delete_flg = 'Y' then 1 else 0 end) as del_contcts,
		COALESCE(count(b.ssi_cntct_id) - ((case when b.multi_opp_delete_flg = 'Y' then 1 else 0 end)),0) as net_contcts,
		count(distinct c.contact_key) as distnct_contcts,
	   current_timestamp(0) as dw_trans_ts, 'I' as row_stat_cd, 'MKTG' as appl_src_cd, 100 as load_id     
	 FROM
	  (select cntct_key,ssi_cntct_id,multi_opp_delete_flg,campgn_wave_key from eda.bio_campaign_vws.bz_fact_wave_cntct limit 50)b  
	   LEFT JOIN (
	   select map_chan, wave_launch_dt,camp_wave_key from eda.bio_campaign_vws.bz_dim_camp_wave where wave_launch_dt >= date_trunc('month', CURRENT_DATE) and map_chan  IN  ( 'Email','Text','App'  )
	   )a  ON b.campgn_wave_key=a.camp_wave_key
	   LEFT JOIN (select contact_key,last_donation_dt from eda.bio_appointment_vws.bzl_dim_contact )c ON b.cntct_key=c.contact_key  
	group by 1,2 ,3,b.ssi_cntct_id,b.multi_opp_delete_flg
	
	UNION ALL 
	
		 SELECT
	  cast ('All' as char(6)) as chanl,
	  DATE_TRUNC('month', wave_launch_dt) as scr_mnth,/*Gets the first date of the Month */
	 	case when last_donation_dt <= current_date AND last_donation_dt >= ADD_MONTHS(current_date, -12) THEN 'Active Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -12) AND last_donation_dt >= ADD_MONTHS(current_date, -24) THEN 'Inactive Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -24) AND last_donation_dt >= ADD_MONTHS(current_date, -48) THEN 'Lapsed Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -48) AND last_donation_dt >= ADD_MONTHS(current_date, -60) THEN 'Moderately Lapsed Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -60) AND last_donation_dt >= ADD_MONTHS(current_date, -120) THEN 'Deeply Lapsed Donor' 
				when last_donation_dt < ADD_MONTHS(current_date, -120) THEN 'Extended Lapse Donor' 
				else 'No Productive Donat'
		end as life_stage_dsc,
		count(b.ssi_cntct_id) as tot_contcts,
		sum(case when b.multi_opp_delete_flg = 'Y' then 1 else 0 end) as del_contcts,
		COALESCE(count(b.ssi_cntct_id) - ((case when b.multi_opp_delete_flg = 'Y' then 1 else 0 end)),0) as net_contcts,
		count(distinct c.contact_key) as distnct_contcts,
	   current_timestamp(0) as dw_trans_ts, 'I' as row_stat_cd, 'MKTG' as appl_src_cd, 100 as load_id     
	 FROM
	  (select cntct_key,ssi_cntct_id,multi_opp_delete_flg,campgn_wave_key from eda.bio_campaign_vws.bz_fact_wave_cntct limit 50)b  
	   LEFT JOIN (
	   select map_chan, wave_launch_dt,camp_wave_key from eda.bio_campaign_vws.bz_dim_camp_wave where wave_launch_dt >= date_trunc('month', CURRENT_DATE) and map_chan  IN  ( 'Email','Text','App'  )
	   )a  ON b.campgn_wave_key=a.camp_wave_key
	   LEFT JOIN (select contact_key,last_donation_dt from eda.bio_appointment_vws.bzl_dim_contact )c ON b.cntct_key=c.contact_key 
	   group by 1,2 ,3,b.ssi_cntct_id,b.multi_opp_delete_flg
 );
 
 	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = '';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message,recs_processed=cast((select count(*) from mktg_ops_tbls.dv_de_scorcrd_campgns) as INTEGER)
        WHERE proc_name = 'ld_dv_de_scorcrd_campgns' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_dv_de_scorcrd_campgns', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));		
    END;
END;
$$
