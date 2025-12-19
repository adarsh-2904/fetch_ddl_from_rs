CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_cnst_behvrl_segmnt()
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
    VALUES ('ld_gms_cnst_behvrl_segmnt', 'Stored Procedure', 'Inprogress', v_start_time);


begin


/*
Truncate and reload the table
*/
TRUNCATE TABLE mktg_ops_tbls.gms_cnst_behvrl_segmnt;
/*
Now reload the table.
*/
INSERT INTO mktg_ops_tbls.gms_cnst_behvrl_segmnt
SELECT 
    a.cnst_mstr_id,
    a.hhla_id,
    CASE 
        WHEN b.fr_last_dntn_dt IS NULL THEN 'UN'
        WHEN b.fr_last_non_distr_dntn_dt IS NOT NULL AND b.fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE) THEN 'AM'
        WHEN b.fr_last_non_distr_dntn_dt IS NOT NULL AND b.fr_last_dntn_dt >= DATEADD(month, -120, CURRENT_DATE) THEN 'LM'
        WHEN b.fr_last_non_distr_dntn_dt IS NOT NULL AND b.fr_last_dntn_dt < DATEADD(month, -120, CURRENT_DATE) THEN 'IM'
        WHEN b.fr_last_non_distr_dntn_dt IS NULL AND b.fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE) THEN 'AD'
        WHEN b.fr_last_non_distr_dntn_dt IS NULL AND b.fr_last_dntn_dt >= DATEADD(month, -120, CURRENT_DATE) THEN 'LD'
        WHEN b.fr_last_non_distr_dntn_dt IS NULL AND b.fr_last_dntn_dt < DATEADD(month, -120, CURRENT_DATE) THEN 'ID'
        ELSE 'NA' 
    END AS bsd_cd,
    CASE 
        WHEN b.fr_last_dntn_dt IS NULL THEN 'Unknown'
        WHEN b.fr_last_non_distr_dntn_dt IS NOT NULL AND b.fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE) THEN 'Active Mission'
        WHEN b.fr_last_non_distr_dntn_dt IS NOT NULL AND b.fr_last_dntn_dt >= DATEADD(month, -120, CURRENT_DATE) THEN 'Lapsed Mission'
        WHEN b.fr_last_non_distr_dntn_dt IS NOT NULL AND b.fr_last_dntn_dt < DATEADD(month, -120, CURRENT_DATE) THEN 'Inactive Mission'
        WHEN b.fr_last_non_distr_dntn_dt IS NULL AND b.fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE) THEN 'Active Disaster'
        WHEN b.fr_last_non_distr_dntn_dt IS NULL AND b.fr_last_dntn_dt >= DATEADD(month, -120, CURRENT_DATE) THEN 'Lapsed Disaster'
        WHEN b.fr_last_non_distr_dntn_dt IS NULL AND b.fr_last_dntn_dt < DATEADD(month, -120, CURRENT_DATE) THEN 'Inactive Disaster'
        ELSE 'Not Applicable' 
    END AS bsd_dsc
FROM (
		SELECT 
		a.cnst_mstr_id,
		COALESCE(
		'HH' || TRIM(a.cnst_hsld_id),
		'LA' || TRIM(CAST(b.dm_locator_addr_key AS VARCHAR(19))),
		'LA' || TRIM(CAST(a.locator_addr_key AS VARCHAR(19)))
		) AS hhla_id,
		c.fr_last_dntn_dt,
		c.fr_last_non_distr_dntn_dt
		FROM (select cnst_mstr_id,cnst_hsld_id,cnst_typ_cd,locator_addr_key from mktg_ops_vws.bzfc_arc_best_smry )a
		LEFT JOIN (select cnst_mstr_id,dm_locator_addr_key from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr )b ON a.cnst_mstr_id = b.cnst_mstr_id
		LEFT JOIN (select cnst_mstr_id,fr_last_dntn_dt,fr_last_non_distr_dntn_dt from mktg_ops_vws.gms_arc_fr_smry )c ON a.cnst_mstr_id = c.cnst_mstr_id
		WHERE a.cnst_typ_cd = 'IN'
) a
LEFT JOIN (
	SELECT 
	hhla_id,
	MAX(fr_last_dntn_dt) AS fr_last_dntn_dt,
	MAX(fr_last_non_distr_dntn_dt) AS fr_last_non_distr_dntn_dt
	FROM (
		SELECT 
		a.cnst_mstr_id,
		COALESCE(
		'HH' || TRIM(a.cnst_hsld_id),
		'LA' || TRIM(CAST(b.dm_locator_addr_key AS VARCHAR(19))),
		'LA' || TRIM(CAST(a.locator_addr_key AS VARCHAR(19)))
	) AS hhla_id,
	c.fr_last_dntn_dt,
	c.fr_last_non_distr_dntn_dt
	FROM (select cnst_mstr_id,cnst_hsld_id,cnst_typ_cd,locator_addr_key from mktg_ops_vws.bzfc_arc_best_smry )a
	LEFT JOIN (select cnst_mstr_id,dm_locator_addr_key from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr )b ON a.cnst_mstr_id = b.cnst_mstr_id
	LEFT JOIN (select cnst_mstr_id,fr_last_dntn_dt,fr_last_non_distr_dntn_dt from mktg_ops_vws.gms_arc_fr_smry )c ON a.cnst_mstr_id = c.cnst_mstr_id
	WHERE a.cnst_typ_cd = 'IN')sub
	GROUP BY hhla_id
) b ON a.hhla_id = b.hhla_id;

	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.gms_cnst_behvrl_segmnt) as integer)
        WHERE proc_name = 'ld_gms_cnst_behvrl_segmnt' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_gms_cnst_behvrl_segmnt', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;


$$
