CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_active_cnst_multi_snpsht()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Andrien
Create Date:01/14/2019
Purpose:  This macro captures a monthly snapshot of our active multi-lob constituents.  The snapshot data helps the MODS team
				assess our 'AMulti-LOB Active Cnst'' metrics month over month and across an annual basis.  We'll use the data to compare active cnst_mstr_ids from month to month. 
				This makes it ease to track reactivation, lapsed and retention metrics.
				
				Snapshots are taken on the 5th of each month. Note, the first snapshot was taken on 1/11/2019.
				
Modified by: Majeed Mohammad
Modified on: 03/06/2019
Purpose: Updated the UPDATE statement. The UPDATE statement was using incorrect table in the WHERE clause. 

Modified by: Majeed Mohammad
Modified on: 03/11/2019
Purpose: Added the logic to run this macro SQLs only on the 5th of this month. If 5th is sunday, the macro runs on the 6th of the month 

Modified by: Michael Andrien
Modified on: 05/29/2019
Purpose: Added mobile donation attributes
*/
/* Check for merged master ids and update*/
/*Commented out by Majeed: 3/6/2019 */
/*UPDATE mktg_ops_tbls.bzfc_active_cnst_multi_snpsht
SET cnst_mstr_id = mktg_ops_vws.cnst_mstr_id_map.new_cnst_mstr_id
WHERE   mktg_ops_tbls.bzfc_active_cnst_snpsht.cnst_mstr_id =  mktg_ops_vws.cnst_mstr_id_map.cnst_mstr_id; */

/* Check for merged master ids and update*/
/*Updated by Majeed: 3/6/2019 */
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
    v_ins_count INT := 0;
    v_upd_count INT := 0;
    v_rows INT;
    v_is_run_day BOOLEAN := FALSE;
BEGIN
    v_start_time := GETDATE();
    
    -- Check if today is the run day
    v_is_run_day := (EXTRACT(DAY FROM CURRENT_DATE) = 5 AND EXTRACT(DOW FROM CURRENT_DATE) <> 0) OR
                    (EXTRACT(DAY FROM CURRENT_DATE) = 6 AND EXTRACT(DOW FROM CURRENT_DATE) = 1);
    
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_active_cnst_multi_snpsht', 'Stored Procedure', 'Inprogress', v_start_time);
    
    BEGIN
        IF v_is_run_day THEN
            UPDATE mktg_ops_tbls.bzfc_active_cnst_multi_snpsht
            SET cnst_mstr_id = map.new_cnst_mstr_id
            FROM mktg_ops_vws.cnst_mstr_id_map map
            WHERE mktg_ops_tbls.bzfc_active_cnst_multi_snpsht.cnst_mstr_id = map.cnst_mstr_id;
            
            GET DIAGNOSTICS v_rows = ROW_COUNT;
            v_upd_count := v_upd_count + v_rows;

            INSERT INTO mktg_ops_tbls.bzfc_active_cnst_multi_snpsht
            SELECT
                CAST(CURRENT_DATE AS DATE) AS snpsht_dt,
                cnst_mstr_id, 
                cnst_mstr_id AS orig_cnst_mstr_id,
                cnst_typ_cd, active_fr_ind, active_fr_flg,
                active_no_trans_fr_ind, active_no_trans_fr_flg, active_all_trans_fr_ind,
                active_all_trans_fr_flg, fr_first_dntn_dt, fr_patronage_day_cnt,
                fr_last_dntn_dt, rolling_2yr_dntn_amt, fr_month_lapsed_ind, fr_new_cnst_ind,
                active_fr_mbl_ind, active_fr_mbl_flg, first_mbl_gift_dt, last_mbl_gift_dt, mbl_gift_cnt, mbl_gift_amt,
                active_bio_ind, active_bio_flg, active_no_trans_bio_ind, active_no_trans_bio_flg,
                active_all_trans_bio_ind, active_all_trans_bio_flg, first_bio_donat_dt,
                bio_patronage_day_cnt, last_donat_dt, rolling_2yr_proc_cnt, bio_month_lapsed_ind,
                bio_new_cnst_ind, active_vms_ind, active_vms_flg, first_vol_dt,
                vol_patronage_day_cnt, active_rcs_ind, active_rcs_flg, first_rcs_order_dt,
                rcs_patronage_day_cnt, last_rcs_order_dt, rcs_month_lapsed_ind,
                rcs_new_cnst_ind, active_dmw_ind, active_dmw_flg, first_dmw_order_dt,
                dmw_patronage_day_cnt, last_dmw_order_dt, active_phss_ind, active_phss_flg,
                active_phss_rcs_ind, active_phss_rcs_flg, first_crs_cmptn_dt,
                phss_patronage_day_cnt, last_crs_cmptn_dt, phss_month_lapsed_ind,
                phss_new_cnst_ind, active_cnst_ind, active_cnst_flg, active_all_trans_cnst_ind,
                active_all_trans_cnst_flg, multi_lob_ind, multi_lob_flg, multi_lob_all_trans_ind,
                multi_lob_all_trans_flg, last_update_dt
            FROM mktg_ops_vws.bzfc_active_cnst_segmnt
            WHERE multi_lob_all_trans_ind = 1;
            
            GET DIAGNOSTICS v_rows = ROW_COUNT;
            v_ins_count := v_ins_count + v_rows;
            
            v_end_time := GETDATE();
            v_ok_message := v_ins_count || ' rows inserted, ' || v_upd_count || ' rows updated.';
            
            UPDATE etl_config.audit_log
            SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, 
                recs_processed = v_ins_count + v_upd_count
            WHERE proc_name = 'ld_bzfc_active_cnst_multi_snpsht' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
            
        ELSE
            v_end_time := GETDATE();
            v_ok_message := 'Procedure skipped: Today (' || TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD (Day)') || 
                           ') is not a scheduled run day. Runs only on 5th (not Sunday) or 6th (if 5th was Sunday).';
            
            UPDATE etl_config.audit_log
            SET status = 'Skipped', end_time = v_end_time, TaskMessage = v_ok_message, 
                recs_processed = 0
            WHERE proc_name = 'ld_bzfc_active_cnst_multi_snpsht' 
            AND task_name = 'Stored Procedure' 
            AND start_time = v_start_time;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
            v_error_message := 'Error in ld_bzfc_active_cnst_multi_snpsht: ' || SQLERRM;
            
            -- Log the error before raising the exception
            INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
            VALUES ('ld_bzfc_active_cnst_multi_snpsht', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

            -- Now raise the exception
            RAISE EXCEPTION 'An error occurred: %', SQLERRM;
    END;
END;
$$
