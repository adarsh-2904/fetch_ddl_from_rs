CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dim_recipient()
 LANGUAGE plpgsql
AS $$

/* Modified By: 	Hitansu Sahoo
Modified Date: 	11/24/2025
Purpose: Created the stored proc from Informatica mapping using Merge functionality. */

/* -------- INSTRUCTIONS	from Majeed:  -----------------------

 The column adb.iRecipientId is looked up in the existing dim_recipient.nk_recipient_id(same as adb.iRecipientId) column. 

If it exists, the record doesn't generate a new recipient_key--surrogate key. use the old one.
If it doesn't exist, it generates a new max+1 value for the recipient_key column. 
-- dim_recipient.lineaddr1-saddress2		use these info for mapping
-- dim_recipient.lineaddr2-saddress3
SELECT adb.iRecipientId, adb.sAddress1, adb.sAddress3, adb.sCity, adb.sEmail, adb.sFirstName, adb.sLastName, adb.sMiddleName, adb.sStateCode, adb.sZipCode, adb.tsLastModified, adb.biCnst_mstr_id
FROM
 mktg_ops_tbls.adb_NmsRecipient adb
WHERE adb.dw_trans_ts >  'INCREMENT_TS' */

DECLARE
    v_increment_ts TIMESTAMP;
    v_appl_src_cd VARCHAR(4);
    v_dw_load_id INT;
    v_next_extract_ts TIMESTAMP;
    v_start_time TIMESTAMP := CURRENT_TIMESTAMP;
	v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
    v_inserted_count INT := 0;
	v_updated_count INT := 0;
	v_recipient_id bigint;
	v_existing_key INT;
BEGIN
    
   -- Step 1: Fetch parameters from control table
    SELECT next_begin_dt, appl_src_cd, load_id + 1
    INTO v_increment_ts, v_appl_src_cd, v_dw_load_id
    FROM etl_config.load_cntl_tbl
    WHERE process_nm = 'ld_dim_recipient'
      AND LOWER(table_nm) = 'dim_recipient';

    -- Step 2a: Set default values if null
    IF v_appl_src_cd IS NULL THEN
        v_appl_src_cd := 'NMS';
    END IF;
    IF v_dw_load_id IS NULL THEN
        v_dw_load_id := 1001;
    END IF;
	IF v_increment_ts IS NULL THEN
        v_increment_ts := '1900-01-01 00:00:52.698 +0530'; 
    END IF;
	
	 --	Initialize recipient_key with current max value
	 
    SELECT COALESCE(MAX(recipient_key), 0) INTO v_recipient_id
    FROM mktg_ops_tbls.dim_recipient;
	
	-- Step 2b: insert audit log InProgress status 
	
	v_start_time := CURRENT_TIMESTAMP;
 	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dim_recipient', 'Stored Procedure', 'Inprogress', v_start_time);
	
	drop table if exists mktg_stage_tbls.temp_dim_recipient;  	--temp tables have issues handling millions of records
																--useful for debug as well
	create table mktg_stage_tbls.temp_dim_recipient as
	with temp_source as (
	SELECT 
        adb.iRecipientId AS nk_recipient_id,
        COALESCE(mktg.recipient_key, ROW_NUMBER() OVER (ORDER BY adb.dw_trans_ts) + v_recipient_id) AS recipient_key,
        adb.biCnst_mstr_id,
        adb.sEmail,
        adb.sFirstName,
        adb.sMiddleName,
        adb.sLastName,
        adb.sAddress1 AS recipient_line_1_addr,
        adb.sAddress3 AS recipient_line_2_addr,
        adb.sCity as recipient_city_nm,
        adb.sStateCode as recipient_st_cd,
        LEFT(TRIM(adb.sZipCode), 5) AS recipient_zip_5_cd,
        RIGHT(TRIM(adb.sZipCode), 4) AS recipient_zip_4_cd,
        adb.tsLastModified AS srcsys_trans_ts,
        CURRENT_TIMESTAMP AS dw_trans_ts,
        CASE WHEN mktg.nk_recipient_id IS NULL THEN 'I' ELSE 'U' END AS row_stat_cd,
        'NMS' AS appl_src_cd,
        v_dw_load_id AS load_id
    FROM (select * from mktg_ops_tbls.adb_NmsRecipient /* limit 100 */) adb
    LEFT JOIN mktg_ops_tbls.dim_recipient mktg 
        ON mktg.nk_recipient_id = adb.iRecipientId
    WHERE adb.dw_trans_ts > v_increment_ts
    
	)
	select * from temp_source;

 MERGE INTO mktg_ops_tbls.dim_recipient --target table
USING 
mktg_stage_tbls.temp_dim_recipient source

ON mktg_ops_tbls.dim_recipient.nk_recipient_id = source.nk_recipient_id

WHEN MATCHED THEN UPDATE SET
    --recipient_key = source.recipient_key,
    cnst_mstr_id = source.biCnst_mstr_id,
    email_addr = source.sEmail,
    recipient_first_nm = source.sFirstName,
    recipient_midl_nm = source.sMiddleName,
    recipient_last_nm = source.sLastName,
    recipient_line_1_addr = source.recipient_line_1_addr,
    recipient_line_2_addr = source.recipient_line_2_addr,
    recipient_city_nm = source.recipient_city_nm,
    recipient_st_cd = source.recipient_st_cd,
    recipient_zip_5_cd = REGEXP_REPLACE(source.recipient_zip_5_cd, '[^0-9]', ''),  --handle non ascii chars
    recipient_zip_4_cd = source.recipient_zip_4_cd,
    srcsys_trans_ts = source.srcsys_trans_ts,
    dw_trans_ts = CURRENT_TIMESTAMP,
    row_stat_cd = 'U',
    appl_src_cd = 'NMS',
    load_id = v_dw_load_id

WHEN NOT MATCHED THEN INSERT (
    recipient_key,
    nk_recipient_id,
    cnst_mstr_id,
    email_addr,
    recipient_first_nm,
    recipient_midl_nm,
    recipient_last_nm,
    recipient_line_1_addr,
    recipient_line_2_addr,
    recipient_city_nm,
    recipient_st_cd,
    recipient_zip_5_cd,
    recipient_zip_4_cd,
    srcsys_trans_ts,
    dw_trans_ts,
    row_stat_cd,
    appl_src_cd,
    load_id
)
VALUES (
    source.recipient_key,
    source.nk_recipient_id,
    source.biCnst_mstr_id,
    source.sEmail,
    source.sFirstName,
    source.sMiddleName,
    source.sLastName,
    source.recipient_line_1_addr,
    source.recipient_line_2_addr,
    source.recipient_city_nm,
    source.recipient_st_cd,
    REGEXP_REPLACE(source.recipient_zip_5_cd, '[^0-9]', ''),
    source.recipient_zip_4_cd,
    source.srcsys_trans_ts,
	CURRENT_TIMESTAMP,
     'I',  --row_stat_cd
    'NMS',	--appl_src_cd
    v_dw_load_id--load_id 
);
 
GET DIAGNOSTICS v_updated_count = ROW_COUNT;	

--	v_recipient_id := v_recipient_id + 1;

 -- Step 6: Get latest timestamp for next run and Update load control	
    SELECT coalesce(MAX(dw_trans_ts),'1900-01-01 00:00:52.698 +0530')
    INTO v_next_extract_ts
    FROM mods_bi.mktg_ops_tbls.dim_recipient;
	
	

    	
    CALL etl_config.sp_upsert_load_control(
        'ld_dim_recipient', 'dim_recipient',--this will be updated in every stored proc
        v_next_extract_ts, v_appl_src_cd, v_dw_load_id
		);

    
	
	-- Step 7: Audit update	
			v_end_time := GETDATE();
            v_ok_message := '';
			
		UPDATE mods_bi.etl_config.audit_log
       	SET 
           status = 'Complete',
           end_time = v_end_time,
           TaskMessage = v_ok_message,
           recs_processed = v_updated_count
       WHERE 
           proc_name = 'ld_dim_recipient' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;
		   
	-- Step 7: Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_dim_recipient', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500)); 

END;

$$
