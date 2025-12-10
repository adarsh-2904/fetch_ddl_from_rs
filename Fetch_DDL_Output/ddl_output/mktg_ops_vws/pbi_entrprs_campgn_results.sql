CREATE OR REPLACE VIEW mktg_ops_vws.pbi_entrprs_campgn_results
AS
/*
Created By: Michael Andrien
Create Date: 01/10/2023
Purpose:  This view supports the PBI Enterprise Campaign Cross-Promotion dashaboard and captures the Enterprise Campaign Results referenced within the dashboard.  The table is loaded daily 
by the ld_pbi_entrprs_campgn_results macro, which contains an insert statement referencing multiple sources capture cross-promo summary results.
*/

SELECT	
	result_type, 
	subsrc_cd, 
	campaign_result, 
	src_system, 
	load_date
FROM mktg_ops_tbls.pbi_entrprs_campgn_results
WITH NO SCHEMA BINDING;