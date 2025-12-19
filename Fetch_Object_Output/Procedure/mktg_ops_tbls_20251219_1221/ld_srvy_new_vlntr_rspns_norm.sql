CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_new_vlntr_rspns_norm()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Andrien
Created date: 12/10/2024
Purpose: The macro is scheduled to run nightly through a BTEQ script on our Informatica ETL server.  The macro reads the flattened new volunteer satisfaction 
survey response data and loads a normalized response table.  This table is accessed by a view and is the source for our PowerBI survey reporting model.

Modified By: Michael Andrien
Modified Date: 12/18/2024
Purpose: Added the insert for the Why Volunteer question - byte1

Modified By: Michael Andrien
Modified Date: 06/12/2025
Purpose: Added inserts for FY26 Questions 4a and 4b.  These are AD-Agree/Disagree questions mapped to string4 and string3.
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
	v_load_id INTEGER;
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_new_vlntr_rspns_norm', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		
		-- Get the max load_id and increment by 1
		SELECT COALESCE(MAX(load_id), 0) + 1 INTO v_load_id 
		FROM mktg_ops_tbls.srvy_new_vlntr_rspns_norm;
	
		TRUNCATE TABLE mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg;
		
		DROP TABLE IF EXISTS temp_srvy_new_vlntr_rspns_norm_data;

		CREATE TEMP TABLE temp_srvy_new_vlntr_rspns_norm_data AS
			SELECT 
				a.iwebapplogid,
				COALESCE(x.new_cnst_mstr_id, nr.bicnst_mstr_id) AS cnst_mstr_id,
				nr.bicnst_mstr_id AS orig_cnst_mstr_id,	
				e.srvy_id,
				wa.iWebAppId,
				a.string10,
				a.string17,
				a.string1,
				a.string0,
				a.string18,
				a.string11,
				a.string28,
				a.string26,
				a.string25,
				a.string23,
				a.string22,
				a.string20,
				a.string16,
				a.string2,
				a.string4,
				a.string3,
				a.string8,
				a.boolean17,
				a.boolean16,
				a.boolean15,
				a.boolean14,
				a.boolean13,
				a.byte1,
				TRY_CAST(TRIM(a.string10) AS BIGINT) AS string10_num,
				TRY_CAST(TRIM(a.string17) AS BIGINT) AS string17_num,
				TRY_CAST(TRIM(a.string1)  AS BIGINT) AS string1_num,
				TRY_CAST(TRIM(a.string0)  AS BIGINT) AS string0_num,
				TRY_CAST(TRIM(a.string18) AS BIGINT) AS string18_num,
				TRY_CAST(TRIM(a.string11) AS BIGINT) AS string11_num,
				TRY_CAST(TRIM(a.boolean17) AS BIGINT) AS boolean17_num,
				TRY_CAST(TRIM(a.boolean16) AS BIGINT) AS boolean16_num,
				TRY_CAST(TRIM(a.boolean15) AS BIGINT) AS boolean15_num,
				TRY_CAST(TRIM(a.boolean14) AS BIGINT) AS boolean14_num,
				TRY_CAST(TRIM(a.boolean13) AS BIGINT) AS boolean13_num,
				TRY_CAST(TRIM(a.byte1) AS BIGINT) AS byte1_num,
				CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
				CURRENT_TIMESTAMP AS dw_trans_ts,
				ROW_NUMBER() OVER (PARTITION BY c.fiscal_yr, nr.bicnst_mstr_id ORDER BY nr.bicnst_mstr_id, c.fiscal_yr, b.tslog ASC) AS rn
			FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
			LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient nr ON b.iRecipientId = nr.iRecipientId
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
			LEFT JOIN mktg_ops_tbls.srvy_new_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
			LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON nr.bicnst_mstr_id = x.cnst_mstr_id
			LEFT JOIN eda.dw_common_vws.dim_calendar c ON (CAST(b.tslog AS DATE) = c.calendar_dt) 
			WHERE  
				lc.active_ind = 1
				AND CAST(b.tslog AS DATE) >= lc.active_start_dt;

		-- 1st insert:
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.string10_num = d.value_num AND d.value_catgry_cd = 'ER'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string10'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;

		-- 2nd insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.string17_num = d.value_num AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string17'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;

		--3RD INSERT
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.string1_num = d.value_num AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string1'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;

		--4th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.string0_num = d.value_num AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string0'
			WHERE  
				bd.rn = 1  
				AND f.question_id IS NOT NULL;
			
		--5th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.string18_num = d.value_num AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string18'
			WHERE  
				bd.rn = 1  
				AND f.question_id IS NOT NULL;
				
		--6TH INSERT
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.string11_num = d.value_num AND d.value_catgry_cd = 'NPS'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string11'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--7th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string28::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string28'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--8th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string26::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string26'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--9th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string25::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string25'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;

		--10th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string23::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string23'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--11th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string22::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string22'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;

		--12th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string20::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string20'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--13th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string16::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string16'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--14th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string2::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string2'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--15th insert
		/*Added for FY26 question 4a*/
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string4::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string4'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--16TH INSERT
		/*Added for FY26 question 4b*/
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string3::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string3'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--17TH INSERT
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON collate(bd.string8::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'AD'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string8'
			WHERE  
				bd.rn = 1 
				AND f.question_id IS NOT NULL;
				
		--18th insert:
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.boolean17_num = d.value_num AND d.value_catgry_cd = 'YN'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean17'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;
			
		--19TH INSERT
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.boolean16_num = d.value_num AND d.value_catgry_cd = 'YN'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean16'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;
			
		--20th insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.boolean15_num = d.value_num AND d.value_catgry_cd = 'YN'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean15'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;
			
			
		--21st insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.boolean14_num = d.value_num AND d.value_catgry_cd = 'YN'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean14'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;

		--22nd insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.boolean13_num = d.value_num AND d.value_catgry_cd = 'YN'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean13'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;

		--23rd insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg
			SELECT 
				bd.iwebapplogid AS rspns_id,
				bd.cnst_mstr_id AS cnst_mstr_id,
				bd.orig_cnst_mstr_id AS orig_cnst_mstr_id,	
				bd.srvy_id AS srvy_id, 
				f.question_id AS question_id,
				COALESCE(d.value_id, 0) AS value_id, 
				bd.srcsys_trans_ts AS srcsys_trans_ts, 
				bd.dw_trans_ts AS dw_trans_ts, 
				'I' AS row_stat_cd, 
				'ADBE' AS apple_src_cd, 
				v_load_id AS load_id 
			FROM temp_srvy_new_vlntr_rspns_norm_data bd
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_values d ON bd.byte1_num = d.value_num AND d.value_catgry_cd = 'WHYVOL'
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON bd.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'byte1'
			WHERE  
				bd.rn = 1
				AND f.question_id IS NOT NULL;
				
				
		DELETE FROM mktg_ops_tbls.srvy_new_vlntr_rspns_norm
		WHERE srvy_id IN (
			SELECT srvy_id 
			FROM mktg_ops_tbls.srvy_new_vlntr_load_cntl 
			WHERE active_ind = 1
		);
		
		-- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.srvy_new_vlntr_rspns_norm
        SELECT * FROM mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg;
		

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_stage_tbls.srvy_new_vlntr_rspns_norm_stg) as INTEGER)
        WHERE proc_name = 'ld_srvy_new_vlntr_rspns_norm' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_srvy_new_vlntr_rspns_norm: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_srvy_new_vlntr_rspns_norm', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
