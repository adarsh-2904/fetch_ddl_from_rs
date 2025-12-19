CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_anvrsry_rspns_txt_norm()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Hall
Created date: 01/10/2025
Purpose: The macro is scheduled to run nightly through a BTEQ script on our Informatica ETL server.  
The macro reads the flattened Volunteer Anniversary Satisfaction survey response data and loads a normalized response table for the open-ended text-based questions.  
This table is accessed by a view and is the source for our PowerBI survey reporting model.

Modified By: Michael Hall
Modified Date: 03/04/2025
Purpose: Removed '%varTeamworkWhy%' entry and replaced with 'var6' entry. Added comment headers to each INSERT statement.
*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_anvrsry_rspns_txt_norm', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
DELETE FROM mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_txt_norm 
WHERE 
	appl_src_cd = 'ADBE'
	AND srvy_id IN (SELECT srvy_id FROM mktg_ops_tbls.srvy_anvrsry_vlntr_load_cntl WHERE active_ind = 1);


INSERT INTO mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_txt_norm
SELECT
	a.iwebapplogid,
	COALESCE(x.new_cnst_mstr_id,c.bicnst_mstr_id) AS cnst_mstr_id,
	c.bicnst_mstr_id AS orig_cnst_mstr_id,	
	e.srvy_id, /* Survey id value */
	f.question_id,
	CASE

        WHEN a.mdata LIKE '%_2backgroundwhy%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<_2backgroundwhy>([^<]*)</_2backgroundwhy>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )

        ELSE NULL

    END AS rspns_txt,
	CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP), /*srcsys_trans_ts*/
	CURRENT_TIMESTAMP, /*dw_trans_ts*/
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */

FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'mdata'  AND f.adobe_path_var = '_2backgroundwhy'
LEFT JOIN  mktg_ops_tbls.srvy_anvrsry_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id  /* Added this join to get the new merged cnst_mstr_ids */
LEFT JOIN 
(
	SELECT MAX(load_id)
	FROM mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_norm
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND 	
		CASE
		  WHEN a.mdata LIKE '%_2backgroundwhy%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<_2backgroundwhy>([^<]*)</_2backgroundwhy>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )

		 ELSE NULL
		END IS NOT NULL
	AND CAST(b.tslog AS DATE) >= lc.active_start_dt ;

commit;


INSERT INTO mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_txt_norm
SELECT
	a.iwebapplogid,
	COALESCE(x.new_cnst_mstr_id,c.bicnst_mstr_id) AS cnst_mstr_id,
	c.bicnst_mstr_id AS orig_cnst_mstr_id,	
	e.srvy_id, /* Survey id value */
	f.question_id,
	CASE

        WHEN a.mdata LIKE '%whyrecognizedappreciated%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<whyrecognizedappreciated>([^<]*)</whyrecognizedappreciated>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )

        ELSE NULL

    END AS rspns_txt,
	CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP(0)), /*srcsys_trans_ts*/
	CURRENT_TIMESTAMP(0), /*dw_trans_ts*/
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'mdata' AND f.adobe_path_var = 'whyrecognizedappreciated'
LEFT JOIN  mktg_ops_tbls.srvy_anvrsry_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id  /* Added this join to get the new merged cnst_mstr_ids */
LEFT JOIN 
(
	SELECT MAX(load_id)
	FROM mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_norm
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND 	
		CASE
		 WHEN a.mdata LIKE '%whyrecognizedappreciated%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<whyrecognizedappreciated>([^<]*)</whyrecognizedappreciated>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )

		 ELSE NULL
		END IS NOT NULL
	AND CAST(b.tslog AS DATE) >= lc.active_start_dt ;
		 
commit;


INSERT INTO mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_txt_norm
SELECT
	a.iwebapplogid,
	COALESCE(x.new_cnst_mstr_id,c.bicnst_mstr_id) AS cnst_mstr_id,
	c.bicnst_mstr_id AS orig_cnst_mstr_id,	
	e.srvy_id, /* Survey id value */
	f.question_id,
	CASE

        WHEN a.mdata LIKE '%whysupportsupervisor%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<whysupportsupervisor>([^<]*)</whysupportsupervisor>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )

        ELSE NULL

    END AS rspns_txt,
	CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP(0)), /*srcsys_trans_ts*/
	CURRENT_TIMESTAMP(0), /*dw_trans_ts*/
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'mdata' AND f.adobe_path_var = 'whysupportsupervisor'
LEFT JOIN  mktg_ops_tbls.srvy_anvrsry_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id  /* Added this join to get the new merged cnst_mstr_ids */
LEFT JOIN 
(
	SELECT MAX(load_id)
	FROM mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_norm
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND 	
		CASE
		  WHEN a.mdata LIKE '%whysupportsupervisor%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<whysupportsupervisor>([^<]*)</whysupportsupervisor>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )
		 ELSE NULL
		END IS NOT NULL
	AND CAST(b.tslog AS DATE) >= lc.active_start_dt ;
            
commit;


INSERT INTO mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_txt_norm
SELECT
	a.iwebapplogid,
	COALESCE(x.new_cnst_mstr_id,c.bicnst_mstr_id) AS cnst_mstr_id,
	c.bicnst_mstr_id AS orig_cnst_mstr_id,	
	e.srvy_id, /* Survey id value */
	f.question_id,
	CASE

        WHEN a.mdata LIKE '%var6%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<var6>([^<]*)</var6>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )

        ELSE NULL

    END AS rspns_txt,
	CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP(0)), /*srcsys_trans_ts*/
	CURRENT_TIMESTAMP(0), /*dw_trans_ts*/
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'mdata' AND f.adobe_path_var = 'var6'
LEFT JOIN  mktg_ops_tbls.srvy_anvrsry_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id  /* Added this join to get the new merged cnst_mstr_ids */
LEFT JOIN 
(
	SELECT MAX(load_id)
	FROM mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_norm
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND 	
		CASE
		  WHEN a.mdata LIKE '%var6%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<var6>([^<]*)</var6>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )
		 ELSE NULL
		END IS NOT NULL
	AND CAST(b.tslog AS DATE) >= lc.active_start_dt ;
 
commit;
            
INSERT INTO mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_txt_norm
SELECT
	a.iwebapplogid,
	COALESCE(x.new_cnst_mstr_id,c.bicnst_mstr_id) AS cnst_mstr_id,
	c.bicnst_mstr_id AS orig_cnst_mstr_id,	
	e.srvy_id, /* Survey id value */
	f.question_id,
	CASE

        WHEN a.mdata LIKE '%var8%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<var8>([^<]*)</var8>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )

        ELSE NULL

    END AS rspns_txt,
	CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP(0)), /*srcsys_trans_ts*/
	CURRENT_TIMESTAMP(0), /*dw_trans_ts*/
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'mdata' AND f.adobe_path_var = 'var8'
LEFT JOIN  mktg_ops_tbls.srvy_anvrsry_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON c.bicnst_mstr_id=x.cnst_mstr_id  /* Added this join to get the new merged cnst_mstr_ids */
LEFT JOIN 
(
	SELECT MAX(load_id)
	FROM mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_norm
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND 	
		CASE
		 WHEN a.mdata LIKE '%var8%' THEN

            -- Extracts content between the tags.

            -- [^<]* matches any character that is NOT '<', zero or more times,

            -- ensuring it stops before the next tag.

            REGEXP_SUBSTR(

                TRIM(a.mdata),

                '<var8>([^<]*)</var8>',

                1, -- Start search from the first character

                1, -- Return the first occurrence of the match

                'e' -- Use extended regular expressions (standard for most modern regex)

            )
		 ELSE NULL
		END IS NOT NULL
	AND CAST(b.tslog AS DATE) >= lc.active_start_dt ;
commit;


		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_txt_norm) as INTEGER)
			WHERE proc_name = 'ld_srvy_anvrsry_rspns_txt_norm' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_srvy_anvrsry_rspns_txt_norm', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
