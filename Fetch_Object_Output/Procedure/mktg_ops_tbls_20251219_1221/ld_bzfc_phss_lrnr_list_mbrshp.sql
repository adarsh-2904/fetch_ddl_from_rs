CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_phss_lrnr_list_mbrshp()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 08-Sept-2015
Purpose: This macro populates the PHSS Learner Recert List Membership table (mktg_ops_tbls.bz_phss_lrnr_list_membrshp)
				from the source view mktg_ops_vws.phss_lrnr_list_membrshp_src.  The source view contains the selection
				logic for each of the PHSS Learner recertification campaigns.  The initial source view contains 6 learner recert list definitions, 
				which define the 30,60 and 90 day recert groups for CPR Professionals (CPRO) and Non-CPR Professional courses.  The non-CPR professional 
				courses include first aid, lifegaurding and other CPR and non-CPR related courses.  The MACRO was created to instantiate the view to improve selection
				performance.  The macro inserts rows to the previous list and does not delete the previous entries.  A second macro will be required to archive older, unused list
				data.
				
Modified by: Majeed Mohammad
Modified date: 1/14/2016
Purpose: Added the filter in the WHERE clause to check if day_of_week=7 (Saturday). This ensures that the macro is run once a week on Saturdays 
------------------------------------------------------------------------------------------------------------------------------------ */
/* Below comment is for mktg_ops_vws.phss_lrnr_list_membrshp_src, which used to be in Teradata but is now incorporated into this stored procedure */
/* 
	Created By Michael Andrien
	Created Date 26-August-2015
	Purpose: This view provides the logic to populate the bzfc_phss_lrnr_list_membrshp table in mktg_ops_tbls.  Each unioned select SQL block below provides the logic
					for selecting the constituents that meet the criteria for a defined PHSS campaign list.  The macro mktg_data_tbls.ld_phss_lrnr_recert_tbls is run daily and references this view
					to physically instantiate the mktg_data_tbls.bzfc_phss_lrnr_list_membrshp table. The table is copied from the EDW TD server to the MKTG TD server daily through an Informatica sync mapping 
					and exposed to Aprimo in aprimo_wrk_tbls database.  The pre-built PHSS campaign lists are intended to simplify the PHSS compaign Segmentation List definitions in Aprimo.  NOTE: The
					list membership view does not apply the list suppressions - these will be applied in Aprimo.
	
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_phss_lrnr_list_mbrshp', 'Stored Procedure', 'Inprogress', v_start_time);

    BEGIN
        -- Check if today is Saturday (dow = 6)
        IF EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN

            -- Truncate staging table
            TRUNCATE TABLE mods_bi.mktg_stage_tbls.bzfc_phss_lrnr_list_membrshp_stg;

            -- Insert into staging table
            INSERT INTO mods_bi.mktg_stage_tbls.bzfc_phss_lrnr_list_membrshp_stg (
                list_typ_key, cnst_mstr_id, cert_expire_dt, membrshp_start_dt,
                membrshp_end_dt, course_nm, earliestexpmth, subject_area, focis_pgm,
                lrnrcert_comp1, lrnrcert_exp_dt1, lrnrcert_comp2, lrnrcert_exp_dt2,
                lrnrcert_comp3, lrnrcert_exp_dt3, lrnrcert_comp4, lrnrcert_exp_dt4,
                lrnrcert_comp5, lrnrcert_exp_dt5, list_run_dt,
                dw_create_ts, dw_update_ts
            )
			With phss_lrnr_list_membrshp_src AS (
				SELECT
					1 AS list_typ_key, 
					cnst_mstr_id, 
					LrnrCert_ExpDt1 AS cert_expire_dt,
					LrnrCert_ExpDt1 AS membrshp_start_dt,
					NULL::date AS membrshp_end_dt,
					course_nm,
					earliestexpmth,
					NULL AS subject_area,
					course_focis_pgm AS focis_pgm,
					lrnrcert_comp1,
					LrnrCert_ExpDt1 AS lrnrcert_exp_dt1,
					lrnrcert_comp2,
					LrnrCert_ExpDt2 AS lrnrcert_exp_dt2,
					lrnrcert_comp3,
					LrnrCert_ExpDt3 AS lrnrcert_exp_dt3,
					lrnrcert_comp4,
					LrnrCert_ExpDt4 AS lrnrcert_exp_dt4,
					lrnrcert_comp5,
					LrnrCert_ExpDt5 AS lrnrcert_exp_dt5,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_create_ts,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_update_ts 
				FROM data_lab_mktg_tbls.phss_lrnr_recert_pivot
				WHERE LrnrCert_ExpDt1 >= GETDATE() + 35 
				AND LrnrCert_ExpDt1 <= GETDATE() + 41
				AND course_focis_pgm LIKE '%PRO%'

				UNION 

				SELECT
					2 AS list_typ_key, 
					cnst_mstr_id, 
					LrnrCert_ExpDt1 AS cert_expire_dt,
					LrnrCert_ExpDt1 AS membrshp_start_dt,
					NULL AS membrshp_end_dt,
					course_nm,
					earliestexpmth,
					NULL AS subject_area,
					course_focis_pgm AS focis_pgm,
					lrnrcert_comp1,
					LrnrCert_ExpDt1 AS lrnrcert_exp_dt1,
					lrnrcert_comp2,
					LrnrCert_ExpDt2 AS lrnrcert_exp_dt2,
					lrnrcert_comp3,
					LrnrCert_ExpDt3 AS lrnrcert_exp_dt3,
					lrnrcert_comp4,
					LrnrCert_ExpDt4 AS lrnrcert_exp_dt4,
					lrnrcert_comp5,
					LrnrCert_ExpDt5 AS lrnrcert_exp_dt5,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_create_ts,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_update_ts 
				FROM data_lab_mktg_tbls.phss_lrnr_recert_pivot
				WHERE LrnrCert_ExpDt1 >= GETDATE() + 65 
				AND LrnrCert_ExpDt1 <= GETDATE() + 71
				AND course_focis_pgm LIKE '%PRO%'

				UNION

				SELECT
					3 AS list_typ_key, 
					cnst_mstr_id, 
					LrnrCert_ExpDt1 AS cert_expire_dt,
					LrnrCert_ExpDt1 AS membrshp_start_dt,
					NULL AS membrshp_end_dt,
					course_nm,
					earliestexpmth,
					NULL AS subject_area,
					course_focis_pgm AS focis_pgm,
					lrnrcert_comp1,
					LrnrCert_ExpDt1 AS lrnrcert_exp_dt1,
					lrnrcert_comp2,
					LrnrCert_ExpDt2 AS lrnrcert_exp_dt2,
					lrnrcert_comp3,
					LrnrCert_ExpDt3 AS lrnrcert_exp_dt3,
					lrnrcert_comp4,
					LrnrCert_ExpDt4 AS lrnrcert_exp_dt4,
					lrnrcert_comp5,
					LrnrCert_ExpDt5 AS lrnrcert_exp_dt5,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_create_ts,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_update_ts 
				FROM data_lab_mktg_tbls.phss_lrnr_recert_pivot
				WHERE LrnrCert_ExpDt1 >= GETDATE() + 95 
				AND LrnrCert_ExpDt1 <= GETDATE() + 101
				AND course_focis_pgm LIKE '%PRO%'

				UNION

				SELECT
					4 AS list_typ_key, 
					cnst_mstr_id, 
					LrnrCert_ExpDt1 AS cert_expire_dt,
					LrnrCert_ExpDt1 AS membrshp_start_dt,
					NULL AS membrshp_end_dt,
					course_nm,
					earliestexpmth,
					NULL AS subject_area,
					course_focis_pgm AS focis_pgm,
					lrnrcert_comp1,
					LrnrCert_ExpDt1 AS lrnrcert_exp_dt1,
					lrnrcert_comp2,
					LrnrCert_ExpDt2 AS lrnrcert_exp_dt2,
					lrnrcert_comp3,
					LrnrCert_ExpDt3 AS lrnrcert_exp_dt3,
					lrnrcert_comp4,
					LrnrCert_ExpDt4 AS lrnrcert_exp_dt4,
					lrnrcert_comp5,
					LrnrCert_ExpDt5 AS lrnrcert_exp_dt5,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_create_ts,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_update_ts 
				FROM data_lab_mktg_tbls.phss_lrnr_recert_pivot
				WHERE LrnrCert_ExpDt1 >= GETDATE() + 35 
				AND LrnrCert_ExpDt1 <= GETDATE() + 41
				AND course_focis_pgm NOT LIKE '%PRO%'

				UNION

				SELECT
					5 AS list_typ_key, 
					cnst_mstr_id, 
					LrnrCert_ExpDt1 AS cert_expire_dt,
					LrnrCert_ExpDt1 AS membrshp_start_dt,
					NULL AS membrshp_end_dt,
					course_nm,
					earliestexpmth,
					NULL AS subject_area,
					course_focis_pgm AS focis_pgm,
					lrnrcert_comp1,
					LrnrCert_ExpDt1 AS lrnrcert_exp_dt1,
					lrnrcert_comp2,
					LrnrCert_ExpDt2 AS lrnrcert_exp_dt2,
					lrnrcert_comp3,
					LrnrCert_ExpDt3 AS lrnrcert_exp_dt3,
					lrnrcert_comp4,
					LrnrCert_ExpDt4 AS lrnrcert_exp_dt4,
					lrnrcert_comp5,
					LrnrCert_ExpDt5 AS lrnrcert_exp_dt5,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_create_ts,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_update_ts 
				FROM data_lab_mktg_tbls.phss_lrnr_recert_pivot
				WHERE LrnrCert_ExpDt1 >= GETDATE() + 65 
				AND LrnrCert_ExpDt1 <= GETDATE() + 71
				AND course_focis_pgm NOT LIKE '%PRO%'

				UNION

				SELECT
					6 AS list_typ_key, 
					cnst_mstr_id, 
					LrnrCert_ExpDt1 AS cert_expire_dt,
					LrnrCert_ExpDt1 AS membrshp_start_dt,
					NULL AS membrshp_end_dt,
					course_nm,
					earliestexpmth,
					NULL AS subject_area,
					course_focis_pgm AS focis_pgm,
					lrnrcert_comp1,
					LrnrCert_ExpDt1 AS lrnrcert_exp_dt1,
					lrnrcert_comp2,
					LrnrCert_ExpDt2 AS lrnrcert_exp_dt2,
					lrnrcert_comp3,
					LrnrCert_ExpDt3 AS lrnrcert_exp_dt3,
					lrnrcert_comp4,
					LrnrCert_ExpDt4 AS lrnrcert_exp_dt4,
					lrnrcert_comp5,
					LrnrCert_ExpDt5 AS lrnrcert_exp_dt5,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_create_ts,
					CAST(CAST(GETDATE() AS VARCHAR(19)) AS TIMESTAMP) AS dw_update_ts 
				FROM data_lab_mktg_tbls.phss_lrnr_recert_pivot
				WHERE LrnrCert_ExpDt1 >= GETDATE() + 95
				AND LrnrCert_ExpDt1 <= GETDATE() + 101
				AND course_focis_pgm NOT LIKE '%PRO%')
            SELECT
                list_typ_key,
                cnst_mstr_id,
                cert_expire_dt,
                membrshp_start_dt,
                membrshp_end_dt,
                course_nm,
                earliestexpmth,
                subject_area,
                focis_pgm,
                lrnrcert_comp1,
                lrnrcert_exp_dt1,
                lrnrcert_comp2,
                lrnrcert_exp_dt2,
                lrnrcert_comp3,
                lrnrcert_exp_dt3,
                lrnrcert_comp4,
                lrnrcert_exp_dt4,
                lrnrcert_comp5,
                lrnrcert_exp_dt5,
                CURRENT_DATE AS list_run_dt,
                dw_create_ts,
                dw_update_ts
            FROM phss_lrnr_list_membrshp_src;

            TRUNCATE TABLE mods_bi.mktg_ops_tbls.bzfc_phss_lrnr_list_membrshp;

            INSERT INTO mods_bi.mktg_ops_tbls.bzfc_phss_lrnr_list_membrshp
            SELECT * FROM mods_bi.mktg_stage_tbls.bzfc_phss_lrnr_list_membrshp_stg;

            v_end_time := GETDATE();
            v_ok_message := 'Records inserted.';

            UPDATE etl_config.audit_log
            SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = CAST((SELECT COUNT(*) FROM mods_bi.mktg_ops_tbls.bzfc_phss_lrnr_list_membrshp) AS INTEGER)
            WHERE proc_name = 'ld_bzfc_phss_lrnr_list_mbrshp' 
              AND task_name = 'Stored Procedure' 
              AND start_time = v_start_time;

        ELSE
            v_end_time := GETDATE();
            v_ok_message := 'Procedure skipped: Today is not Saturday.';

            UPDATE etl_config.audit_log
            SET status = 'Skipped', end_time = v_end_time, TaskMessage = v_ok_message
            WHERE proc_name = 'ld_bzfc_phss_lrnr_list_mbrshp' 
              AND task_name = 'Stored Procedure' 
              AND start_time = v_start_time;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
            v_error_message := 'Error in ld_bzfc_phss_lrnr_list_mbrshp: ' || SQLERRM;

            INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
            VALUES ('ld_bzfc_phss_lrnr_list_mbrshp', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

            RAISE EXCEPTION 'An error occurred: %', SQLERRM;
    END;
END;
$$
