CREATE OR REPLACE VIEW mktg_ops_vws.srvy_blood_sponsor
/*
Created By:		Michael Andrien
Create Date:	06/19/2024
Purpose:	This view contains the Biomed SalesForce Account details and links to the DRMS Sponsor.  The nk_acct_ufid is the unique attribute in the view.  This view is joined to the srvy_blood_sponsor
view in the Adobe Campaign schema and has a one to many relationship joining on the nk_acct_ufid.  The view supports Blood Sponsor survey process.  Note, the view is limited to BSF account tagged with the 
HEMO appl_src_cd.

Modified By: 	Michael Andrien
Modified Date:	07/22/2024
Purpose:		Modified join 'h' to remove the next drive date key.  The intent is to return the next drive date for 'Confirmed' drives associated with the sponsor.
*/
AS 
SELECT
	mb.cnst_mstr_id, -- (TITLE 'CDI Master Id'),
	a.master_sponsor_key as cnst_key, -- (TITLE 'BSF Constituent Key') as cnst_key, --a.cnst_key 
	a.account_guid as nk_acct_guid, -- (TITLE 'BSF Account id') as nk_acct_guid, --a.nk_acct_guid 
	b.sfbd_sponsor_ufid as nk_acct_ufid, -- (TITLE 'BSF Unified Account ID') as nk_acct_ufid, --
	a.sponsor_national_name as natnl_nm, -- (TITLE 'National Name'), --a.natnl_nm
	a.account_name as acct_nm, -- (TITLE 'BSF Account Name'),
	a.account_internal_name as int_nm, -- (TITLE 'Internal Name'), -- a.int_nm
	spc.master_constituent_key as bpl_cntct_cnst_key, -- (TITLE 'BPL Contact Key'), --a.bpl_cntct_cnst_key
	CAST(NULL as SMALLINT) as mngd_acct_ind,--a.mngd_acct_ind (TITLE 'Managed Account Ind'),
	a.account_company_sub_type as compny_sub_typ, -- (TITLE 'Company Sub-Type'), --a.compny_sub_typ
	a.account_active_indicator as act_ind, -- (TITLE 'Active Ind'), --a.act_ind
	a.account_portfolio as bsf_portfolio_nm, -- (TITLE 'BSF Portfolio Name'), --a.bsf_portfolio_nm
	c.sponsor_key, -- (TITLE 'EDW Sponsor Key'),
	c.nk_row_id, --(TITLE 'DRMS Row Id'), 
	c.nk_spon_int_id, --(TITLE 'DRMS Internal Sponsor Id'), 
	c.nk_spon_ext_id, --(TITLE 'DRMS External Sponsor Id'), 
	c.sponsor_dsc, --(TITLE 'DRMS Sponsor Desc'), 
	c.territory_id, --(TITLE 'DRMS Territory Id'), 
	c.territory_nm, --(TITLE 'DRMS Territory Name'),
	c.indus_cd, --(TITLE 'DRMS Industry Name'),
	a.account_type as acct_typ_dsc, --(TITLE 'Sponsor Group Type'), --f.acct_typ_dsc
	d.account_affiliation as unf_affl_typ_ntnl_loc, --d.unf_affl_typ_ntnl_loc, --(TITLE 'National Affiliation'),
	--CASE WHEN d.unf_affl_typ_ntnl_loc IN ('NA', 'National') THEN 1 ELSE 0 END (TITLE 'National Affiliation Ind') AS natnl_affltn_ind,
	CASE WHEN coalesce(d.account_affiliation_type, 'NA') IN ('NA', 'National') and d.sponsor_affiliation_active_indicator = 1 THEN 1 ELSE 0 END as natnl_affltn_ind,
	CAST(NULL as VARCHAR(100)) as bpl_cntct_nm, --e.cntct_nm AS bpl_cntct_nm, 
	CAST(NULL as VARCHAR(100)) as bpl__title_nm, --e.title_nm AS bpl_title_nm,
	spc.first_name AS bpl_first_nm, 
	spc.last_name AS bpl_last_nm ,
	CAST(NULL AS VARCHAR(20)) as bpl_nm_sfx, --e.nm_sfx AS bpl_nm_sfx,
	CAST(NULL as VARCHAR(100)) as bpl_cntct_salutn, --e.cntct_salutn AS bpl_cntct_salutn,
	CAST(NULL as VARCHAR(100)) as bpl_salutn, --e.salutn AS bpl_salutn, 
	spc.email as bpl_email_addr, --e.email_addr AS bpl_email_addr,
	g.cntct_email_inv_flg,
	g.do_not_email_flg,
	h.next_drive_start_dt
FROM eda.bio_drive_planning_vws.bzl_dim_sponsor_mstr_smry a
--left join eda.bio_drive_planning_vws.bzl_dim_sponsor_constituent_mstr a2 on a.master_sponsor_key = a2.master_sponsor_key -- Covered by join spc
/* Get the BPL attributes from bzfc_dim_sponsor_mstr_alt_id  */
LEFT JOIN eda.bio_drive_planning_vws.bzfc_dim_sponsor_mstr_alt_id b ON trim(a.dw_srcsys_id) = trim(b.sfbd_sponsor_ufid)
left join eda.bio_drive_planning_vws.bzl_dim_sponsor_constituent_mstr spc on b.master_sponsor_key = spc.master_sponsor_key and spc.person_sub_type = 'Primary Contact/Blood Program Leader'
LEFT JOIN eda.drms_vws.bz_dim_sponsor c ON c.nk_spon_int_id = b.sponsor_internal_id
LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge mb ON c.sponsor_key = mb.cnst_mstr_subj_area_id AND mb.cnst_mstr_subj_area_cd = 'HEMO'
LEFT JOIN eda.bio_drive_planning_vws.bzl_fact_sponsor_affl_dtl d on a.master_sponsor_key = d.master_sponsor_key
--LEFT JOIN ubds_vws.bzl_dim_sponsor_affl_mstr_unf d ON d.unf_mstr_spon_key = b.mstr_key AND d.unf_spon_affl_act_ind = 1 /* get national affiliation from bio_drive_planning_vws.bzl_dim_sponsor_mstr_smry */
--LEFT JOIN eda.bio_drive_planning_vws.bz_dim_constituent e ON a.bpl_cntct_cnst_key = e.cnst_key
--LEFT JOIN ubds_vws.bsfbz_dim_acct_typ f ON a.acct_typ_key = f.acct_typ_key  /* get account type from bio_drive_planning_vws.bzl_dim_sponsor_mstr_smry */
LEFT JOIN 
(
	SELECT 
		Trim(a.cntct_email_addr),
		CASE WHEN a.cntct_email_inv_flg IS NULL THEN 'N' ELSE a.cntct_email_inv_flg END AS cntct_email_inv_flg,
		CASE WHEN b.src_field_desc IS NULL THEN 'N' ELSE b.src_field_desc END AS do_not_email_flg	
	FROM eda.drms_vws.bz_dim_cntct_email a
	LEFT JOIN eda.drms_vws.bz_dim_enrol_pref_loc_ref b ON a.enroll_pref_loc_key = b.enroll_pref_loc_key AND b.enroll_pref_loc_key = 38 
	LEFT JOIN eda.drms_vws.bz_dim_cntct_pref c ON c.contact_key = a.contact_key
	WHERE a.cntct_email_addr IS NOT null
) g (email_addr, cntct_email_inv_flg,do_not_email_flg) ON g.email_addr = spc.email --e.email_addr
LEFT JOIN 
(
	SELECT 
		sponsor_int_id,
		Min(start_dt)
	FROM eda.drms_vws.bz_dim_drive a
	WHERE start_dt > Current_Date AND drv_stat = 'Confirmed'
	GROUP BY 1
) h (sponsor_int_id, next_drive_start_dt) ON c.nk_spon_int_id = h.sponsor_int_id
left join eda.bio_drive_planning_vws.bzl_fact_portfolio_account_assignment i on i.master_sponsor_key = a.master_sponsor_key
left join eda.bio_drive_planning_vws.bzl_fact_portfolio_assignment j on i.account_portfolio_assigned_portfolio = j.portfolio_guid
QUALIFY Row_Number() Over (PARTITION BY b.sfbd_sponsor_ufid,c.nk_spon_int_id  ORDER BY CASE WHEN a.sponsor_national_affiliation_name_list is not null THEN 1
																			  	WHEN a.sponsor_national_affiliation_name_list = 'NA' THEN 2
																				ELSE 3
																				END) = 1
WITH NO SCHEMA BINDING;