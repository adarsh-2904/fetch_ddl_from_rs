CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_hsptl_rspns()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Andrien
Created date: 10/18/2023
Purpose: The macro is scheduled to run nightly through a BTEQ script on our Informatica ETL server.  The macro reads the flattened hospital satisfaction 
survey response data and loads it into an normalized response table.  This table is accessed by a view and is the source for our PowerBI survey reporting model.

Modified By:  Michael Andrien
Modified Date: 11/01/2023
Purpose:	Added the partition logic to the respondent table join to avoid adding duplicate response rows to the table.  The respondent table has duplicate rows across
the historical and Adobe source records.

Modified By:  Michael Andrien
Modified Date: 06/06/2024
Purpose:  Updated the macro to leverage the svry_hsptl_load_cntl table, which was created to specify the active survey id.  The DELETE statement was updated to only delete rows associated with the active 
survey id.  Each UNIONed SELECT includes a join to the load control table to limit the response inserts to the current, active survey id.  Added new inserts to support the new questions added to the
redesigned FY24 Summer survey.

Modified By:  Michael Andrien
Modified Date: 10/31/2024
Purpose:  Added new UNION ALL SELECT statement to include the new data field mappings for the FY25 Fall survey.

Modified By:  Michael Andrien
Modified Date: 11/01/2024
Purpose: Removed duplicate insert blocks from the macroc

Modified By:  Michael Andrien
Modified Date: 11/05/2024
Purpose:	Added the following condition in the WHERE clause of each insert to exlude test records.
	'AND Cast(b.tslog AS DATE) >= lc.active_start_dt;'

Modified By:  Michael Andrien
Modified Date: 11/07/2024
Purpose:Updated the join logic for the srvy_dim_values join for questions 56-62 to reference the new value category group 'CTOSR' - 
'Compared to Other Suppier Rating'.  Included the CASE logic below to use the '6-Not Applicable' ER rating if the input value = '6' otherwise use 'CTOSR' for the group.
	CASE WHEN a.string39= '6' THEN 'ER' ELSE 'CTOSR' END

Modified By:  Michael Andrien
Modified Date: 11/21/2024
Purpose: Added insert statements for string49, string66 and string53.  Corrected to question value scale for string47 from CTOST to ER.

Modified By:  Michael Andrien
Modified Date: 11/22/2024
Purpose: Added insert statements for string74 and added conditional logic to the string questions with the CTOSR scale to use the ER scale for older versions of the srvy.

Modified By:  Michael Andrien
Modified Date: 05/30/2025
Purpose: Added the 3 new questions below for the FY25 Spring/Summer survey
    Availability of IRL Consultation - string76
    Availability of HLA testing services - string2
    Courtesy of Reference Lab - string29

Modified By:  Michael Andrien
Modified Date: 06/09/2025
Purpose: Remove duplicate inserts for string2 and string29

Modified By:  Michael Andrien
Modified Date: 10/17/2025
Purpose:  Add response logic for questions 103-113 for the FY26 Fall survey.  Also added a second entry for question 10 referencing string77.
*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_hsptl_rspns', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		


DELETE From mktg_ops_tbls.srvy_hsptl_rspns 
WHERE 
	appl_src_cd = 'ADBE'
	AND srvy_id IN (SELECT srvy_id FROM mktg_ops_tbls.srvy_hsptl_load_cntl WHERE active_ind = 1);



INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end, /*respondent_id*/
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp, /*dw_trans_ts*/
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP), /*srcsys_trans_ts*/
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string0 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string0'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1

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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;



INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string11 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string11'
LEFT JOIN  mktg_ops_tbls.srvy_hsptl_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN
(SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

		

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string10 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string10'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;



INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string7 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string7'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string6 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string6'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string4 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string4'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

		
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string3 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string3'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;



INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT join mktg_ops_vws.srvy_hsptl_values d ON a.string63 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string63'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string14 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string14'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;



INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string15 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string15'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string16 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string16'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string13 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string13'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string16 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string16'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


		
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string32 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string32'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;



INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string24 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string24'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;



INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string23 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string23'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string22 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string22'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;



INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string17 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string17'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;





INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string20 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string20'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string15 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string15'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string19 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string19'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string31 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string31'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string30 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string30'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string28 = d.value_num AND d.value_catgry_cd = CASE WHEN a.string28 = '6' OR wa.iwebappid <> 228572399 THEN 'ER' ELSE 'CTOSR' END
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string28'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string27 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string27'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
    
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
/*Courtesy of Reference Lab - string29 */
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string29 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string29'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string26 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string26'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string18 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string18'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string33 = d.value_num AND d.value_catgry_cd = 'YN'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string33'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string5 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string5'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string1 = d.value_num AND d.value_catgry_cd = 'LR10'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string1'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string9 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string9'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string12 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string12'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string21 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string21'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.boolean3 = d.value_num AND d.value_catgry_cd = 'YN'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean3'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.boolean2 = d.value_num AND d.value_catgry_cd = 'YN'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean2'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.boolean1 = d.value_num AND d.value_catgry_cd = 'YN'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean1'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.boolean0 = d.value_num AND d.value_catgry_cd = 'YN'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean0'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string36 = d.value_num AND d.value_catgry_cd = 'CAH'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string36'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns 

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON collate(a.string37::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'OSR'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns 

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON collate(a.string37::text,'CASE_INSENSITIVE') = collate(d.value_dsc::text,'CASE_INSENSITIVE') AND d.value_catgry_cd = 'OSR'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string38'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns 

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string42 = d.value_num AND d.value_catgry_cd = CASE WHEN a.string42 = '6' OR wa.iwebappid <> 228572399 THEN 'ER' ELSE 'CTOSR' END
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string42'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string43 = d.value_num AND d.value_catgry_cd = CASE WHEN a.string43 = '6' OR wa.iwebappid <> 228572399 THEN 'ER' ELSE 'CTOSR' END
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string41 = d.value_num AND d.value_catgry_cd = CASE WHEN a.string41 = '6' OR wa.iwebappid <> 228572399 THEN 'ER' ELSE 'CTOSR' END
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string41'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string40 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string40'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
	
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string39 = d.value_num AND d.value_catgry_cd = CASE WHEN a.string39= '6' OR wa.iwebappid <> 228572399 THEN 'ER' ELSE 'CTOSR' END
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string39'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
		
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string8 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string8'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string15 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string15'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string16 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string16'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1 
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string16 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string16'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string47 = d.value_num AND d.value_catgry_cd = 'ER' 
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;


INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string64 = d.value_num AND d.value_catgry_cd = 'ER' 
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string64'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string65 = d.value_num AND d.value_catgry_cd = CASE WHEN a.string65 = '6' OR wa.iwebappid <> 228572399 THEN 'ER' ELSE 'CTOSR' END
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string65'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
SELECT
    a.iwebapplogid,
    CASE WHEN g.respondent_id IS NULL THEN 0
        ELSE g.respondent_id
    end AS respondent_id,
    e.srvy_id, /* Survey id value */
    f.question_id,
    Coalesce(d.value_id,0), /* Response value key (id) */
    Current_Timestamp AS dw_trans_ts,
    Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
    'I', /*row_stat_cd*/
    'ADBE', /*appl_src_cd*/
    max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string66 = d.value_num AND d.value_catgry_cd = CASE WHEN a.string66 = '6' OR wa.iwebappid <> 228572399 THEN 'ER' ELSE 'CTOSR' END
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string66'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--  wa.sNature = 'survey'
--  AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
    lc.active_ind = 1
    AND f.question_id IS NOT NULL
    AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string49 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string49'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string50 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string50'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string51 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string51'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string52 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string52'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string53 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string53'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string54 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string54'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string55 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string55'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string56 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string56'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string57 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string57'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1 
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string58 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string58'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
/* Availability of IRL Consultation - string76 */
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string76 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string76'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
    
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
/* Availability of HLA testing services - string2 */
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string2 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string2'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
/* Availability of HLA testing services - string77 for srvy_id 33 */
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp(0) AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string77 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string77'
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
    from(
			SELECT 
			respondent_id, 
			sf_contact_id, 
			respondent_nm, 
			respondent_email, 
			respondent_role, 
			hospital_id,
			srcsys_trans_ts,
			Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		) as subqry
	where subqry.rn=1
	
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string59 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string59'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string60 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string60'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id)"
" */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string61 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string61'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string62 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string62'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string71 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string71'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string72 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string72'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string73 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string73'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1 
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns

SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	Coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string74 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string74'
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
		from(
		
				SELECT 
		respondent_id, 
		sf_contact_id, 
		respondent_nm, 
		respondent_email, 
		respondent_role, 
		hospital_id,
		srcsys_trans_ts,
		Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
		FROM mktg_ops_vws.srvy_hsptl_respondents 
		WHERE appl_src_cd = 'ADBE'
		
		) as subqry
		 
		where subqry.rn=1
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
--	wa.sNature = 'survey'
--	AND wa.iWebAppId = 221027477 /* FY24 Hospital Satisfaction Survey (AF Edits) */
	lc.active_ind = 1
	AND f.question_id IS NOT NULL
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
/*Question 103 */

INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp(0) AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string78 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string78'
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
   from
	    (
			SELECT 
			respondent_id, 
			sf_contact_id, 
			respondent_nm, 
			respondent_email, 
			respondent_role, 
			hospital_id,
			srcsys_trans_ts,
			Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
			FROM mktg_ops_vws.srvy_hsptl_respondents 
			WHERE appl_src_cd = 'ADBE'
		) as subqry
		where subqry.rn = 1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;

/*Question 104 */
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp(0) AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string79 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string79'
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
   from
	    (
			SELECT 
			respondent_id, 
			sf_contact_id, 
			respondent_nm, 
			respondent_email, 
			respondent_role, 
			hospital_id,
			srcsys_trans_ts,
			Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
			FROM mktg_ops_vws.srvy_hsptl_respondents 
			WHERE appl_src_cd = 'ADBE'
		) as subqry
		where subqry.rn = 1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
    
/*Question 111 */
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp(0) AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP(0)) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string75 = d.value_num AND d.value_catgry_cd = 'BTWT'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string75'
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
   from
	    (
			SELECT 
			respondent_id, 
			sf_contact_id, 
			respondent_nm, 
			respondent_email, 
			respondent_role, 
			hospital_id,
			srcsys_trans_ts,
			Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
			FROM mktg_ops_vws.srvy_hsptl_respondents 
			WHERE appl_src_cd = 'ADBE'
		) as subqry
		where subqry.rn = 1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
    
/*Question 112 */
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp(0) AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP(0)) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string80 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string80'
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
   from
	    (
			SELECT 
			respondent_id, 
			sf_contact_id, 
			respondent_nm, 
			respondent_email, 
			respondent_role, 
			hospital_id,
			srcsys_trans_ts,
			Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
			FROM mktg_ops_vws.srvy_hsptl_respondents 
			WHERE appl_src_cd = 'ADBE'
		) as subqry
		where subqry.rn = 1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;
    
/*Question 113 */
INSERT INTO mktg_ops_tbls.srvy_hsptl_rspns
SELECT
	a.iwebapplogid,
	CASE WHEN g.respondent_id IS NULL THEN 0
		ELSE g.respondent_id
	end AS respondent_id,
	e.srvy_id, /* Survey id value */
	f.question_id,
	coalesce(d.value_id,0), /* Response value key (id) */
	Current_Timestamp(0) AS dw_trans_ts,
	Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, /* Response value key (id) */
	'I', /*row_stat_cd*/
	'ADBE', /*appl_src_cd*/
	max_load_id + 1 /*load_id */
FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata_1 a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_hsptl_values d ON a.string81 = d.value_num AND d.value_catgry_cd = 'ER'
LEFT JOIN mktg_ops_vws.srvy_hsptl_survey e ON wa.iWebAppId = e.iWebAppId 
LEFT JOIN mktg_ops_vws.srvy_hsptl_questn_2_srvy_xref f ON wa.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string81'
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
   from
	    (
			SELECT 
			respondent_id, 
			sf_contact_id, 
			respondent_nm, 
			respondent_email, 
			respondent_role, 
			hospital_id,
			srcsys_trans_ts,
			Row_Number() Over ( PARTITION BY sf_contact_id, respondent_nm, respondent_email, respondent_role, hospital_id ORDER BY srcsys_trans_ts) as rn
			FROM mktg_ops_vws.srvy_hsptl_respondents 
			WHERE appl_src_cd = 'ADBE'
		) as subqry
		where subqry.rn = 1
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
	AND Cast(b.tslog AS DATE) >= lc.active_start_dt;




		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.srvy_hsptl_rspns) as INTEGER)
			WHERE proc_name = 'ld_srvy_hsptl_rspns' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_srvy_hsptl_rspns', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
