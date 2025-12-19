CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_email_append
/*
Created By:	Michael Andrien
Create Date:	04/12/2021
Purpose:	This view provides access to email append return file records.  The view union the return file results from Fresh Address, our former email append vendor, and Pacific East - our current email append vendor.  The view combines
the email append data with the CDI locator and assesment view as well as our Mktg email profile views to append internally managed attributes to the return file data.  We've assigned 'PEEM' as the append source code for Pacific East and
'FAEM' as the append source code for Fresh Address.

Modified By: Michael Andrien
Modified Date: 07/28/2021
Purpose: Added 3 new attributes to the Fresh Address and Pacific East email append tables listed below
	row_stat_cd - to allow us to manage logical delete requests (done by setting the row_stat_cd = 'L') 
	locator_dnc_ind - set to 1 to restrict the email for the assigned cnst_mstr_id from being mapped to the Marketing preferred Line of Business (LOB) preferred email.
	append_comnt - to document updates to the append record
	
Modified By: Michael Andrien
Modified Date: 10/29/2021
Purpose: Added a qualify statement to the view definition to limit the view to the most recend append record for a constituent.

Modified By: Michael Andrien
Modified Date: 05/14/2024
Purpose: Added the the 'AND a.append_status_cd = 'A'' qualifier to the Pacific East select to limit the view rows 
that were successfully appended by Pacific East.
	WHERE a.row_stat_cd <> 'L' AND a.append_status_cd = 'A'
*/
AS
SELECT
	cnst_mstr_id, 
	orig_cnst_mstr_id,
	cnst_prsn_f_nm, 
	cnst_prsn_l_nm, 
	cnst_line_1_addr, 
	cnst_line_2_addr, 
	cnst_city_nm, 
	cnst_st_cd, 
	cnst_zip_5_cd, 
	cnst_email, 
	list_source_nm, 
	append_data_src_cd,
	email_key,
	list_upload_ts,
	locator_dnc_ind,
	append_comnt,
	a.row_stat_cd
FROM 
(
/* Get Email Append records from the Pacific East Email Append table */
	SELECT 
		cnst_mstr_id, 
		orig_cnst_mstr_id,
		cnst_prsn_f_nm, 
		cnst_prsn_l_nm, 
		cnst_line_1_addr, 
		cnst_line_2_addr, 
		cnst_city_nm, 
		cnst_st_cd, 
		cnst_zip_5_cd, 
		cnst_email, 
		list_source_nm, 
		'PEEM' AS em_cnst_data_src_cd,
		b.email_key AS em_email_key,
		CASE  WHEN c.assessmnt_ctg IS NULL THEN 'Validated' ELSE c.assessmnt_ctg end AS em_cnst_email_assessmnt_ctg,
		d.ok_to_email_flg AS ok_to_email_flg,
		list_upload_ts,
		locator_dnc_ind,
		append_comnt,
		a.row_stat_cd
	FROM mktg_ops_tbls.pacific_east_email_append a
	LEFT JOIN eda.arc_mdm_vws.bz_locator_email b ON b.cnst_email_addr = a.cnst_email
	LEFT JOIN eda.arc_mdm_vws.bz_assessmnt c ON b.assessmnt_key = c.assessmnt_key
	LEFT JOIN mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile d ON a.cnst_email = d.email_addr
	WHERE a.row_stat_cd <> 'L' AND a.append_status_cd = 'A'

/* Union the Email Append records from the Fresh Address Email Append table */	
	UNION ALL

	SELECT 
		CASE WHEN e.cnst_mstr_id IS NOT NULL THEN e.new_cnst_mstr_id ELSE a.cnst_mstr_id end AS cnst_mstr_id, 
		a.cnst_mstr_id AS orig_cnst_mstr_id,
		cnst_prsn_f_nm, 
		cnst_prsn_l_nm, 
		cnst_line_1_addr, 
		cnst_line_2_addr, 
		cnst_city_nm, 
		cnst_st_cd, 
		cnst_zip_5_cd, 
		cnst_email, 
		list_nm, 
		'FAEM' AS em_cnst_data_src_cd,
		b.email_key AS em_email_key,
		CASE  WHEN c.assessmnt_ctg IS NULL THEN 'Validated' ELSE c.assessmnt_ctg end AS em_cnst_email_assessmnt_ctg,
		d.ok_to_email_flg AS ok_to_email_flg,
		list_upload_ts,
		locator_dnc_ind,
		append_comnt,
		a.row_stat_cd
	FROM mktg_ops_tbls.fresh_address_email_append a
	LEFT JOIN eda.arc_mdm_vws.bz_locator_email b ON b.cnst_email_addr = a.cnst_email
	LEFT JOIN eda.arc_mdm_vws.bz_assessmnt c ON b.assessmnt_key = c.assessmnt_key
	LEFT JOIN mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile d ON a.cnst_email = d.email_addr
	LEFT JOIN mktg_ops_vws.cnst_mstr_id_map e ON a.cnst_mstr_id = e.cnst_mstr_id
	WHERE a.row_stat_cd <> 'L'
) a (	cnst_mstr_id, orig_cnst_mstr_id,	cnst_prsn_f_nm, 	cnst_prsn_l_nm, 	cnst_line_1_addr, 	cnst_line_2_addr, 	cnst_city_nm, 	cnst_st_cd, 	cnst_zip_5_cd, 	cnst_email, 	list_source_nm, 	append_data_src_cd,	email_key,	email_assessmnt_ctg,	ok_to_email_flg,	list_upload_ts, locator_dnc_ind, append_comnt,
		row_stat_cd)
	QUALIFY Row_Number() Over (PARTITION BY a.cnst_mstr_id  ORDER BY a.list_upload_ts DESC) = 1
WITH NO SCHEMA BINDING;