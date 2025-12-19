CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_arc_vms_txn()
 LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_arc_vms_txn', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN
		-- Truncate the staging table before loading new data
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.arc_vms_txn_stg;
		-- Load data into staging table
		INSERT INTO mods_bi.mktg_stage_tbls.arc_vms_txn_stg (
			cnst_mstr_id, cnst_hsld_id, vol_key, nk_hrs_summary_sku, 
			tot_hrs_cnt, hrs_wrkd_dt, unit_key, vol_geo_zip_cd, 
			Disaster_Assignment_Flg, lob_nm, dw_trans_ts, 
			appl_src_cd, load_id
		)
		SELECT
			cnst_mstr_id,
			cnst_hsld_id,
			vol_key,
			nk_hrs_summary_sku,
			tot_hrs_cnt,
			CAST(hrs_wrkd_datetime AS DATE),
			unit_key,
			vol_geo_zip,
			NULL,
			NULL,
			CAST(time_stamp AS TIMESTAMP),
			'MKTG',
			0
		FROM (
			SELECT DISTINCT
				bz_cnst_mstr.cnst_mstr_id,
				bz_cnst_mstr.cnst_hsld_id, 
				dim_volunteer.vol_key,  
				fact_hrs.nk_hrs_summary_sku,
				fact_hrs.tot_hrs_cnt, 
				fact_hrs.hrs_wrkd_datetime,
				fact_hrs.unit_key,
				fact_hrs.vol_geo_zip,
				CURRENT_TIMESTAMP(0) as time_stamp
			FROM eda.arc_mdm_vws.cnst_mstr bz_cnst_mstr
				INNER JOIN eda.arc_mdm_vws.cnst_mstr_bridge bz_cnst_mstr_bridge
					ON bz_cnst_mstr.cnst_mstr_id = bz_cnst_mstr_bridge.cnst_mstr_id
					AND bz_cnst_mstr_bridge.cnst_mstr_subj_area_cd = 'VMS'
				INNER JOIN eda.vms_vws.dim_volunteer dim_volunteer
					ON dim_volunteer.vol_key = bz_cnst_mstr_bridge.cnst_mstr_subj_area_id
				LEFT JOIN eda.vms_vws.fact_hrs fact_hrs
					ON fact_hrs.vol_key = dim_volunteer.vol_key
		);

        -- Only proceed to target table if staging was successful
        TRUNCATE TABLE mods_bi.mktg_ops_tbls.arc_vms_txn;
        
        -- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.arc_vms_txn
        SELECT * FROM mods_bi.mktg_stage_tbls.arc_vms_txn_stg;

        v_end_time := GETDATE();
		v_ok_message = cast((select count(*) from mods_bi.mktg_ops_tbls.arc_vms_txn) as nvarchar)+ ' Records inserted.';
        
        UPDATE mods_bi.mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message
        WHERE proc_name = 'ld_arc_vms_txn' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_arc_vms_txn: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_arc_vms_txn', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
