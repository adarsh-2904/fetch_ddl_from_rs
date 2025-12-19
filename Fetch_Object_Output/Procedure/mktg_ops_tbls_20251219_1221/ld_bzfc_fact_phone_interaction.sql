CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_fact_phone_interaction()
 LANGUAGE plpgsql
AS $$
/*
Modidfied By: Michael Andrien
Modified Date: 07/13/2023
Purpose: This macro captures telerecruitment results. We receive weekly campaign files current vendor MDS as well as an end of campaign (EOC) for each
telerecruitment campaign. The weekly files are limited to the completed calls for the week whereas the EOC file contains one row for every constituent included
in the campaign. The EOC file can contain call attempt rows for completed calls we receive in the weekly file. We attempt to account for these duplicates and limit the
view to the final call result row. We have noticed we can receive more than one final call row for a constituent - one for each phone number contacted. There may be more than one
landline and more than one cell or a combination of cell and landline. The table contains one row for the final call status for each unique phone line contacted.

Modidfied By: Michael Andrien
Modified Date: 07/14/2023
Purpose: Added the call_trans_id to provide a unique transaction id for reporting. Note, since the macro is a truncate and load process, the call_trans_id value will change with each
daily load. The MODS reporting team requested this attribute and is aware of this approach.

Modidfied By: Michael Andrien
Modified Date: 08/02/2023
Purpose: Added the scr3_val, scr1_id, scr1_val, scr2_id, scr2_val, scr3_id attributes to the table.

Modidfied By: Michael Andrien
Modified Date: 08/14/2023
Purpose: changed the dim_phone_campgn and dim_phone_script joins from the mktg_tbls to mktg_ops_vws because the approach for managing the dimension keys changed to being added as a
row number in the view def.

Modidfied By: Michael Andrien
Modified Date: 08/15/2023
Purpose: Added the campaign code update statements for the EOC table to ensure the improperly coded campaign code is updated prior to loading the bzfc_fact_phone_interaction table.

Modidfied By: Michael Andrien
Modified Date: 08/17/2023
Purpose: Added the qualify statement below to the insert query to eliminate duplicate records.

Modidfied By: Michael Andrien
Modified Date: 09/20/2023
Purpose: Added the 'ARC2409SIA' campaign code updates below to align bad response data with the proper campaign code.

Modidfied By: Michael Andrien
Modified Date: 01/31/2024
Purpose: Added the pgm_type and sgmnt_dsc attributes from the phone_interaction_eoc to the table.

Modified By: Greg Seaberg
Implemented By: Michael Andrien
Modified Date: 10/22/2024
Purpose: Modified join to bz_dim_phone_call_dspstn to include coalesce(dspstn2_cd,'') to both tables in the join conditions.  Also, added the cmnt and decile attributes 
to the table.
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
	
	v_increment_ts TIMESTAMP;
    v_appl_src_cd VARCHAR(4);
    v_dw_load_id INT;
    v_next_extract_ts TIMESTAMP;

    v_inserted_count INT := 0;
	v_updated_count1 INT := 0;
	v_updated_count2 INT := 0;
	v_updated_count3 INT := 0;

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_fact_phone_interaction', 'Stored Procedure', 'Inprogress', v_start_time);
	
	SELECT MAX(load_id)+1--modified to dw_trans_ts from tslastmodified
    INTO v_dw_load_id
    FROM mktg_ops_tbls.bzfc_fact_phone_interaction;

-- Update campaign codes
UPDATE mktg_ops_tbls.phone_interaction_eoc
SET cmpgn_cd = 'ARC2305SIA'
WHERE cmpgn_cd = 'ARC2305SI';
GET DIAGNOSTICS v_updated_count1 = ROW_COUNT;

UPDATE mktg_ops_tbls.phone_interaction_eoc
SET cmpgn_cd = 'ARC0523DMS'
WHERE cmpgn_cd = 'ARC0523DM';
GET DIAGNOSTICS v_updated_count2 = ROW_COUNT;

UPDATE mktg_ops_tbls.phone_interaction_eoc
SET cmpgn_cd = 'ARC2409SIA'
WHERE cmpgn_cd = 'ARC2409SI';
GET DIAGNOSTICS v_updated_count3 = ROW_COUNT;

-- Truncate existing data in fact table
TRUNCATE TABLE mktg_ops_tbls.bzfc_fact_phone_interaction;

INSERT INTO mktg_ops_tbls.bzfc_fact_phone_interaction
SELECT *
FROM (
    SELECT
        -- Dimension Surrogate Keys
        a.cnst_mstr_id,
        a.orig_cnst_mstr_id,
        b.campgn_key,
        c.script_key,
        d.dspstn_key,
        COALESCE(e.adtnl_reqst_key, 0) AS adtnl_reqst_key,
        um.unit_key,
        um.orig_unit_key,

        ROW_NUMBER() OVER (ORDER BY a.cnst_mstr_id, a.call_dt) AS call_trans_key,

        -- Dimension Natural Keys/IDs
        a.unq_id,
        a.cmpgn_cd,
        a.scrpt_num,
        a.dspstn_id,
        a.dspstn1 AS dspstn1_cd,
        a.dspstn2 AS dspstn2_cd,
        a.addi_rqst AS addi_rqst_cd,
        a.nk_ecode,
        a.pgm_type,
        a.sgmnt_dsc,

        -- Call Campaign Time Period
        a.fiscal_yr,
        a.qtr,
        a.src_cd,
        a.home_phn_num_cln,
        a.mbl_phn_num_cln,
        a.phn_chng_type AS phn_line_typ,
        a.call_dt,
        a.call_start_ts,
        a.call_end_ts,
        a.elapsed_call_tm,
        a.cmpgn_call_atmpt_cnt,
        COALESCE(a.gift_amt, 0) AS gift_amt,
        COALESCE(a.pledge_amt, 0) AS pledge_amt,

        CASE WHEN a.phn_chng_flg = 'Y' THEN 1 ELSE 0 END AS phone_change_ind,
        CASE WHEN a.addr_chng_flg = 'Y' THEN 1 ELSE 0 END AS addr_change_ind,
        CASE WHEN a.nm_chng_flg = 'Y' THEN 1 ELSE 0 END AS name_change_ind,
        CASE WHEN a.email_chng_flg = 'Y' THEN 1 ELSE 0 END AS email_change_ind,
        CASE WHEN a.is_cell_flg = 'Y' THEN 1 ELSE 0 END AS is_cell_ind,

        ROW_NUMBER() OVER (
            PARTITION BY a.orig_cnst_mstr_id, b.campgn_key
            ORDER BY d.is_cmplt_ind DESC, d.is_fnl_ind DESC, a.cmpgn_call_atmpt_cnt DESC
        ) AS rn,

        a.scr1_id, a.scr1_val,
        a.scr2_id, a.scr2_val,
        a.scr3_id, a.scr3_val,
        CAST(a.decile AS SMALLINT) AS decile,
        a.cmnt,
        a.curr_prcsd_file_nm,
        a.dw_trans_ts,
        'I' AS row_stat_cd,
        'MDS' AS appl_src_cd,
        v_dw_load_id AS load_id

    FROM mktg_ops_vws.phone_interaction_eoc a
    LEFT JOIN mktg_ops_vws.bz_dim_phone_campgn b 
        ON a.cmpgn_cd = b.campgn_cd
    LEFT JOIN mktg_ops_vws.bz_dim_phone_script c 
        ON a.scrpt_num = c.script_num
    LEFT JOIN mktg_ops_tbls.dim_phone_call_dspstn d 
        ON COALESCE(a.dspstn1, '') = d.dspstn1_cd 
       AND COALESCE(a.dspstn2, '') = COALESCE(d.dspstn2_cd, '')
    LEFT JOIN mktg_ops_tbls.dim_phone_adtnl_reqst e 
        ON a.addi_rqst = e.adtnl_reqst_cd
    LEFT JOIN mktg_ops_vws.dim_unit_merged um 
        ON a.nk_ecode = um.orig_nk_ecode
) sub
WHERE rn = 1;

-- Capture number of rows inserted
    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
--audit update	
			v_end_time := GETDATE();
            v_ok_message := '';
			
		UPDATE mods_bi.etl_config.audit_log
       	SET 
           status = 'Complete',
           end_time = v_end_time,
           TaskMessage = v_ok_message,
           recs_processed = v_inserted_count
       WHERE 
           proc_name = 'ld_bzfc_fact_phone_interaction' 
           AND task_name = 'Stored Procedure' 
           AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bzfc_fact_phone_interaction', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

			
    END;
$$
