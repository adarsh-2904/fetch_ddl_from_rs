CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_anvrsry_vlntr_rspns_norm()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Hall
Created date: 01/10/2025
Purpose: The macro is scheduled to run nightly through a BTEQ script on our Informatica ETL server.  
The macro reads the flattened Volunteer Anniversary Satisfaction survey response data and loads a normalized response table.  
This table is accessed by a view and is the source for our PowerBI survey reporting model.

Modified By: Michael Hall
Modified Date: 03/02/2025
Purpose: Fixed the all the question INSERT statements to align properly with the cross-reference spreadsheet.
*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_anvrsry_vlntr_rspns_norm', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
truncate table mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg;
drop table if exists srvy_anvrsry_vlntr_rspns_norm_tmp;
create temp table srvy_anvrsry_vlntr_rspns_norm_tmp as
SELECT 
	a.iwebapplogid,
	COALESCE(x.new_cnst_mstr_id,nr.bicnst_mstr_id) AS cnst_mstr_id,
	nr.bicnst_mstr_id,	
	e.srvy_id AS srvy_id,  
	CAST(SUBSTRING(CAST(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	max_load_id + 1 AS load_id,
	a.string10,
	wa.iWebAppId,
	a.string17,
	a.string1,
	a.string0,
	a.string18,
	a.string11,
	a.string2,
	a.string7,
	a.string3,
	a.string12,
	a.string9,
	a.string32,
	a.string15,
	a.string13,
	a.string22,
	a.string21,
	a.string20,
	a.string26,
	a.string25,
	a.string24,
	a.string23,
	a.string29,
	a.string28,
	a.string27,
	a.string31,
	a.string30,
	a.string33,
	a.string16,
	a.string14,
	a.string8,
	a.string6,
	a.string5,
	a.string4,
	a.boolean16,
	a.boolean15,
	a.boolean14,
	a.boolean13,
	a.boolean17,
	ROW_NUMBER() OVER (PARTITION BY c.fiscal_yr, nr.bicnst_mstr_id ORDER BY nr.bicnst_mstr_id, c.fiscal_yr, b.tslog ASC) as rn
	
	FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient nr ON b.iRecipientId = nr.iRecipientId
LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_survey e ON wa.iWebAppId = e.iWebAppId
LEFT JOIN  mktg_ops_tbls.srvy_anvrsry_vlntr_load_cntl lc ON e.srvy_id = lc.srvy_id
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map x ON nr.bicnst_mstr_id=x.cnst_mstr_id  /* Added this join to get the new merged cnst_mstr_ids */
LEFT JOIN eda.dw_common_vws.dim_calendar c ON (CAST(b.tslog AS DATE) = c.calendar_dt) /* join to calendar dimension to get FY for de-duping purposes. Each respondent should have only one entry per FY */	
--LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr svp ON COALESCE(x.new_cnst_mstr_id, nr.bicnst_mstr_id)   = CAST(svp.cnst_mstr_id AS BIGINT)
LEFT JOIN
(
	SELECT MAX(load_id)
	FROM mktg_ops_vws.srvy_anvrsy_vlntr_rspns
) h (max_load_id) ON 1=1
where
	 lc.active_ind = 1
	 and CAST(b.tslog AS DATE) >= lc.active_start_dt;

	
INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string10 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string10'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;

commit;	 
	 
INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string17 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string17'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;
	 
commit;	
	 
INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string1 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string1'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;
commit;		 

	 
INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string0 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string0'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;
	 
commit;		 

	 
INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string18 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string18'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 

commit;		 

	 
INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string11 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'NPS'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string11'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 

commit;		 

	 
INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string2 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string2'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 

commit;	
	 
INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string7 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string7'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 

commit;	


INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string3 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string3'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 

commit;	

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string12 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string12'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 

commit;	

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string9 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string9'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 

commit;	

	 
	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string32 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string32'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	

commit;	

	 
	 	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string15 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string15'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	

commit;	

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string13 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string13'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
	 
commit;	

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string22 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string22'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 

	 
commit;	

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string21 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string21'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
	 
commit;		 

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string20 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string20'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 

	 
commit;	

	 
	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string26 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string26'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 
	 
commit;		


	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string25 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string25'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	

commit;	

	 
	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string24 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string24'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
	 
commit;		 

	 

	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string23 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string23'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
commit;		 


	
	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string29 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string29'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1; 
	 
commit;		 

	 
	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string28 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string28'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1; 

commit;		 

	 
	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string27 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string27'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1; 
commit;		 

	 
	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string31 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string31'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
	 
commit;		 


	 	 
	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string30 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string30'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;
commit;		

	 
	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.string33 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'ER'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string33'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
	 
commit;		 

	 
	 	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON cast(savrn.string16 as SMALLINT) = d.value_dsc AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string16'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 

commit;		 

	 

	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON cast(savrn.string14 as SMALLINT) = d.value_dsc AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string14'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;
commit;		 


	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON cast(savrn.string8 as SMALLINT) = d.value_dsc AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string8'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;
commit;		 

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON cast(savrn.string6 as SMALLINT) = d.value_dsc AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string6'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
	 
commit;		 

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON cast(savrn.string5 as smallint) = d.value_dsc AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string5'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
	
commit;	 

	 

	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON cast(savrn.string4 as SMALLINT) = d.value_dsc AND d.value_catgry_cd = 'AD'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'string4'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
	 
commit;	

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.boolean16 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'YN'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean16'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
commit;		 	

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.boolean15 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'YN'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean15'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 
	 
commit;		 

	 
	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.boolean14 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'YN'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean14'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;		 
	 
commit;		 

	INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.boolean13 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'YN'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean13'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	 
commit;		 

	 
		INSERT INTO mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg
SELECT 
	iwebapplogid AS rspns_id,
	cnst_mstr_id,
	bicnst_mstr_id AS orig_cnst_mstr_id,	
	savrn.srvy_id AS srvy_id, 
	f.question_id AS question_id,
	coalesce(d.value_id) AS value_id, 
	savrn.srcsys_trans_ts, 
	CURRENT_TIMESTAMP AS dw_trans_ts, 
	'I' AS row_stat_cd, 
	'ADBE' AS apple_src_cd, 
	savrn.load_id 
	from srvy_anvrsry_vlntr_rspns_norm_tmp as savrn
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_values d ON CAST(savrn.boolean17 AS SMALLINT) = d.value_num AND d.value_catgry_cd = 'YN'
	LEFT JOIN mktg_ops_vws.srvy_anvrsry_vlntr_questn_2_srvy_xref f ON savrn.iwebappid = f.iwebappid AND f.src_attrbt_nm = 'boolean17'
	WHERE  
	 
	 f.question_id IS NOT NULL
	AND savrn.rn = 1;	  
commit;		 

	 
DELETE From mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_norm
WHERE 
	srvy_id IN (SELECT srvy_id FROM mktg_ops_tbls.srvy_anvrsry_vlntr_load_cntl WHERE active_ind = 1);

INSERT INTO mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_norm select * from mktg_stage_tbls.srvy_anvrsry_vlntr_rspns_norm_stg;


		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.srvy_anvrsry_vlntr_rspns_norm) as INTEGER)
			WHERE proc_name = 'ld_srvy_anvrsry_vlntr_rspns_norm' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_srvy_anvrsry_vlntr_rspns_norm', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
