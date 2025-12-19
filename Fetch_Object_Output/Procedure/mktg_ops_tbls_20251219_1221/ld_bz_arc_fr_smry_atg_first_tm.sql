CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bz_arc_fr_smry_atg_first_tm()
 LANGUAGE plpgsql
AS $$
/*
Created by: Majeed Mohammad
Created on:  12/08/2015
Purpose: This macro instantiates the table mktg_ops_tbls.bz_cnst_cdi_smry_fr_atg using the view mktg_ops_vws.cnst_cdi_smry_fr_atg_src 


Modified by: Majeed Mohammad
Modified on: 05/10/2016
Purpose: Updated the macro to used the updated view. The view was updated to add the nk_order_id, cnst first, last name, em_cnst_data_src_cd 
*/

/* Below comment is for the teradata view mktg_ops_vws.arc_fr_smry_atg_first_tm_src which has been now incorporated in this stored procedure */

/*Created by: Majeed Mohammad
Created on: 12/7/2015
Purpose: This view gets the first time donation date for the ATG donors in the FR Pref Profile. The ATG donoros have the source codes ATG and ATGO in the 
bridge tables 

Modified by: Majeed Mohammad
Modified on: 12/7/2015
Purpose: Added the filter to get the records with a Non-Null transaction date 

Modified by: Majeed Mohammad
Modified on: 01/05/2016
Purpose: Renamed the view 

Modified by: Majeed Mohammad
Modified on: 01/06/2016
Purpose: Removed the union for the ATG transactions. Only included the ATGO transactions. 
Reason: Eric thinks the Convio interface uses the billing information from ATG.  If this is true, then will need to modify the view you create to limit the selection to the 'ATGO' source code when linking to the bridge to get the master.  

Modified by: Michael Andrien
Modified on: 05/09/2016
Purpose:  Replaced the join to the arc_mdm_vws external master bridge table with the special atgo bzl view created by the ADM team to include all the ATGO order billing constituents in the bridge table.

Modified by: Majeed Mohammad
Modified on: 05/10/2016
Purpose: Updated the view based on the updates made by Mike for the SELECT. Added the nk_order_id, cnst first, last name, em_cnst_data_src_cd 

Modified by: Michael Andrien
Modified on: 09/06/2017
Purpose:  Added the trans_dt >= '01/01/2016' qualifier to address spool issues.  NOTE: I removed the constraint on 9/6/17

Modified by: Michael Andrien
Modified on: 04/27/2020
Purpose: Changed the FR Preferred join to the GMS view.
*/
/* Latest Query to return ATG First time transactions */
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bz_arc_fr_smry_atg_first_tm', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN 
		TRUNCATE TABLE mktg_stage_tbls.bz_arc_fr_smry_atg_first_tm_stg;
		
		INSERT INTO mktg_stage_tbls.bz_arc_fr_smry_atg_first_tm_stg 
		WITH ranked_data AS (
		SELECT 
			c.cnst_mstr_id AS cnst_mstr_id,
			b.nk_order_id AS nk_order_id, 
			CAST(trans_dt AS DATE) AS first_time_trans_dt, 
			--a.trans_dt, 
			b.email AS cnvo_email, 
			b.bill_to_first_nm AS cnvo_bill_to_first_nm, 
			b.bill_to_last_nm AS cnvo_bill_to_last_nm,
			d.em_cnst_data_src_cd,
			d.em_cnst_email,
			ROW_NUMBER() OVER (PARTITION BY a.order_id ORDER BY trans_dt) AS rn
		FROM eda.atg_vws.dim_order_billing b
		LEFT JOIN eda.atg_vws.fact_atg_order_line a ON a.order_id = b.nk_order_id
		LEFT JOIN eda.arc_mdm_vws.bzl_cnst_mstr_atgo c ON c.nk_order_id = a.order_id   
		LEFT JOIN mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr d ON d.cnst_mstr_id = c.cnst_mstr_id
		/*  
		Added the arc_fr_smry join so we can compare the ATG trans date to the first donation date in the N=Mktg FR summary profile.  Since the intent is to capture the first time donation
		before the ATG gift has been processed through Team Approach and into the DW, we expect the summary record to be NULL or at best equal to the incoming ATG trans date.  This
		additional join was added becuase we discovered ATG order line records marked as first time when in fact we have earlier transactions/gifts in the DW for the constituent.  This is one of
		two checks we added to the query to ensure we pull the correct records.
		*/
		LEFT JOIN mktg_ops_tbls.gms_arc_fr_smry e ON d.cnst_mstr_id = e.cnst_mstr_id
		LEFT JOIN (
			/*
			This join addresses an ATG Billing Account issue that where multiple accounts are created for billing records that have mixed cases in the email address. ATG transactions are
			being marked as 'first time' transactions becuase the system thinks it's the first time it's seen the email account. For example, transaction 1 on Jan 1 2015 with email andrienm@gmail is 
			marked as a first time txn.  On Dec 1 2015 transaction 2 is recorded for AndrienM@GMAIL.com and is also marked as a first time donation when it shouldn't.  The select below sets
			the email address to uppercase and gets the lowest trans date for the email. This is compared to the trans date for the transactions marked as 'First Time' - if the dates don't match, then the 
			record is excluded from the selection.
			*/
			SELECT 
				UPPER(a.email) AS email, 
				MIN(CAST(trans_dt AS DATE)) AS first_trans_dt
			FROM eda.atg_vws.dim_order_billing a
			LEFT JOIN eda.atg_vws.fact_atg_order_line b ON a.nk_order_id = b.order_id
			GROUP BY 1
		) f ON b.email = f.email
		WHERE a.trans_dt IS NOT NULL  
			AND a.first_time_ind = 1
			AND a.trans_typ_key = 1
			AND a.refund_ind = 0
			AND CAST(a.trans_dt AS DATE) = f.first_trans_dt -- This qualifier is to make sure the ATG trans date is equal to the minimum trans dt we see for the email address. 
			AND (e.fr_fst_dntn_dt IS NULL OR e.fr_fst_dntn_dt = CAST(a.trans_dt AS DATE))
			--and cast(a.trans_dt as date format 'mm/dd/yyyy') >= '01/01/2016'  -- MTA removed temp time constraint 9/6/17
			/* MM - Need to replace with this. This works faster than the OR . 
			and (cast(coalesce(e.fr_fst_dntn_dt,a.trans_dt) as date format 'mm/dd/yyyy') = cast(a.trans_dt as date format 'mm/dd/yyyy'))
			*/
			--and cast(trans_dt as date format 'mm/dd/yyyy') between  '03/01/2016' and  '03/01/2016'  -- This line was used for test purpose to test one day's first time records
		)
		SELECT 
			cnst_mstr_id,
			nk_order_id, 
			first_time_trans_dt, 
			cnvo_email, 
			cnvo_bill_to_first_nm, 
			cnvo_bill_to_last_nm,
			em_cnst_data_src_cd,
			em_cnst_email
		FROM ranked_data
		WHERE rn = 1;
		
		Truncate table mktg_ops_tbls.bz_arc_fr_smry_atg_first_tm;
		
		-- Insert data from staging to target
        INSERT INTO mktg_ops_tbls.bz_arc_fr_smry_atg_first_tm
        SELECT * FROM mktg_stage_tbls.bz_arc_fr_smry_atg_first_tm_stg;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_ops_tbls.bz_arc_fr_smry_atg_first_tm) as INTEGER)
        WHERE proc_name = 'ld_bz_arc_fr_smry_atg_first_tm' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_bz_arc_fr_smry_atg_first_tm: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_bz_arc_fr_smry_atg_first_tm', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
