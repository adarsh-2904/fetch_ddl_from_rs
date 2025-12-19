CREATE OR REPLACE PROCEDURE mktg_ops_tbls.sp_upsert_dim_campgn()
 LANGUAGE plpgsql
AS $$

/*
Created By: 	Adarsh Ram
Created Date:	11/12/2025
Purpose: Creating a stored procedure from Informatica existing code. 

	
*/	
	
DECLARE
    v_max_campgn_key INT;
    v_increment_ts TIMESTAMP;
    v_appl_src_cd VARCHAR(4);
    v_dw_load_id INT;
    v_next_extract_ts TIMESTAMP;
    v_start_time TIMESTAMP := CURRENT_TIMESTAMP;
	v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
    v_inserted_count INT := 0;	

BEGIN
	-- Step 1: Fetch parameters from control table
	    SELECT next_begin_dt, appl_src_cd, load_id + 1
	    INTO v_increment_ts, v_appl_src_cd, v_dw_load_id
	    FROM etl_config.load_cntl_tbl
	    WHERE process_nm = 'sp_upsert_dim_campgn'
	      AND LOWER(table_nm) = 'dim_campgn';

		

	-- Step 2a: Set default values if null
	    IF v_appl_src_cd IS NULL THEN
	        v_appl_src_cd := 'ADBE';
	    END IF;
	    IF v_dw_load_id IS NULL THEN
	        v_dw_load_id := 101;
	    END IF;
		
		IF v_increment_ts IS NULL THEN
			v_increment_ts:= '1990-01-01'::timestamp;
		END IF;

	-- Step 2b: insert audit log InProgress status 
		v_start_time := CURRENT_TIMESTAMP;
		INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
	    VALUES ('sp_upsert_dim_campgn', 'Stored Procedure', 'Inprogress', v_start_time);

	--step 3: select existing record
		SELECT COALESCE(MAX(campgn_key), 0) INTO v_max_campgn_key FROM mktg_ops_tbls.dim_campgn;

		create temp table existingrecord as
		SELECT
	        campgn_key,
	        nk_campgn_id,
	        campgn_cd,
	        campgn_nm,
	        plan_id,
	        plan_nm,
	        lob_plan_id,
	        lob_plan_nm,
	        channel_id,
	        channel_nm,
	        program_id,
	        program_nm,
	        iistriggeredcampaign,
	        tsLastModified,
	        dw_trans_ts,
	        row_stat_cd,
	        appl_src_cd,
	        load_id
		from(
			  SELECT
			        CASE
			            WHEN d.campgn_key IS NULL THEN v_max_campgn_key + ROW_NUMBER() OVER ()
			            ELSE d.campgn_key
			        END AS campgn_key,
			        o.ioperationid AS nk_campgn_id,
			        o.sinternalname AS campgn_cd,
			        o.slabel AS campgn_nm,
			        d1.ifolderid AS plan_id,
			        d1.slabel AS plan_nm,
			        c.ifolderid AS lob_plan_id,
			        c.slabel AS lob_plan_nm,
			        x.ifolderid AS channel_id,
			        x.slabel AS channel_nm,
			        b.ifolderid AS program_id,
			        b.slabel AS program_nm,
			        o.iistriggeredcampaign,
			        o.tsLastModified,
			        CURRENT_TIMESTAMP as dw_trans_ts,
			        CASE WHEN d.campgn_key IS NULL THEN 'I' ELSE 'U' END as row_stat_cd,
			        v_appl_src_cd as appl_src_cd,
			        v_dw_load_id as load_id,
					ROW_NUMBER() OVER (PARTITION BY o.ioperationid ORDER BY o.tsLastModified DESC) as rn
			    FROM mktg_ops_tbls.adb_nmsoperation o
			    LEFT JOIN mktg_ops_tbls.adb_xtkfolder b ON o.iprogramid = b.ifolderid
			    LEFT JOIN mktg_ops_tbls.adb_xtkfolder x ON b.iparentid = x.ifolderid
			    LEFT JOIN mktg_ops_tbls.adb_xtkfolder c ON x.iparentid = c.ifolderid
			    LEFT JOIN mktg_ops_tbls.adb_xtkfolder d1 ON c.iparentid = d1.ifolderid
			    LEFT JOIN mktg_ops_tbls.adb_xtkfolder e ON d1.iparentid = e.ifolderid
			    LEFT JOIN mktg_ops_tbls.dim_campgn d ON o.ioperationid = d.nk_campgn_id
			    WHERE e.slabel = 'Campaign Management'
			      AND (
			          o.dw_trans_ts > v_increment_ts OR
			          b.dw_trans_ts > v_increment_ts OR
			          x.dw_trans_ts > v_increment_ts OR
			          c.dw_trans_ts > v_increment_ts OR
			          d1.dw_trans_ts > v_increment_ts OR
			          e.dw_trans_ts > v_increment_ts
			      )

			) as subqry
			where subqry.rn=1;
		
	    

	---Step 4: delete from tgt where src matches the conditions.

		delete from  mktg_ops_tbls.dim_campgn
		where campgn_key in (select campgn_key from existingrecord where row_stat_cd='C'); 

   -- Step 5: insert all stg records into tgt-ops table.
    INSERT INTO mktg_ops_tbls.dim_campgn (
        campgn_key, nk_campgn_id, campgn_cd, campgn_nm,
        campgn_plan_id, campgn_plan_nm, campgn_lob_id, campgn_lob_nm,
        campgn_channel_id, campgn_channel_nm, campgn_program_id, campgn_program_nm,
        is_triggrd_campgn, srcsys_trans_ts, dw_trans_ts,
        row_stat_cd, appl_src_cd, load_id
    )
    SELECT
         	campgn_key,
	        nk_campgn_id,
	        campgn_cd,
	        campgn_nm,
	        plan_id,
	        plan_nm,
	        lob_plan_id,
	        lob_plan_nm,
	        channel_id,
	        channel_nm,
	        program_id,
	        program_nm,
	        iistriggeredcampaign,
	        tsLastModified,
	        dw_trans_ts,
	        row_stat_cd,
	        appl_src_cd,
	        load_id
		from existingrecord;

    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

    -- Step 6: Get latest timestamp for next run and Update load control	
	   	SELECT COALESCE(MAX(tslastmodified), '9999-01-01'::timestamp)
	    INTO v_next_extract_ts
	    FROM existingrecord;

		CALL etl_config.sp_upsert_load_control(
	        'sp_upsert_dim_campgn', 'dim_campgn',
	        v_next_extract_ts, v_appl_src_cd, v_dw_load_id
	    );
        drop table existingrecord;

	-- Step 7: Audit update	
			v_end_time := GETDATE();
            v_ok_message := '';
			
		UPDATE mods_bi.etl_config.audit_log
       	SET 
           status = 'Complete',
           end_time = v_end_time,
           TaskMessage = v_ok_message,
           recs_processed = v_inserted_count
       WHERE 
           proc_name = 'sp_upsert_dim_campgn' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;

	-- Step 8: Insert in audit to Error
	    EXCEPTION
	        WHEN OTHERS THEN
	            v_end_time := CURRENT_TIMESTAMP;
				RAISE NOTICE 'NOTICE: An exception occurred.';
				
	    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('sp_upsert_dim_campgn', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
END;

$$
