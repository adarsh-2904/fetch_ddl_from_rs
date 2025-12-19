CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_pg_src_convrsn()
 LANGUAGE plpgsql
AS $$

/*
Modified By: Michael Andrien
Modified Date: 	08/23/2021
Purpose:	This macro was created insert new records into the PG Source Code Conversion table (mktg_ops_tbls.pg_src_convrsn).  The to translate the PG Source Code Conversion table was originally created
to correct old PG direct mail source codes that were entered incorrectly into the gift processing system and could not be corrected in the gifrt system.  The coversion table is referenced in the mktg_ops_vws.gmpbzal_dim_src view and feeds the PG  source code attributes in the view.
The original record entries were loaded from a spreadsheet provided by the GPLG program.  This macro adds additional rows for PG DM campaigns starting in FY22.  
*/
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_pg_src_convrsn', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN
		truncate table mktg_stage_tbls.pg_src_convrsn_stg;
		
		insert into mktg_stage_tbls.pg_src_convrsn_stg
		with gmpbzal_dim_src as (
			
			select src_cd, src_dsc
			from (
				select  src_cd, src_dsc,row_number() over(partition by src_cd order by active_ind desc, src_key desc) as rn  
				from mktg_ops_vws.gmpbzal_dim_src
			) as subqry
			
			where subqry.rn = 1
			
		
		)

		select
			distinct
		    dmi.motivtn_cd orig_src_cd,
		    msrc.src_dsc orig_src_dsc,
		    dmi.src_cd new_src_cd,
		    csrc.src_dsc new_src_dsc
		from mktg_ops_vws.bzfc_fact_dmail_intrctn_norm dmi
		left join gmpbzal_dim_src msrc on dmi.motivtn_cd = msrc.src_cd
		left join gmpbzal_dim_src csrc on dmi.src_cd = csrc.src_cd
		left join mktg_ops_vws.bz_dim_campgn cmp on dmi.campaign_key = cmp.campgn_key
		where cmp.campgn_lob_nm = 'Planned Giving'
		    and cmp.campgn_channel_nm = 'Direct Mail'
		    and SUBSTRING(dmi.motivtn_cd,9,3) <> 'M00'
		    and dmi.motivtn_cd <> dmi.src_cd
			and dmi.motivtn_cd not in (select distinct orig_src_cd from mktg_ops_tbls.pg_src_convrsn);

		
		truncate table mktg_ops_tbls.pg_src_convrsn;

		insert into mktg_ops_tbls.pg_src_convrsn select * from mktg_stage_tbls.pg_src_convrsn_stg;

		----audit update-----
        v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE mods_bi.etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.pg_src_convrsn) as INTEGER)
        WHERE proc_name = 'ld_pg_src_convrsn' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_pg_src_convrsn: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_pg_src_convrsn', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
