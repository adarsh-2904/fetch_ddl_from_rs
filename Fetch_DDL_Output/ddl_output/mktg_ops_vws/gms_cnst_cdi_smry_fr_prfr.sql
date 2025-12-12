CREATE OR REPLACE VIEW mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr AS 
-- drop view mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr;
create or replace view mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr 

/* ---------------------------------------------------------------------------------------------------------------------------

Created by: Michael Andrien
Created date: 31-Jul-2013
******************************************************************************************************************
Purpose: This view provides the Fundraising CDI Preferred Demographic information for a constituent.  The record has an email (em) section
                and a direct mail (dm) section, which are populated base on prioritized rules provided by the Consumer Fundraising and other Marketing 
                business partners.

*****************************************************************************************************************
Modified Date: 30-Oct-2014  
Modified By: Michael Andrien - 
ISDM Task # 315
Applied the following updates:
1. Changed view definition from a 'select * from table' view to explicitly list the columns selected.  
2. Added logic to set the dm and em last name column to the Org Name if the constituent type is Organization. 
3. Add the secondary name to the preferred view.  We added the join to aprimo_lndng_tbls.bzf_cnst_cdi_sltn_id, which originates on the EDW
    platform and is copied to the Mktg platform every day.  The secondary name columns are used to formulate the salutation on the direct mail
    letters and may be used to personalize emails as well.  For direct mail the salutation is 'Dear primary first name and secondary first name'
    
ISDM Task #341
Modified Date 29-Jan-2015
Modified by Michael Andrien
*** Added joins to view to derive the County Name in the profile.

ISDM/MODS Task #
Modified Date 04-March-2015
Modified by  Michael Andrien
Purpose: The view had gotten over-written when the MODS team reployed the Address locator fields with a select * from aprm_lndng_tbls.cnst_cdi_sumry_fr_prfr view.  This 
     caused errors in Aprimo because the landing table had a different name for the EM County and DM county columns.  This view corrected the issue and restored the joins
     to the salutaion tables to get the secondary name columns.  It all changed the view from Task 341 to remove joins for the county columns.  The previous deployment added both the 
     address locator and the county columns.    
     
ISDM/MODS Task # 397
Modified Date: 14-Sept-2015
Modified by: Majeed Mohammad
Purpose: Added the relationship manager Name and Email address columns                                           

Modified Date: 19-Nov-2015
Modified by: Majeed Mohammad
Purpose: Added the column dm_pa_addr_check which identified if we picked the DM or the PA(Primary affiliated) columns 

Modified Date: 30-Nov-2015
Modified by: Majeed Mohammad
Purpose: Added the column unit_key_src which identified if we picked the DM or the PA Unit key

Modified Date: 27-Apr-2016
Modified By: Michael Andrien 
Purpose: Added the joins below to derive the 'Marketing' unit key based on the zip code of the DM address.  The CFR team
    asked to create a chapter affiliation - unit key that is based on the mailing address zip code.  This was to address
    issues with having the dynamic content in the mailing not aligning with the state associated with the chapter affiliation derived from 
    the FR chapter affiliation view we use in CDI to set the unit_key in the FR Preferred view.  We've labled the new column mktg_unit_key
    to distinguish the affiliation from the FR unit_key.

Modified Date: 18-May-2016
Modified By: Michael Andrien 
Purpose: Add a join to the arc_fr_smry table and added the has_smry_profile_ind column. The summary profile indicator allows users to identify which cnstituents have been linked to gifts.  
This can be leverage in the DDCOE universe to avoid double counting gifts when reporting at the master id grain.  This is useful in first time gift analysis when a constituent has multiple TA acount
ids or is in both TA and has distinct cnst_fsa_keys from migrated chapter data.

Modified by: Majeed Mohammad
Modified on: 10/19/2016
Purpose: Added the logic for the DM & EM name locator key and name assessment category. 

Modified by:  Michael Andrien
Modified Date: 2/10/2017
Purpose:  Renamed dm_cnst_county_nm to dm_cnst_addr_county_nm  and em_cnst_county_nm to em_cnst_addr_county_nm to fix discrepancy with Adobe universe - had
				to align Webi and Adobe object names.  Also added the a.cnst_typ_cd ,a.org_typ_cd columns back to the view.  They were missing from the 2700 view.

Modified by:  Michael Andrien
Modified Date: 4/25/2017
Purpose:  MODS Task #362 - Save prior view definition in the task notes.
				Added join to arc_stage_tbls.stg_fresh_address to override the em column values selected by the email ranking rules in the ld_cnst_cdi_s_f_p_fr_email macro with the
				email returned by Fresh Address.  This was a one-time test with 150,000 FR constituents to see whether we could append emails on donors where either we had an old email or no email at all.
				I set the em_appl_src_cd to FAEM for these recs.  NOTE: The em_email_key will be NULL for most of these records because the ADM team did not master the email records returned from Fresh
				Address.  We will alter this view when they do.

Modified by:  Michael Andrien
Modified Date: 08/10/2017
Purpose:  Added the acct_in_salutn_nm and acct_out_salutn_nm attributes to the FR preferred view.  These represent the Salesforce Account inside and outside salutation details.  The inside salutation
				is the Salutation and the outside salutation attribute is referred to as the Addressee.


Modified by: Majeed Mohammad
Modified on: 08/11/2017
Purpose: Added the columns inactvtn_reason_cd, inactvtn_reason_dsc, inactvtn_dt , inactvtn_reason_txt to track the inactive attributes 

Modified By: Michael Andrien
Modified Date: 10/24/2017
Purpose:  Added dpv_cd from the bzfc_cnst_addr to further qualify the address assessment category coding.  We were getting a high volume of returned mail
				and were told to exclude mailing addresses that have a 'Deliverable' assessment but the dpv_cd is not equal to 'Y'

Modified by: Majeed Mohammad
Modified on: 11/24/2017
Purpose: The macro to load the table cnst_cdi_smry_fr_prfr has been updated and all the joins in the previous version of this view have been incoporated in the macro. This view has been simplified to read from the base table. This will improve the performance of this view 

Modified By: Michael Andrien
Modified Date: 08/31/2018
Purpose: Added zeroifnull logic to unit_key and mktg_unit_key to default null values to zero (0).  Also added unit table joins to include the unit_cd and mktg_unit_cd attributes to match the other LOB profiles.

Modified By: Michael Andrien
Modified Date: 12/02/2019 
Purpose:  Created a GMS version or the cnst_cdi_smry_fr_prfr view to enaable us to separate our DDCOE and GMS FR Profile Structures.  The GMS views (FR Preferred, Smry and Txn) are all prefixed with 'gms_'

Modified By: Michael Andrien
Modified Date: 3/25/2020
Purpose:  Added active_cnts_ind and active_email_cnst_ind attributes to the GMS view

Modified by: Michael Andrien
Modified date:  11/02/2020
Purpose: Added the following columns to track CEM and NCOA updates:
	a.cem_all_mail_override_flg, 
	a.cem_fr_mail_override_flg, 
	a.cem_all_mail_override_ind, 
	a.cem_fr_mail_override_ind, 
	a.ncoa_mail_override_flg, 
	a.ncoa_mail_override_ind
	
Modified by: Michael Andrien
Modified date:  12/02/2020
Purpose  Added the three new attributes below:
		last_email_open_dt, last_email_intrctn_dt, last_dmail_intrctn_dt

Modified by: Michael Andrien
Modified date:  10/29/2022
Purpose: Added the nm_rnk join to rank FR profile names.  The objects from the name rank derived table are then used in the EM and DM case 
statements to set the applicable name attributes from the ranked names in cases where there is no usable name for ranked DM mailing 
address source or the ranked EM email address source.  We've added the em_prsn_nm_src_cd and dm_prsn_nm_src_cd attributes
to enable users to know when the name sources to not match the address source.  This was implemented to address null names
in the profile.  The update is related to TW ticket  https://arcmarketingcommunications.teamwork.com/desk/tickets/8956683

Modified by: Michael Andrien
Modified date:  06/28/2023
Purpose: Added the phone append attributes listed below.  This may be a temporary solution for the phone append data.  We'll update the macro once we have 
better requirements from the CFR team regarding how the append data should be incorporated into our primary phone ranking rules.
	Phone Append Attributes: 
		d.append_phone_appl_src_cd,
		d.append_phone_num,
		d.append_phone_status,
		d.append_phone_line_typ,
		d.append_phone_locator_dnc_ind,
		d.append_phone_list_source_nm,
		d.append_phone_list_upload_ts,

Modified by: Michael Andrien
Modified date:  04/22/2025
Purpose:    Added a join to our gofundraise donor table.  The CFR team is running a 1 month test with this 3rd party platform and wants the MODS OPs team 
to suppress donors from this table from our daily email campaigns. We may remove this from the view defs after the test has been completed in May.
*/
as
SELECT  
a.cnst_mstr_id AS cnst_mstr_id, 
a.cnst_hsld_id AS cnst_hsld_id , 
a.cnst_arc_deceased_cd AS cnst_arc_deceased_cd, 
a.dm_prsn_nm_src_cd,
a.dm_cnst_data_src_cd AS dm_cnst_data_src_cd,
a.dm_locator_prsn_nm_key AS dm_locator_prsn_nm_key , 
a.dm_cnst_prsn_nm_assessmnt_ctg AS dm_cnst_prsn_nm_assessmnt_ctg,
a.dm_cnst_prsn_prfx_nm AS dm_cnst_prsn_prfx_nm , 
a.dm_cnst_prsn_f_nm AS dm_cnst_prsn_f_nm, 
a.dm_cnst_prsn_m_nm AS dm_cnst_prsn_m_nm, 
a.dm_cnst_prsn_l_nm  AS dm_cnst_prsn_l_nm,
a.dm_cnst_prsn_sfx_nm AS dm_cnst_prsn_sfx_nm ,
a.dm_cnst_prsn_full_nm AS dm_cnst_prsn_full_nm, 
a.dm_cnst_alias_in_saltn_nm AS dm_cnst_alias_in_saltn_nm,
a.dm_cnst_alias_out_saltn_nm AS dm_cnst_alias_out_saltn_nm, 
a.dm_pa_addr_check, 
a.dm_locator_addr_key AS dm_locator_addr_key,
a.dm_cnst_addr_assessmnt_ctg AS dm_cnst_addr_assessmnt_ctg,
a.dpv_cd AS dpv_cd,
a.dm_cnst_line_1_addr AS dm_cnst_line_1_addr, 
a.dm_cnst_line_2_addr AS dm_cnst_line_2_addr,
a.dm_cnst_city_nm AS dm_cnst_city_nm, 
a.dm_cnst_st_cd AS dm_cnst_st_cd, 
a.dm_cnst_zip_5_cd AS dm_cnst_zip_5_cd, 
a.dm_cnst_zip_4_cd AS dm_cnst_zip_4_cd,
a.dm_cnst_addr_county_nm AS dm_cnst_addr_county_nm,
a.cem_all_mail_override_flg, 
a.cem_fr_mail_override_flg, 
a.cem_all_mail_override_ind, 
a.cem_fr_mail_override_ind, 
a.ncoa_mail_override_flg, 
a.ncoa_mail_override_ind,
a.dm_cnst_email AS dm_cnst_email, 
a.dm_cnst_org_nm AS dm_cnst_org_nm, 
a.dm_cnst_typ_dsc AS dm_cnst_typ_dsc, 
a.dm_cnst_prsn_prfx_nm2, 
a.dm_cnst_prsn_f_nm2, 
a.dm_cnst_prsn_m_nm2, 
a.dm_cnst_prsn_l_nm2,
a.dm_cnst_prsn_sfx_nm2,
a.dm_cnst_prsn_full_nm2, 
a.em_prsn_nm_src_cd,
a.em_cnst_data_src_cd,  
a.em_locator_prsn_nm_key AS em_locator_prsn_nm_key , 
a.em_cnst_prsn_nm_assessmnt_ctg AS em_cnst_prsn_nm_assessmnt_ctg,
a.em_cnst_prsn_prfx_nm AS em_cnst_prsn_prfx_nm, 
a.em_cnst_prsn_f_nm, 
a.em_cnst_prsn_m_nm AS em_cnst_prsn_m_nm,
a.em_cnst_prsn_l_nm,
a.em_cnst_prsn_sfx_nm AS em_cnst_prsn_sfx_nm, 
a.em_cnst_prsn_full_nm AS em_cnst_prsn_full_nm, 
a.em_cnst_alias_in_saltn_nm AS em_cnst_alias_in_saltn_nm,
a.em_cnst_alias_out_saltn_nm AS em_cnst_alias_out_saltn_nm, 
a.em_locator_addr_key,
a.em_cnst_line_1_addr, 
a.em_cnst_line_2_addr,
a.em_cnst_city_nm, 
a.em_cnst_st_cd, 
a.em_cnst_zip_5_cd,
a.em_cnst_zip_4_cd,
a.em_cnst_addr_county_nm AS em_cnst_addr_county_nm,
a.em_cnst_email,  
a.em_email_key, 
a.em_cnst_email_assessmnt_ctg,  
a.em_cnst_org_nm AS em_cnst_org_nm, 
a.em_cnst_typ_dsc,
a.em_cnst_prsn_prfx_nm2 , 
a.em_cnst_prsn_f_nm2, 
a.em_cnst_prsn_m_nm2, 
a.em_cnst_prsn_l_nm2,
a.em_cnst_prsn_sfx_nm2,
a.em_cnst_prsn_full_nm2, 
a.email_dlvrbl_ind AS email_dlvrbl_ind, 
a.prim_cnst_phn AS prim_cnst_phn,
a.prim_cnst_phn_source AS prim_cnst_phn_source,
a.prim_cnst_phn_typ_dsc AS prim_cnst_phn_typ_dsc,
a.cnst_work_phn AS cnst_work_phn, 
a.cnst_work_phn_source AS cnst_work_phn_source, 
a.cnst_work_phn_typ_dsc AS cnst_work_phn_typ_dsc, 
a.cnst_mbl_phn AS cnst_mbl_phn, 
a.cnst_mbl_phn_source AS cnst_mbl_phn_source, 
a.cnst_mbl_phn_typ_dsc AS cnst_mbl_phn_typ_dsc,
/* Phone Append Attribute */
d.append_phone_appl_src_cd,
d.append_phone_num,
d.append_phone_status,
d.append_phone_line_typ,
d.append_phone_locator_dnc_ind,
d.append_phone_list_source_nm,
d.append_phone_list_upload_ts,
a.do_not_call_hm_phn_ind AS do_not_call_hm_phn_ind, 
a.do_not_call_mbl_phn_ind AS do_not_call_mbl_phn_ind, 
a.do_not_call_work_phn_ind AS do_not_call_work_phn_ind,
a.do_not_email_ind AS do_not_email_ind, 
a.do_not_mail_ind AS do_not_mail_ind, 
a.do_not_txt_ind AS do_not_txt_ind, 
a.cnst_3rd_prty_segmtn_group_nm AS cnst_3rd_prty_segmtn_group_nm,
a.unit_key_src AS unit_key_src, 
coalesce(a.unit_key,0) AS unit_key, 
b.nk_ecode AS unit_cd,
a.affl_lock_ind, 
a.sf_acct_fmd_ind,
a.frf_status_cd,
a.portfolio_category,
a.rlshp_mgr_ownr_key,
a.rlshp_mgr_nm , 
a.rlshp_mgr_prefd_email_addr , 
a.acct_in_salutn_nm,
a.acct_out_salutn_nm ,
coalesce(a.mktg_unit_key,0) AS mktg_unit_key,
c.nk_ecode AS mktg_unit_cd,
a.cnst_typ_cd ,
a.org_typ_cd,
a.has_smry_profile_ind,  
a.inactvtn_reason_cd,  
a.inactvtn_reason_dsc, 
a.inactvtn_dt , 
a.inactvtn_reason_txt,
a.ag_bzd_sfid,
a.cntct_bzd_sfid,
a.mult_sf_cnst_ind,
a.active_cnst_ind,
a.active_email_cnst_ind,
a.last_email_open_dt, 
a.last_email_intrctn_dt, 
a.last_dmail_intrctn_dt,
CASE WHEN e.gofundraise_email IS NOT NULL THEN 1 ELSE 0 END AS gofundraise_supress_ind,
e.gofundraise_proc_dt
FROM  mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr    a 
LEFT JOIN mktg_ops_vws.bz_dim_unit b ON a.unit_key = b.unit_key
LEFT JOIN mktg_ops_vws.bz_dim_unit c ON a.mktg_unit_key = c.unit_key
LEFT join
(
select cnst_mstr_id,
	append_phone_num,
	append_phone_status,
	line_typ,
	locator_dnc_ind,
	list_source_nm,
	list_upload_ts,
	'PEPA' AS appl_src_cd
from (SELECT
	cnst_mstr_id,
	append_phone_num,
	append_status AS append_phone_status,
	line_typ,
	locator_dnc_ind,
	list_source_nm,
	list_upload_ts,
	'PEPA' AS appl_src_cd,
	Row_Number() Over (PARTITION BY cnst_mstr_id  ORDER BY list_upload_ts DESC) as rn
FROM mktg_ops_tbls.pacific_east_phone_append) as subqry
where subqry.rn=1
)  d (cnst_mstr_id,append_phone_num,append_phone_status,append_phone_line_typ,append_phone_locator_dnc_ind,append_phone_list_source_nm,append_phone_list_upload_ts,append_phone_appl_src_cd) ON a.cnst_mstr_id = d.cnst_mstr_id
LEFT JOIN
(
    SELECT 
        email_a, 
        Cast(dw_trans_ts AS DATE) AS gofundraise_proc_dt
    FROM mktg_ops_tbls.gofundraise_donor
) e (gofundraise_email, gofundraise_proc_dt) ON collate(a.em_cnst_email::text, 'CASE_INSENSITIVE') = collate(e.gofundraise_email::text, 'CASE_INSENSITIVE')

with no schema binding;