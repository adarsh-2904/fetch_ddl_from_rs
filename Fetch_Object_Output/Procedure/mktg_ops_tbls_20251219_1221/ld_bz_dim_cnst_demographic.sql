CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_dim_cnst_demographic()
 LANGUAGE plpgsql
AS $_$
/* ---------------------------------------------------------------------------------------------------------------------------
Created By: 	Michael Andrien
Create Date: 10/14/2017
Purpose: 	To provide a normalize constituent dimension that contains race, ethnicity, gender, educations and other characteristics from the arc_mdm_vws CDI 
				database and other tables.  The purpose of the dimension is to simplify access to the translated characterisic codes/values and descriptions and to 
				improve query performance when these details need to be joined to other marketing fact and transaction tables.

Modified By: 	Michael Andrien
Modified Date: 03/15/2018
Purpose: Added CASE logic to derive income group descriptions for the incomce characteristic.

Modified By: 	Michael Andrien
Modified Date: 07/02/2018
Purpose:	Added the case statement and new attribute below
			case when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political = 00 then 'Uncoded' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political = 01 then 'Unconnected $ Unregistered' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political =02 then 'Informed But Unregistered' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political =03 then 'Super Democrats' 
			when  mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political = 04 then 'Left Out Democrats' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political =05 then 'Conservative Democrats' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political =06 then 'On-the-Fence Liberals' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political =07 then 'Green Traditionalists' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political =08 then 'Mild Republicans' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political =09 then 'Uninvolved Conservatives' 
			when mktg_ops_vws.bzf_cnst_chrctrstc.bzd_political =10 then 'Ultra Conservatives' 
			else 'Unknown' 
end AS political_persona
	
Modified By: 	Michael Andrien
Modified Date: 06/18/2019
Purpose: Added Age Band details

Modified By: 	Michael Andrien
Modified Date: 12/31/2020
Purpose: Updated difinition for 'Caucasion'  the in list group included '30' twice.  Added '33' to the list  
	from
	    when a.bzd_ethnic_exp_group1 in ('05','06','07','08','09','10','11','15','16','18','23','25','26','27','28','29','30','30') then 'Caucasian' 
	to
		when a.bzd_ethnic_exp_group1 in ('05','06','07','08','09','10','11','15','16','18','23','25','26','27','28','29','30','33') then 'Caucasian' 

Modified By: 		Greg Seaberg
Implemented By:	Michael Andrien
Modified Date: 	04/16/2024
Purpose:				With Blackbaud / Experian data being discontinued at the end of May 2024, the following changes have been made:
								- Primary table changed from bzf_cnst_chrctrstc to bzf_cnst_chrctrstc_simio
								- Gender reference changed from bzf_cnst_chrctrstc to bz_cnst_gender_best
								- Score reference changed from bzf_cnst_scr to bzf_cnst_scr_simio (this also eliminates duplicate rows)
Note:						Change in race / ethnicity values may require a change in the table / view definition (smallint --> varchar(1))
	---------------------------------------------------------------------------------------------------------------------------- */
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_bz_dim_cnst_demographic', 'Stored Procedure', 'Inprogress', v_start_time);
	
	-- Start transaction block
	BEGIN
		-- Truncate the staging table before loading new data
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.bz_dim_cnst_demographic_stg;
		
		-- Load data into staging table
		INSERT INTO mods_bi.mktg_stage_tbls.bz_dim_cnst_demographic_stg
		SELECT
			a.cnst_mstr_id,
			CASE 
				WHEN a.marital_stat_cd = 'B' THEN 'S'
				WHEN a.marital_stat_cd = 'A' THEN 'M'
				WHEN a.marital_stat_cd IS NOT NULL THEN a.marital_stat_cd 
				ELSE 'U' 
			END AS marital_status_cd, 
			CASE 
				WHEN a.marital_stat_cd IN ('S','B') THEN 'Single' 
				WHEN a.marital_stat_cd IN ('M','A') THEN 'Married' 
				ELSE 'Unknown' 
			END AS marital_status_dsc,
			a.eductn_cd AS education_level_cd,
			CASE 
				WHEN a.eductn_cd = '1' THEN 'High School Diploma' 
				WHEN a.eductn_cd = '2' THEN 'Bachelors Degree' 
				WHEN a.eductn_cd = '3' THEN 'Advanced Degree' 
				WHEN a.eductn_cd = '4' THEN 'Associates Degree'  
				ELSE 'Unknown' 
			END AS education_level_dsc,
			scr.sm_arc_lapsed_scrval AS chpt_lapsed_tag1_scrval,
			scr.sm_arc_non_fr_scrval AS un_conv_tag_scrval,
			CASE 
				WHEN scr.sm_mnthly_sust_propnsty_scrval >= 15 THEN 'T' 
				ELSE 'F' 
			END AS sustainer_flg,
			CASE WHEN g.gender_best_cd IS NULL THEN 'U' ELSE g.gender_best_cd END AS gender_cd,
			CASE 
				WHEN g.gender_best_cd IS NULL THEN 'Unknown' 
				WHEN g.gender_best_cd = 'F' THEN 'Female' 
				WHEN g.gender_best_cd = 'M' THEN 'Male' 
				WHEN g.gender_best_cd = 'U' THEN 'Unknown' 
				ELSE 'Unknown'
			END AS gender_dsc,
			CASE WHEN a.race_cd IS NOT NULL THEN a.race_cd ELSE 'U' END AS ethnic_exp_group_cd,
			CASE WHEN a.race_cd IS NOT NULL THEN a.race_cd ELSE 'U' END AS ethnic_exp_group_dsc,
			CASE 
				WHEN a.race_cd = 'A' THEN 'Asian' 
				WHEN a.race_cd = 'B' THEN 'Black or African-American' 
				WHEN a.race_cd = 'W' THEN 'Caucasian' 
				WHEN a.race_cd = 'H' THEN 'Hispanic or Latino' 
				ELSE 'Other or Unknown' 
			END AS race_group_dsc,
			CASE WHEN b.gen_segmnt_key IS NOT NULL THEN b.gen_segmnt_key ELSE 0 END AS gen_segmnt_key,
			CASE WHEN b.generation_segmnt_cd IS NOT NULL THEN b.generation_segmnt_cd ELSE 'U' END AS generation_segmnt_cd,
			CASE 
				WHEN b.generation_segmnt_dsc IS NOT NULL THEN b.generation_segmnt_dsc 
				ELSE 'Unknown' 
			END AS generation_segmnt_dsc,
			CASE 
				WHEN a.hh_income_cd BETWEEN '1' AND '9' THEN '1. <$50k' 
				WHEN a.hh_income_cd BETWEEN 'A' AND 'E' THEN '2. $50-100k' 
				WHEN a.hh_income_cd = 'F' THEN '3. $100-150k' 
				WHEN a.hh_income_cd BETWEEN 'G' AND 'J' THEN '4. $150k+' 
				ELSE '5. Unknown' 
			END AS income_group_dsc,
			poltcl_party_dsc AS political_persona,
			CASE WHEN ab.age_band_dsc IS NULL THEN 'Unknown' ELSE ab.age_band_dsc END AS age_band_dsc
		FROM mods_bi.mktg_ops_vws.bzf_cnst_chrctrstc_simio a
		LEFT JOIN mods_bi.mktg_ops_vws.bz_cnst_birth_best b ON a.cnst_mstr_id = b.cnst_mstr_id
		LEFT JOIN mods_bi.mktg_ops_vws.dim_age_band ab ON ab.age_band_key = b.bzd_derived_age
		LEFT JOIN mods_bi.mktg_ops_vws.bz_cnst_gender_best g ON a.cnst_mstr_id = g.cnst_mstr_id
		LEFT JOIN mods_bi.mktg_ops_vws.bzf_cnst_scr_simio scr ON a.cnst_mstr_id = scr.cnst_mstr_id;
		
		-- Only proceed to target table if staging was successful
        TRUNCATE TABLE mods_bi.mktg_ops_tbls.bz_dim_cnst_demographic;
		
		-- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.bz_dim_cnst_demographic
        SELECT * FROM mods_bi.mktg_stage_tbls.bz_dim_cnst_demographic_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bz_dim_cnst_demographic) as INTEGER)
        WHERE proc_name = 'ld_bz_dim_cnst_demographic' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;
		
	EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bz_dim_cnst_demographic: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bz_dim_cnst_demographic', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$_$
