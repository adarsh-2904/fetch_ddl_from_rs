CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dv_de_accessblty_lifestg()
 LANGUAGE plpgsql
AS $$
/* 
Created on: Majeed Mohammad
Created on: 08/16/2017
Purpose: To load the table mktg_ops_tbls.dv_de_accessblty_lifestg.  Added this filter to run the macro on the 1st of each month :: extract(day from date) =1 

Modified By: Michael Andrien
Modified Date: 12/04/2019
Purpose: Altered the WHERE clause logic to run on the 1st expect if the 1st is on Sunday.  If the 1st is a Sunday then run on the 2nd when the calendar day of the week is Monday.  Added 
the joined to the shared calendar dimension on the current date to enable the day of week evaluation.

Modified By: Majeed Mohammad
Modified Date: 08/12/2021
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
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dv_de_accessblty_lifestg', 'Stored Procedure', 'Inprogress', v_start_time);
	
INSERT INTO mktg_ops_tbls.dv_de_accessblty_lifestg (
    run_dt, donor_lifestage, 
    phn_chan_accessible_cnt, txt_chan_accessible_cnt,
    em_chan_accessible_cnt, dm_chan_accessible_cnt, bz_app_chan_accessible_cnt
)
SELECT
    CASE 
        WHEN EXTRACT(day FROM cal.calendar_dt) = 1 THEN CURRENT_DATE
        WHEN EXTRACT(day FROM cal.calendar_dt) = 2 THEN CURRENT_DATE - INTERVAL '1 day'
    END AS run_dt,

    CASE
        WHEN most_recent_any_visit_dt BETWEEN dateadd(month, -12, CURRENT_DATE) AND CURRENT_DATE THEN 'Active Donor'
        WHEN most_recent_any_visit_dt BETWEEN dateadd(month, -24, CURRENT_DATE) AND CURRENT_DATE THEN 'Inactive Donor'
        WHEN most_recent_any_visit_dt BETWEEN dateadd(month, -48, CURRENT_DATE) AND CURRENT_DATE THEN 'Lapsed Donor'
    END AS donor_lifestage,

    SUM(CASE WHEN dc.phn_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) AS phn_chan_accessible_cnt,
    SUM(CASE WHEN dc.txt_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) AS txt_chan_accessible_cnt,
    SUM(CASE WHEN dc.em_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) AS em_chan_accessible_cnt,
    SUM(CASE WHEN dc.dm_chan_accessible_flg = 'Y' THEN 1 ELSE 0 END) AS dm_chan_accessible_cnt,
    
    SUM(CASE WHEN i.attribute_1_flg  = 'Y' THEN 1 ELSE 0 END) AS bz_app_chan_accessible_cnt


FROM  eda.bio_donation_vws.bz_dim_donor  a 

LEFT JOIN eda.bio_appointment_vws.bzl_dim_contact dc
            ON a.donor_external_id = dc.nk_key_donor

LEFT JOIN eda.dw_common_vws.dim_calendar cal
    ON cal.calendar_dt = CURRENT_DATE
    
LEFT JOIN eda.bio_donation_vws.bzal_fact_donation h 
            ON a.donor_id = h.donor_id
            
LEFT JOIN eda.drms_vws.bz_dim_donor_mktg i 
            ON h.contact_id = i.nk_contact_id

WHERE (
        (EXTRACT(day FROM cal.calendar_dt) = 1 AND cal.calendar_dow <> 'SUN')
     OR (EXTRACT(day FROM cal.calendar_dt) = 2 AND cal.calendar_dow = 'MON')
    )
  AND i.nxt_wb_rec_dt <= CURRENT_DATE + INTERVAL '115 days'
  AND donor_lifestage is not null
GROUP BY 1, 2;





--audit update	
			v_end_time := GETDATE();
            v_ok_message := '';
			
		UPDATE mods_bi.etl_config.audit_log
       	SET 
           status = 'Complete',
           end_time = v_end_time,
           TaskMessage = v_ok_message,
           recs_processed = (  SELECT CAST(COUNT(*) AS INTEGER) FROM mods_bi.mktg_ops_tbls.dv_de_accessblty_lifestg )
       WHERE 
           proc_name = 'ld_dv_de_accessblty_lifestg' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_dv_de_accessblty_lifestg', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

			
    END;

$$
