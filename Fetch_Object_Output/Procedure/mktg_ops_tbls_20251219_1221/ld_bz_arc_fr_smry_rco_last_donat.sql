CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_arc_fr_smry_rco_last_donat()
 LANGUAGE plpgsql
AS $$	
/*
Created by: Michael Andrien
Created on:  03/24/2020
Purpose: This macro instantiates the table mktg_ops_tbls.bz_cnst_cdi_smry_fr_rco_last_tm using the view mktg_ops_vws.cnst_cdi_smry_fr_rco_first_tm_src.  The 
					is used within Adobe to identify the most recent online donation for a donor.  The table was created to enable the MODS Ops team to include activate "Thank You' campagn messages
					to online donors more quickly.  A view over the table will be exposed in the Adobe schema to activate the data.  This data enables the team to act on the data before it is available in the gift processing system.
					
Updated By: Michael Andrien
Update Date: 5/14/2020
Purpose: Changed the FR Preferred table to reference the GMS version.
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_arc_fr_smry_rco_last_donat', 'Stored Procedure', 'Inprogress', v_start_time);


begin

DELETE FROM mktg_ops_tbls.bz_arc_fr_smry_rco_last_donat;

-- Insert the latest donation record per constituent
INSERT INTO mktg_ops_tbls.bz_arc_fr_smry_rco_last_donat

--create table mktg_ops_tbls.bz_arc_fr_smry_rco_last_donat1 as 
SELECT 
    mb.cnst_mstr_id,
    a.trans_id,
    tb.rco_dntn_id,
    CAST(dntn_regis_ts AS DATE) AS dntn_regis_dt,
    b.billng_email AS billing_email,
    b.billng_f_nm AS billing_f_nm, 
    b.billng_l_nm AS billing_l_nm,
    prfr.em_cnst_data_src_cd,
    prfr.em_cnst_email
FROM rco_vws.bz_fact_dnr_trans a 
LEFT JOIN rco_vws.bz_dim_trans_billng b 
    ON a.trans_billng_key = b.trans_billng_key 
LEFT JOIN rco_vws.bz_dim_cdi_1c_trans_bridge tb 
    ON a.dnr_trans_key = tb.dnr_trans_key
LEFT JOIN rco_vws.bz_dim_acct_prsn_cdi_1c ap 
    ON tb.acct_prsn_key = ap.acct_prsn_key
LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge mb 
    ON mb.cnst_mstr_subj_area_id = ap.acct_prsn_key 
    AND mb.cnst_mstr_subj_area_cd = 'RCO'
LEFT JOIN mods_bi.mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr prfr 
    ON mb.cnst_mstr_id = prfr.cnst_mstr_id
WHERE mb.cnst_mstr_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY mb.cnst_mstr_id 
    ORDER BY a.trans_ts DESC
) = 1;

	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.bz_arc_fr_smry_rco_last_donat) as integer)
        WHERE proc_name = 'ld_bz_arc_fr_smry_rco_last_donat' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bz_arc_fr_smry_rco_last_donat', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;


$$
