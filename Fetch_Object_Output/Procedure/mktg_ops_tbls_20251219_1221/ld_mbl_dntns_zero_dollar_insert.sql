CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_mbl_dntns_zero_dollar_insert()
 LANGUAGE plpgsql
AS $$	
/*
Created By:     Michael Andrien
Create Date:    01/30/2025
Purpose:        This macro was insert to zero dollar mobile donation transactions into the mgive_tbls.mbl_dntns table.  These
transaction are inserted into the table daily with the appl_src_cd = 'ADBE'.  The CDI team runs a daily process to read the mgive_tbls.mbl_dntns
table to identify mobile numbers to be passed to the nightly Lexis Nexis reverse phone append process.  The process had been disabled when the Red Cross
terminated our contract with Mobile Commons.  They process has been reenable to pull the zero dollar ADBE records.  When the reverse phone append process 
successfully matches the phone number to a known identity, Lexis returns a national id (dsp_id) and name & address details.  These locator details 
are stored in the CDI locator tables with the appl_src_cd = 'MDON'

*/	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_mbl_dntns_zero_dollar_insert', 'Stored Procedure', 'Inprogress', v_start_time);


begin

INSERT INTO mgive_tbls.mbl_dntns (
    mbl_dntns_key,
    cnst_phn_num,
    msg_ts,
    campgn_id,
    keyword,
    shortcode,
    dntn_amt,
    dntn_stat,
    dntn_stat_dsc,
    dntn_stat_ind,
    dw_srcsys_trans_ts,
    row_stat_cd,
    appl_src_cd,
    load_id
)
SELECT
   CAST(ROW_NUMBER() OVER (ORDER BY a.iinsmsid ASC) + COALESCE(b.max_mbl_dntns_key, 0) AS BIGINT) AS mbl_dntns_key,
   CAST(a.sorigin AS VARCHAR(20)) AS cnst_phn_num,
   CAST(a.tsmessage AS TIMESTAMP) AS msg_ts,
   CAST(a.iinsmsid AS VARCHAR(20)) AS campgn_id,
   CAST(a.smessage AS VARCHAR(40)) AS keyword,
   CAST('90999' AS VARCHAR(10)) AS shortcode,
   CAST(0 AS DECIMAL(13,2)) AS dntn_amt,
   CASE 
       WHEN TRIM(UPPER(REGEXP_REPLACE(a.smessage, '[^0-9A-Za-z]', ''))) IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END') THEN 'opt-out'
       WHEN REGEXP_REPLACE(TRIM(UPPER(REPLACE(a.smessage, ' ', ''))), '[^0-9A-Za-z]', '') IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END') THEN 'opt-out'
       ELSE 'accepted'
   END AS dntn_stat,
   'Zero dollar insert from Adobe for reverse phone append' AS dntn_stat_dsc,
   CASE 
       WHEN TRIM(UPPER(REGEXP_REPLACE(a.smessage, '[^0-9A-Za-z]', ''))) IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END') THEN 0
       WHEN REGEXP_REPLACE(TRIM(UPPER(REPLACE(a.smessage, ' ', ''))), '[^0-9A-Za-z]', '') IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END') THEN 0
       ELSE 1
   END AS dntn_stat_ind,
   CURRENT_TIMESTAMP AS dw_srcsys_trans_ts,
   'I' AS row_stat_cd,
   'ADBE' AS appl_src_cd,
   COALESCE(b.max_load_id, 0) + 1 AS load_id
FROM mktg_ops_vws.bz_adb_nmsinsms a
LEFT JOIN (
    SELECT 
        MAX(mbl_dntns_key) AS max_mbl_dntns_key,
        MAX(load_id) AS max_load_id
    FROM mods_bi.mgive_tbls.mbl_dntns
) b ON 1=1
LEFT JOIN mgive_tbls.mbl_dntns c
  ON a.sorigin::BIGINT = CAST(c.cnst_phn_num AS BIGINT)
WHERE a.sorigin IS NOT NULL
  AND c.cnst_phn_num IS NULL;
	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mgive_tbls.mbl_dntns) as integer)
        WHERE proc_name = 'ld_mbl_dntns_zero_dollar_insert' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_mbl_dntns_zero_dollar_insert', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;


$$
