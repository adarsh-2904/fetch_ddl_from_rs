CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_srvy_new_vlntr_rspns_cmnt_curnt()
 LANGUAGE plpgsql
AS $$
	
	/*
	Created by: Michael Andrien
	Created date: 08/06/2024
	Purpose: The macro is scheduled to run nightly through a BTEQ script on our Informatica ETL server.  The macro reads the flattened new volunteer satisfaction 
	survey response data and loads text response question into a flattened response text table.  This table is accessed by a view and is the source for our PowerBI survey reporting model.
	
	Modified By: Michael Andrien
	Modified Date: 12/18/2024
	Purpose: Changed var6 to varTeamworkWhy
	
	Modified By: Michael Andrien
	Modified Date: 05/12/2025
	Purpose: Fixed the Teamwork comment above.  We missed the leading WHEN condition and have changed
	WHEN a.mdata LIKE '%var6%' to WHEN a.mdata LIKE '%varTeamworkWhy%'

*/
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_srvy_new_vlntr_rspns_cmnt_curnt', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
			DELETE From mktg_ops_tbls.srvy_new_vlntr_rspns_cmnt_curnt
			WHERE 
				iwebappid IN (SELECT iwebappid FROM mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_load_cntl WHERE active_ind = 1);
				
			INSERT INTO mktg_ops_tbls.srvy_new_vlntr_rspns_cmnt_curnt
			select
				wa.iwebappid,
				a.iwebapplogid,
				b.tslog AS respns_ts,
				c.bicnst_mstr_id AS cnst_mstr_id,
				c.bicnst_mstr_id AS orig_cnst_mstr_id,
				NULL AS email,
				wa.slabel,
			    
			    CASE
			        WHEN a.mdata LIKE '%<_2backgroundwhy>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<_2backgroundwhy>(.*?)</_2backgroundwhy>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '<\/?(_2backgroundwhy)>',
			                ''
			            )
			        ELSE NULL
			    END AS why_backgrnd_scr_cmt,
			     CASE
			        WHEN a.mdata LIKE '%<whyrecognizedappreciated>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<whyrecognizedappreciated>(.*?)</whyrecognizedappreciated>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '</?whyrecognizedappreciated>',
			                ''
			            )
			        ELSE NULL
			    END AS why_recgnzd_aprctd_scr_cmt,
			    CASE
			        WHEN a.mdata LIKE '%<whysupportsupervisor>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<whysupportsupervisor>(.*?)</whysupportsupervisor>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '</?whysupportsupervisor>',
			                ''
			            )
			        ELSE NULL
			    END AS why_suprt_suprvsr_scr_cmt,
			    CASE
			        WHEN a.mdata LIKE '%<varTeamworkWhy>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<varTeamworkWhy>(.*?)</varTeamworkWhy>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '</?varTeamworkWhy>',
			                ''
			            )
			        ELSE NULL
			    END AS why_teamwrk_scr_cmt,
			    CASE
			        WHEN a.mdata LIKE '%<var8>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<var8>(.*?)</var8>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '</?var8>',
			                ''
			            )
			        ELSE NULL
			    END AS exprnc_cmt,
			    Current_Timestamp(0), /*dw_trans_ts*/
				Cast(Substring(Cast(b.tslog AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP(0)), /*srcsys_trans_ts*/
				'I', /*row_stat_cd*/
				'ADBE', /*appl_src_cd*/
				max_load_id + 1 /*load_id */
			FROM mktg_ops_vws.bz_adb_nmswebapplogrcpdata a 
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapplogrcp b ON b.iWebAppLogRcpId = a.iWebAppLogId
			LEFT JOIN mktg_ops_vws.bz_adb_nmswebapp wa ON wa.iWebAppId = b.iWebAppId 
			LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON b.iRecipientId = c.iRecipientId
			LEFT JOIN  mktg_ops_tbls.srvy_new_vlntr_rspns_load_cntl lc ON wa.iwebappid = lc.iwebappid
			LEFT JOIN 
			(
				SELECT Max(load_id)
				FROM mktg_ops_vws.srvy_anvrsy_vlntr_rspns_all
			) h (max_load_id) ON 1=1
			WHERE
				lc.active_ind = 1
				and(
				
						CASE
			        WHEN a.mdata LIKE '%<_2backgroundwhy>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<_2backgroundwhy>(.*?)</_2backgroundwhy>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '<\/?(_2backgroundwhy)>',
			                ''
			            )
			        ELSE NULL
			    END is not null
			    
			    or
			    	
			    	CASE
			        WHEN a.mdata LIKE '%<whyrecognizedappreciated>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<whyrecognizedappreciated>(.*?)</whyrecognizedappreciated>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '</?whyrecognizedappreciated>',
			                ''
			            )
			        ELSE NULL
			    END is not null
			    
			    or
			    
			    	CASE
			        WHEN a.mdata LIKE '%<whysupportsupervisor>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<whysupportsupervisor>(.*?)</whysupportsupervisor>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '</?whysupportsupervisor>',
			                ''
			            )
			        ELSE NULL
			    END is not null
			    
			    or
			    
			      CASE
			        WHEN a.mdata LIKE '%<varTeamworkWhy>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<varTeamworkWhy>(.*?)</varTeamworkWhy>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '</?varTeamworkWhy>',
			                ''
			            )
			        ELSE NULL
			    END is not null
			    
			    or
			    
			    	CASE
			        WHEN a.mdata LIKE '%<var8>%' THEN
			            REGEXP_REPLACE(
			                REGEXP_SUBSTR(
			                    a.mdata,
			                    '<var8>(.*?)</var8>',
			                    1,
			                    1,
			                    'p'
			                ),
			                '</?var8>',
			                ''
			            )
			        ELSE NULL
			    END is not null
			    
			);
			






		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.srvy_new_vlntr_rspns_cmnt_curnt) as INTEGER)
			WHERE proc_name = 'ld_srvy_new_vlntr_rspns_cmnt_curnt' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_srvy_new_vlntr_rspns_cmnt_curnt', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
