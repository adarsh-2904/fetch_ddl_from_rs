CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_anvrsy_vlntr_rspns_cmnt_curnt()
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
    VALUES ('ld_srvy_anvrsy_vlntr_rspns_cmnt_curnt', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN

		Truncate Table mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_curnt_stg;

		INSERT INTO mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_curnt_stg
		SELECT
			wa.iwebappid,
			a.iwebapplogid,
			b.tslog AS respns_ts,
			c.bicnst_mstr_id AS cnst_mstr_id,
			c.bicnst_mstr_id AS orig_cnst_mstr_id,
			NULL AS email,
			wa.slabel,
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
			END AS why_backgrnd_scr_cmt,
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
			END AS why_recgnzd_aprctd_scr_cmt,
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
			END AS why_suprt_suprvsr_scr_cmt,
			CASE
				WHEN a.mdata LIKE '%var6%' THEN
					REPLACE(
						REPLACE(
							REGEXP_SUBSTR(TRIM(a.mdata), '<var6>.*</var6>'),
							'<var6>', ''
						),
						'</var6>', ''
					)
				ELSE NULL
			END AS why_teamwrk_scr_cmt,
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
			END AS exprnc_cmt,
			CURRENT_TIMESTAMP AS dw_trans_ts,
			CAST(SUBSTRING(CAST(b.tslog AS VARCHAR(26)), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
			'I' AS row_stat_cd,
			'ADBE' AS appl_src_cd,
			max_load_id + 1 AS load_id
		FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
		LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
		LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
		LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
		LEFT JOIN mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_load_cntl lc ON wa.iwebappid = lc.iwebappid
		LEFT JOIN 
		(
			SELECT MAX(load_id) AS max_load_id
			FROM mktg_ops_vws.srvy_anvrsy_vlntr_rspns_all
		) h ON 1=1
		WHERE
			lc.active_ind = 1
			AND 
			(
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
				END IS NOT NULL
				OR
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
				END IS NOT NULL
				OR
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
				END IS NOT NULL
				OR    
				CASE
					WHEN a.mdata LIKE '%var6%' THEN
						REPLACE(
							REPLACE(
								REGEXP_SUBSTR(TRIM(a.mdata), '<var6>.*</var6>'),
								'<var6>', ''
							),
							'</var6>', ''
						)
					ELSE NULL
				END IS NOT NULL
				OR
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
				END IS NOT NULL
			);
		
		DELETE FROM mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt_curnt
		WHERE 
			iwebappid IN (
				SELECT iwebappid 
				FROM mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_load_cntl 
				WHERE active_ind = 1
			);
		
		-- Insert data from staging to target
        INSERT INTO mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt_curnt
        SELECT * FROM mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_curnt_stg;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_stage_tbls.srvy_anvrsy_vlntr_rspns_cmnt_curnt_stg) as INTEGER)
        WHERE proc_name = 'ld_srvy_anvrsy_vlntr_rspns_cmnt_curnt' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_srvy_anvrsy_vlntr_rspns_cmnt_curnt: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_srvy_anvrsy_vlntr_rspns_cmnt_curnt', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
