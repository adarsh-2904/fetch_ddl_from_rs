CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dv_de_accessblty_overall()
 LANGUAGE plpgsql
AS $$
/* 
Created on: Majeed Mohammad
Created on: 08/16/2017
Purpose: To load the table mktg_ops_tbls.dv_de_accessblty_overall.   Added this filter to run the macro on the 1st of each month :: extract(day from date) =1 

Modified By: Michael Andrien
Modified Date: 12/04/2019
Purpose: Altered the WHERE clause logic to run on the 1st expect if the 1st is on Sunday.  If the 1st is a Sunday then run on the 2nd when the calendar day of the week is Monday.  Added 
the joined to the shared calendar dimension on the current date to enable the day of week evaluation.

Modified By: Majeed Mohammad
Modified Date: 01/02/2020
Purpose:  Updated the logic for run_dt from Current_date-2  to this to populate the 1st of each month. 
				case when extract(day from date) =1 then Current_date 
				 when extract(day from date) =2 then Current_date-1 end  as run_dt


*/	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dv_de_accessblty_overall', 'Stored Procedure', 'Inprogress', v_start_time);


begin

insert into mktg_ops_tbls.dv_de_accessblty_overall
(	run_dt, phn_chan_accessible_cnt, phn_chan_prct, txt_chan_accessible_cnt,
		txt_chan_prct, em_chan_accessible_cnt, em_chan_prct, dm_chan_accessible_cnt,
		dm_chan_prct, bz_app_chan_accessible_cnt, app_chan_prct, cnst_cnt) 

--create table mktg_ops_tbls.dv_de_accessblty_overall as 
SELECT
  CASE 
    WHEN EXTRACT(DAY FROM CURRENT_DATE) = 1 THEN CURRENT_DATE
    WHEN EXTRACT(DAY FROM CURRENT_DATE) = 2 THEN CURRENT_DATE - 1
  END AS run_dt,

  COUNT(DISTINCT a.cnst_mstr_id) AS cnst_cnt,

  SUM(CASE WHEN a.phn_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) AS phn_chan_accessible_cnt,
  SUM(CASE WHEN a.phn_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT a.cnst_mstr_id) AS phn_chan_prct,

  SUM(CASE WHEN a.txt_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) AS txt_chan_accessible_cnt,
  SUM(CASE WHEN a.txt_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT a.cnst_mstr_id) AS txt_chan_prct,

  SUM(CASE WHEN a.em_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) AS em_chan_accessible_cnt,
  SUM(CASE WHEN a.em_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT a.cnst_mstr_id) AS em_chan_prct,

  SUM(CASE WHEN a.dm_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) AS dm_chan_accessible_cnt,
  SUM(CASE WHEN a.dm_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT a.cnst_mstr_id) AS dm_chan_prct,

  SUM(CASE WHEN b.attribute_1_flg = 'Y' THEN 1 ELSE 0 END) AS bz_app_chan_accessible_cnt,
  SUM(CASE WHEN b.attribute_1_flg = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT a.cnst_mstr_id) AS app_chan_prct

FROM (
  SELECT 
    contact_key,
    cnst_mstr_id,
    phn_chan_accessible_flg,
    dm_chan_accessible_flg,
    em_chan_accessible_flg,
    txt_chan_accessible_flg,
    nxt_wb_recruit_dt,
    nk_key_donor
  FROM eda.bio_appointment_vws.bzl_dim_contact
) a

LEFT JOIN eda.drms_vws.bz_dim_donor_mktg b 
  ON a.contact_key = b.contact_key

LEFT JOIN eda.dw_common_vws.dim_calendar cal 
  ON cal.calendar_dt = CURRENT_DATE

LEFT JOIN (select donor_id,most_recent_any_visit_dt from eda.bio_donation_vws.bz_dim_donor) donor 
  ON a.nk_key_donor = donor.donor_id

WHERE (
    (EXTRACT(DAY FROM CURRENT_DATE) = 1 AND cal.calendar_dow <> 'SUN') 
    OR (EXTRACT(DAY FROM CURRENT_DATE) = 2 AND cal.calendar_dow = 'MON')
  )
  AND a.nxt_wb_recruit_dt <= CURRENT_DATE - 2 + 115
  AND donor.most_recent_any_visit_dt >= CURRENT_DATE - INTERVAL '4 year'

GROUP BY 1;


	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.dv_de_accessblty_overall) as nvarchar)+ ' Records inserted.';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_dv_de_accessblty_overall' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_dv_de_accessblty_overall', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
			
    END;
END;
$$
