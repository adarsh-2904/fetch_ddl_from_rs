create or REPLACE VIEW
/* ------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date:  07/13/2017
Purpose: This view selects all the records from the ARC Best summary profile table bzfc_arc_best_smry.  NOTE: This is a copy of the arc_mdm_vws view.
				The MODS team is going to begin testing using this for for cross-promotion campaigns where the campaign specifications require us to include
				records from multiple lines of business (LOBs).  We need the view in mktg_ops_vws to expose the view to the Adobe Schema.

Modified by: Michael Andrien
Modified date:  03/13/2019
Purpose: Added the join logic to include the FR SaleForce Account and Contact IDs.

Modified by: Greg Seaberg
Implemented by: Michael Andrien
Modified date:  06/14/2023
Implemented date:		
Purpose: Updated the join logic to include the FR Saleforce Account and Contact IDs to reference GMS / UFDS database instead of TA / DDCOE database.
				Removed column titles so columns could be aliased to match previous column names.
------------------------------------------------------------------------------------------------------------ */
mktg_ops_vws.bzfc_arc_best_smry             
AS
--LOCK TABLE  arc_mdm_tbls.bzfc_arc_best_smry FOR ACCESS MODE
SELECT 
 a.cnst_mstr_id,
 cnst_typ_cd,
 cnst_dsp_id,
 cnst_hsld_id,
 cnst_strt_dt,
 overall_cnst_data_qlty_scl,
 cnst_data_qlty_plt,
 cnst_rnbw_phnmn,
 cnst_prsn_nm_qlty_scl,
 locator_prsn_nm_key,
 prsn_nm_arc_srcsys_cd,
 prsn_nm_assessmnt_flg,
 prsn_nm_prefix,
 prsn_first_nm,
 prsn_middle_nm,
 prsn_last_nm,
 prsn_nm_suffix,
 cnst_prsn_full_nm,
 gender_arc_srcsys_cd,
 cnst_gender,
 birth_arc_srcsys_cd,
 cnst_birth_mth_num,
 cnst_birth_yr_num,
 death_arc_srcsys_cd,
 cnst_death_dt,
 cnst_deceased_cd,
 org_nm_qlty_scl,
 locator_org_nm_key,
 org_nm_arc_srcsys_cd,
 org_nm_assessmnt_flg,
 cnst_org_nm,
 org_typ_cd,
 ent_org_id,
 ent_org_name,
 cnst_addr_qlty_scl,
 locator_addr_key,
 addr_arc_srcsys_cd,
 addr_typ_cd,
 cnst_addr_deliv_flg,
 cnst_addr_residntl_flg,
 cnst_addr_dnc_cd,
 cnst_line1_addr,
 cnst_line2_addr,
 cnst_addr_city,
 cnst_addr_state,
 cnst_addr_zip_5,
 cnst_addr_zip_4,
 cnst_phn_qlty_scl,
 locator_phn_key,
 phn_arc_srcsys_cd,
 phn_typ_cd,
 phn_assessmnt_flg,
 cnst_phn_dnc_cd,
 cnst_phn_num,
 cnst_phn_extsn_num,
 cnst_email_qlty_scl,
 locator_email_key,
 email_arc_srcsys_cd,
 email_typ_cd,
 email_assessmnt_flg,
 cnst_email_dnc_cd,
 cnst_email_addr,
 lst_bio_dntn_dt,
 lst_fr_dntn_dt,
 lst_phss_cours_cmpltn_dt,
 lst_volntrng_dt,
 lst_arc_patrng_dt,
 lst_arc_patrng_los, -- Added this column for CDI R17
 arc_bst_smry_start_ts,
 arc_bst_smry_end_ts,
 --11/09 - added below three columns
 intnl_mtch_grp_id,
 consldtn_ind_1,
 consldtn_ind_2,
 --05/30 - added 3 and 4 consolidation indicator columns
 consldtn_ind_3,
 consldtn_ind_4,
 b.frf_acct_id as ag_bzd_sfid /*(TITLE 'SF Account ID')*/, 
 b.frf_cntct_id as cntct_bzd_sfid  /*(TITLE 'SF Contact ID')*/
FROM eda.arc_mdm_vws.bzfc_arc_best_smry a
left join /*mktg_ops_vws.bzl_cnst_mstr_fsa_acct_cntct b on a.cnst_mstr_id = b.cntct_cnst_mstr_id*/	
	mktg_ops_vws.gms_sf_acct_contct_brdg b on a.cnst_mstr_id = b.cnst_mstr_id		/*reference GMS / unified FR database instead of TA / DDCOE database*/
qualify row_number() over (partition by a.cnst_mstr_id  order by  b.frf_acct_id desc, b.frf_cntct_id desc) = 1
with no schema binding;