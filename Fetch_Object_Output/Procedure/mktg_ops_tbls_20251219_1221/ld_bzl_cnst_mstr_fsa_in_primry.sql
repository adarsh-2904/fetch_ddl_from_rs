CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzl_cnst_mstr_fsa_in_primry()
 LANGUAGE plpgsql
AS $$
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date:  11/30/2015
Purpose:  This Macro loads the mktg_data_tbls.bzl_cnst_mstr_fsa_in_primary table, 
				which establishes the primary CDI Master ID for a TA Account ID.  The table is referenced by the 
				mktg_ops_vws.bzfc_fact_interaction_all_src view and mktg_data_tbls.ld_bzfc_fact_interaction_all Macro to
				load the correct primary cnst_mstr_id for an interaction record.

Modified by: 	Michael Andrien
Modified date:  03/23/2016
Purpose: 		Changed order by logic for Individuals to order by the Deceased code then by the name id.  We want to make the primary cnst_mstr_id based
					on the non-Deceased person in the account.  This helps align the cnst associated with the gift transaction to the primary cnst mstr id on the interaction record.
					The cnst_mstr_id reflects the original master id with whom we interacted.
					
Modified by: 	Majeed Mohammad
Modified date:  12/05/2016
Purpose: 	Removed the view aprimo_wrk_tbls.bzl_cnst_mstr_fsa_in , which was pointing to the aprimo_lndng_tbls database. This macro was copied from 2580. Updated to use the view arc_mdm_vws.bzal_cnst_mstr instead 

Modified by: Michael Andrien
Modified date: 4/24/2017
Purpose: Change the aprimo_wrk_tbls database view references to drms_vws now that our mktg data is on the EDW server.

Modified by: Adarsh Ram
Modified date: 08/19/2025
Purpose: This Stored procedure loads the mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary table

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
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzl_cnst_mstr_fsa_in_primry', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		truncate table mktg_stage_tbls.bzl_cnst_mstr_fsa_in_primary_stg;

		insert into mktg_stage_tbls.bzl_cnst_mstr_fsa_in_primary_stg 
		select 
		a.cnst_mstr_id,
		case when b.primary_cnst_mstr_id is null then a.cnst_mstr_id else b. primary_cnst_mstr_id end as primary_cnst_mstr_id,
		a.bzd_cnst_fsa_key,
		a.bzd_acct_fsa_key,
		a.bzd_ntrl_key,
		a.bzd_chpt_import_id,
		a.nk_ta_acct_id,
		a.nk_ta_nm_id,
		a.nk_sf_acct_id,
		a.nk_sf_cntct_id,
		a.bzd_SFID,
		a.cnst_typ_cd,
		a.appl_src_cd
		from  eda.arc_mdm_vws.bzl_cnst_mstr_fsa_in a
		left join 
		(select nk_ta_acct_id,
				primry_cnst_mstr_id, 
				nk_ta_nm_id, 
				cnst_typ_cd
				from(
						select a.nk_ta_acct_id,
						a.cnst_mstr_id as primry_cnst_mstr_id, 
						a.nk_ta_nm_id, 
						a.cnst_typ_cd,
						ROW_NUMBER() OVER 
						(PARTITION BY a.nk_ta_acct_id ORDER BY  case when b.cnst_arc_deceased_cd='N' then 1
						when b.cnst_arc_deceased_cd is null then 2 /* The NULLs records are treated as second priority */ 
						when b.cnst_arc_deceased_cd='A' then 3
						when b.cnst_arc_deceased_cd='D' then 4
						else 5 end,     
						 a.nk_ta_nm_id asc) as rn
					from   eda.arc_mdm_vws.bzl_cnst_mstr_fsa_in a
					left join eda.arc_mdm_vws.bzal_cnst_mstr b on a.cnst_mstr_id = b.cnst_mstr_id
				) as subqry
				
				where subqry.rn=1
			
		 )  b (nk_ta_acct_id,primary_cnst_mstr_id, nk_ta_nm_id,cnst_typ_cd) ON a.nk_ta_acct_id = b.nk_ta_acct_id
		where a.cnst_typ_cd = 'IN' and a.appl_src_cd ='TAFS';
		
		commit;
		
		insert into mktg_stage_tbls.bzl_cnst_mstr_fsa_in_primary_stg
		select 
		a.cnst_mstr_id,
		case when b.primary_cnst_mstr_id is null then a.cnst_mstr_id else b. primary_cnst_mstr_id end as primary_cnst_mstr_id,
		a.bzd_cnst_fsa_key,
		a.bzd_acct_fsa_key,
		a.bzd_ntrl_key,
		a.bzd_chpt_import_id,
		a.nk_ta_acct_id,
		a.nk_ta_nm_id,
		a.nk_sf_acct_id,
		a.nk_sf_cntct_id,
		a.bzd_SFID,
		a.cnst_typ_cd,
		a.appl_src_cd
		from  eda.arc_mdm_vws.bzl_cnst_mstr_fsa a
		left join 
		(
		select nk_ta_acct_id, 
				primry_cnst_mstr_id, 
				nk_ta_nm_id,
				cnst_typ_cd
				from (
				
						select nk_ta_acct_id, 
						cnst_mstr_id as primry_cnst_mstr_id, 
						nk_ta_nm_id,
						cnst_typ_cd,
						ROW_NUMBER() OVER (PARTITION BY nk_ta_acct_id ORDER BY  nk_ta_nm_id ) as rn
					from   eda.arc_mdm_vws.bzl_cnst_mstr_fsa
					where cnst_typ_cd in ('OR') and appl_src_cd ='TAFS'
				) as subqry
				
				where subqry.rn=1
		
		     )b (nk_ta_acct_id,primary_cnst_mstr_id, nk_ta_nm_id,cnst_typ_cd) ON a.nk_ta_acct_id = b.nk_ta_acct_id
		where a.cnst_typ_cd in ('OR') and a.appl_src_cd ='TAFS' ;
		commit;
		
		truncate table mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary;
		
		insert into mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary select * from mktg_stage_tbls.bzl_cnst_mstr_fsa_in_primary_stg;






		
		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary) as integer)
			WHERE proc_name = 'ld_bzl_cnst_mstr_fsa_in_primry' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
	    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('ld_bzl_cnst_mstr_fsa_in_primry', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
