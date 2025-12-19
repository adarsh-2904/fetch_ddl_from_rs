CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_arc_vms_smry()
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
	VALUES ('ld_arc_vms_smry', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN
		-- Truncate the staging table before loading new data
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.arc_vms_smry_stg;
		-- Load data into staging table
		INSERT INTO mods_bi.mktg_stage_tbls.arc_vms_smry_stg(
			cnst_mstr_id, cnst_hsld_id, vol_status, 
			status_typ, empl_ind, active_ind, last_vol_dt, first_vol_dt, last_member_num, 
			lftm_hrs_vol_cnt, lftm_vol_cnt, lftm_loc_cnt, cfym0_hrs_vol_cnt, cfym0_vol_cnt, 
			cfym0_loc_cnt, ry0_hrs_vol_cnt, ry0_vol_cnt, ry0_loc_cnt, ry1_hrs_vol_cnt, 
			ry1_vol_cnt, ry1_loc_cnt, account_create_dt, biomed_placement_cnt, other_placement_cnt, 
			initial_vol_dt, srcsys_trans_ts, appl_src_cd, load_id
		)
		
		WITH vol_status_data  AS (
			SELECT 
				aa.cnst_mstr_id, 
				bb.vol_status, 
				bb.status_typ, 
				bb.member_num as last_member_num,
				CASE 
					WHEN bb.status_typ = 'Volunteer' AND bb.vol_status IN (
						'General Volunteer', 'RWTC Member', 'Youth Under 18', 'General Partner Member', 
						'Disaster Event Based Volunteer', 'Disaster Event Based - Youth Under 18',
						'Harvey DRO - EBV', 'Harvey DRO - Partner Member', 'Harvey DRO - Health Professional', 
						'Harvey DRO - Youth Under 18', 'Irma DRO - EBV', 'Irma DRO - Youth Under 18',
						'Maria DRO - EBV', 'Maria DRO - Youth Under 18', 'STA/HFC Youth Volunteer - South Carolina', 
						'STA/HFC Volunteer - South Carolina', 'DCS - HPDD Member', 'Event Based Volunteer',
						'Event Based - Youth Under 18', 'Biomed Event Based Volunteer', 'COVID-19 Event Based Volunteer - Youth Under 18'
					) THEN 1 ELSE 0 
				END AS active_ind,
				bb.status_effect_dt,
				ROW_NUMBER() OVER (
					PARTITION BY aa.cnst_mstr_id 
					ORDER BY active_ind DESC, bb.status_effect_dt DESC
				) AS rn
			FROM mods_bi.mktg_ops_tbls.arc_vms_txn aa 
			INNER JOIN eda.vms_vws.dim_volunteer bb ON aa.vol_key = bb.vol_key
		),

		vol_init_dates  AS (
			SELECT cnst_mstr_id, MIN(initial_vol_dt) AS initial_vol_dt
			FROM eda.arc_mdm_vws.cnst_mstr_bridge BRDG  
			INNER JOIN eda.vms_vws.dim_volunteer bx 
				ON bx.vol_key = BRDG.cnst_mstr_subj_area_id AND BRDG.cnst_mstr_subj_area_cd = 'VMS'
			GROUP BY cnst_mstr_id
		),

		vol_placements  AS (
			SELECT  
				a.vol_key,
				c.account_create_dt,
				SUM(CASE WHEN focis_ctg = 'Biomedical Services' THEN 1 ELSE 0 END) AS biomed_placement_cnt,
				SUM(CASE WHEN focis_ctg <> 'Biomedical Services' THEN 1 ELSE 0 END) AS other_placement_cnt
			FROM eda.vms_vws.fact_placement a
			INNER JOIN eda.vms_vws.dim_position b ON a.position_key = b.position_key
			INNER JOIN eda.vms_vws.dim_vms_user_profile c ON a.nk_account_id = c.account_id
			WHERE a.is_current_flg = 'Yes' AND a.placement_ind = 1
			GROUP BY 1, 2
		),

		calendar_data  AS (
			SELECT 
				a.calendar_dt, 
				a.fiscal_yr, 
				b.fiscal_yr AS FY0
			FROM eda.dw_common_vws.dim_calendar a 
			CROSS JOIN eda.dw_common_vws.dim_calendar b
			WHERE b.calendar_dt = CURRENT_DATE
		),

		vol_summary  AS (
			SELECT
				txn.cnst_mstr_id, 
				txn.cnst_hsld_id, 
				vol_stat.vol_status, 
				vol_stat.status_typ, 
				vol_stat.last_member_num, 
				vol_stat.active_ind,
				MAX(vlntr.empl_ind) AS empl_ind,
				MAX(txn.hrs_wrkd_dt) AS last_vol_dt,
				MIN(txn.hrs_wrkd_dt) AS first_vol_dt,
				SUM(txn.tot_hrs_cnt) AS lftm_hrs_vol_cnt,
				COUNT(txn.tot_hrs_cnt) AS lftm_vol_cnt,
				COUNT(DISTINCT txn.vol_geo_zip_cd) AS lftm_loc_cnt,
				SUM(CASE WHEN (cal.fiscal_yr = CAL.FY0) THEN (txn.tot_hrs_cnt) ELSE (0) END) AS cfym0_tot_vol_hrs_cnt,
				COUNT(CASE WHEN (cal.fiscal_yr = CAL.FY0) THEN (1) END) AS cfym0_tot_vol_cnt,
				COUNT(DISTINCT CASE WHEN (cal.fiscal_yr = CAL.FY0) THEN (txn.vol_geo_zip_cd) END) AS cfym0_tot_vol_geo_cnt,
				SUM(CASE WHEN (txn.hrs_wrkd_dt >= GETDATE()::date - 364) THEN (txn.tot_hrs_cnt) ELSE (0) END) AS ry0_tot_vol_hrs_cnt,
				COUNT(CASE WHEN (txn.hrs_wrkd_dt >= GETDATE()::date - 364) THEN (1) END) AS ry0_tot_vol_cnt,
				COUNT(DISTINCT CASE WHEN (txn.hrs_wrkd_dt >= GETDATE()::date - 364) THEN (txn.vol_geo_zip_cd) END) AS ry0_tot_vol_geo_cnt,
				SUM(CASE WHEN (txn.hrs_wrkd_dt <= GETDATE()::date - 365 AND txn.hrs_wrkd_dt >= GETDATE()::date - 730) THEN (txn.tot_hrs_cnt) ELSE (0) END) AS ry1_tot_vol_hrs_cnt,
				COUNT(CASE WHEN (txn.hrs_wrkd_dt <= GETDATE()::date - 365 AND txn.hrs_wrkd_dt >= GETDATE()::date - 730) THEN (1) END) AS ry1_tot_vol_cnt,
				COUNT(DISTINCT CASE WHEN (txn.hrs_wrkd_dt <= GETDATE()::date - 365 AND txn.hrs_wrkd_dt >= GETDATE()::date - 730) THEN (txn.vol_geo_zip_cd) END) AS ry1_tot_vol_geo_cnt,
				MAX(txn.dw_trans_ts) AS max_dw_trans_ts, 
				MAX(vol_smry.account_create_dt) AS account_create_dt, 
				SUM(vol_smry.biomed_placement_cnt) AS biomed_placement_cnt, 
				SUM(vol_smry.other_placement_cnt) AS other_placement_cnt 
			FROM mods_bi.mktg_ops_tbls.arc_vms_txn txn
			INNER JOIN eda.vms_vws.fact_volunteer vlntr ON txn.vol_key = vlntr.vol_key  
			INNER JOIN (
				SELECT * FROM vol_status_data WHERE rn = 1
			) vol_stat ON txn.cnst_mstr_id = vol_stat.cnst_mstr_id 
			LEFT JOIN vol_placements vol_smry ON vol_smry.vol_key = txn.vol_key 
			LEFT JOIN calendar_data cal ON txn.hrs_wrkd_dt = cal.calendar_dt
			WHERE empl_effect_dt_key < CURRENT_DATE
			GROUP BY txn.cnst_mstr_id, txn.cnst_hsld_id, vol_stat.vol_status, vol_stat.status_typ, vol_stat.last_member_num, vol_stat.active_ind
		)

		SELECT 
			PRFR.cnst_mstr_id, 
			PRFR.cnst_hsld_id, 
			vol_smry.vol_status, 
			vol_smry.status_typ, 
			vol_smry.empl_ind, 
			vol_smry.active_ind, 
			CAST(vol_smry.last_vol_dt AS date), 
			CAST(vol_smry.first_vol_dt AS date), 
			vol_smry.last_member_num, 
			COALESCE(vol_smry.lftm_hrs_vol_cnt, 0), 
			COALESCE(vol_smry.lftm_vol_cnt, 0), 
			COALESCE(vol_smry.lftm_loc_cnt, 0), 
			COALESCE(vol_smry.cfym0_tot_vol_hrs_cnt, 0), 
			COALESCE(vol_smry.cfym0_tot_vol_cnt, 0), 
			COALESCE(vol_smry.cfym0_tot_vol_geo_cnt, 0), 
			COALESCE(vol_smry.ry0_tot_vol_hrs_cnt, 0), 
			COALESCE(vol_smry.ry0_tot_vol_cnt, 0), 
			COALESCE(vol_smry.ry0_tot_vol_geo_cnt, 0), 
			COALESCE(vol_smry.ry1_tot_vol_hrs_cnt, 0), 
			COALESCE(vol_smry.ry1_tot_vol_cnt, 0), 
			COALESCE(vol_smry.ry1_tot_vol_geo_cnt, 0), 
			CAST(vol_smry.account_create_dt AS date), 
			COALESCE(vol_smry.biomed_placement_cnt, 0), 
			COALESCE(vol_smry.other_placement_cnt, 0), 
			CAST(vol_init.initial_vol_dt AS date), 
			CAST(vol_smry.max_dw_trans_ts AS timestamp(0)), 
			'', 
			0 
		FROM mods_bi.mktg_ops_vws.cnst_cdi_smry_vms_prfr PRFR
		LEFT JOIN vol_init_dates vol_init ON PRFR.cnst_mstr_id = vol_init.cnst_mstr_id
		LEFT JOIN vol_summary vol_smry ON vol_smry.cnst_mstr_id = PRFR.cnst_mstr_id;

        -- Only proceed to target table if staging was successful
        TRUNCATE TABLE mods_bi.mktg_ops_tbls.arc_vms_smry;
        
        -- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.arc_vms_smry
        SELECT * FROM mods_bi.mktg_stage_tbls.arc_vms_smry_stg;

        v_end_time := GETDATE();
		v_ok_message = cast((select count(*) from mods_bi.mktg_ops_tbls.arc_vms_smry) as nvarchar)+ ' Records inserted.';
        
        UPDATE mods_bi.mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message
        WHERE proc_name = 'ld_arc_vms_smry' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_arc_vms_smry: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_arc_vms_smry', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
