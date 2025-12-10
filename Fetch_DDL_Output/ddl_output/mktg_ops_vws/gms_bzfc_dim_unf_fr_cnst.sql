create or REPLACE VIEW mktg_ops_vws.gms_bzfc_dim_unf_fr_cnst 
/*
Modified By: 	Michael Andrien
Modified Date:	9/12/2019
Purpose:	This view references the GMS flattened Constituent view.  The flatten view contains many attributes that reflect the current contact info associated with the GMS donor and various donor classification
attributes that were formerly captured in the DDCOE cnst characteristic views.  This version of the view includes all constituent types including Individiuals (IN), Orgs (OR), account groups (AG), individual groups (IG) and
Org groups (OG).  The classification include anonymous, private, manage SF, spotlight, sustainer, planned giving, etc.
The MODS team needs the view definition in the mktg_ops_vws database, which is the source for the Adobe Campaign application. 
*/
AS

SELECT
    unf_fr_cnst_key AS "Unified Fundraising Constituent Key",
    nk_gmp_cnst_id AS "Nk Gift Management Portal Constituent Identifier",
    nk_gpp_cnst_seq AS "Nk Gift Pre Processor Constituent Sequence",
    nk_sf_acct_guid AS "Nk Salesforce Account GUID",
    nk_sf_cntct_guid AS "Nk Salesforce Contact GUID",
    nk_ta_acct_id AS "Nk TA Account Identifier",
    nk_ta_nm_id AS "Nk TA Name Identifier",
    nk_chpt_sys_id AS "Nk Chapter System Identifier",
    nk_hema_intrnl_acct_id AS "Nk Hemasphere Internal Account Identifier",
    nk_hema_intrnl_cntct_id AS "Nk Hemasphere Internal Contact Identifier",
    frf_acct_id AS "Frf Account Identifier",
    frf_cntct_id AS "Frf Contact Identifier",
    cnst_mstr_id AS "Constituent Master Identifier",
    cnst_alt_id AS "Constituent Alternate Identifier",
    ent_org_id AS "Enterprise Organization Identifier",
    obslt_cnst_fsa_key AS "Obsolete Constituent FSA Key",
    cnst_typ_cd AS "Constituent Type Code",
    cnst_typ_dsc AS "Constituent Type Description",
    dnr_typ_cd AS "Donor Type Code",
    dnr_typ_dsc AS "Donor Type Description",
    prfx_cd AS "Prefix Code",
    prfx_dsc AS "Prefix Description",
    first_nm AS "First Name",
    midl_nm AS "Middle Name",
    last_nm AS "Last Name",
    sfx_cd AS "Suffix Code",
    sfx_dsc AS "Suffix Description",
    addressee AS "Addressee",
    salutn AS "Salutation",
    maiden_nm AS "Maiden Name",
    nick_nm AS "Nick Name",
    alias_nm AS "Alias Name",
    presidential_salutn AS "Presidential Salutation",
    job_title_nm AS "Job Title Name",
    org_nm AS "Organization Name",
    nm_line AS "Name Line",
    prefd_addr_locator_key AS "Preferred Address Locator Key",
    prefd_addr_typ AS "Preferred Address Type",
    prefd_addr_line_1 AS "Preferred Address Line 1",
    prefd_addr_line_2 AS "Preferred Address Line 2",
    prefd_city_nm AS "Preferred City Name",
    prefd_state_cd AS "Preferred State Code",
    prefd_state_dsc AS "Preferred State Description",
    prefd_zip_cd AS "Preferred Zip Code",
    prefd_country_cd AS "Preferred Country Code",
    prefd_country_nm AS "Preferred Country Name",
    prefd_county_cd AS "Preferred County Code",
    prefd_county_nm AS "Preferred County Name",
    prefd_phn_locator_key AS "Preferred Phone Locator Key",
    prefd_phn_typ AS "Preferred Phone Type",
    prefd_phn_num AS "Preferred Phone Number",
    prefd_email_locator_key AS "Preferred Email Locator Key",
    prefd_email_typ AS "Preferred Email Type",
    prefd_email_addr AS "Preferred Email Address",
    prefd_lang_cd AS "Preferred Language Code",
    prefd_lang_dsc AS "Preferred Language Description",
    grp_active_cnst_cnt AS "Group Active Constituent Count",
    grp_cnst_1_key AS "Group Constituent 1 Key",
    grp_cnst_2_key AS "Group Constituent 2 Key",
    grp_org_cnst_key AS "Group Org Constituent Key",
    grp_cnst_1_mstr_id AS "Group Constituent 1 Master Identifier",
    grp_cnst_2_mstr_id AS "Group Constituent 2 Master Identifier",
    grp_org_mstr_id AS "Group Organization master Identifier",
    grp_cnst_rmng_mstr_id AS "Group Constituent Remaining Master Identifier",
    grp_cnst_rmng_cnst_nm AS "Group Constituent Remaining Constituent Name",
    CAST(strt_dt AS DATE) AS "Start Date",
    CAST(death_dt AS DATE) AS "Death Date",
    frf_spotlighted_dt AS "Frf Spotlighted Date",
    birth_dy AS "Birth Day",
    birth_mth AS "Birth Month",
    birth_yr AS "Birth Year",
    active_ind AS "Active Indicator",
    frf_active_ind AS "Frf Active Indicator",
    prim_ind AS "Primary Indicator",
    frf_anon_ind AS "Frf Anonymous Indicator",
    trbt_notif_rcpnt_ind AS "Tribute Notification Recipient Indicator",
    third_prty_contributor_ind AS "Third Party Contributor Indicator",
    ownr_ind AS "Owner Indicator",
    deceased_ind AS "Deceased Indicator",
    anon_ind AS "Anonymous Indicator",
    prvt_ind AS "Private Indicator",
    frf_gift_mngd_dnr_ind AS "Frf Gift Managed Donor Indicator",
    frf_cur_mngd_dnr_ind AS "Frf Current Managed Donor Indicator",
    frf_prvt_ind AS "Frf Private Indicator",
    frf_visit_in_pairs_ind AS "Frf Visit In Pairs Indicator",
    frf_spotlight_dnr_ind AS "Frf Spotlight Donor Indicator",
    frf_chan_design_ind AS "Frf Channel Design Indicator",
    sustnr_ind AS "Sustainer Indicator",
    plnd_gvng_confirm_ind AS "Planned Giving Confirm Indicator",
    plnd_gvng_info_rqst_ind AS "Planned Giving Information Request Indicator",
    inactvtn_reason_cd AS "Inactivation Reason Code",
    inactvtn_reason_dsc AS "Inactivation Reason Description",
    CAST(inactvtn_dt AS DATE) AS "Inactivation Date",
    inactvtn_reason_txt AS "Inactivation Reason Text",
    acct_ownr_key AS "Account Owner Key",
    frf_acct_key AS "Frf Account Key",
    frf_status_cd AS "Frf Status Code",
    frf_spotlight_note_txt AS "Frf Spotlight Note Text",
    frf_ent_org_id AS "Frf Enterprise Organization Identifier",
    frf_num_of_lctn AS "Frf Number Of Location",
    frf_ownr_role_nm AS "Frf Owner Role Name",
    frf_gift_portfolio_ctg AS "Frf Gift Portfolio Category",
    frf_cur_portfolio_ctg AS "Frf Current Portfolio Category",
    frf_industry_nm AS "Frf Industry Name",
    CAST(frf_acct_ownr_asgnd_dt AS DATE) AS "Frf Account Owner Assigned Date",
    frf_acct_modified_key AS "Frf Account Modified Key",
    frf_prev_acct_ownr_key AS "Frf Previous Account Owner Key",
    frf_acct_ownr_key AS "Frf Account Owner Key",
    frf_acct_rgn_key AS "Frf Account Region Key",
    rev_credit_key AS "Revenue Credit Key",
    frf_rev_credit_key AS "Frf Revenue Credit Key",
    frf_dnr_intrst_othr_txt AS "Frf Donor Interest Other Text",
    frf_dnr_intrst_txt AS "Frf Donor Interest Text",
    frf_issue_risk_txt AS "Frf Issue Risk Text",
    frf_leverage_point_txt AS "Frf Leverage Point Text",
    frf_rlshp_fit_txt AS "Frf Relationship Fit Text",
    frf_rlshp_gap_txt AS "Frf Relationship Gap Text",
    frf_vsblty_thrshld_excd_ind AS "Frf Visibility Threshold Exceed Indicator",
    frf_vsblty_thrshld_excd_cnt AS "Frf Visibility Threshold Exceed Count",
    CAST(frf_vsblty_thrshld_excd_dt AS DATE) AS "Frf Visibility Threshold Exceed Date",
    bio_acct_mngr_nm AS "Biomed Account Manager Name",
    bio_acct_mngr_email AS "Biomed Account Manager Email",
    bio_acct_mngr_phn AS "Biomed Account Manager Phone",
    bio_acct_ind AS "Biomed Account Indicator",
    bio_annual_collect_tgt AS "Biomed Annual Collect Target",
    bio_annual_drive_tgt AS "Biomed Annual Drive Target",
    bio_rgn_nm AS "Biomed Region Name",
    bio_cllctn_zipcode_dtl_key AS "Biomed Collection Zipcode Detail Key",
    backed_out_ind AS "Backed Out Indicator",
    back_out_reason_cd AS "Back Out Reason Code",
    vendor_src_cd AS "Vendor Source Code",
    CAST(srcsys_create_ts AS TIMESTAMP) AS "Create Timestamp",
    CAST(srcsys_update_ts AS TIMESTAMP) AS "Update Timestamp",
    srcsys_created_by AS "Record Created By",
    srcsys_modified_by AS "Record Modified By",
    row_status_cd AS "Row Status Code",
    CAST(dw_trans_ts AS TIMESTAMP) AS "Dw Trans Ts",
    load_id AS "Load Id",
    appl_src_cd AS "Appl Src Cd",
	grp_cnst_1_spouse_key AS "Group Constituent 1 Spouse Key",
    grp_cnst_2_spouse_key AS "Group Constituent 2 Spouse Key",
    grp_cnst_1_spouse_mstr_id AS "Group Constituent 1 Spouse Master Identifier",
    grp_cnst_2_spouse_mstr_id AS "Group Constituent 2 Spouse Master Identifier",
    related_org_1_key AS "Constituent Related Organization 1 Key",
    related_org_2_key AS "Constituent Related Organization 2 Key",
    related_org_3_key AS "Constituent Related Organization 3 Key"
	
	
FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
WHERE row_status_cd <> 'L' with no schema binding;