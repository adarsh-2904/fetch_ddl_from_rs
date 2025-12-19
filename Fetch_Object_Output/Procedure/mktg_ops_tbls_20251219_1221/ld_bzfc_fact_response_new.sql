CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_fact_response_new()
 LANGUAGE plpgsql
AS $_$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 11/05/2021
Purpose:  This macro was created to convert the flatted PG response data from the mktg_ops_vws.bzfc_pg_response_log view into normalized
PG response rows in the mktg_data_tbls.bzfc_fact_response_new.  This table has been added to the mktg_data_tbls.ld_bzfc_fact_response_all 
macro, which loads all the historic and new PG response data into one normalized table.  A responder can have one row per response type for each PG campaign - 
meaning we may have 1:M response rows from a consituent for a single campaign in this table.  

Modified By; Michael Andrien
Modified Date: 01/31/2022
Purpose:	Added qualifiers to the 4 Survery insert query sections to exclude records where the cnst_mstr_id is null.

Modified By; Majeed Mohammad
Modified Date: 09/09/2022
Purpose:	Temporarily added this SQL to update a bad record that resulted in .600.
This caused a failure in casting as decimal . 
DELETE this part after the record is fixed at the source

Modified by:	Greg Seaberg
Implemented by:	Michael Andrien
Modified Date:	02/13/2023
Purpose:	Added three new insert statements:
		1) FreeWill ARC in Will (PB / W1)
		2) FreeWill Beneficiary Designation (PB / W2)
		3) Supporter Survey Beneficiary Designation (PB / W2)
		
Modified By; Majeed Mohammad
Modified Date: 07/25/2023
Purpose:	Added the filter cnst_mstr_id is not null to fix the macro failures caused due to NOT NULL columns cnst_mstr_id 		

Modified By; Majeed Mohammad
Modified Date: 09/15/2023
Purpose:	Update the cast as decimal(11,2) to decimal(15,2) for the column lead_amt to fit the longer values. 

Modified By: 	Greg Seaberg
Implemented By: Michael Andrien
Modified Date: 	03/28/2024
Purpose:				In FY24, DM WG mailers changed a question from 'consider ARC in will' to 'bequest info request'; this query evaluates PG source codes looking for
									an effort code (character 8) of 2 and a vehicle code (character 9) of M along with a YYMM (characters 4 - 7) value > 2306

Modified By: 		Greg Seaberg
Implemented By: Michael Andrien
Modified Date: 	05/22/2024
Purpose:				Added MDS responses from FY24 Q4 GPLG calling campaign; this includes the following new response type values which have been added to
								the bz_arcpg_response_type table:
								
								INSERT INTO mktg_ops_tbls.bz_arcpg_response_typ
								(67,'W3', 'Intend ARC IN Will', 'PB','Bequest ID',
								        Current_Timestamp(0), 'I', 'ENGR', 70001, Current_Timestamp(0));
								INSERT INTO mktg_ops_tbls.bz_arcpg_response_typ
								(68,'N2', 'Undecided ARC IN Will', 'PN','Considering PG',
								        Current_Timestamp(0), 'I', 'ENGR', 70001, Current_Timestamp(0));
								INSERT INTO mktg_ops_tbls.bz_arcpg_response_typ
								(69,'OF', 'Do Not Intend ARC in Will', 'PO','Other OF',
								        Current_Timestamp(0), 'I', 'ENGR', 70001, Current_Timestamp(0));
								INSERT INTO mktg_ops_tbls.bz_arcpg_response_typ
								(70,'OG', 'No Interest/Refused', 'PO','Other OG',
								        Current_Timestamp(0), 'I', 'ENGR', 70001, Current_Timestamp(0));

Modified By; Majeed Mohammad
Modified Date: 08/23/2024
Purpose:	Updated the WHERE clauses for the column cga_other  to change the cast from  DECIMAL(11,2) to DECIMAL(25,2) . 
Updated all the references to DECIMAL columns as DECIMAL(25,2) . 

Modified By; Greg Seaberg and Michael Andrien
Modified Date: 04/04/2025
Purpose:  Added inserts for 'Intend To' response types and altered inserts for several survey and beneficiary desination questions.  See Teamwork ticket 12011841 for details.

Modified By; Greg Seaberg and Michael Andrien
Modified Date: 04/10/2025
Purpose:  Updated inserts assigned to 67 to 72.

Modified By: Greg Seaberg and Michael Andrien
Modified Date: 04/22/2025
Purpose:  Added inserts for PG Calc Gift Notification Form ARC in Will and Beneficiary Designation responses.
*/
/* 9/9/2022: Temporarily added this SQL to update a bad record that resulted in .600.
This caused a failure in casting as decimal . 
DELETE this part after the record is fixed at the source*/
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
    v_successful_inserts INTEGER := 0;
    v_failed_insert_number INTEGER := 0;
    v_total_inserts INTEGER := 40; 
    v_insert_error_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    
    -- Initialize audit log with INSERT
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_fact_response_new', 'Stored Procedure', 'Inprogress', v_start_time);
	
    -- Create all temp tables used by the inserts
    BEGIN
		DROP TABLE IF EXISTS ranked_src;
        DROP TABLE IF EXISTS dm;
        DROP TABLE IF EXISTS em;
        CREATE TEMP TABLE ranked_src AS
        SELECT 
            src_cd, 
            src_dsc, 
            src_key, 
            pg_src_cd
        FROM (
            SELECT 
                src_cd, 
                src_dsc, 
                src_key, 
                pg_src_cd,
                ROW_NUMBER() OVER(PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
            FROM mktg_ops_vws.gmpbzal_dim_src
        ) AS ranked
        WHERE rn = 1;

        CREATE TEMP TABLE dm AS
        SELECT 
            dmi.cnst_mstr_id, 
            dmi.src_cd, 
            dmi.subsrc_cd AS dm_subsrc_cd, 
            dmi.motivtn_cd, 
            dmi.rpt_cell_cd_id AS cell_id, 
            dmi.nk_treatmnt_id AS treatmnt_id, 
            dmi.segmnt_key AS segmnt_id, 
            dmi.list_run_dt AS run_dt
        FROM mktg_ops_vws.bzfc_fact_dmail_interaction dmi 
        LEFT JOIN mktg_ops_vws.bz_dim_campgn cmp ON dmi.campaign_key = cmp.campgn_key
        LEFT JOIN mktg_ops_vws.bz_dim_delivery dlv ON dmi.delivery_key = dlv.delivery_key
        WHERE cmp.campgn_lob_nm = 'Planned Giving'
            AND dmi.mailed_ind = 1
            AND dlv.exclude_rptng_ind = 0
            AND SUBSTRING(dlv.delivery_nm, 1, 3) <> 'FCP';

        CREATE TEMP TABLE em AS
        SELECT 
            emi.cnst_mstr_id, 
            emi.src_cd, 
            emi.subsrc_cd AS em_subsrc_cd, 
            emi.segmnt_key AS segmnt_id, 
            emi.email_id, 
            emi.list_run_dt AS run_dt
        FROM mktg_ops_vws.bzfc_fact_email_interaction emi 
        LEFT JOIN mktg_ops_vws.bz_dim_campgn cmp ON emi.campaign_key = cmp.campgn_key
        LEFT JOIN mktg_ops_vws.bz_dim_delivery dlv ON emi.delivery_key = dlv.delivery_key
        WHERE cmp.campgn_lob_nm = 'Planned Giving'
            AND emi.intrctn_status_key = 1
            AND dlv.exclude_rptng_ind = 0
            AND SUBSTRING(dlv.delivery_nm, 1, 3) <> 'FCP';

        -- TRUNCATE staging table
        TRUNCATE TABLE mktg_ops_tbls.bzfc_fact_response_new;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Handle errors during temp table creation
            v_end_time := GETDATE();
            v_error_message := 'Temp table creation failed: ' || SQLERRM;
            
            -- Update audit log
            UPDATE etl_config.audit_log
            SET status = 'Failed',
                end_time = v_end_time,
                TaskMessage = v_error_message
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            
            RAISE EXCEPTION 'Temp table creation failed: %', SQLERRM;
    END;
        
        -- Process each insert with individual commits
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*WG Requests Hard Copy Guide*/ 
		--1st Insert. 
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			19 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.wg_fdbk AS note_txt,
			TRIM(rl.wg_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.wg_rqst IN ('x', 'Y') 
			AND rl.appl_src_cd = 'CDS' 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL  
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
		
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*WG Downloads Electronic Guide*/
			--2nd Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			26 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.wg_fdbk AS note_txt,
			TRIM(rl.wg_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.wg_rqst IN ('x', 'Y') 
			AND rl.appl_src_cd = 'PGC' 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL  
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
        v_successful_inserts := v_successful_inserts + 1;
		/*WG Included ARC in Will*/
		--3rd Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			59 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.wg_fdbk AS note_txt,
			TRIM(rl.wg_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.wg_arc_in_will IN ('x', 'Y') 
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL  
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;		
		
	BEGIN
        v_successful_inserts := v_successful_inserts + 1;
		/*WG Considering ARC in Will*/
		--4th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			18 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.wg_fdbk AS note_txt,
			TRIM(rl.wg_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.wg_consider_arc_in_will IN ('x', 'Y')
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND CASE 
				WHEN SUBSTRING(src.pg_src_cd, 8, 2) = '2M' 
					 AND COALESCE(CAST(SUBSTRING(src.pg_src_cd, 4, 4) AS INTEGER), 0) > 2306 
				THEN 1 
				ELSE 0 
			  END = 0
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	BEGIN
        v_successful_inserts := v_successful_inserts + 1;
		/*WG Bequest Info Request*/
		--5th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			52 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.wg_fdbk AS note_txt,
			TRIM(rl.wg_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.wg_consider_arc_in_will IN ('x', 'Y') 
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND SUBSTRING(src.pg_src_cd, 8, 2) = '2M'
			AND COALESCE(CAST(SUBSTRING(src.pg_src_cd, 4, 4) AS INTEGER), 0) > 2306
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
        v_successful_inserts := v_successful_inserts + 1;		
		/*CGA Requests $5,000 CGA Illustration*/
		--6th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			29 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(5000 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.cga_fdbk AS note_txt,
			TRIM(rl.cga_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.cga_5000 IN ('x', 'Y')
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN		
        v_successful_inserts := v_successful_inserts + 1;		
		/*CGA Requests $10,000 CGA Illustration*/
		--7th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			46 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(10000 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.cga_fdbk AS note_txt,
			TRIM(rl.cga_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.cga_10000 IN ('x', 'Y')
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN		
        v_successful_inserts := v_successful_inserts + 1;	
		/*CGA Requests $50,000 CGA Illustration*/	
		--8th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			13 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(50000 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.cga_fdbk AS note_txt,
			TRIM(rl.cga_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.cga_50000 IN ('x', 'Y')
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*CGA Requests $100,000 CGA Illustration*/
		--9th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			39 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(100000 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.cga_fdbk AS note_txt,
			TRIM(rl.cga_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.cga_100000 IN ('x', 'Y')
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;

	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*CGA Requests $25,000 CGA Illustration*/	
		--10th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			12 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(25000 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.cga_fdbk AS note_txt,
			TRIM(rl.cga_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE CAST(
			NULLIF(
				REGEXP_REPLACE(rl.cga_other, '[^0-9.]', ''),
				''
			) AS DECIMAL(25,2)
		) = 25000.00
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*CGA Requests $200,000 CGA Illustration*/	
		--11th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			2 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(200000 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.cga_fdbk AS note_txt,
			TRIM(rl.cga_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE CAST(
			NULLIF(
				REGEXP_REPLACE(rl.cga_other, '[^0-9.]', ''),
				''
			) AS DECIMAL(25,2)
		) = 200000.00
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN		
		v_successful_inserts := v_successful_inserts + 1;
		/*CGA Requests CGA Illustration for Another Amount*/ 
		--12th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			20 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(
			NULLIF(
				REGEXP_REPLACE(rl.cga_other, '[^0-9.]', ''),
				''
			) AS DECIMAL(25,2)
			) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.cga_fdbk AS note_txt,
			TRIM(rl.cga_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			CAST(
				NULLIF(
					REGEXP_REPLACE(rl.cga_other, '[^0-9.]', ''),
					''
				) AS DECIMAL(25,2)
			) > 0 
			AND CAST(
				NULLIF(
					REGEXP_REPLACE(rl.cga_other, '[^0-9.]', ''),
					''
				) AS DECIMAL(25,2)
			) <> 25000.00 
			AND CAST(
				NULLIF(
					REGEXP_REPLACE(rl.cga_other, '[^0-9.]', ''),
					''
				) AS DECIMAL(25,2)
			) <> 200000.00 
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL  
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;

	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*CGA Requests CGA Illustration, But No Amount Specified*/
		--13th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			20 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.cga_fdbk AS note_txt,
			TRIM(rl.cga_fdbk) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			(rl.cga_5000 IS NULL OR LENGTH(TRIM(rl.cga_5000)) = 0) 
			AND (rl.cga_10000 IS NULL OR LENGTH(TRIM(rl.cga_10000)) = 0) 
			AND (rl.cga_50000 IS NULL OR LENGTH(TRIM(rl.cga_50000)) = 0) 
			AND (rl.cga_100000 IS NULL OR LENGTH(TRIM(rl.cga_100000)) = 0) 
			AND (
				rl.cga_other IS NULL 
				OR NOT(
					CAST(
						NULLIF(
							REGEXP_REPLACE(rl.cga_other, '[^0-9.]', ''),
							''
						) AS DECIMAL(25,2)
					) > 0
				)
			)
			AND SUBSTRING(src.pg_src_cd, 8, 1) = '1' 
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL  
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;

	BEGIN		
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey Donor Responded to Survey*/
		--14th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			41 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE SUBSTRING(src.pg_src_cd, 8, 1) = '4' 
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL  
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey Included ARC in Will*/
		--15th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			59 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			(rl.means_of_support_gift_in_your_will = 'Have done' 
			 OR rl.means_of_support_gift_in_your_will_honoring_a_loved_one = 'Have done')
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey Considering ARC in Will*/
		--16th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			18 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			(rl.means_of_support_gift_in_your_will = 'Would consider' 
			 OR rl.means_of_support_gift_in_your_will_honoring_a_loved_one = 'Would consider')
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey Requests More Information About Beneficiary Designation and Beneficiary Designation Campaign Interest in Gift Outside Will*/ 
		--17th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			54 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE
			(rl.means_of_support_beneficiary_designation = 'Would like more detail' 
			 OR (rl.interest_in_gift_outside_will = 'x' AND SUBSTRING(rl.scr_cd, 8, 1) = 'B'))
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Beneficiary Designation Campaign Will Guide ARC in Will*/ 
		--18th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			28 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE rl.wg_arc_in_will = 'x' 
			AND SUBSTRING(rl.scr_cd, 8, 1) = 'B'
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;

	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey Requests More Information About Estate Planning*/
		--19th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			17 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE
			(rl.means_of_support_gift_in_your_will = 'Would like more detail' 
			 OR rl.means_of_support_gift_in_your_will_honoring_a_loved_one = 'Would like more detail' 
			 OR rl.means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct = 'Would like more detail')
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;	
		/*Survey More Information on Life Income Gifts*/
		--20th Statement.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			23 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			(rl.interest_in_life_income_gifts IN ('x','Y') OR rl.means_of_support_gifts_that_pay_you_income_for_life = 'Would like more detail') 
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*CDRP CDRP Info Request*/
		--21st Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			17 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			NULL AS note_txt,
			TRIM(NULL) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			rl.cdrp_pg_info_request_pg_information IN ('x','Y') 
			AND rl.appl_src_cd IN ('CDS', 'PGC', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*CDRP Included ARC in Will*/
		--22nd Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			59 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			NULL AS note_txt,
			TRIM(NULL) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			rl.cdrp_pg_confirm_arc_in_will IN ('x','Y') 
			AND rl.appl_src_cd IN ('CDS','PGC','ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN	
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey More Information on Life Income Gifts*/ 
		--23rd Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			23 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			(rl.interest_in_life_income_gifts IN ('x','Y') OR rl.means_of_support_gifts_that_pay_you_income_for_life = 'Would like more detail') 
			AND rl.appl_src_cd IN ('CDS','PGC','ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey IRA QCD gift */
		--24th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			71 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			rl.means_of_support_gift_ira_chrtbl_dstrbtn = 'Have Done'
			AND Substring(rl.scr_cd, 4, 4) >= '2501'
			AND rl.appl_src_cd IN ('CDS', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
		
	BEGIN	
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey means_of_support_gift_in_your_will in ('Intend', 'Intend To')  */
		--25th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			72 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			rl.means_of_support_gift_in_your_will IN ('Intend', 'Intend To')
			AND SUBSTRING(rl.scr_cd, 4, 4) >= '2501'
			AND rl.appl_src_cd IN ('CDS', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey means_of_support_beneficiary_designation in ('Intend', 'Intend To')  */   
		--26th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			73 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			rl.means_of_support_beneficiary_designation IN ('Intend', 'Intend To')
			AND SUBSTRING(rl.scr_cd, 4, 4) >= '2501'
			AND rl.appl_src_cd IN ('CDS', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey means_of_support_gifts_that_pay_you_income_for_life in ('Intend', 'Intend To') */
		--27th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			74 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			rl.means_of_support_gifts_that_pay_you_income_for_life IN ('Intend', 'Intend To')
			AND SUBSTRING(rl.scr_cd, 4, 4) >= '2501'
			AND rl.appl_src_cd IN ('CDS', 'ADBE') 
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;

	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Survey means_of_support_gift_ira_chrtbl_dstrbtn in ('Intend', 'Intend To') */
		--28th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			75 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.arc_story AS note_txt,
			TRIM(rl.arc_story) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			rl.means_of_support_gift_ira_chrtbl_dstrbtn IN ('Intend', 'Intend To')
			AND SUBSTRING(rl.scr_cd, 4, 4) >= '2501'
			AND rl.appl_src_cd IN ('CDS', 'ADBE')
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
		
	BEGIN	
		v_successful_inserts := v_successful_inserts + 1;
		/*FreeWill Bequest and Contingent Bequest responses*/
		--29th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			59 AS response_typ_key,
			27 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			NULL AS treatmnt_id,
			NULL AS segmnt_id,
			NULL AS email_id,
			NULL AS cell_id,
			src.src_cd,
			NULL AS subsrc_cd,
			NULL::DATE AS run_dt,
			COALESCE(rl.new_gift_value_amt, rl.est_gift_value_amt)::DECIMAL(25,2) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(rl.chng_made_dt AS DATE) AS update_dt,
			rl.message AS note_txt,
			TRIM(rl.message) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		WHERE 
			rl.gift_typ IN ('Bequest', 'Contingent Bequest') 
			AND rl.appl_src_cd = 'FRWL' 
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*FreeWill Beneficiary and Contingent Beneficiary*/
		--30th Statement.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			28 AS response_typ_key,
			27 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			NULL AS treatmnt_id,
			NULL AS segmnt_id,
			NULL AS email_id,
			NULL AS cell_id,
			src.src_cd,
			NULL AS subsrc_cd,
			NULL::DATE AS run_dt,
			COALESCE(rl.new_gift_value_amt, rl.est_gift_value_amt)::DECIMAL(25,2) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(rl.chng_made_dt AS DATE) AS update_dt,
			rl.message AS note_txt,
			TRIM(rl.message) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		WHERE 
			rl.gift_typ IN ('Beneficiary', 'Contingent Beneficiary') 
			AND rl.appl_src_cd = 'FRWL' 
			AND rl.response_dt >= '2021-03-31'::DATE
			AND rl.cnst_mstr_id IS NOT NULL 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*Supporter survey beneficiary designations*/	
		--31st Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			28 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			NULL AS note_txt,
			TRIM(NULL) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE 
			rl.means_of_support_beneficiary_designation = 'Have Done' 
			AND rl.appl_src_cd IN ('CDS','ADBE') 
		/*  beneficiary designation added to supporter survey as of FY23 January*/
			AND CAST(SUBSTRING(src.pg_src_cd,4,4) AS INTEGER) >= 2301
			AND SUBSTRING(src.pg_src_cd,8,1) = '4'
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*MDS tele-engagement ARC in Will*/
		--32nd Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			59 AS response_typ_key,
			1 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			eoc.trtmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			eoc.rpt_cell_cd_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			eoc.cmnt AS note_txt,
			TRIM(eoc.cmnt) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		LEFT JOIN mktg_ops_tbls.phone_interaction_pg_eoc eoc 
			ON rl.mds_unq_id = eoc.unq_id
		WHERE 
			rl.mds_pg_response_typ = 'ARC IN WILL' 
			AND rl.appl_src_cd = 'MDS' 
			AND CASE WHEN rl.row_stat_cd = 'L' THEN 1 ELSE 0 END = 0 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*MDS tele-engagement Intend*/	
		--33rd Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			72 AS response_typ_key,
			1 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			eoc.trtmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			eoc.rpt_cell_cd_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			eoc.cmnt AS note_txt,
			TRIM(eoc.cmnt) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		LEFT JOIN mktg_ops_tbls.phone_interaction_pg_eoc eoc 
			ON rl.mds_unq_id = eoc.unq_id
		WHERE 
			rl.mds_pg_response_typ = 'INTEND' 
			AND rl.appl_src_cd = 'MDS' 
			AND CASE WHEN rl.row_stat_cd = 'L' THEN 1 ELSE 0 END = 0 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*MDS tele-engagement Consider*/
		--34th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			18 AS response_typ_key,
			1 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			eoc.trtmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			eoc.rpt_cell_cd_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			eoc.cmnt AS note_txt,
			TRIM(eoc.cmnt) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		LEFT JOIN mktg_ops_tbls.phone_interaction_pg_eoc eoc 
			ON rl.mds_unq_id = eoc.unq_id
		WHERE 
			rl.mds_pg_response_typ = 'CONSIDER' 
			AND rl.appl_src_cd = 'MDS' 
			AND CASE WHEN rl.row_stat_cd = 'L' THEN 1 ELSE 0 END = 0 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
		
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*MDS tele-engagement Undecided*/
		--35th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			68 AS response_typ_key,
			1 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			eoc.trtmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			eoc.rpt_cell_cd_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			eoc.cmnt AS note_txt,
			TRIM(eoc.cmnt) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		LEFT JOIN mktg_ops_tbls.phone_interaction_pg_eoc eoc 
			ON rl.mds_unq_id = eoc.unq_id
		WHERE 
			rl.mds_pg_response_typ = 'UNDECIDED' 
			AND rl.appl_src_cd = 'MDS' 
			AND CASE WHEN rl.row_stat_cd = 'L' THEN 1 ELSE 0 END = 0 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*MDS tele-engagement More Info*/
		--36th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			52 AS response_typ_key,
			1 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			eoc.trtmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			eoc.rpt_cell_cd_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			eoc.cmnt AS note_txt,
			TRIM(eoc.cmnt) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		LEFT JOIN mktg_ops_tbls.phone_interaction_pg_eoc eoc 
			ON rl.mds_unq_id = eoc.unq_id
		WHERE 
			rl.mds_pg_response_typ = 'MORE INFO' 
			AND rl.appl_src_cd = 'MDS' 
			AND CASE WHEN rl.row_stat_cd = 'L' THEN 1 ELSE 0 END = 0 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*MDS tele-engagement Don't Intend*/
		--37th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			69 AS response_typ_key,
			1 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			eoc.trtmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			eoc.rpt_cell_cd_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			eoc.cmnt AS note_txt,
			TRIM(eoc.cmnt) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		LEFT JOIN mktg_ops_tbls.phone_interaction_pg_eoc eoc 
			ON rl.mds_unq_id = eoc.unq_id
		WHERE 
			rl.mds_pg_response_typ LIKE 'DON%T INTEND' 
			AND rl.appl_src_cd = 'MDS' 
			AND CASE WHEN rl.row_stat_cd = 'L' THEN 1 ELSE 0 END = 0 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*MDS tele-engagement No Interest*/
		--38th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			70 AS response_typ_key,
			1 AS chan_typ_key,
			COALESCE(unt.unit_key, zu.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			eoc.trtmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			eoc.rpt_cell_cd_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(0 AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			eoc.cmnt AS note_txt,
			TRIM(eoc.cmnt) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				ztc.zip, 
				unt2.unit_key 
			FROM eda.dw_common_vws.geo_zip_code_to_chapter ztc
			LEFT JOIN eda.dw_common_vws.dim_unit unt2 
				ON ztc.ecode = unt2.nk_ecode
		) zu ON rl.zip_cd = zu.zip
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		LEFT JOIN mktg_ops_tbls.phone_interaction_pg_eoc eoc 
			ON rl.mds_unq_id = eoc.unq_id
		WHERE 
			rl.mds_pg_response_typ = 'NO INTEREST' 
			AND rl.appl_src_cd = 'MDS' 
			AND CASE WHEN rl.row_stat_cd = 'L' THEN 1 ELSE 0 END = 0 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*PG Calc Gift Notification Form Beneficiary Designation*/
		--39th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			28 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(est_gift_value_amt AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.gft_cmnts AS note_txt,
			TRIM(rl.gft_cmnts) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE
			TRIM(rl.gft_vhcl_dsc) IN ('Life Insurance Policy', 'IRA or retirement plan') 
			AND rl.lander_type = 'Notification'
			AND rl.appl_src_cd = 'PGC'
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		/*PG Calc Gift Notification Form ARC in Will*/ 
		--40th Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_new
		SELECT
			rl.pg_response_log_key,
			rl.cnst_mstr_id,
			rl.orig_cnst_mstr_id,
			bst.cnst_hsld_id,
			COALESCE(src.src_key, 0) AS src_key,
			1 AS comnictn_typ_key,
			59 AS response_typ_key,
			CASE WHEN rl.appl_src_cd = 'CDS' THEN 12 ELSE 27 END AS chan_typ_key,
			COALESCE(unt.unit_key, 0) AS unit_key,
			1 AS amt_typ_key,
			cal.calendar_key AS response_dt_key,
			rl.response_dt,
			src.src_dsc,
			dm.treatmnt_id,
			COALESCE(dm.segmnt_id, em.segmnt_id) AS segmnt_id,
			em.email_id,
			dm.cell_id,
			src.src_cd,
			COALESCE(dm.dm_subsrc_cd, em.em_subsrc_cd) AS subsrc_cd,
			COALESCE(dm.run_dt, em.run_dt) AS run_dt,
			CAST(est_gift_value_amt AS DECIMAL(25,2)) AS lead_amt,
			CAST(0.00 AS DECIMAL(25,2)) AS closed_amt,
			CAST(NULL AS DATE) AS update_dt,
			rl.gft_cmnts AS note_txt,
			TRIM(rl.gft_cmnts) AS trim_note_txt,
			'I' AS row_stat_cd,
			rl.appl_src_cd,
			CAST(0 AS INTEGER) AS load_id,
			rl.response_ts AS srcsys_trans_ts,
			CURRENT_TIMESTAMP AS dw_trans_ts
		FROM mktg_ops_vws.bzfc_pg_response_log rl
		LEFT JOIN ranked_src src ON rl.scr_cd = src.src_cd
		LEFT JOIN (
			SELECT 
				unit_key,
				nk_ecode
			FROM eda.dw_common_vws.dim_unit
		) as unt ON rl.nk_ecode = unt.nk_ecode
		LEFT JOIN (
			SELECT 
				calendar_key,
				calendar_dt
			FROM eda.dw_common_vws.dim_calendar
		) as cal ON rl.response_dt = cal.calendar_dt
		LEFT JOIN (
			SELECT 
				cnst_hsld_id,
				cnst_mstr_id
			FROM mktg_ops_vws.bzfc_arc_best_smry
		) as bst ON rl.cnst_mstr_id = bst.cnst_mstr_id
		LEFT JOIN dm ON rl.cnst_mstr_id = dm.cnst_mstr_id AND rl.scr_cd = dm.motivtn_cd
		LEFT JOIN em ON rl.cnst_mstr_id = em.cnst_mstr_id AND rl.scr_cd = em.src_cd
		WHERE
			TRIM(rl.gft_vhcl_dsc) IN ('Will/trust', 'Charitable Trust', 'Other', 'Prefer not to share') 
			AND rl.lander_type = 'Notification'
			AND rl.appl_src_cd = 'PGC'
			AND rl.response_dt >= '2021-03-31'::DATE 
			AND rl.cnst_mstr_id IS NOT NULL 
			AND rl.row_stat_cd <> 'L';
		COMMIT;
	EXCEPTION
        WHEN OTHERS THEN
            v_failed_insert_number := v_successful_inserts;
            v_insert_error_message := 'Failed at insert #' || v_failed_insert_number || ': ' || SQLERRM;
            -- Log this specific insert failure but continue
            RAISE NOTICE 'Insert % failed: %', v_failed_insert_number, SQLERRM;
            v_successful_inserts := v_successful_inserts - 1; -- Adjust counter since this insert failed
            
            -- Update audit log immediately when an insert fails
            UPDATE etl_config.audit_log
            SET TaskMessage = COALESCE(TaskMessage, '') || ' Insert #' || v_failed_insert_number || ' failed: ' || SQLERRM || ';'
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
		
    -- Continue this pattern for all your remaining inserts (INSERT #3, #4, etc.)
    -- Add more INSERT blocks here following the same pattern
    
    -- Final processing
    v_end_time := GETDATE();
    
    IF v_successful_inserts = v_total_inserts THEN
        -- All inserts succeeded
        v_ok_message := 'All ' || v_total_inserts || ' inserts completed successfully';
        
        UPDATE etl_config.audit_log
        SET status = 'Complete',
            end_time = v_end_time,
            recs_processed = (SELECT COUNT(*) FROM mktg_ops_tbls.bzfc_fact_response_new),
            TaskMessage = v_ok_message
        WHERE proc_name = 'ld_bzfc_fact_response_new' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;
    ELSE
        -- Some inserts failed
        v_error_message := v_successful_inserts || ' out of ' || v_total_inserts || ' inserts completed successfully. Check logs for failed inserts.';
        
        UPDATE etl_config.audit_log
        SET status = 'Partial Success',
            end_time = v_end_time,
            recs_processed = (SELECT COUNT(*) FROM mktg_ops_tbls.bzfc_fact_response_new),
            TaskMessage = v_error_message
        WHERE proc_name = 'ld_bzfc_fact_response_new' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;
    END IF;
    
    -- Cleanup temp tables
    DROP TABLE IF EXISTS ranked_src;
    DROP TABLE IF EXISTS dm;
    DROP TABLE IF EXISTS em;

EXCEPTION
    WHEN OTHERS THEN
        -- Final catch-all exception handler for any unexpected errors
        v_end_time := GETDATE();
        v_error_message := 'Procedure terminated unexpectedly: ' || SQLERRM || '. Completed ' || v_successful_inserts || ' out of ' || v_total_inserts || ' inserts.';
        
        -- Force audit log update even if procedure is terminating
        BEGIN
            UPDATE etl_config.audit_log
            SET status = 'Failed',
                end_time = v_end_time,
                recs_processed = COALESCE((SELECT COUNT(*) FROM mktg_ops_tbls.bzfc_fact_response_new), 0),
                TaskMessage = COALESCE(TaskMessage, '') || ' ' || v_error_message
            WHERE proc_name = 'ld_bzfc_fact_response_new' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT; -- Force commit of audit log update
        EXCEPTION
            WHEN OTHERS THEN
                -- If even the audit log update fails, at least log it
                RAISE NOTICE 'Failed to update audit log: %', SQLERRM;
        END;
        
        -- Cleanup temp tables in case of unexpected termination
        BEGIN
            DROP TABLE IF EXISTS ranked_src;
            DROP TABLE IF EXISTS dm;
            DROP TABLE IF EXISTS em;
        EXCEPTION
            WHEN OTHERS THEN
                -- Ignore cleanup errors
                NULL;
        END;
        
        -- Re-raise the original error with proper level and message
        RAISE EXCEPTION 'Procedure failed with error: %', v_error_message;
        
END;
$_$
