CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_dim_rpt_cell_cd()
 LANGUAGE plpgsql
AS $$
/*
Created By: Michael Andrien
Created Date: 5/30/2017
Purpose: 	This macro combines the Aprimo and Adobe report cell code reference tables and loads the data into mktg_ops_tbls.bz_dim_rpt_cell_cd, which is
				the source for the mktg_ops_vws.bz_dim_rpt_cell_cd view referenced in the Campaign Effectiveness universe.

*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_dim_rpt_cell_cd', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN

TRUNCATE TABLE mktg_stage_tbls.bz_dim_rpt_cell_cd_stg;

INSERT INTO mktg_stage_tbls.bz_dim_rpt_cell_cd_stg
SELECT 
    iReportCellCodeId AS rpt_cell_cd_key,
    iReportCellCodeId AS rpt_cell_cd_id, 
    sLowDate || sHighDate || sTag || sLowDonation || sHighDonation AS rpt_cell_cd,
    sLowDate AS low_dt, 
    sHighDate AS high_dt, 
    sTag AS tag_cd, 
    sLowDonation AS low_dontn, 
    sHighDonation AS high_dontn, 
    dw_trans_ts, 
    row_stat_cd, 
    appl_src_cd, 
    load_id
FROM mktg_ops_tbls.adb_arcreportcellcode;

-- Get the Aprimo Report Cell Code Records

INSERT INTO mktg_stage_tbls.bz_dim_rpt_cell_cd_stg
SELECT DISTINCT
    cell_id AS rpt_cell_cd_key, -- Report Cell Code Key
    cell_id AS rpt_cell_cd_id,  -- Report Cell Code ID
    cell_subsrc_cd AS rpt_cell_cd, -- Report Cell Code
    SUBSTRING(cell_subsrc_cd, 1, 2) AS low_dt, -- Low Gift Date
    SUBSTRING(cell_subsrc_cd, 3, 2) AS high_dt, -- High Gift Date
    SUBSTRING(cell_subsrc_cd, 5, 4) AS tag_cd, -- TAG Code
    SUBSTRING(cell_subsrc_cd, 9, 4) AS low_dontn, -- Low Donation Amount
    SUBSTRING(cell_subsrc_cd, 13, 4) AS high_dontn, -- High Gift Amount
    dw_trans_ts, 
    'A' AS row_stat_cd, 
    appl_src_cd, 
    load_id
FROM mktg_ops_vws.bzfc_fact_interaction
WHERE SUBSTRING(cell_src_cd, 1, 2) IN ('RQ', 'RR') 
  AND cell_id IS NOT NULL;
  
TRUNCATE TABLE mktg_ops_tbls.bz_dim_rpt_cell_cd;

INSERT INTO mktg_ops_tbls.bz_dim_rpt_cell_cd
SELECT * from mktg_stage_tbls.bz_dim_rpt_cell_cd_stg;
  
	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_stage_tbls.bz_dim_rpt_cell_cd_stg) as integer)
        WHERE proc_name = 'ld_bz_dim_rpt_cell_cd' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bz_dim_rpt_cell_cd', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
