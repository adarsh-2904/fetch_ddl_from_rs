CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_arc_fr_giftran_stg()
 LANGUAGE plpgsql
AS $$
	
DECLARE
    v_increment_ts TIMESTAMP;
	v_max_processed_ts TIMESTAMP;
	v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
    v_procedure_nm VARCHAR(100) := 'ld_gms_arc_fr_giftran_stg';
    v_table_nm VARCHAR(100) := 'gms_arc_fr_giftran_stg';
 	v_record_count INT;
BEGIN
	v_start_time := CURRENT_TIMESTAMP;
    INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
    VALUES (v_procedure_nm, 'Stored Procedure', 'Inprogress', v_start_time);

    BEGIN
        -- Get the increment timestamp from the control table
        SELECT next_begin_dt INTO v_increment_ts
        FROM mods_bi.mktg_ops_tbls.load_control_table
        WHERE procedure_nm = v_procedure_nm
        AND table_nm = v_table_nm;
        
        -- If no record exists or v_increment_ts is null, use a default value
        /* IF v_increment_ts IS NULL THEN
			v_increment_ts := '1900-01-01 00:00:00'::TIMESTAMP;
         
            -- Insert a new control record if one doesn't exist
            INSERT INTO mods_bi.mktg_ops_tbls.load_control_table (procedure_nm, table_nm, next_begin_dt, dw_trans_ts)
            SELECT v_procedure_nm, v_table_nm, v_increment_ts, CURRENT_TIMESTAMP
            WHERE NOT EXISTS (
                SELECT 1 FROM mods_bi.mktg_ops_tbls.load_control_table
                WHERE procedure_nm = v_procedure_nm AND table_nm = v_table_nm
            );
        END IF; */

        -- Track the maximum source timestamp we're going to process
        -- This will be used to update the control table to ensure we don't skip records
        SELECT MAX(srcsys_update_ts) INTO v_max_processed_ts 
        FROM eda.ufds_vws.bzfc_fact_giftran 
        WHERE srcsys_update_ts > v_increment_ts;
        
		-- Default to the original increment timestamp if no records were found
		IF v_max_processed_ts IS NULL THEN
		    v_max_processed_ts := v_increment_ts;  -- No DATEADD here
		END IF;

        BEGIN
            TRUNCATE TABLE mods_bi.mktg_stage_tbls.gms_arc_fr_giftran_stg;
            
            INSERT INTO mktg_stage_tbls.gms_arc_fr_giftran_stg (
                giftran_key, 
                srcsys_update_ts, 
                dw_trans_ts, 
                row_stat_cd, 
                appl_src_cd, 
                load_id
            )
            SELECT 
                giftran_key, 
                CAST(srcsys_update_ts AS TIMESTAMP), 
                CAST(dw_trans_ts AS TIMESTAMP), 
                'I', 
                'MKTG', 
                100 
            FROM (
                SELECT  
                    giftran.giftran_key, 
                    CURRENT_TIMESTAMP AS srcsys_update_ts, 
                    CURRENT_TIMESTAMP AS dw_trans_ts
                FROM
                    eda.ufds_vws.bzfc_fact_giftran giftran 
                WHERE 
                    giftran.srcsys_update_ts > v_increment_ts
                
                UNION 
                
                SELECT 
                    a.giftran_key, 
                    CURRENT_TIMESTAMP, 
                    CURRENT_TIMESTAMP  
                FROM 
                    mods_bi.mktg_ops_tbls.gms_arc_fr_txn a 
                LEFT OUTER JOIN 
                    eda.ufds_vws.bzfc_fact_giftran b 
                    ON a.giftran_key = b.giftran_key 
                    AND b.active_ind = 1
                LEFT OUTER JOIN 
                    eda.ufds_vws.bzl_gift_cnst_mstr_brg c 
                    ON b.gift_cnst_grp_key = c.gift_cnst_grp_key
                    AND a.cnst_mstr_id = COALESCE(c.cnst_mstr_id, 0)  
                WHERE  
                    b.giftran_key IS NOT NULL 
                    AND a.cnst_mstr_id <> COALESCE(c.cnst_mstr_id, 0)  
                
                UNION 
                
                SELECT  
                    b.giftran_key, 
                    CURRENT_TIMESTAMP, 
                    CURRENT_TIMESTAMP  
                FROM 
                    eda.ufds_vws.bzfc_fact_giftran b 
                LEFT OUTER JOIN 
                    eda.ufds_vws.bzl_gift_cnst_mstr_brg c 
                    ON b.gift_cnst_grp_key = c.gift_cnst_grp_key
                LEFT OUTER JOIN 
                    mods_bi.mktg_ops_tbls.gms_arc_fr_txn a 
                    ON a.giftran_key = b.giftran_key 
                    AND a.cnst_mstr_id = COALESCE(c.cnst_mstr_id, 0)  
                WHERE  
                    b.active_ind = 1 
                    AND COALESCE(a.cnst_mstr_id, 0) <> COALESCE(c.cnst_mstr_id, 0)
            ) subq;
            
            -- Get the inserted row count
            SELECT COUNT(*) INTO v_record_count FROM mods_bi.mktg_stage_tbls.gms_arc_fr_giftran_stg;
            v_ok_message := CAST(v_record_count AS VARCHAR) || ' Records inserted.';
            
            -- Update the control table with the max processed timestamp
            UPDATE mods_bi.mktg_ops_tbls.load_control_table
            SET next_begin_dt = v_max_processed_ts,
                dw_trans_ts = CURRENT_TIMESTAMP
            WHERE procedure_nm = v_procedure_nm
            AND table_nm = v_table_nm;
            
            -- Log success
            UPDATE mods_bi.mktg_ops_tbls.audit_log
            SET status = 'Complete', end_time = CURRENT_TIMESTAMP, TaskMessage = v_ok_message
            WHERE proc_name = v_procedure_nm
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            
            COMMIT;
        END; -- Added missing END for the inner BEGIN block
        
    EXCEPTION
        WHEN OTHERS THEN
            IF EXISTS (SELECT 1 FROM pg_locks WHERE locktype = 'transactionid' AND pid = pg_backend_pid()) THEN
                ROLLBACK;
            END IF;
            
            v_end_time := CURRENT_TIMESTAMP;
            v_error_message := 'Error in ' || v_procedure_nm || ': ' || SQLERRM;

            SELECT COUNT(*) INTO v_record_count FROM mods_bi.mktg_stage_tbls.gms_arc_fr_giftran_stg;
            v_error_message := v_error_message || ' (Partial records inserted: ' || COALESCE(v_record_count::VARCHAR, '0') || ')';
            INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
            VALUES (v_procedure_nm, 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

            RAISE EXCEPTION '%', v_error_message;
    END;
END;
$$
