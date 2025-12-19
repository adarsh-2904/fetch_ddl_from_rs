CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_google_analytics_txn()
 LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_google_analytics_txn', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN
    -- First truncate the data in bz_google_analytics_txn
    TRUNCATE TABLE mktg_ops_tbls.bz_google_analytics_txn;

    -- Now insert the current data into the bz_google_analytics_txn table
    INSERT INTO mktg_ops_tbls.bz_google_analytics_txn (
        trans_id,
        source1,
        medium1,
        campaign,
        device,
        channel_grp
    )
    SELECT DISTINCT
        trans_id,
        source1,
        medium1,
        campaign,
        device,
        channel_grp
    FROM mktg_ops_tbls.google_analytics_txn;
	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.bz_google_analytics_txn) as integer)
        WHERE proc_name = 'ld_bz_google_analytics_txn' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bz_google_analytics_txn', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
