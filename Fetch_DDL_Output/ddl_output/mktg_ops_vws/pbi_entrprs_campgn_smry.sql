CREATE OR REPLACE VIEW mktg_ops_vws.pbi_entrprs_campgn_smry
AS
/*
Created By: Michael Andrien
Create Date: 01/10/2023
Purpose:  This view supports the PBI Enterprise Campaign Cross-Promotion and Enterprise Contact dashaboards.  The base table is loaded by the mktg_ops_tbls.ld_pbi_entrprs_campgn_smry macro and 
is refreshed daily.

Modified By:	Majeed Mohammad
Modified Date:	10/16/2024 
Purpose:		Added the column appt_cnt to the select from the new table mktg_ops_tbls.pbi_entrprs_campgn_smry. 

*/

SELECT	
	launch_dt, channel, lob, target_audience, delivery_label,
	yrqtr, src_cd, subsrc_cd, campgn_program_nm, xpromo_ind, is_trigg_msg_ind,
	sent_cnt, open_cnt, click_cnt, bounce_cnt, unsub_cnt, appt_cnt, src_system,
	load_dt
FROM mktg_ops_tbls.pbi_entrprs_campgn_smry
WITH NO SCHEMA BINDING;