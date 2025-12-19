CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_bio_dnr_segmnt_dashbrd()
 LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_bio_dnr_segmnt_dashbrd', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
        -- Check if today is Saturday (dow = 6)
        IF EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN
		
			-- Truncate existing dashboard summary table rows:
			TRUNCATE TABLE mktg_stage_tbls.bzfc_bio_dnr_segment_dashbrd_stg;
			
			-- Now reload the summary dashboard table:
			INSERT INTO mktg_stage_tbls.bzfc_bio_dnr_segment_dashbrd_stg (
				region_key,
				region_id,
				region_nm,
				division_cd,
				division_dsc,
				ldrshp_cd,
				ldrshp_nm,
				gender_cd,
				race_key,
				race_dsc,
				blood_type_key,
				abo,
				age_band_key,
				age_band_dsc,
				generation_segmnt_key,
				generation_segmnt_cd,
				generation_segmnt_dsc,
				life_stage_wb,
				drive_typ_wb,
				life_stage_2rc,
				drive_typ_2rc,
				life_stage_redcell_typ_cd,
				life_stage_redcell,
				drive_typ_redcell,
				life_stage_plasma,
				drive_typ_plasma,
				life_stage_plt,
				drive_typ_plt,
				life_stage_apheresis_typ_cd,
				life_stage_apheresis,
				drive_typ_apheresis,
				life_stage_current_typ_cd,
				life_stage_current,
				drive_typ_current,
				life_stage_sub_cat,
				life_stage_sub_cat_sort,
				any_chan_accessible_flg,
				em_chan_accessible_flg,
				dm_chan_accessible_flg,
				txt_chan_accessible_flg,
				phn_chan_accessible_flg,
				app_chan_accessible_flg,
				special_donor_notif_flg,
				sickle_cell_donor_flg,
				cmv_status,
				perm_defer_flg,
				red_cell_temp_defer_flg,
				cnst_cnt
			)
			SELECT 
				COALESCE(e.region_key, 0) AS region_key,
				e.region_id,
				e.region_nm,
				e.division_cd,
				e.division_dsc,
				e.ldrshp_cd,
				e.ldrshp_nm,
				g.gender_cd,
				COALESCE(a.race_id, 0) AS race_key,
				b.race_description,
				COALESCE(c.blood_type_key, 0) AS blood_type_key,
				c.abo,
				CASE 
					WHEN a.age = 0 THEN 0
					WHEN a.age BETWEEN 1 AND 15 THEN 1
					WHEN a.age BETWEEN 16 AND 19 THEN 2
					WHEN a.age BETWEEN 20 AND 24 THEN 3
					WHEN a.age BETWEEN 25 AND 34 THEN 4
					WHEN a.age BETWEEN 35 AND 44 THEN 5
					WHEN a.age BETWEEN 45 AND 54 THEN 6
					WHEN a.age BETWEEN 55 AND 64 THEN 7
					WHEN a.age BETWEEN 65 AND 74 THEN 8
					WHEN a.age BETWEEN 75 AND 99 THEN 9
					WHEN a.age >= 100 THEN 10
					ELSE 0
				END AS age_band_key,
				CASE 
					WHEN a.age = 0 THEN 'Unknown'
					WHEN a.age BETWEEN 1 AND 15 THEN 'Under 16'
					WHEN a.age BETWEEN 16 AND 19 THEN '16-19'
					WHEN a.age BETWEEN 20 AND 24 THEN '20-24'
					WHEN a.age BETWEEN 25 AND 34 THEN '25-34'
					WHEN a.age BETWEEN 35 AND 44 THEN '35-44'
					WHEN a.age BETWEEN 45 AND 54 THEN '45-54'
					WHEN a.age BETWEEN 55 AND 64 THEN '55-64'
					WHEN a.age BETWEEN 65 AND 74 THEN '65-74'
					WHEN a.age BETWEEN 75 AND 99 THEN '75-99'
					WHEN a.age >= 100 THEN '100+'
					ELSE 'Unknown'
				END AS age_band_dsc,
				CAST((
					CASE 
						WHEN EXTRACT(YEAR FROM a.birth_dt) >= 1996 THEN 1
						WHEN EXTRACT(YEAR FROM a.birth_dt) BETWEEN 1981 AND 1995 THEN 2
						WHEN EXTRACT(YEAR FROM a.birth_dt) BETWEEN 1965 AND 1980 THEN 3
						WHEN EXTRACT(YEAR FROM a.birth_dt) BETWEEN 1946 AND 1964 THEN 4
						WHEN EXTRACT(YEAR FROM a.birth_dt) BETWEEN 1928 AND 1945 THEN 5
						WHEN EXTRACT(YEAR FROM a.birth_dt) < 1928 THEN 6
						ELSE 0
					END
				) AS INTEGER) AS generation_segmnt_key,
				CASE 
					WHEN EXTRACT(YEAR FROM a.birth_dt) >= 1996 THEN 'Z'
					WHEN EXTRACT(YEAR FROM a.birth_dt) BETWEEN 1981 AND 1995 THEN 'Y'
					WHEN EXTRACT(YEAR FROM a.birth_dt) BETWEEN 1965 AND 1980 THEN 'X'
					WHEN EXTRACT(YEAR FROM a.birth_dt) BETWEEN 1946 AND 1964 THEN 'B'
					WHEN EXTRACT(YEAR FROM a.birth_dt) BETWEEN 1928 AND 1945 THEN 'S'
					WHEN EXTRACT(YEAR FROM a.birth_dt) < 1928 THEN 'G'
					ELSE 'U'
				END AS generation_segmnt_cd,
				CASE 
					WHEN generation_segmnt_cd = 'Z' THEN 'New Generation'
					WHEN generation_segmnt_cd = 'Y' THEN 'Gen Y, Nexters, Generation Next'
					WHEN generation_segmnt_cd = 'X' THEN 'Baby busters, the MTV generation'
					WHEN generation_segmnt_cd = 'B' THEN 'Baby Boomers'
					WHEN generation_segmnt_cd = 'S' THEN 'The Silent Generation or the seekers'
					WHEN generation_segmnt_cd = 'G' THEN 'The Greatest Generation or the G.I. Generation'
					WHEN generation_segmnt_cd = 'U' THEN 'Unknown'
				END AS generation_segmnt_dsc,
				CASE 
					WHEN wb_latest.last_wb_donat_dt <= CURRENT_DATE
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN wb_latest.last_wb_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN wb_latest.last_wb_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN wb_latest.last_wb_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed'
					WHEN wb_latest.last_wb_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed'
					WHEN wb_latest.last_wb_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed'
					ELSE 'No Segment'
				END AS life_stage_wb,
				CASE 
					WHEN wb_drv_typ.wb_drive_typ IS NULL THEN 'NA'
					ELSE wb_drv_typ.wb_drive_typ
				END AS drive_typ_wb,
				CASE 
					WHEN drbc_latest.last_r2_donat_dt <= CURRENT_DATE
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN drbc_latest.last_r2_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN drbc_latest.last_r2_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN drbc_latest.last_r2_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed'
					WHEN drbc_latest.last_r2_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed'
					WHEN drbc_latest.last_r2_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed'
					ELSE 'No Segment'
				END AS life_stage_2rc,
				CASE 
					WHEN drbc_drv_typ.drbc_drive_typ IS NULL THEN 'NA'
					ELSE drbc_drv_typ.drbc_drive_typ
				END AS drive_typ_2rc,
				CASE 
					WHEN (wb_latest.days_since_last_wb > 0
						AND (drbc_latest.days_since_last_drbc = 0
							OR wb_latest.days_since_last_wb <= drbc_latest.days_since_last_drbc
							OR drbc_latest.days_since_last_drbc IS NULL))
						THEN 'WB'
					WHEN (drbc_latest.days_since_last_drbc > 0
						AND (wb_latest.days_since_last_wb = 0
							OR drbc_latest.days_since_last_drbc <= wb_latest.days_since_last_wb
							OR wb_latest.days_since_last_wb IS NULL))
						THEN '2RC'
					ELSE 'No Red Cell Segment'
				END AS life_stage_redcell_typ_cd,
				CASE 
					WHEN life_stage_redcell_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt <= CURRENT_DATE
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN life_stage_redcell_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN life_stage_redcell_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN life_stage_redcell_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed Donor'
					WHEN life_stage_redcell_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed Donor'
					WHEN life_stage_redcell_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed Donor'
					WHEN life_stage_redcell_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= CURRENT_DATE
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN life_stage_redcell_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -12, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN life_stage_redcell_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -24, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN life_stage_redcell_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -48, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed Donor'
					WHEN life_stage_redcell_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -60, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed Donor'
					WHEN life_stage_redcell_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed Donor'
					ELSE 'No Red Cell Segment'
				END AS life_stage_redcell,
				CASE 
					WHEN life_stage_redcell_typ_cd = 'WB' THEN wb_drv_typ.wb_drive_typ
					WHEN life_stage_redcell_typ_cd = '2RC' THEN drbc_drv_typ.drbc_drive_typ
					ELSE 'NA'
				END AS drive_typ_redcell,
				CASE 
					WHEN plasma_latest.last_plasma_donat_dt <= CURRENT_DATE
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN plasma_latest.last_plasma_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN plasma_latest.last_plasma_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN plasma_latest.last_plasma_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed'
					WHEN plasma_latest.last_plasma_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed'
					WHEN plasma_latest.last_plasma_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed'
					ELSE 'No Segment'
				END AS life_stage_plasma,
				CASE 
					WHEN plasma_drv_typ.plasma_drive_typ IS NULL THEN 'NA'
					ELSE plasma_drv_typ.plasma_drive_typ
				END AS drive_typ_plasma,
				CASE 
					WHEN plt_latest.last_plt_donat_dt <= CURRENT_DATE
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN plt_latest.last_plt_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN plt_latest.last_plt_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN plt_latest.last_plt_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed'
					WHEN plt_latest.last_plt_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed'
					WHEN plt_latest.last_plt_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed'
					ELSE 'No Segment'
				END AS life_stage_plt,
				CASE 
					WHEN plt_drv_typ.plt_drive_typ IS NULL THEN 'NA'
					ELSE plt_drv_typ.plt_drive_typ
				END AS drive_typ_plt,
				CASE 
					WHEN (plt_latest.days_since_last_plt > 0
						AND (plasma_latest.days_since_last_plasma = 0
							OR plt_latest.days_since_last_plt <= plasma_latest.days_since_last_plasma
							OR plasma_latest.days_since_last_plasma IS NULL))
						THEN 'PLT'
					WHEN (plasma_latest.days_since_last_plasma > 0
						AND (plt_latest.days_since_last_plt = 0
							OR plasma_latest.days_since_last_plasma <= plt_latest.days_since_last_plt
							OR plt_latest.days_since_last_plt IS NULL))
						THEN 'PLASMA'
					ELSE 'No Apheresis Segment'
				END AS life_stage_apheresis_typ_cd,
				CASE 
					WHEN life_stage_apheresis_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt <= CURRENT_DATE
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt <= CURRENT_DATE
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed Donor'
					WHEN life_stage_apheresis_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed Donor'
					ELSE 'No Segment'
				END AS life_stage_apheresis,
				CASE 
					WHEN life_stage_apheresis_typ_cd = 'PLT' THEN plt_drv_typ.plt_drive_typ
					WHEN life_stage_apheresis_typ_cd = 'PLASMA' THEN plasma_drv_typ.plasma_drive_typ
					ELSE 'NA'
				END AS drive_typ_apheresis,
				CASE 
					WHEN wb_latest.days_since_last_wb > 0
						AND (drbc_latest.days_since_last_drbc = 0
							OR wb_latest.days_since_last_wb < drbc_latest.days_since_last_drbc
							OR drbc_latest.days_since_last_drbc IS NULL)
						AND (plt_latest.days_since_last_plt = 0
							OR wb_latest.days_since_last_wb < plt_latest.days_since_last_plt
							OR plt_latest.days_since_last_plt IS NULL)
						AND (plasma_latest.days_since_last_plasma = 0
							OR wb_latest.days_since_last_wb < plasma_latest.days_since_last_plasma
							OR plasma_latest.days_since_last_plasma IS NULL)
						THEN 'WB'
					WHEN drbc_latest.days_since_last_drbc > 0
						AND (plt_latest.days_since_last_plt = 0
							OR drbc_latest.days_since_last_drbc < plt_latest.days_since_last_plt
							OR plt_latest.days_since_last_plt IS NULL)
						AND drbc_latest.days_since_last_drbc > 0
						AND (plasma_latest.days_since_last_plasma = 0
							OR drbc_latest.days_since_last_drbc < plasma_latest.days_since_last_plasma
							OR plasma_latest.days_since_last_plasma IS NULL)
						THEN '2RC'
					WHEN (plt_latest.days_since_last_plt > 0
						AND (plasma_latest.days_since_last_plasma = 0
							OR plt_latest.days_since_last_plt <= plasma_latest.days_since_last_plasma
							OR plasma_latest.days_since_last_plasma IS NULL))
						THEN 'PLT'
					WHEN (plasma_latest.days_since_last_plasma > 0
						AND (plt_latest.days_since_last_plt = 0
							OR plasma_latest.days_since_last_plasma <= plt_latest.days_since_last_plt
							OR plt_latest.days_since_last_plt IS NULL))
						THEN 'PLASMA'
					ELSE 'No Segment'
				END AS life_stage_current_typ_cd,
				CASE 
					WHEN life_stage_current_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt <= CURRENT_DATE
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN life_stage_current_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN life_stage_current_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND wb_latest.last_wb_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'WB'
						AND wb_latest.last_wb_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed Donor'
					WHEN life_stage_current_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= CURRENT_DATE
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN life_stage_current_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -12, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN life_stage_current_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -24, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN life_stage_current_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -48, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed Donor'
					WHEN life_stage_current_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -60, CURRENT_DATE)
						AND drbc_latest.last_r2_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed Donor'
					WHEN life_stage_current_typ_cd = '2RC'
						AND drbc_latest.last_r2_donat_dt <= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt <= CURRENT_DATE
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN life_stage_current_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN life_stage_current_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND plt_latest.last_plt_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'PLT'
						AND plt_latest.last_plt_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt <= CURRENT_DATE
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -12, CURRENT_DATE)
						THEN 'Active Donor'
					WHEN life_stage_current_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -12, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -24, CURRENT_DATE)
						THEN 'Inactive Donor'
					WHEN life_stage_current_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -24, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -48, CURRENT_DATE)
						THEN 'Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -48, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -60, CURRENT_DATE)
						THEN 'Moderately Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -60, CURRENT_DATE)
						AND plasma_latest.last_plasma_donat_dt >= DATEADD(month, -120, CURRENT_DATE)
						THEN 'Deeply Lapsed Donor'
					WHEN life_stage_current_typ_cd = 'PLASMA'
						AND plasma_latest.last_plasma_donat_dt < DATEADD(month, -120, CURRENT_DATE)
						THEN 'Extended Lapsed Donor'
					ELSE 'No Segment'
				END AS life_stage_current,
				CASE 
					WHEN life_stage_current_typ_cd = 'WB' THEN wb_drv_typ.wb_drive_typ
					WHEN life_stage_current_typ_cd = '2RC' THEN drbc_drv_typ.drbc_drive_typ
					WHEN life_stage_current_typ_cd = 'PLT' THEN plt_drv_typ.plt_drive_typ
					WHEN life_stage_current_typ_cd = 'PLASMA' THEN plasma_drv_typ.plasma_drive_typ
					ELSE 'NA'
				END AS drive_typ_current,
				CASE 
					WHEN f.donor_life_stage_group = 'VBD' THEN f.donor_life_stage_nm
					ELSE 'Not Active'
				END AS life_stage_sub_cat,
				CAST((
					CASE 
						WHEN f.donor_life_stage_group = 'VBD' THEN f.donor_life_stage_sort
						ELSE 99
					END
				) AS INTEGER) AS life_stage_sub_cat_sort,
				CASE 
					WHEN g.any_chan_accessible_flg IS NULL THEN 'U'
					ELSE g.any_chan_accessible_flg
				END AS any_chan_accessible_flg,
				CASE 
					WHEN g.em_chan_accessible_flg IS NULL THEN 'U'
					ELSE g.em_chan_accessible_flg
				END AS em_chan_accessible_flg,
				CASE 
					WHEN g.dm_chan_accessible_flg IS NULL THEN 'U'
					ELSE g.dm_chan_accessible_flg
				END AS dm_chan_accessible_flg,
				CASE 
					WHEN g.txt_chan_accessible_flg IS NULL THEN 'U'
					ELSE g.txt_chan_accessible_flg
				END AS txt_chan_accessible_flg,
				CASE 
					WHEN g.phn_chan_accessible_flg IS NULL THEN 'U'
					ELSE g.phn_chan_accessible_flg
				END AS phn_chan_accessible_flg,
				CASE 
					WHEN dm.attribute_1_flg = 'Y' THEN 'Y'
					ELSE 'N'
				END AS app_chan_accessible_flg,
				CASE 
					WHEN COALESCE(ce.special_donor_notif_ind, 0) = 1 THEN 'Y'
					ELSE 'N'
				END AS special_donor_notif_flg,
				CASE 
					WHEN COALESCE(ce.sickle_cell_donor_ind, 0) = 1 THEN 'Y'
					ELSE 'N'
				END AS sickle_cell_donor_flg,
				CASE 
					WHEN a.cmv_stat IS NULL THEN 'Unknown'
					ELSE a.cmv_stat
				END AS cmv_status,
				CASE 
					WHEN (g.nxt_wb_recruit_dt >= '2200-01-01' AND g.recruit_comment IS NULL)
						OR (g.recruit_comment IN ('Donor Health Self Deferral','Sickle Cell Patient Match','Sponsor','Unspecified Reason'))
						THEN 'Y'
					ELSE 'N'
				END AS perm_defer_flg,
				CASE 
					WHEN g.nxt_wb_recruit_dt BETWEEN (CURRENT_DATE + 113) AND (CURRENT_DATE + 366)
						THEN 'Y'
					ELSE 'N'
				END AS red_cell_temp_defer_flg,
				COUNT(DISTINCT a.donor_id) AS cnst_cnt 
			FROM (
				SELECT 
					donor_id,
					race_id,
					blood_type_key,
					age,
					birth_dt,
					zip,
					life_stage_key,
					donor_external_id,
					cmv_stat
				FROM eda.bio_donation_vws.bz_dim_donor
			) a
			LEFT JOIN (
				SELECT 
					race_id,
					race_description
				FROM eda.bio_donation_vws.bz_dim_race
			) b ON a.race_id = b.race_id
			LEFT JOIN (
				SELECT 
					blood_type_key,
					abo
				FROM eda.bio_common_vws.bz_dim_blood_type
			) c ON a.blood_type_key = c.blood_type_key
			LEFT JOIN (
				SELECT 
					zip,
					region_code
				FROM eda.dw_common_vws.dim_zipcodes
			) d ON a.zip = d.zip
			LEFT JOIN (
				SELECT 
					region_key,
					region_id,
					region_nm,
					division_cd,
					division_dsc,
					ldrshp_cd,
					ldrshp_nm,
					nk_region_id
				FROM eda.dw_common_vws.dim_region
			) e ON d.region_code = e.nk_region_id
			LEFT JOIN (
				SELECT 
					donor_life_stage_key,
					donor_life_stage_group,
					donor_life_stage_nm,
					donor_life_stage_sort
				FROM eda.bio_donation_vws.bz_dim_donor_life_stage
			) f ON a.life_stage_key = f.donor_life_stage_key
			LEFT JOIN (
				SELECT 
					nk_key_donor,
					gender_cd,
					any_chan_accessible_flg,
					em_chan_accessible_flg,
					dm_chan_accessible_flg,
					txt_chan_accessible_flg,
					phn_chan_accessible_flg,
					nxt_wb_recruit_dt,
					recruit_comment
				FROM eda.bio_appointment_vws.bzl_dim_contact
			) g ON a.donor_external_id = g.nk_key_donor
			-- calculates days since last whole blood
			LEFT JOIN (
				SELECT 
					donor_id as donor_key,
					MAX(donation_dt) AS last_wb_donat_dt,
					MIN(DATEDIFF(day, donation_dt, CURRENT_DATE)) AS days_since_last_wb,
					MAX(drive_external_id) AS drive_key
				FROM eda.bio_donation_vws.bzal_fact_donation a_wb
				LEFT JOIN (
					SELECT 
						phleb_key,
						phleb_proc_cd
					FROM eda.bio_common_vws.bz_dim_phleb
				) b_wb ON a_wb.phleb_type_key = b_wb.phleb_key
				WHERE b_wb.phleb_proc_cd = 'WB'
				GROUP BY donor_id
			) wb_latest ON wb_latest.donor_key = a.donor_id
			-- added join to drive to determine the drive type
			LEFT JOIN (
				SELECT 
					mstr_drive_key as wb_drive_key,
					drv_typ as wb_drive_typ
				FROM eda.bio_donation_vws.bz_dim_drive
			) wb_drv_typ ON wb_drv_typ.wb_drive_key = wb_latest.drive_key
			-- calculates days since last double red cell (2RBC)
			LEFT JOIN (
				SELECT 
					donor_id as donor_key,
					MAX(donation_dt) AS last_r2_donat_dt,
					MIN(DATEDIFF(day, donation_dt, CURRENT_DATE)) AS days_since_last_drbc,
					MAX(drive_external_id) AS drive_key
				FROM eda.bio_donation_vws.bzal_fact_donation a_drbc
				LEFT JOIN (
					SELECT 
						phleb_key,
						phleb_proc_cd
					FROM eda.bio_common_vws.bz_dim_phleb
				) b_drbc ON a_drbc.phleb_type_key = b_drbc.phleb_key
				WHERE b_drbc.phleb_proc_cd = 'R2'
				GROUP BY donor_id
			) drbc_latest ON drbc_latest.donor_key = a.donor_id
			LEFT JOIN (
				SELECT 
					mstr_drive_key as drbc_drive_key,
					drv_typ as drbc_drive_typ
				FROM eda.bio_donation_vws.bz_dim_drive
			) drbc_drv_typ ON drbc_drv_typ.drbc_drive_key = drbc_latest.drive_key
			-- calculates days since last plasma
			LEFT JOIN (
				SELECT 
					donor_id as donor_key,
					MAX(donation_dt) AS last_plasma_donat_dt,
					MIN(DATEDIFF(day, donation_dt, CURRENT_DATE)) AS days_since_last_plasma,
					MAX(drive_external_id) AS drive_key
				FROM eda.bio_donation_vws.bzal_fact_donation a_plasma
				LEFT JOIN (
					SELECT 
						phleb_key,
						phleb_proc_cd
					FROM eda.bio_common_vws.bz_dim_phleb
				) b_plasma ON a_plasma.phleb_type_key = b_plasma.phleb_key
				WHERE b_plasma.phleb_proc_cd IN ('PL','P5') -- plasma procedure codes
				GROUP BY donor_key
			) plasma_latest ON plasma_latest.donor_key = a.donor_id
			-- added join to drive to determine the drive type
			LEFT JOIN (
				SELECT 
					mstr_drive_key as plasma_drive_key,
					drv_typ as plasma_drive_typ
				FROM eda.bio_donation_vws.bz_dim_drive
			) plasma_drv_typ ON plasma_drv_typ.plasma_drive_key = plasma_latest.drive_key
			-- calculates days since last platelet
			LEFT JOIN (
				SELECT 
					donor_id as donor_key,
					MAX(donation_dt) AS last_plt_donat_dt,
					MIN(DATEDIFF(day, donation_dt, CURRENT_DATE)) AS days_since_last_plt,
					MAX(drive_external_id) AS drive_key
				FROM eda.bio_donation_vws.bzal_fact_donation a_plt
				LEFT JOIN (
					SELECT 
						phleb_key,
						phleb_proc_cd
					FROM eda.bio_common_vws.bz_dim_phleb
				) b_plt ON a_plt.phleb_type_key = b_plt.phleb_key
				WHERE b_plt.phleb_proc_cd IN ('P2','P3','P4','LP','PP') -- platelet procedure codes
				GROUP BY donor_key
			) plt_latest ON plt_latest.donor_key = a.donor_id
			LEFT JOIN (
				SELECT 
					mstr_drive_key as plt_drive_key,
					drv_typ as plt_drive_typ
				FROM eda.bio_donation_vws.bz_dim_drive
			) plt_drv_typ ON plt_drv_typ.plt_drive_key = plt_latest.drive_key
			LEFT JOIN (
				SELECT 
					donor_id,
					contact_id
				FROM eda.bio_donation_vws.bzal_fact_donation
			) h ON a.donor_id = h.donor_id
			LEFT JOIN (
				SELECT 
					nk_contact_id,
					attribute_1_flg
				FROM eda.drms_vws.bz_dim_donor_mktg
				WHERE current_flg = 'Y'
			) dm ON h.contact_id = dm.nk_contact_id
			LEFT JOIN (
				SELECT 
					contact_key,
					special_donor_notif_ind,
					sickle_cell_donor_ind
				FROM eda.bio_appointment_vws.bzf_dim_cntct_enrol
				WHERE special_donor_notif_ind = 1
					OR sickle_cell_donor_ind = 1
			) ce ON h.contact_id = ce.contact_key
			GROUP BY 
			1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
			31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47;
			
			TRUNCATE TABLE mktg_ops_tbls.bzfc_bio_dnr_segment_dashbrd;

            INSERT INTO mktg_ops_tbls.bzfc_bio_dnr_segment_dashbrd
            SELECT * FROM mktg_stage_tbls.bzfc_bio_dnr_segment_dashbrd_stg;

            v_end_time := GETDATE();
            v_ok_message := 'Records inserted.';

            UPDATE etl_config.audit_log
            SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = CAST((SELECT COUNT(*) FROM mktg_ops_tbls.bzfc_bio_dnr_segment_dashbrd) AS INTEGER)
            WHERE proc_name = 'ld_bzfc_bio_dnr_segmnt_dashbrd' 
              AND task_name = 'Stored Procedure' 
              AND start_time = v_start_time;
		ELSE
            v_end_time := GETDATE();
            v_ok_message := 'Procedure skipped: Today is not Saturday.';

            UPDATE etl_config.audit_log
            SET status = 'Skipped', end_time = v_end_time, TaskMessage = v_ok_message
            WHERE proc_name = 'ld_bzfc_bio_dnr_segmnt_dashbrd' 
              AND task_name = 'Stored Procedure' 
              AND start_time = v_start_time;
        END IF;
	EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
            v_error_message := 'Error in ld_bzfc_bio_dnr_segmnt_dashbrd: ' || SQLERRM;

            INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
            VALUES ('ld_bzfc_bio_dnr_segmnt_dashbrd', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

            RAISE EXCEPTION 'An error occurred: %', SQLERRM;
    END;
END;
$$
