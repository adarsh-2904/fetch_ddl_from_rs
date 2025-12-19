CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dim_dm_src_treatmnt_xref()
 LANGUAGE plpgsql
AS $$
	/*
	Created By: Michael Andrien
	Create Date: 01/08/2024
	Purpose:  This macro was created as part of an automated process to load and maintain the direct mail  (DM)
	source code to treatment code and description cross reference table.  The macro reads the campaign history tables
	(dm_campaign_hist and dm_campaign_pg_hist) maintained in the mktg_data_tbls database.  These tables
	capture the DM return file information profided by our DM vendors.  We created the cross reference table 
	because the treatment id attribute maintained in the DM fact interaction reporting tables is reused across
	DM campaigns.  The cross refernce table enables the team to reflect the treatment description used for a given
	DM campaign source code.  Our current campaign dimention (dim_campaign) reflects the current treatment description associated 
	with a treatment id.

*/
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dim_dm_src_treatmnt_xref', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
			truncate table mktg_stage_tbls.dim_dm_src_treatmnt_xref_stg;
			
			/* Now reloaded the latest treatment data */
			INSERT INTO mktg_stage_tbls.dim_dm_src_treatmnt_xref_stg
			SELECT DISTINCT
				b.src_key, 
				aprm_src_cd as src_cd, 
				cast(NULL as VARCHAR(14)) as pg_src_cd, 
				di.nk_treatmnt_id as treatmnt_id, 
				treatmnt_cd,
				treatmnt_dsc, 
				current_timestamp(0) as dw_trans_ts, 
				'I' as row_stat_cd,
				'ENGR' as appl_src_cd,
				c.load_id + 1 as load_id
			FROM mktg_ops_tbls.dm_campaign_hist a
			LEFT JOIN mktg_ops_vws.bzfc_fact_dmail_interaction di on a.orig_cnst_mstr_id = di.orig_cnst_mstr_id and a.aprm_src_cd = di.src_cd
			LEFT JOIN 
			(	SELECT src_key, src_cd
				from(
					SELECT src_key, src_cd,ROW_NUMBER() OVER ( PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) as rn
					FROM mktg_ops_vws.gmpbzal_dim_src 
				) as subqry
				
				where subqry.rn=1
				
				
			) b (src_key, src_cd) on a.aprm_src_cd = b.src_cd
			LEFT JOIN 
			(
				select coalesce(max(load_id),0)
				from mktg_ops_tbls.dim_dm_src_treatmnt_xref
			) c (load_id) on 1=1
			WHERE SUBSTRING(aprm_src_cd,1,3) in ('RQA', 'RQS', 'RQC') AND b.src_key IS NOT NULL
			
			UNION ALL
			
			SELECT DISTINCT
				b.src_key as src_key, 
				cell_src_cd as src_cd , 
				coalesce(c.new_src_cd, 
				a.cell_src_cd) as pg_src_cd, 
				a.treatment_id as treatmnt_id, 
				treatment_cd AS treatmnt_cd,
				treatment_dsc AS treatmnt_dsc, 
				current_timestamp(0) as dw_trans_ts, 
				'I' as row_stat_cd,
				'ENGR' as appl_src_cd,
				d.load_id + 1 as load_id
			FROM mktg_ops_tbls.dm_campaign_pg_hist a
			LEFT JOIN 
			(	
				SELECT src_key, src_cd
			    from(
				    SELECT src_key, src_cd,ROW_NUMBER() OVER ( PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC)  as rn
					FROM mktg_ops_vws.gmpbzal_dim_src 
			    ) as subqry
			    
			    where subqry.rn=1
				
				
			) b (src_key, src_cd) on a.cell_src_cd = b.src_cd
			LEFT JOIN mktg_ops_vws.bz_pg_src_convrsn c ON b.src_cd = c.orig_src_cd
			LEFT JOIN 
			(
				select coalesce(max(load_id),0)
				from mktg_ops_tbls.dim_dm_src_treatmnt_xref
			) d (load_id) on 1=1
			WHERE b.src_key IS NOT NULL;
			
			truncate table mktg_ops_tbls.dim_dm_src_treatmnt_xref;
			
			insert into mktg_ops_tbls.dim_dm_src_treatmnt_xref select * from mktg_stage_tbls.dim_dm_src_treatmnt_xref_stg;




		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.dim_dm_src_treatmnt_xref) as INTEGER)
			WHERE proc_name = 'ld_dim_dm_src_treatmnt_xref' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_dim_dm_src_treatmnt_xref', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
