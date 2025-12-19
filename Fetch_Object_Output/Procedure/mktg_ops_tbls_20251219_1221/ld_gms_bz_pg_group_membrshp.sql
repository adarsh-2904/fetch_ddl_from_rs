CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_bz_pg_group_membrshp()
 LANGUAGE plpgsql
AS $$
---------------------------------------------------------------------------------------------------------------------------
-- Created by: Michael Andrien
-- Created date: 10-Feb-2015
-- Purpose: This script populates the Planned Giving Group Membership table (mktg_ops_tbls.gms_bz_pg_group_membrshp)
--          from the source view mktg_ops_vws.pg_group_membrshp_src. The source view contains the selection
--          logic for each of the 15 PG campaign groups originally defined by Rich Reider from the PG team. These
--          select statements are 'Unioned' together. The script was created to instantiate the view to improve Selection
--          performance. The view is leveraged within the Aprimo universe to simplify the PG Campaign Segmentation definitions.
-- Modified By: Michael Andrien
-- Modified Date: 6/30/2016
-- Purpose: Added second insert to include PG group 25, which has dependencies on other groups so we need to insert the dependent group rows before
--          inserting the group 25 rows.
--
-- Modified By: Majeed Mohammad
-- Modified Date: 2/9/2017
-- Purpose: Updated the view to use the mktg_ops_vws vs. the aprimo_wrk_tbls.bz_pg_group_membrshp
--
-- Modified By: Michael Andrien
-- Modified Date: 02/29/2020
-- Purpose: Created GMS version of the view to reference the new GMS FR profiles tables and views
-- ---------------------------------------------------------------------------------------------------------------------------
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_bz_pg_group_membrshp', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN
-- Delete all existing records
DELETE FROM mktg_ops_tbls.gms_bz_pg_group_membrshp;

-- Insert from source view
INSERT INTO mktg_ops_tbls.gms_bz_pg_group_membrshp (
    cnst_mstr_id,
    pg_group_key,
    dw_trans_ts
)
SELECT
    cnst_mstr_id,
    pg_group_key,
    dw_trans_ts
FROM mktg_ops_vws.gms_pg_group_membrshp_src;
commit;

-- The insert below was added because PG Group 25 is based on other PG group definitions from the source view.
-- Since we truncate the table before the first insert, we cannot include PG group 25 in the source view.
-- This second insert ensures the dependent group records are inserted before PG group 25.
INSERT INTO mktg_ops_tbls.gms_bz_pg_group_membrshp (
    cnst_mstr_id,
    pg_group_key,
    dw_trans_ts
)
SELECT
    cnst_mstr_id,
    25 AS pg_group_key, -- PG CDRP Newsletter Group
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP)
FROM mktg_ops_vws.gms_bz_pg_group_membrshp
WHERE pg_group_key IN (15, 10) -- PG Closed or PG Info Request No Age
  AND cnst_mstr_id NOT IN (
      SELECT cnst_mstr_id
      FROM mktg_ops_vws.gms_bz_pg_group_membrshp
      WHERE pg_group_key = 14 -- PG Survey Responders
  );
 commit;
 
 	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.gms_bz_pg_group_membrshp) as integer)
        WHERE proc_name = 'ld_gms_bz_pg_group_membrshp' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_gms_bz_pg_group_membrshp', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
