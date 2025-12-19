CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_pbi_bio_demogrphcs()
 LANGUAGE plpgsql
AS $$

/* Created by: Majeed Mohammad
Created on: 02/04/2022
Purpose: To load the table  mktg_ops_tbls.pbi_bio_demogrphcs all 
 
*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_pbi_bio_demogrphcs', 'Stored Procedure', 'Inprogress', v_start_time);


begin

truncate table mktg_ops_tbls.pbi_bio_demogrphcs;

INSERT	INTO mktg_ops_tbls.pbi_bio_demogrphcs
(donor_key, dr_contact_key, race_dsc, gndr_cd, cnst_addr_state,
		age_band_dsc, sickle_cell_dnr_flg, nk_ep_abo_id, row_stat_cd,
		dw_trans_ts, appl_src_cd, load_id)		
with DIM_CNST_UNF as (
select dn.donor_id,dn.blood_type_key,
ct.contact_key, dn.age, dn.state, dn.race_id, dn.sickle_cell_flag,dn.last_time_donation_dt, ct.gender_cd
from eda.bio_donation_vws.bz_dim_donor dn
inner join eda.bio_appointment_vws.bzl_dim_contact ct
on dn.donor_external_id = ct.nk_key_donor
)

SELECT  DISTINCT 
  coalesce(DIM_CNST_UNF.donor_id,0) as "donor_key",
  DIM_CNST_UNF.contact_key,
coalesce(RACE.race_description,'Unknown') as "Race",
  coalesce(DIM_CNST_UNF.gender_cd,'Unknown') as "Gender",
  coalesce(DIM_CNST_UNF.state,'Unknown') as "State",
  coalesce(AGE.age_band_dsc,'Unknown') as "Age Band",
  case when ENROL.SICKLE_CELL_DONOR_IND = 1 then 'Yes' else 'No' End as "Sickle Cell Donor Flag",
coalesce(BTYPE.nk_ep_abo_id,'Unknown') as "Blood Type", 
'I' as row_stat_cd, CURRENT_TIMESTAMP(0) as dw_trans_ts, 'MKTG' as appl_src_cd, 100 as load_id
FROM
DIM_CNST_UNF LEFT OUTER JOIN eda.bio_appointment_vws.bzf_dim_cntct_enrol ENROL ON (ENROL.contact_key=DIM_CNST_UNF.contact_key)
LEFT OUTER JOIN eda.bio_appointment_vws.bzl_fact_appointment  APPT ON (DIM_CNST_UNF.contact_key=APPT.contact_key)
LEFT OUTER JOIN eda.dw_common_vws.dim_age_band AGE ON DIM_CNST_UNF.age=AGE.age_band_key
LEFT OUTER JOIN eda.bio_donation_vws.bz_dim_race RACE ON   DIM_CNST_UNF.race_id  = RACE.race_id
LEFT OUTER JOIN eda.dw_common_vws.dim_blood_type BTYPE ON DIM_CNST_UNF.blood_type_key=BTYPE.blood_type_key
WHERE
((DIM_CNST_UNF.last_time_donation_dt >= date_trunc('month',add_months(current_date,-60)) 
AND DIM_CNST_UNF.last_time_donation_dt  < date_trunc('month',current_date) )
AND DIM_CNST_UNF.contact_key is not null ) 
  OR 
   ((APPT.apptmt_dt >= date_trunc('month',add_months(current_date,-60)) 
AND APPT.apptmt_dt  < date_trunc('month',current_date) )
AND DIM_CNST_UNF.contact_key is not null); 


	
	--audit update	
	v_end_time := GETDATE();
	v_ok_message = 'Records inserted.';
        UPDATE mods_bi.etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.pbi_bio_demogrphcs) as INTEGER)
        WHERE proc_name = 'ld_pbi_bio_demogrphcs' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_pbi_bio_demogrphcs', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
