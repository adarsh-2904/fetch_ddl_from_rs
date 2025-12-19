CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_cnst_birth_best()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Andrien
Created date: 18-Mar-2015
Purpose: This view was built to provide a single row for the Planned Giving Segmentation and reporting lists.  
               The view is based on the bz_cnst_birth view, but added the QUALIFY statement to select the 
			   best birth date based on the source system prioritization rules provided by the Planned Giving team. 
			   I included 6 derived columns in the view to build the complete birth date in DATE format and to 
			   reflect the constituent age base on the current date.  The derived birth date selects records from 
			   the ARC MDM VWS database.

Modified by: Michael Andrien
Modified date: 9-July-2015
Purpose:  Added CAST to derived age (bzd_derived_age) to cast the value as an integer.

Modified by: Michael Andrien
Modified date: 04/5/2016
Purpose:  Added the Generation Segment columns.  The rules driving the new column are below:
		-- Definition is based on Blackbaud generation cohort definitions
		--  Derived from constituent birth year
		--   Z == Birth year >= 1996
		--  Y == Birth year between 1981 and 1995
		--  X == Birth year between 1965-1980
		--  B == Birth year between 1946 and 1964
		--  S == Birth year between 1928 and 1945
		--  G == Birth year < 1928
		
Modified by: Michael Hall
Modified date: 03/13/2017
Purpose:  Updated five Generation Segment Descriptions to agree with the MODS team preferred descriptions.
               They are shorter in length and more commonly used by marketeers.
               
Modified by: Majeed Mohammad
Modified date: 07/21/2017
Purpose: Added the explicit column names to the INSERT statement and updated the position of the columns in the SELECT statement accordingly. 

Modified By: Michael Andrien
Modified Date: 2/1/2019
Purpose: Added join to the bzf_cnst_chrctrstc view to add the experian age as an additional attribute to the table.

Modified By: Michael Andrien
Modified Date: 3/24/2020
Purpose: We discovered cases where we have the Experian Age characteristic (bzd_equ_age1) in the CDI characteristics table, but no birth records in CDI for some cnsts.  In these cases, records were missing from the bz_cnst_birth_best view.  I've added the join to 
arc_mdm_vws.bz_cnst_mstr and added a where constraint on the view to limit records where we have either a birth record for the cnst in CDI or the Experian Age characteristic.

Modified By: Michael Andrien
Modified Date: 3/27/2020
Purpose: Added experian_birth_yrmth and experian_derived_age attributes to the view and updated the method for calculating derived age.

Modified By: Michael Andrien
Modified Date: 09/13/2022
Purpose:  Added the bb_age_cd attribute to the bz_cnst_birth_best table.

Modified By: Michael Andrien
Modified Date: 10/03/2022
Purpose:  Changed the QUALIFY ranking order from
	CASE
		WHEN a.arc_srcsys_cd = 'BADW' THEN 1  -- Biomed eProgesa
		WHEN a.arc_srcsys_cd = 'DRMS' THEN 2  -- Biomed DRMS
		WHEN a.arc_srcsys_cd = 'VMS'  THEN 3    -- Volunteer Management System - Volunteer Connection
		WHEN a.arc_srcsys_cd = 'CDIM'  THEN 4   -- CDI/Lexis Nexis source code
		WHEN a.arc_srcsys_cd = 'SFFS' THEN 5    -- Fundraising Salesforce system
		WHEN a.arc_srcsys_cd = 'PHSS'   THEN 6 -- SABA
	--Below condition  is to check FR LOB Systems
		WHEN line_of_service_cd = 'FR' 
		and a.arc_srcsys_cd NOT IN ('SFFS','ATG', 'ATGO','CNVO','TAFS') THEN 7
		WHEN a.arc_srcsys_cd = 'ATG'  THEN 8
		WHEN a.arc_srcsys_cd = 'TAFS' THEN 9
		ELSE 10 
	END	-- Other

To
	CASE
		WHEN a.arc_srcsys_cd = 'BADW' THEN 1  -- Biomed eProgesa
		WHEN a.arc_srcsys_cd = 'DRMS' THEN 2  -- Biomed DRMS
		WHEN a.arc_srcsys_cd = 'VMS'  THEN 3    -- Volunteer Management System - Volunteer Connection
		WHEN a.arc_srcsys_cd = 'CDIM'  THEN 4   -- CDI/Lexis Nexis source code
		WHEN a.arc_srcsys_cd = 'SFFS' THEN 5    -- Fundraising Salesforce system
		WHEN a.arc_srcsys_cd = 'PHSS'   THEN 6 -- SABA
	--Below condition  is to check FR LOB Systems
		WHEN line_of_service_cd = 'FR' 
		and a.arc_srcsys_cd NOT IN ('SFFS','ATG', 'ATGO','CNVO','TAFS') THEN 7
		WHEN a.arc_srcsys_cd = 'ATG'  THEN 8
		WHEN a.arc_srcsys_cd = 'TAFS' THEN 9
		ELSE 10 
	END	-- Other

Modified By: Michael Andrien
Modified Date: 07/12/2023
Purpose: Added Simio Birth Year, month, derived birth date and derived age attributes.

Modified By: Michael Andrien
Modified Date: 08/07/2023
Purpose: Added the Simio PID to the table. The first letter of the PID reflects the Simio constituent demographic append process confidence level.  PID values
starting with 'Y' indicate a high confidence match and PID values starting with 'N' reflect a low confidence match.
---------------------------------------------------------------------------------------------------------------------------------------------- */
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_bz_cnst_birth_best', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN
		-- Truncate the staging table before loading new data
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.bz_cnst_birth_best_stg;
		-- Load data into staging table
		INSERT INTO mods_bi.mktg_stage_tbls.bz_cnst_birth_best_stg
		(
			cnst_mstr_id, pid, cnst_srcsys_id, arc_srcsys_cd, cnst_birth_dy_num,
			cnst_birth_mth_num, cnst_birth_yr_num, bzd_char_month, bzd_char_day,
			bzd_char_yr, bzd_birth_dt, bzd_altered_dt_flg, bzd_derived_age, 
			experian_age, experian_birth_yrmth, experian_derived_age,
			bb_age_cd,
			simio_birth_dt_yr_num, simio_birth_dt_mth_num, simio_derived_birth_dt, simio_derived_age,
			cnst_birth_strt_ts, cnst_birth_end_dt, 
			gen_segmnt_key, generation_segmnt_cd,
			generation_segmnt_dsc, 
			cnst_birth_best_los_ind, trans_key, user_id,
			dw_srcsys_trans_ts, row_stat_cd, appl_src_cd, load_id
		) 
		WITH ranked_data AS (
			SELECT                
				mstr.cnst_mstr_id,
				sbb.pid,
				a.cnst_srcsys_id,  
				CASE WHEN a.arc_srcsys_cd IS NULL THEN 'EXPR' ELSE a.arc_srcsys_cd END AS arc_srcsys_cd,
				a.cnst_birth_dy_num,
				a.cnst_birth_mth_num,
				a.cnst_birth_yr_num,
				CASE 
					WHEN LPAD(REPLACE(CAST(a.cnst_birth_mth_num AS VARCHAR(2)), '.', ''), 2, '0') = '00'
						THEN CAST('01' AS VARCHAR(2)) 
					ELSE LPAD(REPLACE(CAST(a.cnst_birth_mth_num AS VARCHAR(2)), '.', ''), 2, '0')
				END AS bzd_char_month,
				CASE 
					WHEN LPAD(REPLACE(CAST(COALESCE(a.cnst_birth_dy_num, 0) AS VARCHAR(2)), '.', ''), 2, '0') = '00' 
						THEN CAST('01' AS VARCHAR(2)) 
					ELSE LPAD(REPLACE(CAST(COALESCE(a.cnst_birth_dy_num, 0) AS VARCHAR(2)), '.', ''), 2, '0')
				END AS bzd_char_day,
				LPAD(REPLACE(CAST(a.cnst_birth_yr_num AS VARCHAR(4)), '.', ''), 4, '0') AS bzd_char_yr,
				TO_DATE(bzd_char_month || '/' || bzd_char_day || '/' || bzd_char_yr, 'MM/DD/YYYY') AS bzd_birth_dt,
				CASE 
					WHEN (LPAD(REPLACE(CAST(COALESCE(cnst_birth_dy_num, 0) AS VARCHAR(2)), '.', ''), 2, '0') = '00') 
						OR (LPAD(REPLACE(CAST(COALESCE(a.cnst_birth_dy_num, 0) AS VARCHAR(2)), '.', ''), 2, '0') = '00')
						THEN 'Y' 
					ELSE 'N' 
				END AS bzd_altered_dt_flg,
				-- CAST (((CURRENT_DATE - bzd_birth_dt) YEAR(4)) AS INTEGER) AS bzd_derived_age, -- The age is derived by subtracting the derived birth date from the current date. NOTE: Replaced this method with the line below 3/27/20 MTA
				CASE 
					WHEN EXTRACT(month FROM bzd_birth_dt) > EXTRACT(month FROM CURRENT_DATE) 
						THEN EXTRACT(year FROM CURRENT_DATE) - EXTRACT(year FROM bzd_birth_dt) - 1
					WHEN EXTRACT(month FROM bzd_birth_dt) = EXTRACT(month FROM CURRENT_DATE) 
						AND EXTRACT(day FROM bzd_birth_dt) > EXTRACT(day FROM CURRENT_DATE) 
						THEN EXTRACT(year FROM CURRENT_DATE) - EXTRACT(year FROM bzd_birth_dt) - 1
					ELSE EXTRACT(year FROM CURRENT_DATE) - EXTRACT(year FROM bzd_birth_dt) 
				END AS bzd_derived_age,
			--	exp_age.experian_age, -- not present because of columns not present in bzf_cnst_chrctrstc
			--	exp_age.experian_birth_yrmth, -- not present because of columns not present in bzf_cnst_chrctrstc
			--	exp_age.experian_derived_age, -- not present because of columns not present in bzf_cnst_chrctrstc
				NULL::integer as experian_age,
				NULL::integer as experian_birth_yrmth,
				NULL::integer AS experian_derived_age,
				c.bb_agecode_scrval as bb_age_cd,
				sbb.simio_birth_dt_yr_num, 
				sbb.simio_birth_dt_mth_num, 
				CAST(sbb.simio_derived_birth_dt AS DATE), 
				sbb.simio_derived_age,
				CAST(a.cnst_birth_strt_ts AS TIMESTAMP) AS cnst_birth_strt_ts,
				CAST(a.cnst_birth_end_dt AS DATE) AS cnst_birth_end_dt,
			/*	CASE 
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END >= 1996 THEN 1
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END BETWEEN 1981 AND 1995 THEN 2
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END BETWEEN 1965 AND 1980 THEN 3
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END BETWEEN 1946 AND 1964 THEN 4
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END BETWEEN 1928 AND 1945 THEN 5
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END < 1928 THEN 6
					ELSE 0
				END AS generation_segmnt_key, */  --These no longer available in bzf_cnst_chrctrstc as per business decision
				NULL::integer AS gen_segmnt_key,
			/*	CASE 
					WHEN CAST(a.cnst_birth_yr_num AS INTEGER) >= 1996 THEN 'Z'
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END BETWEEN 1981 AND 1995 THEN 'Y'
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END BETWEEN 1965 AND 1980 THEN 'X'
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END BETWEEN 1946 AND 1964 THEN 'B'
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END BETWEEN 1928 AND 1945 THEN 'S'
					WHEN CASE WHEN a.cnst_birth_yr_num IS NULL 
							THEN CAST(SUBSTR(experian_birth_yrmth, 1, 4) AS INTEGER) 
							ELSE CAST(a.cnst_birth_yr_num AS INTEGER) 
						END < 1928 THEN 'G' 
					ELSE 'U'
				END AS generation_segmnt_cd, */ --These no longer available in bzf_cnst_chrctrstc as per business decision
				NULL::char AS generation_segmnt_cd,
			/*	CASE 
					WHEN generation_segmnt_cd = 'Z' THEN 'Gen Z'
					WHEN generation_segmnt_cd = 'Y' THEN 'Millennials'
					WHEN generation_segmnt_cd = 'X' THEN 'Gen X'
					WHEN generation_segmnt_cd = 'B' THEN 'Baby Boomers'
					WHEN generation_segmnt_cd = 'S' THEN 'The Silent Generation'
					WHEN generation_segmnt_cd = 'G' THEN 'The Greatest Generation'
					WHEN generation_segmnt_cd = 'U' THEN 'Unknown'
				END AS generation_segmnt_dsc,*/  --These no longer available in bzf_cnst_chrctrstc as per business decision
				NULL::varchar(100) AS generation_segmnt_dsc,
				a.cnst_birth_best_los_ind, 
				a.trans_key,
				a.user_id, 
				CAST(a.dw_srcsys_trans_ts AS TIMESTAMP) AS dw_srcsys_trans_ts,
				a.row_stat_cd,
				a.appl_src_cd,
				a.load_id,
				ROW_NUMBER() OVER (
					PARTITION BY mstr.cnst_mstr_id 
					ORDER BY
						CASE
							WHEN a.arc_srcsys_cd = 'BADW' THEN 1  -- Biomed eProgesa
							WHEN a.arc_srcsys_cd = 'DRMS' THEN 2  -- Biomed DRMS
							WHEN a.arc_srcsys_cd = 'VMS'  THEN 3  -- Volunteer Management System - Volunteer Connection
							WHEN a.arc_srcsys_cd = 'CDIM' THEN 4  -- CDI/Lexis Nexis source code
							WHEN a.arc_srcsys_cd = 'SFFS' THEN 5  -- Fundraising Salesforce system
							WHEN a.arc_srcsys_cd = 'PHSS' THEN 6  -- SABA
							-- Below condition is to check FR LOB Systems
							WHEN b.line_of_service_cd = 'FR' 
								AND a.arc_srcsys_cd NOT IN ('SFFS','ATG', 'ATGO','CNVO','TAFS') THEN 7
							WHEN a.arc_srcsys_cd = 'ATG'  THEN 8
							WHEN a.arc_srcsys_cd = 'TAFS' THEN 9
							ELSE 10 
						END
				) AS row_num
			FROM eda.arc_mdm_vws.bz_cnst_mstr mstr
			LEFT JOIN eda.arc_mdm_vws.bz_cnst_birth a ON mstr.cnst_mstr_id = a.cnst_mstr_id 
			LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys b ON a.arc_srcsys_cd = b.arc_srcsys_cd  
			LEFT JOIN mods_bi.mktg_ops_vws.bzf_cnst_scr c ON a.cnst_mstr_id = c.cnst_mstr_id
		/*	LEFT JOIN (
				SELECT 
					cnst_mstr_id, 
					-- bzd_equ_age1 AS experian_age,   
					-- bzd_exp_ex_bmyr1 AS experian_birth_yrmth, 
				--	CASE 
				--		WHEN CAST(SUBSTR(bzd_exp_ex_bmyr1, 5, 2) AS INTEGER) > EXTRACT(month FROM CURRENT_DATE) 
				--			THEN EXTRACT(year FROM CURRENT_DATE) - CAST(SUBSTR(bzd_exp_ex_bmyr1, 1, 4) AS INTEGER) - 1
				--		ELSE EXTRACT(year FROM CURRENT_DATE) - CAST(SUBSTR(bzd_exp_ex_bmyr1, 1, 4) AS INTEGER)
				--	END AS experian_derived_age 
				FROM mods_bi.mktg_ops_vws.bzf_cnst_chrctrstc
				WHERE bzd_equ_age1 IS NOT NULL
			) exp_age ON mstr.cnst_mstr_id = exp_age.cnst_mstr_id */ -- These columns no longer available in bzf_cnst_chrctrstc as per business decision
			LEFT JOIN (
				SELECT 
					cnst_mstr_id,
					pid,
					birth_dt_mth AS simio_birth_dt_mth_num,
					birth_dt_yr AS simio_birth_dt_yr_num,
					TO_DATE(
						LPAD(CAST(CASE WHEN birth_dt_mth = 0 THEN 1 ELSE birth_dt_mth END AS VARCHAR(2)), 2, '0') || 
						'/01/' || 
						TRIM(CAST(birth_dt_yr AS VARCHAR(4))), 
						'MM/DD/YYYY'
					) AS simio_derived_birth_dt,
					CASE 
						WHEN CAST(LPAD(CAST(birth_dt_mth AS VARCHAR(2)), 2, '0') AS INTEGER) > EXTRACT(month FROM CURRENT_DATE) 
							THEN EXTRACT(year FROM CURRENT_DATE) - CAST(birth_dt_yr AS INTEGER) - 1
						ELSE EXTRACT(year FROM CURRENT_DATE) - CAST(birth_dt_yr AS INTEGER)
					END AS simio_derived_age
				FROM mods_bi.mktg_ops_vws.bzf_cnst_chrctrstc_simio
			) sbb ON mstr.cnst_mstr_id = sbb.cnst_mstr_id 
			WHERE (a.cnst_mstr_id IS NOT NULL -- OR exp_age.cnst_mstr_id IS NOT NULL
			)
		)
		SELECT
			cnst_mstr_id, pid, cnst_srcsys_id, arc_srcsys_cd, cnst_birth_dy_num,
			cnst_birth_mth_num, cnst_birth_yr_num, bzd_char_month, bzd_char_day,
			bzd_char_yr, bzd_birth_dt, bzd_altered_dt_flg, bzd_derived_age, 
			experian_age, experian_birth_yrmth, experian_derived_age, 
			bb_age_cd,
			simio_birth_dt_yr_num, simio_birth_dt_mth_num, simio_derived_birth_dt, simio_derived_age,
			cnst_birth_strt_ts, cnst_birth_end_dt,
			gen_segmnt_key, 
			generation_segmnt_cd, generation_segmnt_dsc, 
			cnst_birth_best_los_ind, trans_key, user_id,
			dw_srcsys_trans_ts, row_stat_cd, appl_src_cd, load_id
		FROM ranked_data
		WHERE row_num = 1;
		
		-- Only proceed to target table if staging was successful
        TRUNCATE TABLE mods_bi.mktg_ops_tbls.bz_cnst_birth_best;
        
        -- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.bz_cnst_birth_best
        SELECT * FROM mods_bi.mktg_stage_tbls.bz_cnst_birth_best_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bz_cnst_birth_best) as INTEGER)
        WHERE proc_name = 'ld_bz_cnst_birth_best' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bz_cnst_birth_best: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bz_cnst_birth_best', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
