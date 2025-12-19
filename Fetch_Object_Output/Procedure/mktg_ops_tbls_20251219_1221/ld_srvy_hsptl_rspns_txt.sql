CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_hsptl_rspns_txt()
 LANGUAGE plpgsql
AS $$

/*
Created by: Michael Andrien
Created date: 10/23/2023
Purpose: The macro is scheduled to run nightly through a BTEQ script on our Informatica ETL server.  The macro reads the flattened hospital satisfaction 
survey response data and loads text response question into an normalized response text table.  This table is accessed by a view and is the source for our PowerBI survey reporting model.

Modified By:  Michael Andrien
Modified Date: 11/01/2023
Purpose:	Added the partition logic to the respondent table join to avoid adding duplicate response rows to the table.  The respondent table has duplicate rows across
the historical and Adobe source records.

Modified By:  Michael Andrien
Modified Date: 11/27/2023
Purpose: Fixed the string 47 union - we referenced string43 in the select rather than string47.

Modified By:  Michael Andrien
Modified Date: 06/27/2024
Purpose: Updated the macro to leverage the mktg_ops_tbls.srvy_hsptl_load_cntl to determine which survey version to load.  Aslo, added logic
to pull the open-ended response text from the mdata attribute for the FY24 Summer survey version and added a qualifier on the FY24 Fall text fields to limit those to 
the FY24 Fall version.

Modified By:  Michael Andrien
Modified Date: 11/01/2024
Purpose:  Added an INSERT for question 49 from the FY25 Fall survey - RedCrossImprovSerUrHosp

Modified By:  Michael Andrien
Modified Date: 11/04/2024
Purpose: Added an INSERT for question 64 from the FY25 Fall surevey - varAnythngTellAbtRCB

Modified By:  Michael Andrien
Modified Date: 05/30/2025
Purpose: Added the new open-ended question for Please_share_how_we_could_do_better_for_you for the FY25 Spring/Summer survey.

Modified By:  Michael Andrien
Modified Date: 06/09/2025
Purpose: Altered the join logic for the new open-ended question for Please_share_how_we_could_do_better_for_you Adobe Path Variable to ensure the Select linked to question 102 vs 62.

*/

DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_hsptl_rspns_txt', 'Stored Procedure', 'Inprogress', v_start_time);


begin

-- DELETE statement
DELETE FROM mktg_ops_tbls.srvy_hsptl_rspns_txt
WHERE appl_src_cd = 'ADBE'
  AND srvy_id IN (
    SELECT srvy_id
    FROM mktg_ops_tbls.srvy_hsptl_load_cntl
    WHERE active_ind = 1
);

-- INSERT statement
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns_txt

SELECT
    a.iwebapplogid,
    COALESCE(g.respondent_id, 0) AS respondent_id,
    e.srvy_id, -- Survey id value
    f.question_id,
    CASE
        WHEN a.mdata LIKE '%<varAnythingTellAbtRCB>%' THEN
            REGEXP_SUBSTR(TRIM(a.mdata),'<varAnythingTellAbtRCB>([^<]*)</varAnythingTellAbtRCB>',1,1,'e')
        ELSE NULL
    END AS rspns_txt,
    CURRENT_TIMESTAMP AS dw_trans_ts,
    CAST(SUBSTRING(CAST(b.tslog AS VARCHAR), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
    'I' AS row_stat_cd,
    'ADBE' AS appl_src_cd,
    max_load_id + 1 AS load_id

FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'mdata'
LEFT JOIN mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id

LEFT JOIN
(
	SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
	FROM mktg_ops_vws.srvy_hsptl_respondents 
	WHERE appl_src_cd = 'ADBE'
	QUALIFY Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) = 1 
) g (respondent_id, sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id, srcsys_trans_ts)
	ON Coalesce(a.string46, 'NULL') = Coalesce(g.respondent_nm, 'NULL') 
		AND Coalesce(a.string45, 'NULL') = Coalesce(g.respondent_email, 'NULL') 
		AND Coalesce(a.string44, 'NULL') = Coalesce(g.respondent_role, 'NULL') 
		AND Coalesce(a.string34, 'NULL') = Coalesce(g.hospital_id, 'NULL')
		AND Coalesce(a.string48, 'NULL') = Coalesce(g.sf_contact_id, 'NULL')LEFT JOIN 
(
	SELECT Max(load_id)
	FROM mktg_ops_vws.srvy_hsptl_rspns
) h (max_load_id) ON 1=1
WHERE
    lc.active_ind = 1
    AND f.question_id IS NOT NULL
    AND (
        CASE
			WHEN a.mdata LIKE '%varAnythingTellAbtRCB%' THEN
				SUBSTRING(
					REGEXP_SUBSTR(TRIM(a.mdata),'<varAnythingTellAbtRCB>([^<]*)</varAnythingTellAbtRCB>',1,1,'e'),
					1,
					1000
				)
			ELSE NULL
		END

    ) IS NOT NULL
    AND CAST(b.tslog AS TIMESTAMP) >= '2023-10-23 00:00:00'

--Hitansu:tested till here.
	
UNION ALL ---First Union

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
    CASE
        WHEN a.mdata LIKE '%<varAnythngTellAbtRCB>%' THEN
            REGEXP_SUBSTR(
                TRIM(a.mdata),
                '<varAnythngTellAbtRCB>([^<]*)</varAnythngTellAbtRCB>',
                1,   -- Start search from the first character
                1,   -- Return the first occurrence of the match
                'e'  -- Use extended regular expressions
            )
        ELSE NULL
    END AS rspns_txt,
	CURRENT_TIMESTAMP AS dw_trans_ts,
    CAST(SUBSTRING(CAST(b.tslog AS VARCHAR), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
    'I' AS row_stat_cd,
    'ADBE' AS appl_src_cd,
    max_load_id + 1 AS load_id
	
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.adobe_path_var = 'varAnythngTellAbtRCB' AND f.src_attrbt_nm = 'mdata'
LEFT JOIN  mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN
(
	SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
	FROM mktg_ops_vws.srvy_hsptl_respondents 
	WHERE appl_src_cd = 'ADBE'
	QUALIFY Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) = 1 
) g (respondent_id, sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id, srcsys_trans_ts)
	ON Coalesce(a.string46, 'NULL') = Coalesce(g.respondent_nm, 'NULL') 
		AND Coalesce(a.string45, 'NULL') = Coalesce(g.respondent_email, 'NULL') 
		AND Coalesce(a.string44, 'NULL') = Coalesce(g.respondent_role, 'NULL') 
		AND Coalesce(a.string34, 'NULL') = Coalesce(g.hospital_id, 'NULL')
		AND Coalesce(a.string48, 'NULL') = Coalesce(g.sf_contact_id, 'NULL')LEFT JOIN 
(
	SELECT Max(load_id)
	FROM mktg_ops_vws.srvy_hsptl_rspns
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND 	
		CASE
        WHEN a.mdata LIKE '%<varAnythngTellAbtRCB>%' THEN
            REGEXP_SUBSTR(
                TRIM(a.mdata),
                '<varAnythngTellAbtRCB>([^<]*)</varAnythngTellAbtRCB>',
                1,   -- Start search from the first character
                1,   -- Return the first occurrence of the match
                'e'  -- Use extended regular expressions
            )
        ELSE NULL
		END IS NOT NULL
	AND CAST(b.tslog AS TIMESTAMP) >= '2023-10-23 00:00:00'
	--7/29 Hitansu: tested fine till here
UNION ALL	--Second Union, third query starts

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
--	a.string35 AS rspns_txt,
		CASE
        WHEN a.mdata LIKE '%RedCrossImprovSerUrHosp%' THEN
            REGEXP_SUBSTR(
                TRIM(a.mdata),
                '<RedCrossImprovSerUrHosp>([^<]*)</RedCrossImprovSerUrHosp>',
                1,   -- Start search from the first character
                1,   -- Return the first occurrence of the match
                'e'  -- Use extended regular expressions
            )
        ELSE null
	END AS rspns_txt,
	CURRENT_TIMESTAMP AS dw_trans_ts,
    CAST(SUBSTRING(CAST(b.tslog AS VARCHAR), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
    'I' AS row_stat_cd,
    'ADBE' AS appl_src_cd,
    max_load_id + 1 AS load_id
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.adobe_path_var = 'RedCrossImprovSerUrHosp' AND f.src_attrbt_nm = 'mdata'
LEFT JOIN  mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN
(
	SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
	FROM mktg_ops_vws.srvy_hsptl_respondents 
	WHERE appl_src_cd = 'ADBE'
	QUALIFY Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) = 1 
) g (respondent_id, sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id, srcsys_trans_ts)
	ON Coalesce(a.string46, 'NULL') = Coalesce(g.respondent_nm, 'NULL') 
		AND Coalesce(a.string45, 'NULL') = Coalesce(g.respondent_email, 'NULL') 
		AND Coalesce(a.string44, 'NULL') = Coalesce(g.respondent_role, 'NULL') 
		AND Coalesce(a.string34, 'NULL') = Coalesce(g.hospital_id, 'NULL')
		AND Coalesce(a.string48, 'NULL') = Coalesce(g.sf_contact_id, 'NULL')LEFT JOIN 
(
	SELECT Max(load_id)
	FROM mktg_ops_vws.srvy_hsptl_rspns
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND CASE
        WHEN a.mdata LIKE '%RedCrossImprovSerUrHosp%' THEN
            REGEXP_SUBSTR(
                TRIM(a.mdata),
                '<RedCrossImprovSerUrHosp>([^<]*)</RedCrossImprovSerUrHosp>',
                1,   -- Start search from the first character
                1,   -- Return the first occurrence of the match
                'e'  -- Use extended regular expressions
            )
        ELSE null	
		END IS NOT NULL
--	AND Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP(0)) >= '2023-10-23 00:00:00'
	--7/29 Hitansu: no data, tested fine till here
UNION ALL

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	a.string35 AS rspns_txt,
	CURRENT_TIMESTAMP AS dw_trans_ts,
    CAST(SUBSTRING(CAST(b.tslog AS VARCHAR), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
    'I' AS row_stat_cd,
    'ADBE' AS appl_src_cd,
    max_load_id + 1 AS load_id
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'mdata'--f.src_attrbt_nm = 'string35'
LEFT JOIN  mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN
(
	SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
	FROM mktg_ops_vws.srvy_hsptl_respondents 
	WHERE appl_src_cd = 'ADBE'
	QUALIFY Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) = 1 
) g (respondent_id, sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id, srcsys_trans_ts)
	ON Coalesce(a.string46, 'NULL') = Coalesce(g.respondent_nm, 'NULL') 
		AND Coalesce(a.string45, 'NULL') = Coalesce(g.respondent_email, 'NULL') 
		AND Coalesce(a.string44, 'NULL') = Coalesce(g.respondent_role, 'NULL') 
		AND Coalesce(a.string34, 'NULL') = Coalesce(g.hospital_id, 'NULL')
		AND Coalesce(a.string48, 'NULL') = Coalesce(g.sf_contact_id, 'NULL')LEFT JOIN 
(
	SELECT Max(load_id)
	FROM mktg_ops_vws.srvy_hsptl_rspns
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND a.string35 IS NOT NULL
	AND e.srvy_id = 24
	AND CAST(b.tslog AS TIMESTAMP) >= '2023-10-23 00:00:00'
--7/29 Hitansu: no data, tested fine till here
UNION ALL

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	a.string37 AS rspns_txt,
	CURRENT_TIMESTAMP AS dw_trans_ts,
    CAST(SUBSTRING(CAST(b.tslog AS VARCHAR), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
    'I' AS row_stat_cd,
    'ADBE' AS appl_src_cd,
    max_load_id + 1 AS load_id
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string37'
LEFT JOIN  mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN
(
	SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
	FROM mktg_ops_vws.srvy_hsptl_respondents 
	WHERE appl_src_cd = 'ADBE'
	QUALIFY Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) = 1 
) g (respondent_id, sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id, srcsys_trans_ts)
	ON Coalesce(a.string46, 'NULL') = Coalesce(g.respondent_nm, 'NULL') 
		AND Coalesce(a.string45, 'NULL') = Coalesce(g.respondent_email, 'NULL') 
		AND Coalesce(a.string44, 'NULL') = Coalesce(g.respondent_role, 'NULL') 
		AND Coalesce(a.string34, 'NULL') = Coalesce(g.hospital_id, 'NULL')
		AND Coalesce(a.string48, 'NULL') = Coalesce(g.sf_contact_id, 'NULL')LEFT JOIN 
(
	SELECT Max(load_id)
	FROM mktg_ops_vws.srvy_hsptl_rspns
) h (max_load_id) ON 1=1
WHERE 
	lc.active_ind = 1
	AND f.question_id IS NOT NULL 	
	AND a.string37 IS NOT NULL
	AND e.srvy_id = 24
	AND CAST(b.tslog AS TIMESTAMP) >= '2023-10-23 00:00:00'
--7/29 Hitansu: no data, tested fine till here

UNION ALL

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	a.string43 AS rspns_txt,

	CURRENT_TIMESTAMP AS dw_trans_ts,
    CAST(SUBSTRING(CAST(b.tslog AS VARCHAR), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
    'I' AS row_stat_cd,
    'ADBE' AS appl_src_cd,
    max_load_id + 1 AS load_id
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string43'
LEFT JOIN  mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN
(
	SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
	FROM mktg_ops_vws.srvy_hsptl_respondents 
	WHERE appl_src_cd = 'ADBE'
	QUALIFY Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) = 1 
) g (respondent_id, sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id, srcsys_trans_ts)
	ON Coalesce(a.string46, 'NULL') = Coalesce(g.respondent_nm, 'NULL') 
		AND Coalesce(a.string45, 'NULL') = Coalesce(g.respondent_email, 'NULL') 
		AND Coalesce(a.string44, 'NULL') = Coalesce(g.respondent_role, 'NULL') 
		AND Coalesce(a.string34, 'NULL') = Coalesce(g.hospital_id, 'NULL')
		AND Coalesce(a.string48, 'NULL') = Coalesce(g.sf_contact_id, 'NULL')LEFT JOIN 
(
	SELECT Max(load_id)
	FROM mktg_ops_vws.srvy_hsptl_rspns
) h (max_load_id) ON 1=1
WHERE 
	lc.active_ind = 1
	AND f.question_id IS NOT NULL 	
	AND a.string43 IS NOT NULL
	AND e.srvy_id = 24
	AND CAST(b.tslog AS TIMESTAMP) >= '2023-10-23 00:00:00'
--7/29 Hitansu: no data, tested fine till here
	
UNION ALL

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	a.string47 AS rspns_txt,
	CURRENT_TIMESTAMP AS dw_trans_ts,
    CAST(SUBSTRING(CAST(b.tslog AS VARCHAR), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
    'I' AS row_stat_cd,
    'ADBE' AS appl_src_cd,
    max_load_id + 1 AS load_id
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string47'
LEFT JOIN  mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN
(
	SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
	FROM mktg_ops_vws.srvy_hsptl_respondents 
	WHERE appl_src_cd = 'ADBE'
	QUALIFY Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) = 1 
) g (respondent_id, sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id, srcsys_trans_ts)
	ON Coalesce(a.string46, 'NULL') = Coalesce(g.respondent_nm, 'NULL') 
		AND Coalesce(a.string45, 'NULL') = Coalesce(g.respondent_email, 'NULL') 
		AND Coalesce(a.string44, 'NULL') = Coalesce(g.respondent_role, 'NULL') 
		AND Coalesce(a.string34, 'NULL') = Coalesce(g.hospital_id, 'NULL')
		AND Coalesce(a.string48, 'NULL') = Coalesce(g.sf_contact_id, 'NULL')
LEFT JOIN 
(
	SELECT Max(load_id)
	FROM mktg_ops_vws.srvy_hsptl_rspns
) h (max_load_id) ON 1=1
WHERE 
	lc.active_ind = 1
	AND f.question_id IS NOT NULL 	
	AND a.string47 IS NOT NULL
	AND e.srvy_id = 24
	AND CAST(b.tslog AS TIMESTAMP) >= '2023-10-23 00:00:00'
	--7/29 Hitansu: no data, tested fine till here
UNION ALL

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
		CASE
        WHEN a.mdata LIKE '%Please_share_how_we_could_do_better_for_you%' THEN
            REGEXP_SUBSTR(
                TRIM(a.mdata),
                '<Please_share_how_we_could_do_better_for_you>([^<]*)</Please_share_how_we_could_do_better_for_you>',
                1,   -- Start search from the first character
                1,   -- Return the first occurrence of the match
                'e'  -- Use extended regular expressions
            )
        ELSE null
       END AS rspns_txt,
	CURRENT_TIMESTAMP AS dw_trans_ts,
    CAST(SUBSTRING(CAST(b.tslog AS VARCHAR), 1, 19) AS TIMESTAMP) AS srcsys_trans_ts,
    'I' AS row_stat_cd,
    'ADBE' AS appl_src_cd,
    max_load_id + 1 AS load_id
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.adobe_path_var = 'Please_share_how_we_could_do_better_for_you' AND f.src_attrbt_nm = 'mdata'
LEFT JOIN  mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN
(
	SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
	FROM mktg_ops_vws.srvy_hsptl_respondents 
	WHERE appl_src_cd = 'ADBE'
	QUALIFY Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) = 1 
) g (respondent_id, sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id, srcsys_trans_ts)
	ON Coalesce(a.string46, 'NULL') = Coalesce(g.respondent_nm, 'NULL') 
		AND Coalesce(a.string45, 'NULL') = Coalesce(g.respondent_email, 'NULL') 
		AND Coalesce(a.string44, 'NULL') = Coalesce(g.respondent_role, 'NULL') 
		AND Coalesce(a.string34, 'NULL') = Coalesce(g.hospital_id, 'NULL')
		AND Coalesce(a.string48, 'NULL') = Coalesce(g.sf_contact_id, 'NULL')LEFT JOIN 
(
	SELECT Max(load_id)
	FROM mktg_ops_vws.srvy_hsptl_rspns
) h (max_load_id) ON 1=1
WHERE
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND 	
			CASE
        WHEN a.mdata LIKE '%Please_share_how_we_could_do_better_for_you%' THEN
            REGEXP_SUBSTR(
                TRIM(a.mdata),
                '<Please_share_how_we_could_do_better_for_you>([^<]*)</Please_share_how_we_could_do_better_for_you>',
                1,   -- Start search from the first character
                1,   -- Return the first occurrence of the match
                'e'  -- Use extended regular expressions
            )
        ELSE null
       END IS NOT NULL
	AND CAST(b.tslog AS TIMESTAMP) >= '2023-10-23 00:00:00'
;
--ld_srvy_hsptl_rspns_txt

	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.srvy_hsptl_rspns_txt) as integer)
        WHERE proc_name = 'ld_srvy_hsptl_rspns_txt' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_srvy_hsptl_rspns_txt', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;


$$
