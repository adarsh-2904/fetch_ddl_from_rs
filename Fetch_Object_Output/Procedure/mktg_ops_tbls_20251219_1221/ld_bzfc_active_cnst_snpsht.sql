CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_active_cnst_snpsht()
 LANGUAGE plpgsql
AS $$

/*
Created by: Michael Andrien
Create Date:01/14/2019
Purpose: This macro captures a monthly snapshot of our active constituents. We'll keep 13 month of data in the table. The snapshot data helps the MODS team
assess our 'Active Cnst'' metrics month over month and across an annual basis. We'll use the data to compare active cnst_mstr_ids from month to month.
This makes it ease to track reactivation, lapsed and retention metrics.

Snapshots are taken on the 5th of each month. Note, the first snapshot was taken on 1/14/2019.

Modified by: Majeed Mohammad
Modified on: 03/11/2019
Purpose: Added the logic to run this macro SQLs only on the 5th of this month. If 5th is sunday, the macro runs on the 6th of the month

Modified by: Michael Andrien
Modified Date:05/29/2019
Purpose: Added mobile donation attributes

Modified by: Greg Seaberg
Implemented by: Michael Andrien
Modified Date:08/12/2022
Purpose: Expand snapshot lookback to 25 months

Modified By:  Michael Andrien
Modified Date: 03/24/2023
Purpose: Added the attributes listed below:
	active_dmw_course_ind,
	active_dmw_course_flg,
	active_dmw_store_ind,
	active_dmw_store_flg
	
Modified By:  Majeed Mohamamd
Modified Date: 07/21/2023
Purpose: 	Explicitly added the columns in the INSERT statement. Added the missing columns (active_multi_ever_ind, active_multi_ever_flg) in the SELECT part of the INSERT statement. 
	
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
	v_deleted_count INT;
	v_updated_count INT;
	v_inserted_count INT;
	

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_active_cnst_snpsht', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN

/* Delete rows where the snapshot data is older than 25 months (expanded from 13 months 8/12/2022). */
DELETE FROM mktg_ops_tbls.bzfc_active_cnst_snpsht
WHERE snpsht_dt < DATEADD(month, -25, DATE_TRUNC('month', current_date))
AND (
    CASE
        WHEN EXTRACT(DAY FROM current_date) = 5 AND EXTRACT(DOW FROM current_date) <> 0 THEN 1 -- Run the sql if it's 5th of month and day <> Sunday
        WHEN EXTRACT(DAY FROM current_date) = 6 AND EXTRACT(DOW FROM current_date) = 1 THEN 1 -- If the 5th of month falls on Sunday, run the sql on next day i.e. Monday (6th)
        ELSE 0
    END
) = 1;
-- Capture number of deleted rows
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;


/* Check for merged master ids and update*/
UPDATE mktg_ops_tbls.bzfc_active_cnst_snpsht AS tgt
SET 
    cnst_mstr_id = src.new_cnst_mstr_id,
    last_update_dt = TO_CHAR(current_date, 'YYYY-MM-DD')::date
FROM mktg_ops_vws.cnst_mstr_id_map AS src
WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
AND (
    CASE
        WHEN EXTRACT(DAY FROM current_date) = 5 AND EXTRACT(DOW FROM current_date) <> 0 THEN 1 -- Run the sql if it's 5th of month and day <> Sunday
        WHEN EXTRACT(DAY FROM current_date) = 6 AND EXTRACT(DOW FROM current_date) = 1 THEN 1 -- If the 5th of month falls on Sunday, run the sql on next day i.e. Monday (6th)
        ELSE 0
    END
) = 1;


-- Capture number of updated rows
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

/* Now insert the snapshot data */
insert into mktg_ops_tbls.bzfc_active_cnst_snpsht
(snpsht_dt, cnst_mstr_id, orig_cnst_mstr_id, cnst_typ_cd,
		active_fr_ind, active_fr_flg, active_no_trans_fr_ind, active_no_trans_fr_flg,
		active_all_trans_fr_ind, active_all_trans_fr_flg, fr_first_dntn_dt,
		fr_patronage_day_cnt, fr_last_dntn_dt, rolling_2yr_dntn_amt,
		fr_month_lapsed_ind, fr_new_cnst_ind, active_fr_mbl_ind, active_fr_mbl_flg,
		first_mbl_gift_dt, last_mbl_gift_dt, mbl_gift_cnt, mbl_gift_amt,
		active_bio_ind, active_bio_flg, active_no_trans_bio_ind, active_no_trans_bio_flg,
		active_all_trans_bio_ind, active_all_trans_bio_flg, first_bio_donat_dt,
		bio_patronage_day_cnt, last_donat_dt, rolling_2yr_proc_cnt, bio_month_lapsed_ind,
		bio_new_cnst_ind, active_vms_ind, active_vms_flg, first_vol_dt,
		vol_patronage_day_cnt, active_rcs_ind, active_rcs_flg, first_rcs_order_dt,
		rcs_patronage_day_cnt, last_rcs_order_dt, rcs_month_lapsed_ind,
		rcs_new_cnst_ind, active_dmw_ind, active_dmw_flg, active_dmw_course_ind,
		active_dmw_course_flg, active_dmw_store_ind, active_dmw_store_flg,
		first_dmw_order_dt, dmw_patronage_day_cnt, last_dmw_order_dt,
		active_phss_ind, active_phss_flg, active_phss_rcs_ind, active_phss_rcs_flg,
		first_crs_cmptn_dt, phss_patronage_day_cnt, last_crs_cmptn_dt,
		phss_month_lapsed_ind, phss_new_cnst_ind, active_cnst_ind, active_cnst_flg,
		active_all_trans_cnst_ind, active_all_trans_cnst_flg, multi_lob_ind,
		multi_lob_flg, multi_lob_all_trans_ind, multi_lob_all_trans_flg,
		active_multi_ever_ind, active_multi_ever_flg, last_update_dt) 

SELECT
    TO_CHAR(current_date, 'MM/DD/YYYY')::date AS snpsht_dt,
    cnst_mstr_id,
    cnst_mstr_id AS orig_cnst_mstr_id,
    cnst_typ_cd,
    active_fr_ind,
    active_fr_flg,
    active_no_trans_fr_ind,
    active_no_trans_fr_flg,
    active_all_trans_fr_ind,
    active_all_trans_fr_flg,
    fr_first_dntn_dt,
    fr_patronage_day_cnt,
    fr_last_dntn_dt,
    rolling_2yr_dntn_amt,
    fr_month_lapsed_ind,
    fr_new_cnst_ind,
    active_fr_mbl_ind,
    active_fr_mbl_flg,
    first_mbl_gift_dt,
    last_mbl_gift_dt,
    mbl_gift_cnt,
    mbl_gift_amt,
    active_bio_ind,
    active_bio_flg,
    active_no_trans_bio_ind,
    active_no_trans_bio_flg,
    active_all_trans_bio_ind,
    active_all_trans_bio_flg,
    first_bio_donat_dt,
    bio_patronage_day_cnt,
    last_donat_dt,
    rolling_2yr_proc_cnt,
    bio_month_lapsed_ind,
    bio_new_cnst_ind,
    active_vms_ind,
    active_vms_flg,
    first_vol_dt,
    vol_patronage_day_cnt,
    active_rcs_ind,
    active_rcs_flg,
    first_rcs_order_dt,
    rcs_patronage_day_cnt,
    last_rcs_order_dt,
    rcs_month_lapsed_ind,
    rcs_new_cnst_ind,
    active_dmw_ind,
    active_dmw_flg,
    active_dmw_course_ind,
    active_dmw_course_flg,
    active_dmw_store_ind,
    active_dmw_store_flg,
    first_dmw_order_dt,
    dmw_patronage_day_cnt,
    last_dmw_order_dt,
    active_phss_ind,
    active_phss_flg,
    active_phss_rcs_ind,
    active_phss_rcs_flg,
    first_crs_cmptn_dt,
    phss_patronage_day_cnt,
    last_crs_cmptn_dt,
    phss_month_lapsed_ind,
    phss_new_cnst_ind,
    active_cnst_ind,
    active_cnst_flg,
    active_all_trans_cnst_ind,
    active_all_trans_cnst_flg,
    multi_lob_ind,
    multi_lob_flg,
    multi_lob_all_trans_ind,
    multi_lob_all_trans_flg,
    active_multi_ever_ind,
    active_multi_ever_flg,
    last_update_dt
FROM mktg_ops_vws.bzfc_active_cnst_segmnt
WHERE EXISTS (SELECT 1
WHERE (
    (EXTRACT(DAY FROM current_date) = 5 AND EXTRACT(DOW FROM current_date) <> 0) -- 0 = Sunday
    OR
    (EXTRACT(DAY FROM current_date) = 6 AND EXTRACT(DOW FROM current_date) = 1) -- 1 = Monday
)
);

-- Capture number of inserted rows
    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;







--audit update	
	v_end_time := CURRENT_TIMESTAMP;
v_ok_message := 'Records Deleted:' || v_deleted_count::VARCHAR || ' || Updated:' || v_updated_count::VARCHAR || ' || Inserted:' || v_inserted_count::VARCHAR;
UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=	v_deleted_count::int+v_updated_count::int+v_inserted_count::int
        WHERE proc_name = 'ld_bzfc_active_cnst_snpsht' AND task_name = 'Stored Procedure' AND start_time = v_start_time;


	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bzfc_active_cnst_snpsht', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
