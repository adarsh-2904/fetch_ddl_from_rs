CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dv_digtl_engmnt_scorcrd()
 LANGUAGE plpgsql
AS $$
/*
Created By Michael Andrien
Create Date 03/24/2017
Purpose:  	This macro populates the summary table referenced by the Digital Engagement Scorecard dashboard.  The dashboard is used by the Biomed Marketing
					Reporting and Analytics team and provides near real-time access to the digital engagement KPIs.  The dashboard replaces a complex, static spreadsheet the team
					compiled on a monthly basis.  Updating the spreadsheet was a labor intensive process, which required the team to export the results from multiple Webi reports and import those results
					into the revised monthly spreadsheet.  This macro automates the process and saves the results into a summary table intended to optimize dashboard performance.
					
					The macro will evolve over time as we layer in more KPIs into the Scorecard.  The Scorecard dashboard presents the data to the team in condensed visual manure and allows them
					to drill into the metrics dynamically and requires no manual input from the end user group.

Modified By:  Mike Andrien
Modified Date: 5/15/2017
Purpose:  Added Cancelled appt logic to the appt count metrics - updated logic provided and tested by Robert Shoemake.

Modified By:  Majeed Mohammad
Modified Date: 2/29/2023
Purpose: Replaced the date interval function with add_months function to handle the leap year. 
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dv_digtl_engmnt_scorcrd', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
        -- Truncate staging table
        TRUNCATE TABLE mods_bi.mktg_stage_tbls.dv_digtl_engmnt_scorcrd_stg;
    
		-- Insert new data
		INSERT INTO mktg_stage_tbls.dv_digtl_engmnt_scorcrd_stg
		SELECT 
			a.apptmt_dt, 
			d.division_dsc, 
			e.calendar_mth_abbr, 
			e.calendar_mth,
			e.fiscal_mth, 
			e.fiscal_yr,
			SUM(CASE WHEN a.apptmt_origin IN ('Mobile App') THEN a.apptmt_ind ELSE 0 END) - 
			SUM(CASE WHEN a.apptmt_cancel_orig IS NOT NULL AND a.apptmt_origin IN ('Mobile App') THEN a.apptmt_ind ELSE 0 END) AS mobl_appt_count,
			SUM(CASE WHEN a.apptmt_origin IN ('Self', 'Self Mobile') THEN a.apptmt_ind ELSE 0 END) - 
			SUM(CASE WHEN a.apptmt_cancel_orig IS NOT NULL AND a.apptmt_origin IN ('Self', 'Self Mobile') THEN a.apptmt_ind ELSE 0 END) AS self_appt_count,
			SUM(CASE WHEN a.apptmt_origin IN ('Self', 'Self Mobile', 'Mobile App') THEN a.apptmt_ind ELSE 0 END) - 
			SUM(CASE WHEN a.apptmt_cancel_orig IS NOT NULL AND a.apptmt_origin IN ('Self', 'Self Mobile', 'Mobile App') THEN a.apptmt_ind ELSE 0 END) AS digital_appt_cnt,
			SUM(a.apptmt_ind) - 
			SUM(CASE WHEN a.apptmt_cancel_orig IS NOT NULL THEN a.apptmt_ind ELSE 0 END) AS total_appt_count,
			SUM(CASE WHEN a.apptmt_origin IN ('Self', 'Self Mobile', 'Mobile App') THEN a.apptmt_show_ind ELSE 0 END) AS digital_show_cnt,
			SUM(CASE WHEN a.apptmt_origin IN ('Self', 'Self Mobile', 'Mobile App') THEN a.productive_apptmt_ind ELSE 0 END) AS digital_prodctv_proc_cnt
		FROM
			eda.bio_appointment_vws.bzl_fact_appointment a
			LEFT JOIN eda.bio_common_vws.bz_dim_phleb c ON c.phleb_key = a.phleb_type_key
			LEFT JOIN eda.dw_common_vws.dim_region d ON d.region_key = a.region_key
			LEFT JOIN eda.dw_common_vws.dim_calendar e ON e.calendar_dt = a.apptmt_dt
		WHERE
			d.division_dsc IN ('East', 'West', 'Central') AND
			a.apptmt_cancel_orig IS NULL AND  
			(a.apptmt_dt >= DATEADD(month, -60, CURRENT_DATE) AND
			CASE WHEN c.dw_phleb_fam_type_dsc = 'Red Cell Apheresis' THEN 'Double Red Cell' ELSE c.dw_phleb_fam_type_dsc END IN ('Double Red Cell', 'Whole Blood'))
		GROUP BY 1, 2, 3, 4, 5, 6;
		
		-- Only proceed to target table if staging was successful
        TRUNCATE TABLE mods_bi.mktg_ops_tbls.dv_digtl_engmnt_scorcrd;
        
        -- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.dv_digtl_engmnt_scorcrd
        SELECT * FROM mods_bi.mktg_stage_tbls.dv_digtl_engmnt_scorcrd_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_ops_tbls.dv_digtl_engmnt_scorcrd) as INTEGER)
        WHERE proc_name = 'ld_dv_digtl_engmnt_scorcrd' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_dv_digtl_engmnt_scorcrd: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_dv_digtl_engmnt_scorcrd', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
