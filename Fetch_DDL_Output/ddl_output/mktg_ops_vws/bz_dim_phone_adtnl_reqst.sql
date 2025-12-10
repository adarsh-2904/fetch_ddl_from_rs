CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_phone_adtnl_reqst AS

/*
Created By: Michael Andrien
Create Date: 06/27/2023
Purpose: 	This dimension joins to the mktg_ops_vws.bzfc_fact_phone_interaction table and captures additional request regarding phone campaign call activity.
			1	10	No Additional Requests
			2	11	Send Financial Statement
			3	12	Do Not Call
*/
SELECT
    adtnl_reqst_key, adtnl_reqst_cd, adtnl_reqst_dsc, dw_create_ts, dw_updt_ts, row_stat_cd, appl_src_cd, load_id
FROM mktg_ops_tbls.dim_phone_adtnl_reqst
WITH NO SCHEMA BINDING
;