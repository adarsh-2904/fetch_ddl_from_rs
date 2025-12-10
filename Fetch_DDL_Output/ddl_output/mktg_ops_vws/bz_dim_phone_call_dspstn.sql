CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_phone_call_dspstn AS

/*
Created By: Michael Andrien
Create Date: 06/27/2023
Purpose: 	This dimension joins to the mktg_ops_vws.bzfc_fact_phone_interaction table and captures call disposition for phone campaign call activity.

Modified By: Michael Andrien
Modified Date: 07/06/2023
Purpose:  Added the dspstn_ctg_cd and dspstn_ctg_dsc attributes
*/
SELECT
    dspstn_key, dspstn_id, dspstn1_cd, dspstn2_cd, dspstn_dsc, dspstn_ctg_cd, dspstn_ctg_dsc, is_std_ind, is_actv_ind, is_cmplt_ind, is_gift_ind, is_no_ind, is_rght_prty_cntct_ind, 	is_sys_wrng_num_ind, is_agnt_wrng_num_ind, is_callbl_ind, is_fnl_ind, is_sys_ind, is_elctrnc_pmt_ind, is_agnt_hndld_ind
FROM mktg_ops_tbls.dim_phone_call_dspstn
WITH NO SCHEMA BINDING
;