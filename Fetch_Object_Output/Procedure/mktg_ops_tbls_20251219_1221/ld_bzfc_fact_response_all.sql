CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_fact_response_all()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 05/14/2019
Purpose:  Created this macro to address performance issues with the original mktg_ops_vws.bzfc_fact_response all view, which contained all the joins in the insert SQL in this macro.
Below are the notes:

Created by: Michael Andrien
Created date: 2015-02-09
Purpose: This view was created to expose the Planned Giving Responses to the mktg_ops_vws 
                database for use in the DW Campaign Effectiveness universe.  The references
                the bz_fact_response_pg table in mktg_data_tbls, which is loaded from a macro.
                The macro populates legacy ARC Planned Giving (PG) constituent communication response records into
				the bz_fact_response_pg table.  The Marketing Business Intelligence team will continue to 
				load PG response data returned from BKV, the PG direct mail fullfillment vendor, and
				from email response dat  A view for the table can be found in the mktg_ops_vws 
				database and will be included in the Campaign Effectiveness Webi universe for reporting
						
Modified By Michael Andrien
Modified Date 2015-03-06
Purpose: 	Renamed the original bz_fact_response_pg view to bzfc_fact_response_all.  This view will UNION
				two fact response tables from mktg_data_tbls (bz_fact_reponse_pg, which contains the legacy ARC PG 
				response data and fact_response_aprm, which contains response data after ARC PG transitions to Aprimo.

Modified By: Michael Andrien
Modified Date: 2015-04-22
Purpose: Added Response Sequence Numbers (response_seq_num for leads and closed_response_seq_num for closed responses)
				 - A sequential number is applied to the response_seq_num 
				column to number each response related to a cnst_mstr_id, cell_src_cd combination.  The sequence
				number is referenced in the Campaign Effectiveness universe to define numbered response objects
				in the reporting universe.  This allows the reportng team to build reports with one line per campaign per constituent and 
				with the multiple responses on a single report line.

Modified By: Michael Andrien
Modified Date: 5/31/2018
Purpose:  Added zeroifnull(closed_amt) statements to SQL to null closed_amt values to 0.  This was necessary for sequence numbers to be assigned to each response row

Modified By: Michael Andrien
Modified Date: 03/14/2019
Purpose: Added the LOB preferred joins to the 2 union all queries and added the case statement in the selects to derive the unit_key.  The unit key was not getting set for aprm respons rows.
Greg Seaberg requested the change to resolve issues with the PG report for PG group.
-
Modified By: Michael Andrien
Modified Date: 03/18/2019
Purpose: Added orig_cnst_mstr_id
		
Modified By: Michael Andrien
Modified Date: 04/14/2020
Purpose:	Added logic to include both the src_key and comnictn_src_key so we can use this table in both the DDCOE CE universe and the GSM version of the CE universe.  The GMS universe
references the src_key and joins to mktg_ops_vws.gmpbzal_dim_src and the DDCOE CE universe referencts the mktg_ops_vws.bz_comnictn_src and join on the comnictn_src_key.

Modified By: Michael Andrien
Modified Date: 12/02/2020
Purpose:  Modified the case logic for setting the src_key in the insert query based on the fact_interaction_aprm table (the second insert section below.
Changed From:
	zeroifnull(case when aprm.src_key is null then src.src_key else aprm.src_key end) (TITLE  'GMS Communication Source Key'  ) as src_key,
To This:
	zeroifnull(case when aprm.src_key is null or aprm.src_key = 0 then src.src_key else aprm.src_key end) (TITLE  'GMS Communication Source Key'  ) as src_key

Modified By: Michael Andrien
Modified Date: 11/03/2021
Purpose: Added a third insert SQL to load the new data from the new bzfc_fact_pg_response_all_new table.  This contains the new data loaded from the flattened PG response table
the MODS team now manages.

Modified By: Michael Andrien
Modified Date: 11/10/2021
Purpose:  Added logic to set the response_seq_num and closed_response_seq_num values in the response new query.

Modified By: Michael Andrien
Modified Date: 11/19/2022
Purpose:	Renamec cnst_cdi_phss_smry_prfr to cnst_cdi_smry_phss_prfr

Modified By: Michael Andrien
Modified Date: 11/19/2022
Purpose:	Replaced gms_cnst_cdi_smry_fr_prfr to gms_gms_cnst_cdi_smry_fr_prfr

Modified By: Michael Andrien
Modified Date: 02/27/2025
Purpose: Added site_src to the table.
----------------------------------------------------------------------------------------------------------------------------------- */
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
    v_successful_inserts INTEGER := 0;
    v_failed_insert_number INTEGER := 0;
    v_total_inserts INTEGER := 3; 
    v_insert_error_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    
    -- Initialize audit log with INSERT
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_fact_response_all', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
        TRUNCATE TABLE mktg_ops_tbls.bzfc_fact_response_all;
        
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
            v_error_message := 'Truncate Table failed: ' || SQLERRM;
            
            -- Update audit log
            UPDATE etl_config.audit_log
            SET status = 'Failed',
                end_time = v_end_time,
                TaskMessage = v_error_message
            WHERE proc_name = 'ld_bzfc_fact_response_all' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            
            RAISE EXCEPTION 'Truncate Table failed: %', SQLERRM;
    END;
        
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		--1st Insert. 
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_all
		SELECT	
			0 AS pg_response_log_key,
			CAST(NULL AS VARCHAR(20)) AS site_src,
			frpg.cnst_mstr_id, 
			frpg.orig_cnst_mstr_id, 
			frpg.cnst_hsld_id,
			cnst_comnictn_key, 
			src_key,
			comnictn_src_key,
			comnictn_typ_key,
			response_typ_key,
			chan_typ_key,
			CASE WHEN frpg.unit_key <> 0 THEN frpg.unit_key
				 WHEN frp.mktg_unit_key <> 0 THEN frp.mktg_unit_key 
				 WHEN frp.unit_key <> 0 THEN frp.unit_key 
				 WHEN biop.mktg_unit_key <> 0 THEN biop.mktg_unit_key
				 WHEN biop.unit_key <> 0 THEN biop.unit_key
				 WHEN vmsp.mktg_unit_key <> 0 THEN vmsp.mktg_unit_key
				 WHEN vmsp.unit_key <> 0 THEN vmsp.unit_key
				 WHEN tsp.mktg_unit_key <> 0 THEN tsp.mktg_unit_key
				 WHEN tsp.unit_key <> 0 THEN tsp.unit_key
				 ELSE 0 
			END AS unit_key,
			amt_typ_key,
			response_dt_key,
			fr_last_ta_acct_id, 
			CAST(nk_response_dt AS DATE) AS nk_response_dt,
			nk_tapg_comnictn_seq, 
			nk_tapg_comnictn_seq_page, 
			comnictn_dsc,
			offer_id,
			treatment_id,
			activity_id,
			segmntn_id,
			segmnt_id,
			outbnd_id, 
			email_id,
			cell_id,
			cell_src_cd, 
			cell_subsrc_cd,
			CAST(run_dt AS DATE) AS run_dt,
			run_id,
			CASE WHEN NVL(closed_amt, 0) = 0 THEN ROW_NUMBER() OVER (PARTITION BY frpg.cnst_mstr_id, cell_src_cd ORDER BY nk_response_dt, nk_tapg_comnictn_seq, NVL(closed_amt, 0)) ELSE 0 END AS response_seq_num,
			CASE WHEN NVL(closed_amt, 0) > 0 THEN ROW_NUMBER() OVER (PARTITION BY frpg.cnst_mstr_id, cell_src_cd ORDER BY closed_amt DESC, nk_response_dt, nk_tapg_comnictn_seq) ELSE 0 END AS closed_response_seq_num,
			lead_amt,
			NVL(closed_amt, 0) AS closed_amt,
			CAST(update_dt AS DATE) AS update_dt,
			note_txt, 
			CAST(note_txt AS VARCHAR(1000)) AS trim_note_txt, 
			row_stat_cd,
			appl_src_cd, 
			load_id, 
			CAST(srcsys_trans_ts AS TIMESTAMP) AS srcsys_trans_ts, 
			CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
		FROM mktg_ops_tbls.bz_fact_response_pg frpg
		LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr frp 
			ON frpg.cnst_mstr_id = frp.cnst_mstr_id
		LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr biop 
			ON frpg.cnst_mstr_id = biop.cnst_mstr_id
		LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr vmsp 
			ON frpg.cnst_mstr_id = vmsp.cnst_mstr_id
		LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr tsp 
			ON frpg.cnst_mstr_id = tsp.cnst_mstr_id;
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
            WHERE proc_name = 'ld_bzfc_fact_response_all' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
		
	BEGIN
		v_successful_inserts := v_successful_inserts + 1;
		--2nd Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_all
		WITH src AS (
			SELECT 
				src_key, 
				src_cd,
				ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) as rn
			FROM eda.ufds_vws.gmpbzal_dim_src
		),
		filtered_src AS (
			SELECT 
				src_key, 
				src_cd
			FROM src
			WHERE rn = 1
		)
		SELECT	
			0 AS pg_response_log_key,
			CAST(NULL AS VARCHAR(20)) AS site_src,
			aprm.cnst_mstr_id, 
			aprm.orig_cnst_mstr_id, 
			aprm.cnst_hsld_id,
			CAST(0 AS BIGINT) AS cnst_comnictn_key, 
			NVL(CASE WHEN aprm.src_key IS NULL OR aprm.src_key = 0 THEN src.src_key ELSE aprm.src_key END, 0) AS src_key,
			comnictn_src_key,
			comnictn_typ_key,
			response_typ_key,
			chan_typ_key,
			CASE WHEN aprm.unit_key <> 0 THEN aprm.unit_key
				 WHEN frp.mktg_unit_key <> 0 THEN frp.mktg_unit_key 
				 WHEN frp.unit_key <> 0 THEN frp.unit_key 
				 WHEN biop.mktg_unit_key <> 0 THEN biop.mktg_unit_key
				 WHEN biop.unit_key <> 0 THEN biop.unit_key
				 WHEN vmsp.mktg_unit_key <> 0 THEN vmsp.mktg_unit_key
				 WHEN vmsp.unit_key <> 0 THEN vmsp.unit_key
				 WHEN tsp.mktg_unit_key <> 0 THEN tsp.mktg_unit_key
				 WHEN tsp.unit_key <> 0 THEN tsp.unit_key
				 ELSE 0 
			END AS unit_key,
			amt_typ_key,
			response_dt_key,
			fr_last_ta_acct_id, 
			nk_response_dt,
			CAST(0 AS DECIMAL(3,0)) AS nk_tapg_comnictn_seq, 
			CAST(0 AS DECIMAL(3,0)) AS nk_tapg_comnictn_seq_page, 
			comnictn_dsc,
			offer_id,
			treatment_id,
			activity_id,
			segmntn_id,
			segmnt_id,
			outbnd_id, 
			email_id,
			cell_id,
			cell_src_cd, 
			cell_subsrc_cd,
			run_dt,
			run_id,
			CASE WHEN NVL(closed_amt, 0) = 0 THEN ROW_NUMBER() OVER (PARTITION BY aprm.cnst_mstr_id, cell_src_cd ORDER BY nk_response_dt, NVL(closed_amt, 0)) ELSE 0 END AS response_seq_num,
			CASE WHEN NVL(closed_amt, 0) > 0 THEN ROW_NUMBER() OVER (PARTITION BY aprm.cnst_mstr_id, cell_src_cd ORDER BY closed_amt DESC, nk_response_dt) ELSE 0 END AS closed_response_seq_num,
			lead_amt,
			NVL(closed_amt, 0) AS closed_amt,
			update_dt,
			note_txt, 
			CAST(note_txt AS VARCHAR(1000)) AS trim_note_txt, 
			row_stat_cd,
			appl_src_cd, 
			load_id, 
			srcsys_trans_ts, 
			dw_trans_ts
		FROM mktg_ops_tbls.fact_response_aprm aprm
		LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr frp 
			ON aprm.cnst_mstr_id = frp.cnst_mstr_id
		LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr biop 
			ON aprm.cnst_mstr_id = biop.cnst_mstr_id
		LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr vmsp 
			ON aprm.cnst_mstr_id = vmsp.cnst_mstr_id
		LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr tsp 
			ON aprm.cnst_mstr_id = tsp.cnst_mstr_id
		LEFT JOIN filtered_src src 
			ON aprm.cell_src_cd = src.src_cd;
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
            WHERE proc_name = 'ld_bzfc_fact_response_all' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;
	
	BEGIN
        v_successful_inserts := v_successful_inserts + 1;
		--3rd Insert.
		INSERT INTO mktg_ops_tbls.bzfc_fact_response_all
		SELECT	
			a.pg_response_log_key, 
			b.site_src,
			CASE WHEN a.cnst_mstr_id > 0 THEN a.cnst_mstr_id
				 WHEN a.cnst_mstr_id = 0 AND orig_cnst_mstr_id > 0 THEN orig_cnst_mstr_id 
				 ELSE a.cnst_mstr_id 
			END AS cnst_mstr_id, 
			CASE WHEN orig_cnst_mstr_id > 0 THEN orig_cnst_mstr_id
				 WHEN orig_cnst_mstr_id = 0 AND a.cnst_mstr_id > 0 THEN a.cnst_mstr_id 
				 ELSE orig_cnst_mstr_id 
			END AS orig_cnst_mstr_id, 
			cnst_hsld_id,
			0 AS cnst_comnictn_key,
			src_key, 
			0 AS comnictn_src_key,
			comnictn_typ_key, 
			response_typ_key, 
			chan_typ_key, 
			unit_key,
			amt_typ_key, 
			response_dt_key, 
			0 AS fr_last_ta_acct_id,
			nk_response_dt, 
			CAST(0 AS DECIMAL(3,0)) AS nk_tapg_comnictn_seq,
			CAST(0 AS DECIMAL(3,0)) AS nk_tapg_comnictn_seq_page,
			src_dsc, 
			CAST(0 AS INTEGER) AS offer_id,
			treatment_id,
			CAST(0 AS INTEGER) AS activity_id,
			CAST(0 AS INTEGER) AS segmntn_id,
			segmnt_id, 
			0 AS outbnd_id,
			email_id, 
			cell_id, 
			src_cd, 
			subsrc_cd, 
			run_dt, 
			0 AS run_id,
			CASE WHEN NVL(closed_amt, 0) = 0 THEN 
				ROW_NUMBER() OVER (
					PARTITION BY 
						CASE WHEN a.cnst_mstr_id > 0 THEN a.cnst_mstr_id 
							 WHEN a.cnst_mstr_id = 0 AND orig_cnst_mstr_id > 0 THEN orig_cnst_mstr_id 
							 ELSE a.cnst_mstr_id 
						END, 
						src_cd 
					ORDER BY nk_response_dt, NVL(closed_amt, 0)
				) 
			ELSE 0 
			END AS response_seq_num,
			CASE WHEN NVL(closed_amt, 0) > 0 THEN 
				ROW_NUMBER() OVER (
					PARTITION BY 
						CASE WHEN a.cnst_mstr_id > 0 THEN a.cnst_mstr_id 
							 WHEN a.cnst_mstr_id = 0 AND orig_cnst_mstr_id > 0 THEN orig_cnst_mstr_id 
							 ELSE a.cnst_mstr_id 
						END, 
						src_cd 
					ORDER BY closed_amt DESC, nk_response_dt
				) 
			ELSE 0 
			END AS closed_response_seq_num,
			lead_amt,
			closed_amt, 
			update_dt, 
			note_txt, 
			trim_note_txt, 
			row_stat_cd,
			appl_src_cd, 
			load_id, 
			srcsys_trans_ts, 
			dw_trans_ts
		FROM mktg_ops_tbls.bzfc_fact_response_new a
		LEFT JOIN (
			SELECT 
				pg_response_log_key,
				cnst_mstr_id,
				site_src
			FROM mktg_ops_vws.bzfc_pg_response_log
			WHERE site_src IS NOT NULL
		) b ON a.pg_response_log_key = b.pg_response_log_key 
		   AND a.cnst_mstr_id = b.cnst_mstr_id;
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
            WHERE proc_name = 'ld_bzfc_fact_response_all' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT;
    END;		
    
    -- Final processing
    v_end_time := GETDATE();
    
    IF v_successful_inserts = v_total_inserts THEN
        -- All inserts succeeded
        v_ok_message := 'All ' || v_total_inserts || ' inserts completed successfully';
        
        UPDATE etl_config.audit_log
        SET status = 'Complete',
            end_time = v_end_time,
            recs_processed = (SELECT COUNT(*) FROM mktg_ops_tbls.bzfc_fact_response_all),
            TaskMessage = v_ok_message
        WHERE proc_name = 'ld_bzfc_fact_response_all' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;
    ELSE
        -- Some inserts failed
        v_error_message := v_successful_inserts || ' out of ' || v_total_inserts || ' inserts completed successfully. Check logs for failed inserts.';
        
        UPDATE etl_config.audit_log
        SET status = 'Partial Success',
            end_time = v_end_time,
            recs_processed = (SELECT COUNT(*) FROM mktg_ops_tbls.bzfc_fact_response_all),
            TaskMessage = v_error_message
        WHERE proc_name = 'ld_bzfc_fact_response_all' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;
    END IF;

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
                recs_processed = COALESCE((SELECT COUNT(*) FROM mktg_ops_tbls.bzfc_fact_response_all), 0),
                TaskMessage = COALESCE(TaskMessage, '') || ' ' || v_error_message
            WHERE proc_name = 'ld_bzfc_fact_response_all' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            COMMIT; -- Force commit of audit log update
        EXCEPTION
            WHEN OTHERS THEN
                -- If even the audit log update fails, at least log it
                RAISE NOTICE 'Failed to update audit log: %', SQLERRM;
        END;        
        -- Re-raise the original error with proper level and message
        RAISE EXCEPTION 'Procedure failed with error: %', v_error_message;
        
END;
$$
