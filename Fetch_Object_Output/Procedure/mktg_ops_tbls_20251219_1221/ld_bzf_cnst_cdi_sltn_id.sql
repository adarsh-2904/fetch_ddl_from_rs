CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzf_cnst_cdi_sltn_id()
 LANGUAGE plpgsql
AS $$
	/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael J. Hall
Created date: 10/28/2014
Purpose: This macro loads Primary and Secondary Name ID data for Individual constituents 
                (e.g., Mr. and Mrs.) into the bzf_cnst_cdi_sltn_id table.  SQL query extracts the primary 
                and secondary name keys and ID's Into a denormalized, flattened record for joining later 
                to the CDI Preferred profile table on Constituent Master Id.  Ultimate goal is to enable 
                secondary name information to appear on the CDI FR Preferred Profile (i.e., spouse).
                Min function logic was added to solve the issue of two different TA accounts belonging 
                to the     same master account. It takes the minimum (first) name ID and finds the lowest row by 
                master constituent ID, thus removing the potential for the same person to appear twice on an 
                account.  It aligns the primary and secondary name at the TA account level.
 Change History:
                 - (11/04/2014, MJH): Updated to remove potential duplicate constituent records that result 
                when multiple constituents reside under a single FSA account.  New process separates the
                duplicate constituent rows from the and the non-duplicates, then proceeds to pick 
                the row with the latest matching gift transaction in the ARC FR Summary table based on 
                matching TA account ID.
                If no matching gift transaction row is found, it proceeds to partition and boil down the 
                remaining duplicate rows by primary name constituent master ID, latest TA account ID.
                In the end it joins all the volatile tables together to create a single table with no 
                duplicate rows.  The final deduped table is then transferred over to the 2580 server.
---------------------------------------------------------------------------------------------------------------------------- */
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzf_cnst_cdi_sltn_id', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
					
			truncate table	mktg_ops_tbls.bzf_cnst_cdi_sltn_id;

			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id
			SELECT
			*
			FROM 
			(
						
						SELECT 
			                cnst_mstr_id,
			                nk_ta_acct_id,
			                nk_ta_nm_id
			                from(
				                		 SELECT 
				                a.cnst_mstr_id,
				                a.nk_ta_acct_id,
				                MIN(a.nk_ta_nm_id) as nk_ta_nm_id, -- Added to take the first name Id
				                ROW_NUMBER() OVER (PARTITION BY a.nk_ta_acct_id 
								ORDER BY MIN(a.nk_ta_nm_id) ASC) as rn
				                FROM  eda.arc_mdm_vws.bzl_cnst_mstr_fsa_in a
				                LEFT JOIN ddcoe_vws.bz_cnst_fsa b 
								ON a.bzd_cnst_fsa_key = b.cnst_fsa_key
							                WHERE  b.cnst_typ_cd = 'IN' -- Individual accounts only
								AND b.act_ind = 1 -- Active accounts only
								AND a.nk_ta_nm_id <> 0 -- Name Id must > 0
								AND a.bzd_acct_fsa_key IS NOT NULL -- Non-null FSA accts only
							                GROUP BY  -- Added to condense like accts, thus         
											a.cnst_mstr_id, -- addressing potential duplicates at the CDI master cnst ID level
							                a.nk_ta_acct_id
							                
			                ) as subqry
			                where subqry.rn=1
			               
			                
			) a(cnst_mstr_id, nk_ta_acct_id, nk_ta_nm_id) -- and select the primary one
			LEFT JOIN
			(
						SELECT 
			                cnst_mstr_id,
			                nk_ta_acct_id,
			   				nk_ta_nm_id
			   				from(
			   					 SELECT 
					                a.cnst_mstr_id,
					                a.nk_ta_acct_id,
					   				MIN(a.nk_ta_nm_id) as nk_ta_nm_id, -- Added to take the first name Id
					                ROW_NUMBER() OVER (PARTITION BY a.nk_ta_acct_id 
									ORDER BY  MIN(a.nk_ta_nm_id) ASC) as rn
					   				FROM  eda.arc_mdm_vws.bzl_cnst_mstr_fsa_in a
					                LEFT JOIN ddcoe_vws.bz_cnst_fsa b 
									ON a.bzd_cnst_fsa_key = b.cnst_fsa_key
								                WHERE  b.cnst_typ_cd = 'IN'  -- Individual accounts only
									AND b.act_ind = 1  -- Active accounts only
									AND a.nk_ta_nm_id <> 0  -- Name Id must > 0
									AND a.bzd_acct_fsa_key IS NOT NULL -- Non-null FSA accts only
												GROUP BY  -- Added to condense like accts         
												a.cnst_mstr_id,
								                a.nk_ta_acct_id
			   				
			   				) as subqry
			           
			   				where subqry.rn=2
			
			) b(cnst_mstr_id2, nk_ta_acct_id2, nk_ta_nm_id2) -- and select the secondary one
				ON a.nk_ta_acct_id = b.nk_ta_acct_id2
				WHERE b.nk_ta_acct_id2 IS NOT NULL -- Choose rows where secondary name acct exists
			;
			
			--=== Run deduplication processing ==============================
			
			-- Populate table #1 containing the rows that are duplicates:
			truncate table mktg_ops_tbls.bzf_cnst_cdi_sltn_id_1;
			
			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id_1
			SELECT *
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id 
			WHERE pn_cnst_mstr_id IN
			(SELECT pn_cnst_mstr_id 
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id 
			GROUP BY pn_cnst_mstr_id
			HAVING COUNT(pn_cnst_mstr_id) > 1 ) 
			;
			
			 --=====================================================================
			-- Populate table #2 containing non-duplicate rows:
			truncate table	mktg_ops_tbls.bzf_cnst_cdi_sltn_id_2;
			
			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id_2
			SELECT *
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id 
			WHERE pn_cnst_mstr_id IN
			(SELECT pn_cnst_mstr_id 
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id 
			GROUP BY pn_cnst_mstr_id
			HAVING COUNT(pn_cnst_mstr_id) = 1 ) 
			;
			
			 --=====================================================================
			-- Populate table #3 containing duplicate rows that have a matching 
			-- gift transaction row:
			truncate table	mktg_ops_tbls.bzf_cnst_cdi_sltn_id_3;
			
			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id_3
			SELECT  a.*
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id_1 a
			INNER JOIN mktg_ops_tbls.gms_arc_fr_smry b 
			ON (a.pn_cnst_mstr_id = b.cnst_mstr_id) AND
			      (a.pn_nk_ta_acct_id = b.fr_last_ta_acct_id)
			;
			
			
			 --=====================================================================
			-- Populate table #4 containing duplicate rows that  do not have a matching 
			-- gift transaction row:
			truncate table	mktg_ops_tbls.bzf_cnst_cdi_sltn_id_4;
			
			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id_4
			SELECT   *
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id_1 a -- all dupes
			WHERE a.pn_cnst_mstr_id NOT IN (
			SELECT pn_cnst_mstr_id 
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id_3 -- matching gift trans table
			) 
			;
			
			 --=====================================================================
			-- Populate table #5 containing duplicate rows with no matching gift trans row,
			-- where table is partitioned and boiled down to a single distinct row:
			truncate table	mktg_ops_tbls.bzf_cnst_cdi_sltn_id_5;
			
			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id_5
			
			SELECT pn_cnst_mstr_id,
			       pn_nk_ta_acct_id,
			       pn_nk_ta_nm_id,
			       sn_cnst_mstr_id,
			       sn_nk_ta_acct_id,
			       sn_nk_ta_nm_id
			from (
					SELECT pn_cnst_mstr_id,
			       pn_nk_ta_acct_id,
			       pn_nk_ta_nm_id,
			       sn_cnst_mstr_id,
			       sn_nk_ta_acct_id,
			       sn_nk_ta_nm_id,
				   ROW_NUMBER() OVER (PARTITION BY pn_cnst_mstr_id 
					ORDER BY pn_cnst_mstr_id, pn_nk_ta_acct_id DESC) as rn
					FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id_4 
			
				) as subqry
				
				where subqry.rn=1
			
			;
			
			
			--=====================================================================
			-- Create a  final composite table of all deduped rows joined together:
			truncate table mktg_ops_tbls.bzf_cnst_cdi_sltn_id_all;
			
			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id_all
			SELECT * 
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id_2 -- no dupes table
			UNION ALL
			SELECT * 
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id_3 -- dupes with a matching gift trans row
			UNION ALL
			SELECT * 
			FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id_5 -- dupes with no matching gift trans row,
			;                                                                            -- boiled down to one row
			
			 --=====================================================================
			-- Copy original table to a backup table
			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id_bk
			SELECT * FROM mktg_ops_tbls.bzf_cnst_cdi_sltn_id;
			
			-- Delete rows from the original table
			truncate table mktg_ops_tbls.bzf_cnst_cdi_sltn_id;
			
			-- Insert deduped rows back into the original table
			INSERT INTO mktg_ops_tbls.bzf_cnst_cdi_sltn_id
			SELECT * FROM  mktg_ops_tbls.bzf_cnst_cdi_sltn_id_all;




		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bzf_cnst_cdi_sltn_id) as INTEGER)
			WHERE proc_name = 'ld_bzf_cnst_cdi_sltn_id' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bzf_cnst_cdi_sltn_id', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
