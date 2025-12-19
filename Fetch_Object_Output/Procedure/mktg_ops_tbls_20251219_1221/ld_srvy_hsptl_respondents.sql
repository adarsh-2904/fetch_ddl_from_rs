CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_hsptl_respondents()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Andrien
Created date: 10/24/2023
Purpose: The macro is scheduled to run nightly through a BTEQ script on our Informatica ETL server.  The macro reads the flattened hospital satisfaction 
survey response data and pulls the respondent details from each response to load into the mktg_ops_tbls.srvy_hsptl_respondents table.  The script first reads the existing 
table to get the max respondent_id, load_id and srcsys_trans_ts and uses the information to limit the inserts to new response rows and to assign a unique respondent id and load_id 
for each new response row.

Modified By:  Michael Andrien
Modified Date: 11/01/2023
Purpose:	Added the partition logic and respondent_id is null qualifier to avoid adding duplicate respondent rows to the table.

Modified By:  Michael Andrien
Modified Date: 06/06/2024
	Purpose: Added the join to the srvy_hsptl_load_cntl table to limit the respondent insert to responses associated with the active survey id.
	In the WHERE clause i replaced the iwebappid = 221027477 with lc.active_ind = 1.  This enables us to control which survey version gets loaded.
	Also, added the coalesce on string25 and string34 to assign to the hospital id.  The Summer FY24 survey references attribute string25 and the fall version
	referenced string34.
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_hsptl_respondents', 'Stored Procedure', 'Inprogress', v_start_time);
	
    BEGIN
		-- Truncate staging table
		TRUNCATE TABLE mktg_stage_tbls.srvy_hsptl_respondents_stg;
		INSERT INTO mktg_stage_tbls.srvy_hsptl_respondents_stg
			WITH max_values AS (
			SELECT 
				MAX(respondent_id) AS max_respondent_id, 
				MAX(load_id) AS max_load_id, 
				MAX(srcsys_trans_ts) AS max_srcsys_trans_ts
			FROM mktg_ops_vws.srvy_hsptl_respondents
		),
		qualified_respondents AS (
			SELECT 
				respondent_id, 
				sf_contact_id, 
				respondent_nm, 
				respondent_email, 
				respondent_role, 
				hospital_id,
				srcsys_trans_ts,
				ROW_NUMBER() OVER (PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) AS rn
			FROM mktg_ops_vws.srvy_hsptl_respondents 
			WHERE row_stat_cd = 'ADBE'
		),
		filtered_respondents AS (
			SELECT 
				respondent_id, 
				sf_contact_id, 
				respondent_nm, 
				respondent_email, 
				respondent_role, 
				hospital_id,
				srcsys_trans_ts
			FROM qualified_respondents
			WHERE rn = 1
		)
		SELECT
			ROW_NUMBER() OVER (ORDER BY a.iwebapplogid, b.tslog) + c.max_respondent_id,
			string48 AS sf_contact_id,
			string46 AS respondent_nm,
			string45 AS respondent_email,
			string44 AS respondent_role,
			COALESCE(a.string25, a.string34, 'NULL') AS hospital_id,
			CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts, 
			CURRENT_TIMESTAMP AS dw_trans_ts,
			'I' AS row_stat_cd,
			'ADBE' AS appl_src_cd,
			NVL(max_load_id, 0) + 1
		FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
		LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
		LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
		LEFT JOIN mktg_ops_vws.srvy_hsptl_survey s ON wa.iWebAppId = s.iWebAppId 
		LEFT JOIN mktg_ops_tbls.srvy_hsptl_load_cntl lc ON s.srvy_id = lc.srvy_id
		LEFT JOIN max_values c ON 1=1
		LEFT JOIN filtered_respondents r
			ON COALESCE(a.string46, 'NULL') = COALESCE(r.respondent_nm, 'NULL') 
				AND COALESCE(a.string45, 'NULL') = COALESCE(r.respondent_email, 'NULL') 
				AND COALESCE(a.string44, 'NULL') = COALESCE(r.respondent_role, 'NULL') 
				AND COALESCE(a.string25, a.string34, 'NULL') = COALESCE(r.hospital_id, 'NULL')
				AND COALESCE(a.string48, 'NULL') = COALESCE(r.sf_contact_id, 'NULL')
		WHERE 
			lc.active_ind = 1
			AND (string25 IS NOT NULL OR string44 IS NOT NULL OR string45 IS NOT NULL OR string46 IS NOT NULL OR string34 IS NOT NULL)
			AND CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)), 1, 19) AS TIMESTAMP) > c.max_srcsys_trans_ts
			AND r.respondent_id IS NULL;
			
		-- Insert data from staging to target
        INSERT INTO mktg_ops_tbls.srvy_hsptl_respondents
        SELECT * FROM mktg_stage_tbls.srvy_hsptl_respondents_stg;

        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_stage_tbls.srvy_hsptl_respondents_stg) as INTEGER)
        WHERE proc_name = 'ld_srvy_hsptl_respondents' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_srvy_hsptl_respondents: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_srvy_hsptl_respondents', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
