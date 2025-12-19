CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_fact_dmail_interaction_updt()
 LANGUAGE plpgsql
AS $$
/*
Created By: Michael Andrien
Created Date: 11/10/2020
Purpose: 	This macro is intended to monitor the treatment and unit code/key values in the initial direct mail (DM) interaction table (mktg_ops_tbls.fact_dmail_interaction) with the treatment and unit details provided in 
the DM return files provided by our direct mail fullfillment vendors.  The treatment and unit details can be changed by the DM vendors after running our files through the NCOA process.  If the zip code changes on the original
address, this can impact the unit and treatment values.  This ensures our details are aligned, which is critical for reporting campaign effectiveness more accurately.

Modified By: Michael Andrien
Modified Date: 01/26/2021
Purpose: Modified the qualifying WHERE clause of the SELECT and UPDATE sections of the query below to detect instances when the treatment or chapter code in the interaction table is null and the return file values are not null.  Also, had to
add a qualify statement to the from query to remove duplicate records.  After further testing, replace the table c join to join directly to the treatment dim.  This prior join was not correct.
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_fact_dmail_interaction_updt', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN


UPDATE mktg_ops_tbls.fact_dmail_interaction
SET
    treatmnt_key = a.rf_treatmnt_key,
    nk_treatmnt_id = a.rf_nk_treatmnt_id,
    nk_ecode = a.rf_nk_ecode,
    unit_key = a.rf_unit_key,
    row_stat_cd = 'U',
    appl_src_cd = 'ENGR',
    dw_trans_ts = current_timestamp
FROM (
    SELECT 
        a.orig_cnst_mstr_id, 
        a.src_cd AS dm_src_cd,
        a.treatmnt_key AS dm_treatmnt_key, 
        a.treatmnt_cd AS dm_treatmnt_cd, 
        c.treatmnt_key AS rf_treatmnt_key,
        c.nk_treatmnt_id AS rf_nk_treatmnt_id,
        b.treatmnt_cd AS rf_treatmnt_cd, 
        a.nk_ecode AS dm_nk_ecode, 
        a.unit_key AS dm_unit_key,
        b.nk_ecode AS rf_nk_ecode, 
        d.unit_key AS rf_unit_key,
        CASE WHEN a.treatmnt_cd <> b.treatmnt_cd THEN 1 ELSE 0 END AS treatmnt_ind, 
        CASE WHEN a.nk_ecode <> b.nk_ecode THEN 1 ELSE 0 END AS ecode_ind
    FROM (
        SELECT 
            a.orig_cnst_mstr_id, 
            a.src_cd, 
            b.treatmnt_key, 
            b.treatmnt_cd, 
            nk_ecode, 
            a.unit_key
        FROM mktg_ops_vws.bzfc_fact_dmail_interaction a
        LEFT JOIN mktg_ops_vws.bz_dim_treatmnt b 
            ON a.treatmnt_key = b.treatmnt_key
        WHERE mailed_ind = 1 
          AND intrctn_dt >= DATE '2018-01-01'
          AND SUBSTRING(src_cd, 1, 3) NOT IN ('RQQ', 'RQL', 'RQD', 'RQP')
          AND cnst_mstr_id <> 0
    ) a
    LEFT JOIN (
        SELECT 
            orig_cnst_mstr_id, 
            aprm_src_cd, 
            treatmnt_dsc, 
            SUBSTRING(treatmnt_dsc, 1, 2) AS treatmnt_cd, 
            chapt_id AS nk_ecode
        FROM mktg_ops_tbls.dm_campaign_hist
        WHERE drop_dt >= DATE '2018-01-01'
          AND cnst_mstr_id <> 0
          AND SUBSTRING(aprm_src_cd, 1, 3) NOT IN ('RQQ', 'RQL', 'RQD', 'RQP')
    ) b 
        ON a.orig_cnst_mstr_id = b.orig_cnst_mstr_id 
       AND a.src_cd = b.aprm_src_cd
    LEFT JOIN mktg_ops_vws.bz_dim_treatmnt c 
        ON b.treatmnt_cd = c.treatmnt_cd 
       AND c.active_ind = 1
    LEFT JOIN mktg_ops_vws.dim_unit d 
        ON b.nk_ecode = d.nk_ecode
    WHERE (
        (a.treatmnt_cd <> b.treatmnt_cd) 
        OR (a.treatmnt_cd IS NULL AND b.treatmnt_cd IS NOT NULL) 
        OR (a.nk_ecode <> b.nk_ecode) 
        OR (a.nk_ecode IS NULL AND b.nk_ecode IS NOT NULL)
    )
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY a.orig_cnst_mstr_id, a.src_cd 
        ORDER BY c.active_ind DESC, c.treatmnt_key DESC
    ) = 1
) a
WHERE 
    mktg_ops_tbls.fact_dmail_interaction.orig_cnst_mstr_id = a.orig_cnst_mstr_id 
    AND mktg_ops_tbls.fact_dmail_interaction.src_cd = a.dm_src_cd
    AND (
        mktg_ops_tbls.fact_dmail_interaction.treatmnt_key <> a.rf_treatmnt_key OR 
        mktg_ops_tbls.fact_dmail_interaction.treatmnt_key IS NULL AND a.rf_treatmnt_key IS NOT NULL OR 
        mktg_ops_tbls.fact_dmail_interaction.unit_key <> a.rf_unit_key OR 
        mktg_ops_tbls.fact_dmail_interaction.unit_key IS NULL AND a.rf_unit_key IS NOT NULL
    );
	
--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='Records updated';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((
SELECT count(*)
FROM mktg_ops_tbls.fact_dmail_interaction
WHERE dw_trans_ts > v_start_time
) as integer)
        WHERE proc_name = 'ld_fact_dmail_interaction_updt' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_fact_dmail_interaction_updt', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
