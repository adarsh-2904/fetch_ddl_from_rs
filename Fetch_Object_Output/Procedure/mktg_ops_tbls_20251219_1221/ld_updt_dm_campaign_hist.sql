CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_updt_dm_campaign_hist()
 LANGUAGE plpgsql
AS $$
/*
Modified by: Michael Andrien
Modified Date: 11/23/2022
Purpose:  Created this macro to run daily to update NULL names found in the mktg_data_tbls.dm_campaign_hist table.  This 
table contains complete direct mail return file history.  Out caging and cashiering vendor (CDS) references this table when processing direct
mail reply devices to align the gift process record details with the outbound direct mail file details.  We had instances where the name details were
null or blank in the return file, but we had valid, usable names for the constiruent in our FR Preferred profile.  This used to be an issue when we tried to force 
the constituent name source to align with the direct mail address source.  We made a change to our preferred profile logic to allow the name source to differ from 
the mailing address source in cases where the name for the address source was null or blank,  This update macro addresses mail files that were sent prior to the 
profile change.  It should become irrelevant over time.

Modified by: Majeed Mohammad
Modified Date: 03/05/2024
Purpose:  Added the DISTINCT to the SELECT part to address the error "Target row updated by multiple source rows" . 
Also changed the date filter format from 06/01/2022 to 2022-06-01

Modified by: Majeed Mohammad
Modified Date: 11/21/2024
Purpose:  Added this condition to the SELECT part -  ( b.dm_cnst_prsn_l_nm is not  null or  b.dm_cnst_org_nm is not null ) . 

*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
	total_updated int :=0;
	tmp_count INT;

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_updt_dm_campaign_hist', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
		update mktg_ops_tbls.dm_campaign_hist
		set
		    ttl = a.dm_cnst_prsn_prfx_nm,
		    first_nm = a.dm_cnst_prsn_f_nm,
		    middle_nm = a.dm_cnst_prsn_m_nm,
		    last_nm = a.dm_cnst_prsn_l_nm,
		    suffix = a.dm_cnst_prsn_sfx_nm,
		    company_nm = UPPER(a.dm_cnst_org_nm)
		from 
		(
		    select  distinct 
		        a.cnst_mstr_id, 
		        a.motivtn_cd,
		        a.aprm_src_cd,
		        b.dm_cnst_prsn_prfx_nm, 
		        b.dm_cnst_prsn_f_nm, 
		        b.dm_cnst_prsn_m_nm, 
		        b.dm_cnst_prsn_l_nm, 
		        b.dm_cnst_prsn_sfx_nm,
		        UPPER(b.dm_cnst_org_nm)
		    from mktg_ops_tbls.dm_campaign_hist a
		    left join  mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr b on a.cnst_mstr_id = b.cnst_mstr_id
		    where
				(a.last_nm is null or trim(a.last_nm) = '')
		         and a.drop_dt >= cast('2022-06-01' as date) 
		        and a.cnst_mstr_id > 0 
		        and (a.company_nm is null or trim(a.company_nm) = '')
		                        and ( b.dm_cnst_prsn_l_nm is not  null or  b.dm_cnst_org_nm is not null ) 
		) a (cnst_mstr_id, motivtn_cd, aprm_src_cd, dm_cnst_prsn_prfx_nm, dm_cnst_prsn_f_nm, dm_cnst_prsn_m_nm, dm_cnst_prsn_l_nm, dm_cnst_prsn_sfx_nm, dm_cnst_org_nm)
		
		where 
		    mktg_ops_tbls.dm_campaign_hist.cnst_mstr_id = a.cnst_mstr_id
		    and mktg_ops_tbls.dm_campaign_hist.motivtn_cd = a.motivtn_cd
		    and mktg_ops_tbls.dm_campaign_hist.aprm_src_cd = a.aprm_src_cd
			and (mktg_ops_tbls.dm_campaign_hist.last_nm is null or trim(mktg_ops_tbls.dm_campaign_hist.last_nm) = '');
		
	   ----getting count of updated record
		GET DIAGNOSTICS tmp_count = ROW_COUNT;
        total_updated := total_updated + tmp_count;



		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records updated';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = total_updated
			WHERE proc_name = 'ld_updt_dm_campaign_hist' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
		    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
		    VALUES ('ld_updt_dm_campaign_hist', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
