CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_email_src_cd()
 LANGUAGE plpgsql
AS $$

/*
Created by: Michael Andrien
Created date: 02/26/2018
Purpose: Create this macro to combine the email source codes from mktg_ops_tbls (sourced from Greg's historical file) with the distinct 
                                                                email source codes from Adobe Email Fact table.  This table is joined to the arc_fr_txn view and helps to identify which the email source codes in the gift transaction profile table.
                                                                
Updated by: Michael Andrien - updates coded by Greg Seaberg
Updated date: 06/16/2020
Purpose: Update source code table to pull in new source codes created since GMS launch; update source key values to GMS.  Added join the mktg_ops_vws.gmpbzal_dim_src and added the src_key, src_cd and src_dsc attributes
for the gms_arc_fr_txn mapping to reference.

Updated by: Michael Andrien
Updated date: 08/27/2020
Purpose: Added an additional WHERE condition on the Fact Email Interaction section of the UNION query to include the e 'and a.src_cd is not null)' logic as shown below.  We added this to avoid duplicate entries in the email source code table.
	--WHERE (b.comnictn_src_key <> 0 and a.src_cd is not null) or 
---------------------------------------------------------------------------------------------------------------------------------------------- */
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_email_src_cd', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN

TRUNCATE TABLE mktg_ops_tbls.bz_email_src_cd;

INSERT INTO mktg_ops_tbls.bz_email_src_cd
select
	COALESCE(src_key, 0),
	coalesce(src_cd, nk_comnictn_src_cd, 'Unknown') as src_cd,
	src_dsc,
	comnictn_src_key, 
	nk_comnictn_src_cd, 
	comnictn_src_dsc, 
	channel, 
	appl_src_cd
from 
(
    SELECT
	b.src_key,
	b.src_cd, 
	b.src_dsc, 
	comnictn_src_key, 
	nk_comnictn_src_cd, 
	comnictn_src_dsc, 
	channel,
	'2MKT' AS appl_src_cd
    FROM mktg_ops_tbls.email_src_cd a
LEFT JOIN (
SELECT src_key, src_cd, src_dsc
FROM (
    SELECT 
        src_key, 
        src_cd, 
        src_dsc,
        ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
    FROM mktg_ops_vws.gmpbzal_dim_src
) sub
WHERE rn = 1

) b ON a.nk_comnictn_src_cd = b.src_cd
WHERE row_stat_cd <> 'L'--Hitansu: working fine

 UNION

    SELECT DISTINCT
        c.src_key,
        c.src_cd, 
        c.src_dsc, 
        a.comnictn_src_key, 
        b.nk_comnictn_src_cd, 
        b.comnictn_src_dsc,
        'email' AS channel,
        '1MKT' AS appl_src_cd
    FROM mktg_ops_tbls.fact_email_interaction a 
    LEFT JOIN mktg_ops_vws.bz_comnictn_src b 
        ON a.comnictn_src_key = b.comnictn_src_key
    LEFT JOIN (
SELECT src_key, src_cd, src_dsc
FROM (
    SELECT 
        src_key, 
        src_cd, 
        src_dsc,
        ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
    FROM mktg_ops_vws.gmpbzal_dim_src
) sub
WHERE rn = 1

    ) c ON a.src_cd = c.src_cd
    WHERE 
        (b.comnictn_src_key <> 0 AND a.src_cd IS NOT NULL) OR 
        (c.src_key IS NOT NULL AND c.src_key <> 0 AND a.src_cd IS NOT NULL AND c.src_cd IS NOT NULL)
) a
QUALIFY ROW_NUMBER() OVER (PARTITION BY a.src_key ORDER BY appl_src_cd) = 1;
 	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.bz_email_src_cd) as integer)
        WHERE proc_name = 'ld_bz_email_src_cd' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bz_email_src_cd', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
