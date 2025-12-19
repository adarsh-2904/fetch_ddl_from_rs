CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_new_vlntr_rspns_txt_norm()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Andrien
Created date: 12/10/2024
Purpose: The macro is scheduled to run nightly through a BTEQ script on our Informatica ETL server.  The macro reads the flattened new volunteer satisfaction 
survey response data and loads a normalized response table for the open-ended text-based questions.  This table is accessed by a view and is the source for our PowerBI survey reporting model.

Modified By: Michael Andrien
Modified Date: 12/18/2024
Purpose: Changed var6 to varTeamworkWhy

Modified By: Michael Andrien
Modified Date: 12/18/2024
Purpose: Added the abobe_path_var qualifier to the srvy_new_vlntr_questn_2_srvy_xref to ensure the join returns
one unique row from the xref table.
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
    VALUES ('ld_srvy_new_vlntr_rspns_txt_norm', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		
		-- Get the max load_id and increment by 1
		SELECT COALESCE(MAX(load_id), 0) + 1 INTO v_load_id 
		FROM mktg_ops_tbls.srvy_new_vlntr_rspns_txt_norm;
	
		TRUNCATE TABLE mktg_stage_tbls.srvy_new_vlntr_rspns_txt_norm_stg;

		--1st Insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_txt_norm_stg
			SELECT
				a.iwebapplogid,
				COALESCE(x.new_cnst_mstr_id, c.bicnst_mstr_id) AS cnst_mstr_id,
				c.bicnst_mstr_id AS orig_cnst_mstr_id,
				e.srvy_id,
				f.question_id,
				CASE
				  WHEN a.mdata LIKE '%_2backgroundwhy%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<_2backgroundwhy>.*</_2backgroundwhy>'),
						'<_2backgroundwhy>', ''
					  ),
					  '</_2backgroundwhy>', ''
					)
				  ELSE NULL
				END AS rspns_txt,
				CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)), 1, 19) AS TIMESTAMP),
				CURRENT_TIMESTAMP,
				'I',
				'ADBE',
				v_load_id
			FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
			LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid 
				AND f.src_attrbt_nm = 'mdata' 
				AND f.adobe_path_var = '_2backgroundwhy'
			LEFT JOIN mktg_ops_tbls.srvy_new_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
			LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id
			WHERE
				lc.active_ind = 1
				AND f.question_id IS NOT NULL
				AND CASE
				  WHEN a.mdata LIKE '%_2backgroundwhy%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<_2backgroundwhy>.*</_2backgroundwhy>'),
						'<_2backgroundwhy>', ''
					  ),
					  '</_2backgroundwhy>', ''
					)
				  ELSE NULL
				END IS NOT NULL
				AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
				
		--2ND INSERT
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_txt_norm_stg
			SELECT
				a.iwebapplogid,
				COALESCE(x.new_cnst_mstr_id, c.bicnst_mstr_id) AS cnst_mstr_id,
				c.bicnst_mstr_id AS orig_cnst_mstr_id,
				e.srvy_id,
				f.question_id,
				CASE
				  WHEN a.mdata LIKE '%whyrecognizedappreciated%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<whyrecognizedappreciated>.*</whyrecognizedappreciated>'),
						'<whyrecognizedappreciated>', ''
					  ),
					  '</whyrecognizedappreciated>', ''
					)
				  ELSE NULL
				END AS rspns_txt,
				CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)), 1, 19) AS TIMESTAMP),
				CURRENT_TIMESTAMP,
				'I',
				'ADBE',
				v_load_id
			FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
			LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid 
				AND f.src_attrbt_nm = 'mdata' 
				AND f.adobe_path_var = 'whyrecognizedappreciated'
			LEFT JOIN mktg_ops_tbls.srvy_new_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
			LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id
			WHERE
				lc.active_ind = 1
				AND f.question_id IS NOT NULL
				AND CASE
				  WHEN a.mdata LIKE '%whyrecognizedappreciated%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<whyrecognizedappreciated>.*</whyrecognizedappreciated>'),
						'<whyrecognizedappreciated>', ''
					  ),
					  '</whyrecognizedappreciated>', ''
					)
				  ELSE NULL
				END IS NOT NULL
				AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

		--3rd Insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_txt_norm_stg
			SELECT
				a.iwebapplogid,
				COALESCE(x.new_cnst_mstr_id, c.bicnst_mstr_id) AS cnst_mstr_id,
				c.bicnst_mstr_id AS orig_cnst_mstr_id,
				e.srvy_id,
				f.question_id,
				CASE
				  WHEN a.mdata LIKE '%whysupportsupervisor%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<whysupportsupervisor>.*</whysupportsupervisor>'),
						'<whysupportsupervisor>', ''
					  ),
					  '</whysupportsupervisor>', ''
					)
				  ELSE NULL
				END AS rspns_txt,
				CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)), 1, 19) AS TIMESTAMP),
				CURRENT_TIMESTAMP,
				'I',
				'ADBE',
				v_load_id
			FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
			LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid 
				AND f.src_attrbt_nm = 'mdata' 
				AND f.adobe_path_var = 'whysupportsupervisor'
			LEFT JOIN mktg_ops_tbls.srvy_new_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
			LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id
			WHERE
				lc.active_ind = 1
				AND f.question_id IS NOT NULL
				AND CASE
				  WHEN a.mdata LIKE '%whysupportsupervisor%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<whysupportsupervisor>.*</whysupportsupervisor>'),
						'<whysupportsupervisor>', ''
					  ),
					  '</whysupportsupervisor>', ''
					)
				  ELSE NULL
				END IS NOT NULL
				AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

		--4th Insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_txt_norm_stg
			SELECT
				a.iwebapplogid,
				COALESCE(x.new_cnst_mstr_id, c.bicnst_mstr_id) AS cnst_mstr_id,
				c.bicnst_mstr_id AS orig_cnst_mstr_id,
				e.srvy_id,
				f.question_id,
				CASE
				  WHEN a.mdata LIKE '%varTeamworkWhy%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<varTeamworkWhy>.*</varTeamworkWhy>'),
						'<varTeamworkWhy>', ''
					  ),
					  '</varTeamworkWhy>', ''
					)
				  ELSE NULL
				END AS rspns_txt,
				CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)), 1, 19) AS TIMESTAMP),
				CURRENT_TIMESTAMP,
				'I',
				'ADBE',
				v_load_id
			FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
			LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid 
				AND f.src_attrbt_nm = 'mdata' 
				AND f.adobe_path_var = 'varTeamworkWhy'
			LEFT JOIN mktg_ops_tbls.srvy_new_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
			LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id
			WHERE
				lc.active_ind = 1
				AND f.question_id IS NOT NULL
				AND CASE
				  WHEN a.mdata LIKE '%varTeamworkWhy%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<varTeamworkWhy>.*</varTeamworkWhy>'),
						'<varTeamworkWhy>', ''
					  ),
					  '</varTeamworkWhy>', ''
					)
				  ELSE NULL
				END IS NOT NULL
				AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
			
		--5th Insert
		INSERT INTO mktg_stage_tbls.srvy_new_vlntr_rspns_txt_norm_stg
			SELECT
				a.iwebapplogid,
				COALESCE(x.new_cnst_mstr_id, c.bicnst_mstr_id) AS cnst_mstr_id,
				c.bicnst_mstr_id AS orig_cnst_mstr_id,
				e.srvy_id,
				f.question_id,
				CASE
				  WHEN a.mdata LIKE '%var8%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<var8>.*</var8>'),
						'<var8>', ''
					  ),
					  '</var8>', ''
					)
				  ELSE NULL
				END AS rspns_txt,
				CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)), 1, 19) AS TIMESTAMP),
				CURRENT_TIMESTAMP,
				'I',
				'ADBE',
				v_load_id
			FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
			LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
			LEFT JOIN mktg_ops_vws.srvy_new_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid 
				AND f.src_attrbt_nm = 'mdata' 
				AND f.adobe_path_var = 'var8'
			LEFT JOIN mktg_ops_tbls.srvy_new_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
			LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id
			WHERE
				lc.active_ind = 1
				AND f.question_id IS NOT NULL
				AND CASE
				  WHEN a.mdata LIKE '%var8%' THEN
					REPLACE(
					  REPLACE(
						REGEXP_SUBSTR(TRIM(a.mdata), '<var8>.*</var8>'),
						'<var8>', ''
					  ),
					  '</var8>', ''
					)
				  ELSE NULL
				END IS NOT NULL
				AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
				
				
		DELETE FROM mktg_ops_tbls.srvy_new_vlntr_rspns_txt_norm 
		WHERE 
			appl_src_cd = 'ADBE'
			AND srvy_id IN (
				SELECT srvy_id 
				FROM mktg_ops_tbls.srvy_new_vlntr_load_cntl 
				WHERE active_ind = 1
			);
		
		-- Insert data from staging to target
        INSERT INTO mktg_ops_tbls.srvy_new_vlntr_rspns_txt_norm
        SELECT * FROM mktg_stage_tbls.srvy_new_vlntr_rspns_txt_norm_stg;
		

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_stage_tbls.srvy_new_vlntr_rspns_txt_norm_stg) as INTEGER)
        WHERE proc_name = 'ld_srvy_new_vlntr_rspns_txt_norm' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_srvy_new_vlntr_rspns_txt_norm: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_srvy_new_vlntr_rspns_txt_norm', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
