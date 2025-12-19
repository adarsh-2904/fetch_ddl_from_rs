CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_arc_fr_smry_cbg()
 LANGUAGE plpgsql
AS $$
	
/*
	Modified by: Michael Andrien
	Modified Date: 08/08/2018
	Purpose:  This macro was created to calculate the which FR constituents are eligible for the Clara Barton Gold (CBG) program.  The macro calucuates the cumulative gift amount for the 
	                                                                current and prior 2 years and returns one row per constituent master id with the date they qualified for the CBG program.  The macro will run daily and will trucate and
	                                                                reload the mktg_ops_tbls.arc_fr_smry_cbg table.  This table is referenced in the mktg_ops_vws.arc_fr_smry view definition to set the respective CBG attributes in the 
	                                                                arc_fr_smry view.
	
	Modified by: Michael Andrien
	Modified Date: 02/10/2020
	Purpose:	Created the GMS version to read from gms_arc_fr_txn and to write the GMS version of the arc_fr_smry_cbg table (gms_arc_fr_smry_cbg).
*/
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_arc_fr_smry_cbg', 'Stored Procedure', 'Inprogress', v_start_time);


begin
truncate table mktg_stage_tbls.gms_arc_fr_smry_cbg_stg;

insert into mktg_stage_tbls.gms_arc_fr_smry_cbg_stg
select 
	    cnst_mstr_id, 
	    max(case when  gift_year = extract(year from CURRENT_DATE)  then dntn_gift_dt else null end) as cbg_eligblty_cym0_dt,
	    max(case when gift_year =  (extract(year from CURRENT_DATE) -1) then dntn_gift_dt else null end) as cbg_eligblty_cym1_dt,
	    max(case when gift_year =  (extract(year from CURRENT_DATE) -2) then dntn_gift_dt else null end) as cbg_eligblty_cym2_dt
	from (
		with cte as (
		select  
		  cnst_mstr_id,
		  dntn_gift_dt,												
		  gift_year,
		  row_number() over (partition by cnst_mstr_id, gift_year order by dntn_gift_dt,cumul_sum) as rn
		from 
		(
			select cnst_mstr_id,  dntn_gift_dt, extract(year from dntn_gift_dt) as gift_year, fr_pmt_amt, 
		    /*the below function gives the cumulative sum grouped by the cnst_mstr_id and gift_year */ 
		    sum(fr_pmt_amt) over (partition by cnst_mstr_id, gift_year order by dntn_gift_dt rows unbounded preceding ) as cumul_sum
		    	from mktg_ops_tbls.gms_arc_fr_txn 
		        where gift_year between  (extract(year from CURRENT_DATE) -2) and  extract(year from CURRENT_DATE)   /*the filter is required to limit the number of records to 3 cys */
		                                                
		) cumul_query                                                                
		 where /*this check is to get all the cumulative records where the cumulative sum was >=5000 */ 
		 cumul_query.cumul_sum>=5000  /*the qualify statement ensures that the first cumulative records with cumulative sum >=5000 is returned */ 
	  )
	
	select cnst_mstr_id,dntn_gift_dt, gift_year from cte where rn=1
	
	)
	group by 1;


truncate table mktg_ops_tbls.gms_arc_fr_smry_cbg;

insert into mktg_ops_tbls.gms_arc_fr_smry_cbg select * from  mktg_stage_tbls.gms_arc_fr_smry_cbg_stg; 


	
	--audit update	
	v_end_time := GETDATE();
	v_ok_message = cast((select count(*) from mktg_ops_tbls.gms_arc_fr_smry_cbg) as nvarchar)+ ' Records inserted.';
        UPDATE mods_bi.etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_gms_arc_fr_smry_cbg' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_gms_arc_fr_smry_cbg', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
