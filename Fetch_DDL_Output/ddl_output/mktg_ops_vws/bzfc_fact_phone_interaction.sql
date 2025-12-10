CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fact_phone_interaction (cnst_mstr_id, orig_cnst_mstr_id, campgn_key, script_key, dspstn_key, adtnl_reqst_key, unit_key, orig_unit_key, call_trans_key, src_key, unq_id, cmpgn_cd, scrpt_num, dspstn_id, dspstn1_cd, dspstn2_cd, addi_rqst_cd, nk_ecode, pgm_type, sgmnt_dsc, fiscal_yr, qtr, src_cd, home_phn_num_cln, mbl_phn_num_cln, phn_line_typ, call_dt, call_start_ts, call_end_ts, elapsed_call_tm, cmpgn_call_atmpt_cnt, gift_amt, pledge_amt, phone_change_ind, addr_change_ind, name_change_ind, email_change_ind, is_cell_ind, call_seqnc_num, scr1_id, scr1_val, scr2_id, scr2_val, scr3_id, scr3_val, decile, cmnt, curr_prcsd_file_nm, dw_trans_ts, row_stat_cd, appl_src_cd, load_id) AS

/*
Created By:	Michael Andrien
Created Date:	06/30/2023
Purpose:  This view captures telerecruitment results.  We receive weekly campaign files current vendor MDS as well as an end of campaign (EOC) for each
telerecruitment campaign.  The weekly files are limited to the completed calls for the week whereas the EOC file contains one row for every constituent included
in the campaign.  The EOC file can contain call attempt rows for completed calls we receive in the weekly file.  We attempt to account for these duplicates and limit the
view to the final call result row.  We have noticed we can receive more than one final call row for a constituent - one for each phone number contacted.  This may be more than one
landline and more than one cell or a combination of cell and landline.  The view contains one row for the final call status for each unique phone line contacted.

Modidfied By: Michael Andrien
Modified Date: 07/13/2023
Purpose: Converted the view to point to the new physical table create by the newly created macro ld_bzfc_fact_phone_interaction.

Modidfied By: Michael Andrien
Modified Date: 07/14/2023
Purpose:  Added the call_trans_key attribute and fixed some missing comma issues from the 7/13 update.

Modidfied By: Michael Andrien
Modified Date: 08/03/2023
Purpose: Added the scr3_val, scr1_id, scr1_val, scr2_id, scr2_val, scr3_id attributes to the table.

Modidfied By: Michael Andrien
Modified Date: 01/31/2024
Purpose: Added the pgm_type and sgmnt_dsc to the view.

Modidfied By: Michael Andrien
Modified Date: 07/25/2024
Purpose: Added the join to mktg_ops_vws.gmpbzal_dim_src to pull src_key into the view.

Modidfied By: Michael Andrien
Modified Date: 10/22/2024
Purpose: Added cmnt (comment) and decile attributes to the view

Modidfied By: Michael Andrien
Modified Date: 07/16/2025
Purpose: Added the WHERE a.row_stat_cd <> 'L' logic to the view
*/
SELECT
/* Dimension Surrogate Keys */
    cnst_mstr_id, orig_cnst_mstr_id, campgn_key, script_key, dspstn_key, adtnl_reqst_key, unit_key, orig_unit_key, call_trans_key, e.src_key,
    /*
    Dimension,
    Natural Keys/ids
    */
    unq_id, cmpgn_cd, scrpt_num, dspstn_id, dspstn1_cd, dspstn2_cd, addi_rqst_cd, nk_ecode, pgm_type, sgmnt_dsc,
    /* Call Campaign Time Period */
    fiscal_yr, qtr, a.src_cd, /* Campaign Source Code */ home_phn_num_cln, mbl_phn_num_cln, phn_line_typ, call_dt, call_start_ts, call_end_ts, elapsed_call_tm, cmpgn_call_atmpt_cnt, gift_amt, pledge_amt, phone_change_ind, addr_change_ind, name_change_ind, email_change_ind, is_cell_ind, call_seqnc_num, scr1_id, scr1_val, scr2_id, scr2_val, scr3_id, scr3_val, decile, cmnt, curr_prcsd_file_nm, dw_trans_ts, row_stat_cd, appl_src_cd, load_id
FROM mktg_ops_tbls.bzfc_fact_phone_interaction AS a
LEFT OUTER JOIN 
(
	SELECT
        src_key, src_cd
    FROM mktg_ops_vws.gmpbzal_dim_src AS gmpbzal_dim_src
    QUALIFY row_number() OVER (PARTITION BY src_cd ORDER BY src_key DESC NULLS LAST) = 1
) AS e (src_key, src_cd) ON a.src_cd = e.src_cd
WHERE a.row_stat_cd <> 'L'
WITH NO SCHEMA BINDING

;