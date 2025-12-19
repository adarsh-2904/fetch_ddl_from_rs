CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_cnst_cdi_smry_fr_prfr1()
 LANGUAGE plpgsql
AS $$
/*
Created by: Majeed Mohammad
Created on: 11/19/2015
Purpose: This macro instantiates the Pref profile view. It reads from the source view mktg_ops_vws.cnst_cdi_fr_smry_prfr_src and loads the table mktg_ops_tbls.cnst_cdi_fr_smry_prfr


Modified by: Majeed Mohammad
Modified on: 04/25/2016
Purpose: Added the column APPL_SRC_CD from the view arc_mdm_vws.bzfc_fr_cnst_affl_prfl to identify the source for the Primary affiliation address. 
Modifed the UPDATE SQL to set the PREFD address columns instead of the DM address columns when we set dm_pa_addr_check='PA Address'

Modified by: Majeed Mohammad
Modified on: 07/01/2016
Purpose: Commented out the logic to assign the address from the primary affiliation table  

Modified by: Majeed Mohammad
Modified on: 09/21/2016
Purpose: Added the logic for the constituent type code and constituency code 

Modified By: Majeed Mohammad
Modified Date: 10/19/2016
Purpose: Added the logic to get the DM & EM name locator key and name assessment

Modified By: Majeed Mohammad
Modified Date: 06/01/2017
Purpose: Added Temporary Update statement to set the cnst_arc_deceased_cd=D when the cnst_arc_death_dt is not null. 

Modified by: Majeed Mohammad
Modified on: 06/06/2017
Purpose:  Updated the macro to use the view mktg_ops_vws.bzf_cem_fr_cnst_loc_prefs

Modified by: Majeed Mohammad
Modified on: 06/07/2017
Purpose:  Added the SQLs to delete data from the TMP table to free space in the mktg_stage_tbls database

Modified by: Majeed Mohammad
Modified on: 06/20/2017
Purpose: Added the unit_key and deceased_cd column update statements from the original view . 
Added the new update to get the NCOA address fields using the view mktg_ops_vws.cnst_addr_ncoa_log 

Modified by: Majeed Mohammad
Modified on: 06/22/2017
Purpose: Updated the NCOA UPDATED statement to use the new_cnst_mstr_id instead of old_cnst_mstr_id 

Modified by: Majeed Mohammad
Modified on: 06/22/2017
Purpose:  Added the subquery to get the account salutations IN and OUT. 

Modified by: Majeed Mohammad
Modified on: 07/12/2017
Purpose: Updated the subquery to use the arc_mdm_vws.bzl_cnst_mstr_fsa_acct and ddcoe_vws.bzfc_cnst_Fsa_all to get the account salutations related to a cnst_mstr_id. 
There are multiple accounts for a given cnst_mstr_id. We had to use the partition by function and order on the bzd_fmd_ind,srcsys_trans_dt to get the 1-1 relation between the account and cnst_mstr_id. 

Modified by: Majeed Mohammad
Modified on: 08/11/2017
Purpose: Added the columns inactvtn_reason_cd, inactvtn_reason_dsc, inactvtn_dt , inactvtn_reason_txt to track the inactive attributes 

Modified by: Majeed Mohammad
Modified on: 10/11/2017
Purpose: Removed the delete statements after the INSERT sql so that the collect stats script can get the correct stats

Modified By: Michael Andrien
Modified Date: 10/23/2017
Purpose:  Added dpv_cd from the bzfc_cnst_addr to further qualify the address assessment category coding.  We were getting a high volume of returned mail
				and were told to exclude mailing addresses that have a 'Deliverable' assessment but the dpv_cd is not equal to 'Y'

Modified by: Majeed Mohammad
Modified on: 11/17/2017
Purpose: Added the logic to load the table in two steps. The first steps retains the original logic of macro to load to STG table. 
The second steps uses the logic from the VWS and loads to the final table. 


Modified by: Majeed Mohammad
Modified on: 12/15/2017
Purpose: Corrected the table name to use the _STG table to get the name details for the 
secondary constituent associated with the primary constituent.

Modified By: Majeed Mohammad
Modified Date: 03/20/2018
Purpose:  Added the logic to exclude  the vms records from the group membership view 

Modified By: Mike Andrien
Modified Date: 06/05/2018
Purpose: Modify the group membership unit key update section to update based in the non-volunteer group lists

Modified by: Michael Andrien
Modified date:  03/13/2019
Purpose: Added the join logic to include the FR SaleForce Account and Contact IDs.

Modified by: Michael Andrien
Modified date:  07/25/2019
Purpose: Added logic to the Fresh Address (FAEM) section of the code to set the email assessment code to 'Validated'' if the email has no assessment code value in CDI (arc_mdm_vws).

Modified by: Michael Andrien
Modified date:  01/16/2020
Purpose: Added active_cnst_ind and active_email_cnst_ind.  Details tracked in Teamwork task #3508919

Modified by: Michael Andrien
Modified date:  01/18/2020
Purpose: Created a GMS version of the FR Preferred profile macro to segregate the GMS and DDCOE loads.  Coverted the GMS version of the macro to reference the new GMS ufds_vws database.

Modified by: Michael Andrien
Modified date:  04/8/2020
Purpose: Replaced DDCOE Salutatio query with UFDS query - missed this in initial GMS conversion

Modified by: Michael Andrien
Modified date:  10/30/2020
Purpose: Updated the NCOA update statement for the mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg table.  Added logic to account for instances when the old_locator_addr_key is null.

Modified by: Michael Andrien
Modified date:  11/01/2020
Purpose: Added the following columns to track CEM and NCOA updates:
	a.cem_all_mail_override_flg, 
	a.cem_fr_mail_override_flg, 
	a.cem_all_mail_override_ind, 
	a.cem_fr_mail_override_ind, 
	a.ncoa_mail_override_flg, 
	a.ncoa_mail_override_ind

Modified by: Michael Andrien
Modified date:  12/02/2020
Purpose  Added the three new attributes below and modified the actem query to remove the 24 month date qualify so the join query could be used to set both the active_email_cnst_ind and the last_email_open_dt.  Added the date qualifier the the select case statement
	case when  a.em_cnst_email_assessmnt_ctg in ('Validated', 'Use With Caution') and a.do_not_email_ind = 0 and (active.cnst_mstr_id is not null or  actem.last_email_open_dt >= add_months(current_date,-24)) then 1 else 0 end as active_email_cnst_ind,
	last_email_open_dt, last_email_intrctn_dt, last_dmail_intrctn_dt
	
Modified by: Michael Andrien
Modified date:  12/14/2020
Purpose	Modified the GMS Salutation subquery 
	From:
	select cnst_mstr_id, salutn as acct_in_salutn_nm, addressee as acct_out_salutn_nm, cnst_typ_cd
	from ufds_vws.bzfc_dim_unf_fr_cnst
	where cnst_typ_cd in ('AG','OR') and appl_src_cd='SFFS' and (salutn is not null or addressee is not null) and cnst_mstr_id is not null
	qualify row_number() over (partition by cnst_mstr_id  order by  active_ind desc, frf_cntct_id desc, frf_acct_id desc) = 1
	
	To:
	select lnk.cnst_mstr_id, fsa.frf_acct_id, fsa.salutn as acct_in_salutn_nm, fsa.addressee as acct_out_salutn_nm, fsa.cnst_typ_cd
    from ufds_vws.bzfc_dim_unf_fr_cnst fsa
    inner join ufds_vws.bzl_cnst_mstr_fsa_acct lnk on fsa.unf_fr_cnst_key= lnk.cnst_key
    where fsa.appl_src_cd='SFFS' and lnk.cnst_typ_cd in ('AG', 'OR') and (fsa.salutn is not null or fsa.addressee is not null) and lnk.cnst_mstr_id is not null
	qualify row_number() over (partition by cnst_mstr_id  order by  active_ind desc, frf_cntct_id desc, frf_acct_id desc) = 1

Modified By: Mike Andrien
Modified Date: 04/09/2021
Purpose: 
	1) Completely restructured the FAEM join, which was originally added to pull in the email address from the Fresh Address email append process.  The original join pulled the
	emails in from the arc_stage_tbls.stg_fresh_address table, which made the MODS team dependant on the CDI team to load the data.  Under the revised process, the MODS team loads return
	data from our email append vendor (formerly Fresh Address - currently Pacific East) into email append table in the mktg_ops_tbls database (fresh_address_email_append and pacific_east email_append).  The FAEM join
	unions the data from these tables, elimates duplicate append records by taking the most recent append, comparing the append email address to the ranked email selected in mktg_ops_tbls.cnst_cdi_s_f_p_fr_email, checks
	whether the append email is in our email profile table (mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile) - if so, has an ok_to_email_flag value of 'Y'.  If this criteria is met the FEAM record is used to overide the ranked email
	from the mktg_ops_tbls.cnst_cdi_s_f_p_fr_email.  We take this approach with emails from the email append process because the CDI team does not ingest them into the CDI email table.

	2) Modified the Active Email join (actem) to reference the mktg_ops_vws.gms_bzfc_cnst_cdi_fr_prfr_em_prfl table rather than gms_bzfc_fact_email_intrctn_smry.  Then, modified the logic for setting the active email indicator to include the ling
	clicked or openen in last 24 months and having the ok_to_email_flg = 'Y'.
	3) Added logic at the beginning of the macro to truncate and reload the mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile table.
	
Modified By: Majeed Mohammad
Modified Date: 04/16/2021
Purpose:  Added the delete statements at the end of the macro to clear out the temporary tables 	

Modified By: Mike Andrien
Modified Date: 04/16/2021
Purpose: 	Modified the table b query within the FAEM join to include the CASE statement below to account for instances where the email from the em ranking table is not found in the profile join table.  This was causing
some issue in selecting the proper email during the FAEM override
	case when c.email_addr is not null then c.ok_to_email_flg else NULL end as ok_to_email_flg
	
Modified By: Mike Andrien
Modified Date: 04/19/2021
Purpose:  Modified the actem join and the rules for setting the active_email_cnst_ind.  Also, modified the FAEM SQL qualifier to account for NULL values in the email profile table.  The original constraint 
was incorrectly suppressing newly appended email addresses.  Adding the where logic to consider NULL values fixed the issue.

Modified By: Mike Andrien
Modified Date: 04/28/2021
Purpose: Removed the steps to load the mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile.  We've implemented a macro to load the table and added the macro to our
evening Mktg load processed to load the physical email profile table after the incremental Adobe Campaign mappings and macros have run.
	--Load stage tables created to optimize the load process
	delete from mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile all;
	insert into mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile
	select * from mktg_ops_vws.gms_bzfc_cdi_fr_prfr_email_profile;
	
Modified By: Mike Andrien
Modified Date: 07/28/2021
Purpose:  Added the WHERE clause below to the UNIONED FAEM query to exclude logically deleted rows from the email append tables
			where a.row_stat_cd <> 'L'

Modified By: Mike Andrien
Modified Date: 11/13/2021
Purpose: Revised the logic for setting the active email indicator (active_email_cnst_ind) to account for the email addresses from the Emal Append process not being in the CDI database.  This fix 
was put in place in response to Teamwork ticket #8001561.  A MODS team member found instance where the active cnst indicator was equal to 1 and the cnst had a valid email address with no DNC, but 
the active email indicator was set to 0.  The revised logic fixes this issue.  
Added the extra 'or' logic below to the case statement
	or (active_cnst_ind = 1 and  faem.cnst_mstr_id is not null and a.do_not_email_ind = 0 and  (actem.ok_to_email_flg = 'Y'  or actem.ok_to_email_flg  IS NULL))
									then 1 else 0
	end as active_email_cnst_ind,

Modified By: Mike Andrien
Modified Date: 02/18/2022
Purpose: Added the Stuart Salutation UPDATE at the end of the script

Modified By: Majeed Mohammad
Modified Date: 10/27/2022
Purpose: The view mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr_src was changed to add additional logic. Also, added the columns dm_prsn_nm_src_cd & em_prsn_nm_src_cd

Modified By: Majeed Mohammad
Modified Date: 10/27/2022
Purpose:  Fixed the incorrect order of the columns in the final load to the table mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr 

Modified By: Majeed Mohammad
Modified Date: 10/31/2022
Purpose:  Added the column em_prsn_nm_src_cd to the inserts in the STG table and final table. 

Modified By: Mike Andrien
Modified Date: 11/09/2022
Purpose: Modified the Stuart Salutation update section to set the include the em and dm person name source code attributes to STRX.
		em_prsn_nm_src_cd = 'STRX',
		dm_prsn_nm_src_cd = 'STRX',
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_cnst_cdi_smry_fr_prfr', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN
	
		Truncate table mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_bzf_cem_cnst_opt_outs_stg;
		Insert into mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_bzf_cem_cnst_opt_outs_stg
		Select * from mktg_ops_vws.bzf_cem_cnst_opt_outs;
		COMMIT;

		Insert into mktg_stage_tbls.stg_gms_cnst_cdi_smry_fr_prfr_src
				SELECT 
				 M.cnst_mstr_id AS cnst_mstr_id
				,M.cnst_hsld_id AS cnst_hsld_id
				,M.cnst_arc_deceased_cd AS cnst_arc_deceased_cd
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.arc_srcsys_cd, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_data_src_cd, 'CASE_INSENSITIVE')
					END AS dm_prsn_nm_src_cd
				,DM.cnst_data_src_cd AS dm_cnst_data_src_cd
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN nm_rnk.locator_prsn_nm_key
					ELSE DM.locator_prsn_nm_key
					END AS dm_locator_prsn_nm_key
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.assessmnt_ctg::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_prsn_nm_assessmnt_ctg::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_prsn_nm_assessmnt_ctg
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_nm_prefix::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_prsn_prfx_nm::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_prsn_prfx_nm
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_first_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_prsn_f_nm::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_prsn_f_nm
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_middle_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_prsn_m_nm::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_prsn_m_nm
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_last_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_prsn_l_nm::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_prsn_l_nm
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_nm_suffix::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_prsn_sfx_nm::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_prsn_sfx_nm
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.cnst_prsn_full_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_prsn_full_nm::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_prsn_full_nm
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.bz_cnst_alias_in_saltn_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_alias_in_saltn_nm::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_alias_in_saltn_nm
				,CASE 
					WHEN DM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.bz_cnst_alias_out_saltn_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(DM.cnst_alias_out_saltn_nm::TEXT, 'CASE_INSENSITIVE')
					END AS dm_cnst_alias_out_saltn_nm
				,DM.locator_addr_key AS dm_locator_addr_key
				,DM.cnst_addr_assessmnt_ctg AS dm_cnst_addr_assessmnt_ctg
				,DM.dpv_cd
				,DM.cnst_line_1_addr AS dm_cnst_line_1_addr
				,DM.cnst_line_2_addr AS dm_cnst_line_2_addr
				,DM.cnst_city_nm AS dm_cnst_city_nm
				,DM.cnst_st_cd AS dm_cnst_st_cd
				,DM.cnst_zip_5_cd AS dm_cnst_zip_5_cd
				,DM.cnst_zip_4_cd AS dm_cnst_zip_4_cd
				,DM.cnst_addr_county_nm AS dm_cnst_addr_county_nm
				,DM.cnst_email AS dm_cnst_email
				,DM.cnst_org_nm AS dm_cnst_org_nm
				,DM.cnst_typ_dsc AS dm_cnst_typ_dsc
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.arc_srcsys_cd::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_data_src_cd::TEXT, 'CASE_INSENSITIVE')
					END AS em_prsn_nm_src_cd
				,EM.cnst_data_src_cd AS em_cnst_data_src_cd
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN nm_rnk.locator_prsn_nm_key
					ELSE EM.locator_prsn_nm_key
					END AS em_locator_prsn_nm_key
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.assessmnt_ctg::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_prsn_nm_assessmnt_ctg::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_prsn_nm_assessmnt_ctg
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_nm_prefix::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_prsn_prfx_nm::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_prsn_prfx_nm
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_first_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_prsn_f_nm::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_prsn_f_nm
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_middle_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_prsn_m_nm::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_prsn_m_nm
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_last_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_prsn_l_nm::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_prsn_l_nm
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.locator_prsn_nm_suffix::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_prsn_sfx_nm::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_prsn_sfx_nm
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.cnst_prsn_full_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_prsn_full_nm::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_prsn_full_nm
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.bz_cnst_alias_in_saltn_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_alias_in_saltn_nm::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_alias_in_saltn_nm
				,CASE 
					WHEN EM.cnst_prsn_l_nm IS NULL
						THEN collate(nm_rnk.bz_cnst_alias_out_saltn_nm::TEXT, 'CASE_INSENSITIVE')
					ELSE collate(EM.cnst_alias_out_saltn_nm::TEXT, 'CASE_INSENSITIVE')
					END AS em_cnst_alias_out_saltn_nm
				,EM.locator_addr_key AS em_locator_addr_key
				,EM.cnst_line_1_addr AS em_cnst_line_1_addr
				,EM.cnst_line_2_addr AS em_cnst_line_2_addr
				,EM.cnst_city_nm AS em_cnst_city_nm
				,EM.cnst_st_cd AS em_cnst_st_cd
				,EM.cnst_zip_5_cd AS em_cnst_zip_5_cd
				,EM.cnst_zip_4_cd AS em_cnst_zip_4_cd
				,EM.cnst_addr_county_nm AS em_cnst_addr_county_nm
				,EM.cnst_email AS em_cnst_email
				,EM.cnst_email_key AS em_email_key
				,EM.cnst_email_assessmnt_ctg AS em_cnst_email_assessmnt_ctg
				,EM.cnst_org_nm AS em_cnst_org_nm
				,EM.cnst_typ_dsc AS em_cnst_typ_dsc
				,0 AS email_dlvrbl_ind
				,hphone.prim_cnst_phn
				,hphone.prim_cnst_phn_source
				,hphone.prim_cnst_phn_typ_dsc
				,wphone.cnst_work_phone AS cnst_work_phn
				,wphone.cnst_work_phone_source AS cnst_work_phn_source
				,wphone.cnst_work_phone_type_cd AS cnst_work_phn_typ_dsc
				,mphone.cnst_mbl_phn
				,mphone.cnst_mbl_phn_source
				,mphone.cnst_mbl_phn_typ_dsc
				,CASE 
					WHEN fr_smry.benevity_suprsn_ind = 1
						THEN 1
					ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_hm_phn_ind, 0)
					END AS do_not_call_hm_phn_ind
				,CASE 
					WHEN fr_smry.benevity_suprsn_ind = 1
						THEN 1
					ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_mbl_phn_ind, 0)
					END AS do_not_call_mbl_phn_ind
				,CASE 
					WHEN fr_smry.benevity_suprsn_ind = 1
						THEN 1
					ELSE COALESCE(cnst_cntct_pref.fr_do_not_call_work_phn_ind, 0)
					END AS do_not_call_work_phn_ind
				,CASE 
					WHEN em.cnst_email LIKE '%@philips.com'
						THEN 1
					WHEN fr_smry.benevity_suprsn_ind = 1
						THEN 1
					ELSE COALESCE(cnst_cntct_pref.fr_do_not_email_ind, 0)
					END AS do_not_email_ind
				,CASE 
					WHEN fr_smry.benevity_suprsn_ind = 1
						THEN 1
					ELSE COALESCE(cnst_cntct_pref.fr_do_not_mail_ind, 0)
					END AS do_not_mail_ind
				,CASE 
					WHEN fr_smry.benevity_suprsn_ind = 1
						THEN 1
					ELSE COALESCE(cnst_cntct_pref.fr_do_not_txt_ind, 0)
					END AS do_not_txt_ind
				,NULL AS cnst_3rd_prty_segmtn_group_nm
				,CASE 
					WHEN DU.unit_key IS NULL
						THEN prim_chpt.prim_affl_unit_key
					ELSE DU.unit_key
					END AS unit_key
				,COALESCE(prim_chpt.acct_affl_lock_ind, 0) AS affl_lock_ind
				,COALESCE(mngd_dnr.frf_cur_mngd_dnr_ind, 0) AS sf_acct_fmd_ind
				,mngd_dnr.frf_status_cd
				,mngd_dnr.frf_cur_portfolio_ctg AS portfolio_category
				,mngd_dnr.rlshp_mgr_ownr_key
				,mngd_dnr.rlshp_mgr_nm
				,mngd_dnr.rlshp_mgr_prefd_email_addr
				,M.cnst_typ_cd
				,CASE 
					WHEN M.cnst_typ_cd = 'IN'
						THEN 'IN'
					ELSE org_typ.org_typ_cd
					END AS org_typ_cd
				,mngd_dnr.frf_acct_id
				,sf_cntct.frf_cntct_id
				,mngd_dnr.mult_sf_cnst_ind
			FROM 
			(
		SELECT DISTINCT a.cnst_mstr_id
		FROM 
		(
		SELECT  brid.cnst_mstr_id 
		FROM eda.arc_mdm_vws.bz_cnst_mstr_bridge brid 
		LEFT JOIN 
			(
				SELECT cnst_mstr_id, arc_srcsys_cd
				FROM mktg_ops_vws.bz_grp_mbrshp a 
				LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
				WHERE grp_typ NOT IN ('Vol NHQ LOB',  'Bio NHQ LOB', 'PHSS NHQ LOB') 
			) fr_list (cnst_mstr_id, arc_srcsys_cd) ON brid.cnst_mstr_id = fr_list.cnst_mstr_id AND brid.cnst_mstr_subj_area_cd = fr_list.arc_srcsys_cd

		WHERE 
		(
			cnst_mstr_subj_area_cd IN   ('RCO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'MDON')
			OR (cnst_mstr_subj_area_cd IN (SELECT arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='FR'))
			OR 	( brid.cnst_mstr_id = fr_list.cnst_mstr_id AND brid.cnst_mstr_subj_area_cd = fr_list.arc_srcsys_cd) 
			OR (brid.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM  mktg_ops_vws.atg_order_registrants WHERE atg_gift_cnt > 0) AND brid.cnst_mstr_subj_area_cd = 'ATGO')
			OR (brid.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM  mktg_ops_vws.atg_registrants WHERE atg_gift_cnt > 0) AND brid.cnst_mstr_subj_area_cd =  'ATG')
		)

		UNION ALL

		SELECT email.cnst_mstr_id
		FROM eda.arc_mdm_vws.bz_cnst_email email
		LEFT JOIN 
			(
				SELECT cnst_mstr_id, arc_srcsys_cd
				FROM mktg_ops_vws.bz_grp_mbrshp a 
				LEFT JOIN eda. arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
				WHERE grp_typ NOT IN ('Vol NHQ LOB',  'Bio NHQ LOB', 'PHSS NHQ LOB') 
			) fr_list (cnst_mstr_id, arc_srcsys_cd) ON email.cnst_mstr_id = fr_list.cnst_mstr_id AND email.arc_srcsys_cd = fr_list.arc_srcsys_cd

		WHERE 
		(
			email.arc_srcsys_cd IN    ('RCO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'MDON')
			OR (email.arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='FR'))
			OR 	( email.cnst_mstr_id = fr_list.cnst_mstr_id AND email.arc_srcsys_cd = fr_list.arc_srcsys_cd) 
			OR (email.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM  mktg_ops_vws.atg_order_registrants WHERE atg_gift_cnt > 0) AND email.arc_srcsys_cd = 'ATGO')
			OR (email.cnst_mstr_id IN (SELECT DISTINCT cnst_mstr_id FROM  mktg_ops_vws.atg_registrants WHERE atg_gift_cnt > 0) AND email.arc_srcsys_cd =  'ATG')
		)
		) a ) FR_CNST 
			JOIN eda.arc_mdm_vws.bz_cnst_mstr M ON fr_cnst.cnst_mstr_id = M.cnst_mstr_id
			LEFT OUTER JOIN mktg_ops_tbls.cnst_cdi_s_f_p_fr_dmail DM ON M.cnst_mstr_id = DM.cnst_mstr_id
			LEFT OUTER JOIN mktg_ops_tbls.cnst_cdi_s_f_p_fr_email EM ON M.cnst_mstr_id = EM.cnst_mstr_id
			LEFT OUTER JOIN (
				SELECT 
					a.cnst_mstr_id,
					a.affl_lock_ind AS acct_affl_lock_ind,
					b.unit_key AS prim_affl_unit_key
				FROM eda.ufds_vws.bzfc_cnst_fr_prfl a
				LEFT JOIN mktg_ops_vws.dim_unit_merged b ON a.rev_credit_key = orig_unit_key
			) prim_chpt ON M.cnst_mstr_id = prim_chpt.cnst_mstr_id
			LEFT JOIN (
			SELECT 
				cmfa.frf_acct_id,
				cmfa.cnst_mstr_id,
				cnst.unf_fr_cnst_key,
				cnst.frf_cur_mngd_dnr_ind,
				ownr.nm_line AS rlshp_mgr_nm,
				ownr.prefd_email_addr AS rlshp_mgr_prefd_email_addr,
				cnst.acct_ownr_key AS rlshp_mgr_ownr_key,
				cnst.frf_status_cd,
				cnst.frf_cur_portfolio_ctg,
				CASE WHEN frf_cnt.acct_cnt > 1 THEN 1 ELSE 0 END AS mult_sf_cnst_ind
			FROM (
				SELECT *
				FROM (
					SELECT 
						cmfa.frf_acct_id,
						cmfa.cnst_mstr_id,
						cmfa.cnst_key,
						cmfa.appl_src_cd,
						cmfa.cnst_typ_cd,
						ROW_NUMBER() OVER (
							PARTITION BY cmfa.cnst_mstr_id 
							ORDER BY 
								CASE WHEN cmfa.appl_src_cd = 'SFFS' THEN 1
									 WHEN cmfa.appl_src_cd = 'GMFS' THEN 2
									 ELSE 3 END,
								CASE WHEN cmfa.cnst_typ_cd IN ('AG','OR') THEN 1
									 ELSE 2 END,
								cnst.frf_cur_mngd_dnr_ind DESC NULLS LAST,
								cnst.active_ind DESC NULLS LAST,
								cnst.frf_active_ind DESC NULLS LAST,
								cnst.frf_acct_key DESC NULLS LAST,
								cmfa.cnst_key DESC
						) AS rn
					FROM eda.ufds_vws.bzl_cnst_mstr_fsa_acct cmfa
					LEFT JOIN eda.ufds_vws.bzfc_dim_unf_fr_cnst cnst 
						ON cmfa.cnst_key = cnst.unf_fr_cnst_key
					WHERE cmfa.cnst_mstr_id > 0
					  AND COALESCE(TRIM(cmfa.frf_acct_id),'') <> ''
				) sub
				WHERE rn = 1
			) cmfa
			LEFT JOIN eda.ufds_vws.bzfc_dim_unf_fr_cnst cnst 
				ON cmfa.cnst_key = cnst.unf_fr_cnst_key
			LEFT JOIN eda.ufds_vws.bzfc_dim_unf_fr_owner ownr 
				ON cnst.acct_ownr_key = ownr.unf_fr_cnst_key
			LEFT JOIN (
				SELECT
					cnst_mstr_id,
					COUNT(DISTINCT frf_acct_id) AS acct_cnt
				FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
				WHERE cnst_mstr_id > 0
				  AND COALESCE(TRIM(frf_acct_id),'') <> ''
				GROUP BY cnst_mstr_id
			) frf_cnt 
				ON cmfa.cnst_mstr_id = frf_cnt.cnst_mstr_id
		) AS mngd_dnr
		ON M.cnst_mstr_id = mngd_dnr.cnst_mstr_id

			LEFT OUTER JOIN mktg_ops_vws.bzfc_dim_unit_merged DU ON prim_chpt.prim_affl_unit_key = DU.orig_unit_key
			LEFT OUTER JOIN (
			SELECT *
			FROM (
				SELECT
					bz_cnst_phn.cnst_mstr_id,
					bz_cnst_phn.cnst_phn_num AS prim_cnst_phn,
					bz_cnst_phn.arc_srcsys_cd AS prim_cnst_phn_source,
					CAST(CASE 
						WHEN bz_cnst_phn.phn_typ_cd = 'H' THEN 'Home'
						ELSE 'Other'
					END AS VARCHAR(20)) AS prim_cnst_phn_typ_dsc,
					CASE 
						WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd
					END AS fr_arc_srcsys_cd,
					CASE 
						WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='SFFS' THEN 1
						WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='GMFS' THEN 2
						WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='TAFS' THEN 2.1
						WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
						WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='RCO' THEN 4.1
						WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='ATG' THEN 4.2
						WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='CNVO' THEN 5
						WHEN bz_cnst_phn.arc_srcsys_cd='CDIM' AND bz_cnst_phn.phn_typ_cd='LN' THEN 6
						ELSE 999
					END AS hnum,
					ROW_NUMBER() OVER (
						PARTITION BY bz_cnst_phn.cnst_mstr_id
						ORDER BY 
							CASE 
								WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='SFFS' THEN 1
								WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='GMFS' THEN 2
								WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='TAFS' THEN 2.1
								WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
								WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='RCO' THEN 4.1
								WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='ATG' THEN 4.2
								WHEN bz_cnst_phn.phn_typ_cd='H' AND bz_cnst_phn.arc_srcsys_cd='CNVO' THEN 5
								WHEN bz_cnst_phn.arc_srcsys_cd='CDIM' AND bz_cnst_phn.phn_typ_cd='LN' THEN 6
								ELSE 999
							END ASC,
							bz_cnst_phn.dw_srcsys_trans_ts DESC
					) AS rownum
				FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
				LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys
					ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
					AND bz_arc_srcsys.line_of_service_cd = 'FR'
				WHERE bz_cnst_phn.phn_typ_cd IN ('H', 'LN')
				  AND bz_cnst_phn.assessmnt_ctg = 'Usable'
				  AND bz_cnst_phn.cnst_phn_end_dt = '9999-12-31'
			) AS ranked_phns
			WHERE ranked_phns.hnum < 999 AND ranked_phns.rownum = 1
		) AS hphone
		ON M.cnst_mstr_id = hphone.cnst_mstr_id


		LEFT OUTER JOIN (
			SELECT *
			FROM (
				SELECT *
				FROM (
					SELECT
						bz_cnst_phn.cnst_mstr_id,
						bz_cnst_phn.cnst_phn_num AS cnst_work_phone,
						bz_cnst_phn.arc_srcsys_cd AS cnst_work_phone_source,
						CAST('Work' AS VARCHAR(20)) AS cnst_work_phone_type_cd,
						CASE 
							WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd 
						END AS fr_arc_srcsys_cd,
						CASE 
							WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' THEN 1
							WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'GMFS' THEN 2
							WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' THEN 2.1
							WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
							WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'RCO' THEN 4.1
							WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' THEN 4.2
							WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'CNVO' THEN 5
							ELSE 999
						END AS wnum,
						ROW_NUMBER() OVER (
							PARTITION BY bz_cnst_phn.cnst_mstr_id
							ORDER BY 
								CASE 
									WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' THEN 1
									WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'GMFS' THEN 2
									WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' THEN 2.1
									WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
									WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'RCO' THEN 4.1
									WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' THEN 4.2
									WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'CNVO' THEN 5
									ELSE 999
								END ASC,
								bz_cnst_phn.dw_srcsys_trans_ts DESC
						) AS rownum
					FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
					LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys
						ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
						AND bz_arc_srcsys.line_of_service_cd = 'FR'
					WHERE 
						bz_cnst_phn.phn_typ_cd = 'W'
						AND bz_cnst_phn.assessmnt_ctg = 'Usable'
						AND bz_cnst_phn.cnst_phn_end_dt = '9999-12-31'
				) AS ranked_work_phns
				WHERE rownum = 1 AND wnum < 999
			) AS filtered_work_phns
		) AS wphone
		ON M.cnst_mstr_id = wphone.cnst_mstr_id


		LEFT OUTER JOIN (
			SELECT *
			FROM (
				SELECT *
				FROM (
					SELECT
						bz_cnst_phn.cnst_mstr_id,
						bz_cnst_phn.cnst_phn_num AS cnst_mbl_phn,
						bz_cnst_phn.arc_srcsys_cd AS cnst_mbl_phn_source,
						CAST('Mobile' AS VARCHAR(20)) AS cnst_mbl_phn_typ_dsc,
						CASE 
							WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd 
						END AS fr_arc_srcsys_cd,
						CASE 
							WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' THEN 1
							WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'GMFS' THEN 2
							WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' THEN 2.1
							WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
							WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'RCO' THEN 4.1
							WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' THEN 4.2
							WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'CNVO' THEN 5
							WHEN bz_cnst_phn.arc_srcsys_cd = 'MDON' THEN 6
							ELSE 999
						END AS mnum,
						ROW_NUMBER() OVER (
							PARTITION BY bz_cnst_phn.cnst_mstr_id
							ORDER BY 
								CASE 
									WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' THEN 1
									WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'GMFS' THEN 2
									WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' THEN 2.1
									WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN 3
									WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'RCO' THEN 4.1
									WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' THEN 4.2
									WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'CNVO' THEN 5
									WHEN bz_cnst_phn.arc_srcsys_cd = 'MDON' THEN 6
									ELSE 999
								END ASC,
								bz_cnst_phn.dw_srcsys_trans_ts DESC
						) AS rownum
					FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
					LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys
						ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
						AND bz_arc_srcsys.line_of_service_cd IN ('FR', 'MDON')
					WHERE 
						(bz_cnst_phn.phn_typ_cd = 'M' OR bz_cnst_phn.arc_srcsys_cd = 'MDON')
						AND bz_cnst_phn.assessmnt_ctg = 'Usable'
						AND bz_cnst_phn.cnst_phn_end_dt = '9999-12-31'
				) AS ranked_mbl_phns
				WHERE rownum = 1 AND mnum < 999
			) AS filtered_mbl_phns
		) AS mphone
		ON M.cnst_mstr_id = mphone.cnst_mstr_id

		LEFT JOIN (
			SELECT *
			FROM (
				SELECT 
					a.cnst_mstr_id,
					b.locator_prsn_nm_key,
					a.cnst_typ_cd,
					b.locator_prsn_first_nm,
					b.locator_prsn_middle_nm,
					b.locator_prsn_last_nm,
					b.locator_prsn_nm_prefix,
					b.locator_prsn_nm_suffix,
					b.cnst_prsn_full_nm,
					b.bz_cnst_alias_out_saltn_nm,
					b.bz_cnst_alias_in_saltn_nm,
					b.assessmnt_ctg,
					b.arc_srcsys_cd,
					b.cnst_nm_strt_dt,
					b.dw_srcsys_trans_ts,
					ROW_NUMBER() OVER (
						PARTITION BY a.cnst_mstr_id
						ORDER BY 
							CASE 
								WHEN b.arc_srcsys_cd = 'STRX' THEN 1
								WHEN b.arc_srcsys_cd = 'CDIM' THEN 2
								WHEN b.arc_srcsys_cd = 'SFFS' THEN 3
								WHEN b.arc_srcsys_cd = 'GMFS' THEN 4
								WHEN b.arc_srcsys_cd = 'RCO'  THEN 5
								ELSE 6
							END,
							b.cnst_nm_strt_dt DESC,
							b.dw_srcsys_trans_ts DESC
					) AS row_num
				FROM eda.arc_mdm_vws.bz_cnst_mstr a
				LEFT JOIN (
					SELECT 
						a.cnst_mstr_id,
						a.locator_prsn_nm_key,
						a.locator_prsn_first_nm,
						a.locator_prsn_middle_nm,
						a.locator_prsn_last_nm,
						a.locator_prsn_nm_prefix,
						a.locator_prsn_nm_suffix,
						a.cnst_prsn_full_nm,
						a.bz_cnst_alias_out_saltn_nm,
						a.bz_cnst_alias_in_saltn_nm,
						a.assessmnt_ctg,
						a.arc_srcsys_cd,
						a.cnst_nm_strt_dt,
						a.dw_srcsys_trans_ts
					FROM eda.arc_mdm_vws.bzfc_cnst_prsn_nm a
					LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys b
						ON a.arc_srcsys_cd = b.arc_srcsys_cd
					WHERE 
						(b.line_of_service_cd = 'FR' OR a.arc_srcsys_cd IN ('CDIM', 'STRX'))
						AND a.assessmnt_ctg = 'Usable'
						AND a.cnst_prsn_nm_end_dt = '9999-12-31'
				) b ON a.cnst_mstr_id = b.cnst_mstr_id
			) AS ranked_names
			WHERE ranked_names.row_num = 1
		) AS nm_rnk 
		ON nm_rnk.cnst_mstr_id = M.cnst_mstr_id
			LEFT JOIN mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_bzf_cem_cnst_opt_outs_stg cnst_cntct_pref ON M.cnst_mstr_id = cnst_cntct_pref.cnst_mstr_id
		 LEFT JOIN (
			SELECT *
			FROM (
				SELECT 
					clss.cnst_mstr_id,
					clss.org_typ_cd,
					clss.dw_srcsys_trans_ts,
					clss.arc_srcsys_cd,
					ROW_NUMBER() OVER (
						PARTITION BY clss.cnst_mstr_id
						ORDER BY 
							CASE 
								WHEN clss.arc_srcsys_cd = 'SFFS' AND clss.org_typ_cd <> 'U' THEN 1
								WHEN clss.arc_srcsys_cd = 'GMFS' AND clss.org_typ_cd <> 'U' THEN 2
								WHEN clss.arc_srcsys_cd = 'TAFS' AND clss.org_typ_cd <> 'U' THEN 2.1
								WHEN clss.arc_srcsys_cd = 'SFFS' THEN 3
								WHEN clss.arc_srcsys_cd = 'GMFS' THEN 4
								WHEN clss.arc_srcsys_cd = 'TAFS' THEN 4.1
								ELSE 5 
							END,
							clss.dw_srcsys_trans_ts DESC
					) AS row_num
				FROM eda.arc_mdm_vws.bz_cnst_org_clssfctn clss
				INNER JOIN eda.arc_mdm_vws.bz_arc_srcsys src
					ON src.arc_srcsys_cd = clss.arc_srcsys_cd
				WHERE src.line_of_service_cd = 'FR'
			) ranked_org
			WHERE row_num = 1
		) org_typ ON M.cnst_mstr_id = org_typ.cnst_mstr_id
		LEFT JOIN (
			SELECT *
			FROM (
				SELECT 
					cnst_mstr_id,
					frf_cntct_id,
					ROW_NUMBER() OVER (
						PARTITION BY cnst_mstr_id 
						ORDER BY active_ind DESC, frf_cntct_id DESC
					) AS row_num
				FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
				WHERE appl_src_cd = 'SFFS' 
					AND cnst_typ_cd IN ('IN')
			) ranked_cntct
			WHERE row_num = 1
		) sf_cntct ON M.cnst_mstr_id = sf_cntct.cnst_mstr_id

			LEFT OUTER JOIN (
				SELECT cnst_mstr_id, benevity_suprsn_ind
				FROM mktg_ops_vws.gms_arc_fr_smry
			) fr_smry ON M.cnst_mstr_id = fr_smry.cnst_mstr_id; --174175046 rows updated in 7m 38s
		COMMIT;


		INSERT INTO mktg_stage_tbls.bzf_cem_fr_cnst_loc_prefs_tmp
		SELECT *
		FROM mktg_ops_vws.bzf_cem_fr_cnst_loc_prefs; --812501 rows updated in 4m 36s
		COMMIT;


		TRUNCATE TABLE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg;

		INSERT INTO mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg (
			cnst_mstr_id
			,cnst_hsld_id
			,cnst_arc_deceased_cd
			,dm_prsn_nm_src_cd
			,dm_cnst_data_src_cd
			,dm_locator_prsn_nm_key
			,dm_cnst_prsn_nm_assessmnt_ctg
			,dm_cnst_prsn_prfx_nm
			,dm_cnst_prsn_f_nm
			,dm_cnst_prsn_m_nm
			,dm_cnst_prsn_l_nm
			,dm_cnst_prsn_sfx_nm
			,dm_cnst_prsn_full_nm
			,dm_cnst_alias_in_saltn_nm
			,dm_cnst_alias_out_saltn_nm
			,dm_locator_addr_key
			,dm_cnst_addr_assessmnt_ctg
			,dpv_cd
			,dm_cnst_line_1_addr
			,dm_cnst_line_2_addr
			,dm_cnst_city_nm
			,dm_cnst_st_cd
			,dm_cnst_zip_5_cd
			,dm_cnst_zip_4_cd
			,dm_cnst_addr_county_nm
			,cem_all_mail_override_flg
			,cem_fr_mail_override_flg
			,cem_all_mail_override_ind
			,cem_fr_mail_override_ind
			,ncoa_mail_override_flg
			,ncoa_mail_override_ind
			,dm_cnst_email
			,dm_cnst_org_nm
			,dm_cnst_typ_dsc
			,em_prsn_nm_src_cd
			,em_cnst_data_src_cd
			,em_locator_prsn_nm_key
			,em_cnst_prsn_nm_assessmnt_ctg
			,em_cnst_prsn_prfx_nm
			,em_cnst_prsn_f_nm
			,em_cnst_prsn_m_nm
			,em_cnst_prsn_l_nm
			,em_cnst_prsn_sfx_nm
			,em_cnst_prsn_full_nm
			,em_cnst_alias_in_saltn_nm
			,em_cnst_alias_out_saltn_nm
			,em_locator_addr_key
			,em_cnst_line_1_addr
			,em_cnst_line_2_addr
			,em_cnst_city_nm
			,em_cnst_st_cd
			,em_cnst_zip_5_cd
			,em_cnst_zip_4_cd
			,em_cnst_addr_county_nm
			,em_cnst_email
			,em_email_key
			,em_cnst_email_assessmnt_ctg
			,em_cnst_org_nm
			,em_cnst_typ_dsc
			,email_dlvrbl_ind
			,prim_cnst_phn
			,prim_cnst_phn_source
			,prim_cnst_phn_typ_dsc
			,cnst_work_phn
			,cnst_work_phn_source
			,cnst_work_phn_typ_dsc
			,cnst_mbl_phn
			,cnst_mbl_phn_source
			,cnst_mbl_phn_typ_dsc
			,do_not_call_hm_phn_ind
			,do_not_call_mbl_phn_ind
			,do_not_call_work_phn_ind
			,do_not_email_ind
			,do_not_mail_ind
			,do_not_txt_ind
			,cnst_3rd_prty_segmtn_group_nm
			,unit_key
			,affl_lock_ind
			,sf_acct_fmd_ind
			,frf_status_cd
			,portfolio_category
			,rlshp_mgr_ownr_key
			,rlshp_mgr_nm
			,rlshp_mgr_prefd_email_addr
			,acct_in_salutn_nm
			,acct_out_salutn_nm
			,dm_pa_addr_check
			,unit_key_src
			,mktg_unit_key
			,cnst_typ_cd
			,org_typ_cd
			,inactvn_unf_fr_cnst_key
			,inactvtn_reason_cd
			,inactvtn_reason_dsc
			,inactvtn_dt
			,inactvtn_reason_txt
			,ag_bzd_sfid
			,cntct_bzd_sfid
			,mult_sf_cnst_ind
			)
		SELECT src.cnst_mstr_id
			,cnst_hsld_id
			,cnst_arc_deceased_cd
			,dm_prsn_nm_src_cd
			,dm_cnst_data_src_cd
			,dm_locator_prsn_nm_key
			,dm_cnst_prsn_nm_assessmnt_ctg
			,dm_cnst_prsn_prfx_nm
			,dm_cnst_prsn_f_nm
			,dm_cnst_prsn_m_nm
			,dm_cnst_prsn_l_nm
			,dm_cnst_prsn_sfx_nm
			,dm_cnst_prsn_full_nm
			,dm_cnst_alias_in_saltn_nm
			,dm_cnst_alias_out_saltn_nm
			,
			/* Use the address from the view mktg_ops_vws.bzf_cem_cnst_pref_loc, if available. 
				If this address is either Null or Undeliverable, use the address from the view mktg_ops_vws.cnst_cdi_smry_fr_prfr_src that is calculated using the address ranking rules */
			CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_locator_addr_key
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.fr_locator_addr_key
				ELSE src.dm_locator_addr_key
				END AS dm_locator_addr_key
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_cnst_addr_assessmnt_ctg
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.fr_cnst_addr_assessmnt_ctg
				ELSE src.dm_cnst_addr_assessmnt_ctg
				END AS dm_cnst_addr_assessmnt_ctg
			,src.dpv_cd
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_cnst_line_1_addr
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.fr_cnst_line_1_addr
				ELSE src.dm_cnst_line_1_addr
				END AS dm_cnst_line_1_addr
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_cnst_line_2_addr
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.fr_cnst_line_2_addr
				ELSE src.dm_cnst_line_2_addr
				END AS dm_cnst_line_2_addr
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_cnst_city_nm
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.fr_cnst_city_nm
				ELSE src.dm_cnst_city_nm
				END AS dm_cnst_city_nm
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_cnst_st_cd
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.fr_cnst_st_cd
				ELSE src.dm_cnst_st_cd
				END AS dm_cnst_st_cd
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_cnst_zip_5_cd
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.frl_cnst_zip_5_cd
				ELSE src.dm_cnst_zip_5_cd
				END AS dm_cnst_zip_5_cd
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_cnst_zip_4_cd
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.fr_cnst_zip_4_cd
				ELSE src.dm_cnst_zip_4_cd
				END AS dm_cnst_zip_4_cd
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.all_cnst_addr_county_nm
				WHEN pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN pref.fr_cnst_addr_county_nm
				ELSE src.dm_cnst_addr_county_nm
				END AS dm_cnst_addr_county_nm
			,
			/* Added the new indicators to specifiy if an address override happened  due to NCOA updates */
			CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN 'Y'
				ELSE 'N'
				END AS cem_all_mail_override_flg
			,CASE 
				WHEN pref.all_locator_addr_key IS NULL
					AND pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN 'Y'
				ELSE 'N'
				END AS cem_fr_mail_override_flg
			,CASE 
				WHEN pref.all_locator_addr_key IS NOT NULL
					AND COALESCE(pref.all_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN 1
				ELSE 0
				END AS cem_all_mail_override_ind
			,CASE 
				WHEN pref.all_locator_addr_key IS NULL
					AND pref.fr_locator_addr_key IS NOT NULL
					AND COALESCE(pref.fr_cnst_addr_assessmnt_ctg, 'Deliverable') = 'Deliverable'
					THEN 1
				ELSE 0
				END AS cem_fr_mail_override_ind
			,'N' AS ncoa_mail_override_flg
			,/*Default to N */
			0 AS ncoa_mail_override_ind
			,/* Defaul to 0 */
			dm_cnst_email
			,dm_cnst_org_nm
			,dm_cnst_typ_dsc
			,em_prsn_nm_src_cd
			,em_cnst_data_src_cd
			,em_locator_prsn_nm_key
			,em_cnst_prsn_nm_assessmnt_ctg
			,em_cnst_prsn_prfx_nm
			,em_cnst_prsn_f_nm
			,em_cnst_prsn_m_nm
			,em_cnst_prsn_l_nm
			,em_cnst_prsn_sfx_nm
			,em_cnst_prsn_full_nm
			,em_cnst_alias_in_saltn_nm
			,em_cnst_alias_out_saltn_nm
			,em_locator_addr_key
			,em_cnst_line_1_addr
			,em_cnst_line_2_addr
			,em_cnst_city_nm
			,em_cnst_st_cd
			,em_cnst_zip_5_cd
			,em_cnst_zip_4_cd
			,em_cnst_addr_county_nm
			,em_cnst_email
			,em_email_key
			,em_cnst_email_assessmnt_ctg
			,em_cnst_org_nm
			,em_cnst_typ_dsc
			,email_dlvrbl_ind
			,prim_cnst_phn
			,prim_cnst_phn_source
			,prim_cnst_phn_typ_dsc
			,cnst_work_phn
			,cnst_work_phn_source
			,cnst_work_phn_typ_dsc
			,cnst_mbl_phn
			,cnst_mbl_phn_source
			,cnst_mbl_phn_typ_dsc
			,do_not_call_hm_phn_ind
			,do_not_call_mbl_phn_ind
			,do_not_call_work_phn_ind
			,do_not_email_ind
			,do_not_mail_ind
			,do_not_txt_ind
			,cnst_3rd_prty_segmtn_group_nm
			,unit_key
			,affl_lock_ind
			,sf_acct_fmd_ind
			,frf_status_cd
			,portfolio_category
			,rlshp_mgr_ownr_key
			,rlshp_mgr_nm
			,rlshp_mgr_prefd_email_addr
			,salutn.acct_in_salutn_nm
			,salutn.acct_out_salutn_nm
			,'DM Address' AS dm_pa_addr_check
			,'PA Unit Key' AS unit_key_src
			,NULL::INTEGER AS mktg_unit_key
			,src.cnst_typ_cd
			,org_typ_cd
			,inactive_attrb.inactvn_unf_fr_cnst_key
			,inactive_attrb.inactvtn_reason_cd
			,inactive_attrb.inactvtn_reason_dsc
			,inactive_attrb.inactvtn_dt
			,inactive_attrb.inactvtn_reason_txt
			,ag_bzd_sfid
			,cntct_bzd_sfid
			,COALESCE(mult_sf_cnst_ind, 0) AS mult_sf_cnst_ind
		FROM mktg_stage_tbls.stg_gms_cnst_cdi_smry_fr_prfr_src src

		LEFT OUTER JOIN mktg_stage_tbls.bzf_cem_fr_cnst_loc_prefs_tmp pref 
			ON src.cnst_mstr_id = pref.cnst_mstr_id

		LEFT OUTER JOIN /* Get the Salutation Attributes */
		(
		/* Replace the DDCOE salutaion query with GMS query
				 select  distinct aa.cnst_mstr_id, lc.in_salutn_nm acct_in_salutn_nm, lc.out_salutn_nm acct_out_salutn_nm  from 
				arc_mdm_vws.bzl_cnst_mstr_fsa_acct aa 
				inner join ddcoe_vws.bzfc_cnst_Fsa_all lc on aa.bzd_cnst_fsa_key =lc.cnst_fsa_key
				 where lc.appl_src_cd = 'SFFS'and lc.cnst_typ_cd = 'AG' 
				and (lc.in_salutn_nm is not null or lc.out_salutn_nm is not null) 
				qualify row_number() over (partition by aa.cnst_mstr_id order by bzd_fmd_ind desc,srcsys_trans_dt desc, lc.row_eff_to_ts desc )=1 
		*/
			SELECT 
				cnst_mstr_id,
				frf_acct_id,
				acct_in_salutn_nm,
				acct_out_salutn_nm,
				cnst_typ_cd
			FROM (
				SELECT 
					lnk.cnst_mstr_id,
					fsa.frf_acct_id,
					fsa.salutn AS acct_in_salutn_nm,
					fsa.addressee AS acct_out_salutn_nm,
					fsa.cnst_typ_cd,
					ROW_NUMBER() OVER (
						PARTITION BY lnk.cnst_mstr_id 
						ORDER BY fsa.active_ind DESC, fsa.frf_cntct_id DESC, fsa.frf_acct_id DESC
					) AS rn
				FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst fsa
				INNER JOIN eda.ufds_vws.bzl_cnst_mstr_fsa_acct lnk 
					ON fsa.unf_fr_cnst_key = lnk.cnst_key
				WHERE fsa.appl_src_cd = 'SFFS' 
					AND lnk.cnst_typ_cd IN ('AG', 'OR')
					AND (fsa.salutn IS NOT NULL OR fsa.addressee IS NOT NULL)
					AND lnk.cnst_mstr_id IS NOT NULL
			) sub
			WHERE rn = 1
		) salutn ON salutn.cnst_mstr_id = src.cnst_mstr_id

		LEFT OUTER JOIN /* Get the Managed Donor Inactive Attributes */
		(
			SELECT 
				cnst_mstr_id,
				inactvn_unf_fr_cnst_key,
				active_ind,
				frf_active_ind,
				inactvtn_reason_cd,
				inactvtn_reason_dsc,
				inactvtn_dt,
				inactvtn_reason_txt
			FROM (
				SELECT 
					cnst_mstr_id,
					unf_fr_cnst_key AS inactvn_unf_fr_cnst_key,
					active_ind,
					frf_active_ind,
					inactvtn_reason_cd,
					inactvtn_reason_dsc,
					inactvtn_dt,
					inactvtn_reason_txt,
					ROW_NUMBER() OVER (
						PARTITION BY cnst_mstr_id 
						ORDER BY active_ind DESC, unf_fr_cnst_key DESC
					) AS rn
				FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
				WHERE inactvtn_dt IS NOT NULL
					AND cnst_mstr_id IS NOT NULL
			) sub
			WHERE rn = 1
		) inactive_attrb ON inactive_attrb.cnst_mstr_id = src.cnst_mstr_id; --122288754 rows updated in 4m 57s
		COMMIT;


		/* 10/11/2017: Majeed: Removed the delete statements after the INSERT sql so that the collect stats script can get the correct stats  								
		delete from mktg_stage_tbls.cnst_cdi_smry_fr_prfr_src_TMP;
		delete from mktg_stage_tbls.bzf_cem_fr_cnst_loc_prefs_TMP ;
		 */
		TRUNCATE TABLE mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm;

		INSERT INTO mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm (
			cnst_mstr_id
			,pa_unit_key
			,dm_cnst_line_1_addr
			,dm_cnst_line_2_addr
			,dm_cnst_city_nm
			,dm_cnst_st_cd
			,dm_cnst_zip_5_cd
			,dm_cnst_zip_4_cd
			,dm_cnst_addr_county_nm
			,affl_lock_ind
			,cnst_line_1_addr
			,cnst_line_2_addr
			,cnst_city_nm
			,cnst_st_cd
			,cnst_zip_5_cd
			,cnst_zip_4_cd
			,cnst_addr_county_nm
			,pa_locator_addr_key
			,dm_locator_addr_key
			,pa_addr_assessmnt_ctg
			,dm_addr_assessmnt_ctg
			,dm_unit_key
			)
		SELECT cnst_mstr_id
			,pa_unit_key
			,dm_cnst_line_1_addr
			,dm_cnst_line_2_addr
			,dm_cnst_city_nm
			,dm_cnst_st_cd
			,dm_cnst_zip_5_cd
			,dm_cnst_zip_4_cd
			,dm_cnst_addr_county_nm
			,affl_lock_ind
			,cnst_line_1_addr
			,cnst_line_2_addr
			,cnst_city_nm
			,cnst_st_cd
			,cnst_zip_5_cd
			,cnst_zip_4_cd
			,cnst_addr_county_nm
			,pa_locator_addr_key
			,dm_locator_addr_key
			,pa_addr_assessmnt_ctg
			,dm_addr_assessmnt_ctg
			,dm_unit_key
		FROM mktg_ops_vws.gms_cnst_cdi_smry_fr_pa_dm;
		COMMIT;

		/* If the PA_UNIT_KEY<>DM_UNIT_KEY and PA_Address=UnDeliverable, set the unit_key from DM fields. Exclude the records that have the affiliation lock set. */

		UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg
		SET unit_key_src = 'DM Unit key',
			unit_key = src.dm_unit_key
		FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm AS src
		WHERE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg.cnst_mstr_id = src.cnst_mstr_id
			AND COALESCE(src.dm_unit_key, 0) <> COALESCE(src.pa_unit_key, 0)
			AND COALESCE(src.pa_addr_assessmnt_ctg, '') <> 'Deliverable'
			AND COALESCE(src.affl_lock_ind, 0) <> 1; --0 records in 41 seconds
		COMMIT;


		/*If the unit_key is null and the DM address is deliverable, then use the unit_key from DM fields */	
		UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
		SET 
			unit_key_src = 'DM Unit key',
			unit_key = src.dm_unit_key
		FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_pa_dm AS src
		WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
		  AND COALESCE(tgt.unit_key, 0) = 0
		  AND COALESCE(src.dm_addr_assessmnt_ctg, '') = 'Deliverable'; --0 records in 41 seconds
		COMMIT;

		/*If the unit_key is null, set the unit_key from the stuart view mktg_ops_vws.cnst_sturt_lst_affl*/
		UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
		SET 
			unit_key_src = 'Stuart Unit key',
			unit_key = src.unit_key
		FROM mktg_ops_vws.cnst_sturt_lst_affl AS src
		WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
		  AND COALESCE(tgt.unit_key, 0) = 0; --56272 records in 29 seconds
		COMMIT;
		
		/*If the unit_key is null, set the unit_key from the Group membership view */
		UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
		SET unit_key_src = 'Grp Mbrshp Unit key'
			,unit_key = src.unit_key
		FROM (
			SELECT DISTINCT cnst_mstr_id
				,unit_key
			FROM (
				SELECT a.cnst_mstr_id
					,a.unit_key
					,ROW_NUMBER() OVER (
						PARTITION BY a.cnst_mstr_id ORDER BY a.srcsys_trans_ts DESC
						) AS rn
				FROM mktg_ops_vws.bz_grp_mbrshp a
				LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key
				WHERE grp_typ <> 'Vol NHQ LOB'
					AND COALESCE(unit_key, 0) > 0
				) sub
			WHERE rn = 1
			) AS src
		WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
			AND COALESCE(tgt.unit_key, 0) = 0;--- 768804 records in 33s
		COMMIT;
		
		/*Update statement to set the cnst_arc_deceased_cd=D when the cnst_arc_death_dt is not null. 
		The EDW team is updating this in the profiles. This is a temporary update until that is done */
		UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
		SET cnst_arc_deceased_cd = 'D'
		FROM eda.arc_mdm_vws.bz_cnst_mstr AS mstr
		WHERE tgt.cnst_mstr_id = mstr.cnst_mstr_id
			AND mstr.cnst_arc_death_dt IS NOT NULL; --1661328 records in 1m 40s
		COMMIT;

		UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg AS tgt
		SET 
			dm_locator_addr_key = src.new_locator_addr_key,
			dm_cnst_addr_assessmnt_ctg = src.assessmnt_ctg,
			dm_cnst_line_1_addr = src.cnst_addr_new_addr1,
			dm_cnst_line_2_addr = src.cnst_addr_new_addr2,
			dm_cnst_city_nm = src.cnst_addr_new_city_nm,
			dm_cnst_st_cd = src.cnst_addr_new_state_cd,
			dm_cnst_zip_5_cd = src.cnst_addr_new_zip_5_cd,
			dm_cnst_zip_4_cd = src.cnst_addr_new_zip_4_cd,
			dm_cnst_addr_county_nm = src.bz_cnst_addr_county_nm,
			ncoa_mail_override_flg = 'Y',
			ncoa_mail_override_ind = 1
		FROM mktg_ops_vws.cnst_addr_ncoa_log AS src
		WHERE tgt.cnst_mstr_id = src.new_cnst_mstr_id /*06/22/17: Majeed: Updated the join to use the new_cnst_mstr_id instead of old_cnst_mstr_id */
		  AND tgt.dm_cnst_line_1_addr = src.cnst_addr_old_addr1
		  AND tgt.dm_cnst_city_nm = src.cnst_addr_old_city_nm
		  AND tgt.dm_cnst_st_cd = src.cnst_addr_old_state_cd
		  AND (
				(src.old_locator_addr_key IS NULL AND src.cnst_addr_new_addr1 IS NOT NULL)
				OR src.old_locator_addr_key <> src.new_locator_addr_key
			  ); -- 0 records in 51 seconds
			  
		COMMIT;
		
		TRUNCATE TABLE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr;

		INSERT INTO mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr (
			cnst_mstr_id
			,cnst_hsld_id
			,cnst_arc_deceased_cd
			,dm_prsn_nm_src_cd
			,dm_cnst_data_src_cd
			,dm_locator_prsn_nm_key
			,dm_cnst_prsn_nm_assessmnt_ctg
			,dm_cnst_prsn_prfx_nm
			,dm_cnst_prsn_f_nm
			,dm_cnst_prsn_m_nm
			,dm_cnst_prsn_l_nm
			,dm_cnst_prsn_sfx_nm
			,dm_cnst_prsn_full_nm
			,dm_cnst_alias_in_saltn_nm
			,dm_cnst_alias_out_saltn_nm
			,dm_pa_addr_check
			,dm_locator_addr_key
			,dm_cnst_addr_assessmnt_ctg
			,dpv_cd
			,dm_cnst_line_1_addr
			,dm_cnst_line_2_addr
			,dm_cnst_city_nm
			,dm_cnst_st_cd
			,dm_cnst_zip_5_cd
			,dm_cnst_zip_4_cd
			,dm_cnst_addr_county_nm
			,cem_all_mail_override_flg
			,cem_fr_mail_override_flg
			,cem_all_mail_override_ind
			,cem_fr_mail_override_ind
			,ncoa_mail_override_flg
			,ncoa_mail_override_ind
			,dm_cnst_email
			,dm_cnst_org_nm
			,dm_cnst_typ_dsc
			,dm_cnst_prsn_prfx_nm2
			,dm_cnst_prsn_f_nm2
			,dm_cnst_prsn_m_nm2
			,dm_cnst_prsn_l_nm2
			,dm_cnst_prsn_sfx_nm2
			,dm_cnst_prsn_full_nm2
			,em_prsn_nm_src_cd
			,em_cnst_data_src_cd
			,em_locator_prsn_nm_key
			,em_cnst_prsn_nm_assessmnt_ctg
			,em_cnst_prsn_prfx_nm
			,em_cnst_prsn_f_nm
			,em_cnst_prsn_m_nm
			,em_cnst_prsn_l_nm
			,em_cnst_prsn_sfx_nm
			,em_cnst_prsn_full_nm
			,em_cnst_alias_in_saltn_nm
			,em_cnst_alias_out_saltn_nm
			,em_locator_addr_key
			,em_cnst_line_1_addr
			,em_cnst_line_2_addr
			,em_cnst_city_nm
			,em_cnst_st_cd
			,em_cnst_zip_5_cd
			,em_cnst_zip_4_cd
			,em_cnst_addr_county_nm
			,em_cnst_email
			,em_email_key
			,em_cnst_email_assessmnt_ctg
			,em_cnst_org_nm
			,em_cnst_typ_dsc
			,em_cnst_prsn_prfx_nm2
			,em_cnst_prsn_f_nm2
			,em_cnst_prsn_m_nm2
			,em_cnst_prsn_l_nm2
			,em_cnst_prsn_sfx_nm2
			,em_cnst_prsn_full_nm2
			,email_dlvrbl_ind
			,prim_cnst_phn
			,prim_cnst_phn_source
			,prim_cnst_phn_typ_dsc
			,cnst_work_phn
			,cnst_work_phn_source
			,cnst_work_phn_typ_dsc
			,cnst_mbl_phn
			,cnst_mbl_phn_source
			,cnst_mbl_phn_typ_dsc
			,do_not_call_hm_phn_ind
			,do_not_call_mbl_phn_ind
			,do_not_call_work_phn_ind
			,do_not_email_ind
			,do_not_mail_ind
			,do_not_txt_ind
			,cnst_3rd_prty_segmtn_group_nm
			,unit_key_src
			,unit_key
			,affl_lock_ind
			,sf_acct_fmd_ind
			,frf_status_cd
			,portfolio_category
			,rlshp_mgr_ownr_key
			,rlshp_mgr_nm
			,rlshp_mgr_prefd_email_addr
			,acct_in_salutn_nm
			,acct_out_salutn_nm
			,mktg_unit_key
			,cnst_typ_cd
			,org_typ_cd
			,has_smry_profile_ind
			,inactvn_unf_fr_cnst_key
			,inactvtn_reason_cd
			,inactvtn_reason_dsc
			,inactvtn_dt
			,inactvtn_reason_txt
			,ag_bzd_sfid
			,cntct_bzd_sfid
			,mult_sf_cnst_ind
			,active_cnst_ind
			,active_email_cnst_ind
			,last_email_open_dt
			,last_email_intrctn_dt
			,last_dmail_intrctn_dt
			)
		SELECT a.cnst_mstr_id AS cnst_mstr_id
			,a.cnst_hsld_id AS cnst_hsld_id
			,a.cnst_arc_deceased_cd AS cnst_arc_deceased_cd
			,a.dm_prsn_nm_src_cd AS dm_prsn_nm_src_cd
			,a.dm_cnst_data_src_cd AS dm_cnst_data_src_cd
			,a.dm_locator_prsn_nm_key AS dm_locator_prsn_nm_key
			,a.dm_cnst_prsn_nm_assessmnt_ctg AS dm_cnst_prsn_nm_assessmnt_ctg
			,a.dm_cnst_prsn_prfx_nm AS dm_cnst_prsn_prfx_nm
			,a.dm_cnst_prsn_f_nm AS dm_cnst_prsn_f_nm
			,a.dm_cnst_prsn_m_nm AS dm_cnst_prsn_m_nm
			,CAST(CASE 
					WHEN a.dm_cnst_typ_dsc = 'Organization'
						AND a.dm_cnst_prsn_l_nm IS NULL
						THEN a.dm_cnst_org_nm
					ELSE a.dm_cnst_prsn_l_nm
					END AS VARCHAR(50)) AS dm_cnst_prsn_l_nm
			,a.dm_cnst_prsn_sfx_nm AS dm_cnst_prsn_sfx_nm
			,a.dm_cnst_prsn_full_nm AS dm_cnst_prsn_full_nm
			,a.dm_cnst_alias_in_saltn_nm AS dm_cnst_alias_in_saltn_nm
			,a.dm_cnst_alias_out_saltn_nm AS dm_cnst_alias_out_saltn_nm
			,a.dm_pa_addr_check
			,a.dm_locator_addr_key AS dm_locator_addr_key
			,a.dm_cnst_addr_assessmnt_ctg AS dm_cnst_addr_assessmnt_ctg
			,a.dpv_cd AS dpv_cd
			,a.dm_cnst_line_1_addr AS dm_cnst_line_1_addr
			,a.dm_cnst_line_2_addr AS dm_cnst_line_2_addr
			,a.dm_cnst_city_nm AS dm_cnst_city_nm
			,a.dm_cnst_st_cd AS dm_cnst_st_cd
			,a.dm_cnst_zip_5_cd AS dm_cnst_zip_5_cd
			,a.dm_cnst_zip_4_cd AS dm_cnst_zip_4_cd
			,a.dm_cnst_addr_county_nm AS dm_cnst_addr_county_nm
			,a.cem_all_mail_override_flg
			,a.cem_fr_mail_override_flg
			,a.cem_all_mail_override_ind
			,a.cem_fr_mail_override_ind
			,a.ncoa_mail_override_flg
			,a.ncoa_mail_override_ind
			,a.dm_cnst_email AS dm_cnst_email
			,a.dm_cnst_org_nm AS dm_cnst_org_nm
			,a.dm_cnst_typ_dsc AS dm_cnst_typ_dsc
			,c.dm_cnst_prsn_prfx_nm AS dm_cnst_prsn_prfx_nm2
			,c.dm_cnst_prsn_f_nm AS dm_cnst_prsn_f_nm2
			,c.dm_cnst_prsn_m_nm AS dm_cnst_prsn_m_nm2
			,c.dm_cnst_prsn_l_nm AS dm_cnst_prsn_l_nm2
			,c.dm_cnst_prsn_sfx_nm AS dm_cnst_prsn_sfx_nm2
			,c.dm_cnst_prsn_full_nm AS dm_cnst_prsn_full_nm2
			,a.em_prsn_nm_src_cd
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_data_src_cd
				ELSE a.em_cnst_data_src_cd
				END AS em_cnst_data_src_cd
			,/* 4/25/17 MTA added for Fresh Address override*/
			a.em_locator_prsn_nm_key AS em_locator_prsn_nm_key
			,a.em_cnst_prsn_nm_assessmnt_ctg AS em_cnst_prsn_nm_assessmnt_ctg
			,a.em_cnst_prsn_prfx_nm AS em_cnst_prsn_prfx_nm
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_prsn_f_nm
				ELSE a.em_cnst_prsn_f_nm
				END AS em_cnst_prsn_f_nm
			,a.em_cnst_prsn_m_nm AS em_cnst_prsn_m_nm
			,CAST(CASE 
					WHEN (
							a.dm_cnst_typ_dsc = 'Organization'
							AND a.em_cnst_prsn_l_nm IS NULL
							)
						THEN a.em_cnst_org_nm
					WHEN faem.cnst_mstr_id IS NOT NULL
						THEN faem.em_cnst_prsn_l_nm
					ELSE a.em_cnst_prsn_l_nm
					END AS VARCHAR(50)) AS em_cnst_prsn_l_nm
			,a.em_cnst_prsn_sfx_nm AS em_cnst_prsn_sfx_nm
			,a.em_cnst_prsn_full_nm AS em_cnst_prsn_full_nm
			,a.em_cnst_alias_in_saltn_nm AS em_cnst_alias_in_saltn_nm
			,a.em_cnst_alias_out_saltn_nm AS em_cnst_alias_out_saltn_nm
			,a.em_locator_addr_key
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_line_1_addr
				ELSE a.em_cnst_line_1_addr
				END AS em_cnst_line_1_addr
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_line_2_addr
				ELSE a.em_cnst_line_2_addr
				END AS em_cnst_line_2_addr
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_city_nm
				ELSE a.em_cnst_city_nm
				END AS em_cnst_city_nm
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_st_cd
				ELSE a.em_cnst_st_cd
				END AS em_cnst_st_cd
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_zip_5_cd
				ELSE a.em_cnst_zip_5_cd
				END AS em_cnst_zip_5_cd
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN NULL
				ELSE a.em_cnst_zip_4_cd
				END AS em_cnst_zip_4_cd
			,a.em_cnst_addr_county_nm AS em_cnst_addr_county_nm
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_email
				ELSE a.em_cnst_email
				END AS em_cnst_email
			,/* 4/25/17 MTA added for Fresh Address override */
			CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN COALESCE(faem.em_email_key, 0)
				ELSE COALESCE(a.em_email_key, 0)
				END AS em_email_key
			,/* 2/10/17 Webi universe was using em_cnst_email_key, but Adobe is using em_locator_addr_key  :  4/25/17 MTA added for Fresh Address override */
			CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN faem.em_cnst_email_assessmnt_ctg
				ELSE a.em_cnst_email_assessmnt_ctg
				END AS em_cnst_email_assessmnt_ctg
			,/* 4/25/17 MTA added for Fresh Address override */
			a.em_cnst_org_nm AS em_cnst_org_nm
			,CASE 
				WHEN faem.cnst_mstr_id IS NOT NULL
					THEN 'IN'
				ELSE a.em_cnst_typ_dsc
				END AS em_cnst_typ_dsc
			,c.em_cnst_prsn_prfx_nm AS em_cnst_prsn_prfx_nm2
			,c.em_cnst_prsn_f_nm AS em_cnst_prsn_f_nm2
			,c.em_cnst_prsn_m_nm AS em_cnst_prsn_m_nm2
			,c.em_cnst_prsn_l_nm AS em_cnst_prsn_l_nm2
			,c.em_cnst_prsn_sfx_nm AS em_cnst_prsn_sfx_nm2
			,c.em_cnst_prsn_full_nm AS em_cnst_prsn_full_nm2
			,a.email_dlvrbl_ind AS email_dlvrbl_ind
			,a.prim_cnst_phn AS prim_cnst_phn
			,a.prim_cnst_phn_source AS prim_cnst_phn_source
			,a.prim_cnst_phn_typ_dsc AS prim_cnst_phn_typ_dsc
			,a.cnst_work_phn AS cnst_work_phn
			,a.cnst_work_phn_source AS cnst_work_phn_source
			,a.cnst_work_phn_typ_dsc AS cnst_work_phn_typ_dsc
			,a.cnst_mbl_phn AS cnst_mbl_phn
			,a.cnst_mbl_phn_source AS cnst_mbl_phn_source
			,a.cnst_mbl_phn_typ_dsc AS cnst_mbl_phn_typ_dsc
			,a.do_not_call_hm_phn_ind AS do_not_call_hm_phn_ind
			,a.do_not_call_mbl_phn_ind AS do_not_call_mbl_phn_ind
			,a.do_not_call_work_phn_ind AS do_not_call_work_phn_ind
			,a.do_not_email_ind AS do_not_email_ind
			,a.do_not_mail_ind AS do_not_mail_ind
			,a.do_not_txt_ind AS do_not_txt_ind
			,a.cnst_3rd_prty_segmtn_group_nm AS cnst_3rd_prty_segmtn_group_nm
			,a.unit_key_src AS unit_key_src
			,a.unit_key AS unit_key
			,COALESCE(a.affl_lock_ind, 0) AS affl_lock_ind
			,a.sf_acct_fmd_ind AS sf_acct_fmd_ind
			,a.frf_status_cd
			,a.portfolio_category
			,a.rlshp_mgr_ownr_key
			,a.rlshp_mgr_nm AS rlshp_mgr_nm
			,a.rlshp_mgr_prefd_email_addr AS bzd_prefd_email_addr
			,a.acct_in_salutn_nm AS acct_in_salutn_nm
			,a.acct_out_salutn_nm AS acct_out_salutn_nm
			,e.unit_key AS mktg_unit_key
			,a.cnst_typ_cd
			,a.org_typ_cd
			,CASE 
				WHEN f.cnst_mstr_id IS NULL
					THEN 0
				ELSE 1
				END AS has_smry_profile_ind
			,/* The summary profile indicator allows users to identify which cnstituents have been linked to gifts.  
		This can be leverage in the DDCOE universe to avoid double counting gifts when reporting at the master id grain.  This is useful in first time gift analysis when a constituent has multiple TA acount
		ids or is in both TA and has distinct cnst_fsa_keys from migrated chapter data. */
			a.inactvn_unf_fr_cnst_key
			,a.inactvtn_reason_cd
			,a.inactvtn_reason_dsc
			,a.inactvtn_dt
			,a.inactvtn_reason_txt
			,a.ag_bzd_sfid
			,a.cntct_bzd_sfid
			,a.mult_sf_cnst_ind
			,CASE 
				WHEN active.cnst_mstr_id IS NOT NULL
					THEN 1
				ELSE 0
				END AS active_cnst_ind
			,--case when  a.em_cnst_email_assessmnt_ctg in ('Validated', 'Use With Caution') and a.do_not_email_ind = 0 and (active.cnst_mstr_id is not null or  actem.cnst_mstr_id is not null) then 1 else 0 end as active_email_cnst_ind
			CASE 
				WHEN (
						a.em_cnst_email_assessmnt_ctg IN (
							'Validated'
							,'Use With Caution'
							)
						AND a.do_not_email_ind = 0
						AND (
							actem.ok_to_email_flg = 'Y'
							OR actem.ok_to_email_flg IS NULL
							)
						AND (
							active.fr_last_dntn_dt >= DATEADD(month, - 24, CURRENT_DATE)
							OR actem.last_email_open_dt >= DATEADD(month, - 24, CURRENT_DATE)
							OR actem.last_email_link_click_dt >= DATEADD(month, - 24, CURRENT_DATE)
							)
						)
					OR (
						active_cnst_ind = 1
						AND faem.cnst_mstr_id IS NOT NULL
						AND a.do_not_email_ind = 0
						AND (
							actem.ok_to_email_flg = 'Y'
							OR actem.ok_to_email_flg IS NULL
							)
						)
					THEN 1
				ELSE 0
				END AS active_email_cnst_ind
			,actem.last_email_open_dt
			,emi.last_email_intrctn_dt
			,dmin.last_dmail_intrctn_dt
		FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg a
		/* join the FR CDI Preferred table to the table that contains the primary and secondary name ids.  This table is built on the EDW 
		box from the based the the DDCOE/TA acounts.  The table associate the primary and secondary name ids for the account
		*/
		LEFT JOIN mktg_ops_tbls.bzf_cnst_cdi_sltn_id b ON a.cnst_mstr_id = b.pn_cnst_mstr_id /* join the CDI FR Preferred cnst_mstr id to the primary master id in the bridge table */
		/* Now we join the CDI FR preferred table to the table to the same primary to secondary master id bridge table to the secondary cnst_mstr_id to get the name details for the 
		secondary constituent associated with the primary constituent.
		*/
		LEFT JOIN mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg c ON c.cnst_mstr_id = b.sn_cnst_mstr_id
		/*  04/27/16 - Mike Andrien added the joins below to derive the 'Marketing' unit key based on the zip code of the DM address */
		LEFT JOIN mktg_ops_vws.geo_zip_code_to_chapter d ON d.zip = a.dm_cnst_zip_5_cd
		LEFT JOIN mktg_ops_vws.dim_unit e ON d.ECODE = e.nk_ecode
		LEFT JOIN mktg_ops_vws.gms_arc_fr_smry f ON a.cnst_mstr_id = f.cnst_mstr_id
		/* 04/25/2017  Added join to Fresh Address email table - MTA*/
		LEFT JOIN (
			SELECT *
			FROM (
				SELECT 
					a.cnst_mstr_id,
					a.cnst_prsn_f_nm,
					a.cnst_prsn_l_nm,
					a.cnst_line_1_addr,
					a.cnst_line_2_addr,
					a.cnst_city_nm,
					a.cnst_st_cd,
					a.cnst_zip_5_cd,
					a.cnst_email,
					a.list_source_nm,
					a.em_cnst_data_src_cd,
					a.em_email_key,
					a.em_cnst_email_assessmnt_ctg,
					a.ok_to_email_flg,
					a.list_upload_ts,
					ROW_NUMBER() OVER (PARTITION BY a.cnst_mstr_id ORDER BY a.list_upload_ts DESC) AS rn
				FROM (
					SELECT 
						peem.cnst_mstr_id,
						peem.cnst_prsn_f_nm,
						peem.cnst_prsn_l_nm,
						peem.cnst_line_1_addr,
						peem.cnst_line_2_addr,
						peem.cnst_city_nm,
						peem.cnst_st_cd,
						peem.cnst_zip_5_cd,
						peem.cnst_email,
						peem.list_source_nm,
						'PEEM' AS em_cnst_data_src_cd,
						ble.email_key AS em_email_key,
						COALESCE(ba.assessmnt_ctg, 'Validated') AS em_cnst_email_assessmnt_ctg,
						ep.ok_to_email_flg,
						peem.list_upload_ts
					FROM mktg_ops_tbls.pacific_east_email_append peem
					LEFT JOIN eda.arc_mdm_vws.bz_locator_email ble ON ble.cnst_email_addr = peem.cnst_email
					LEFT JOIN eda.arc_mdm_vws.bz_assessmnt ba ON ble.assessmnt_key = ba.assessmnt_key
					LEFT JOIN mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile ep ON peem.cnst_email = ep.email_addr
					WHERE peem.row_stat_cd <> 'L'
					
					UNION ALL
					
					SELECT 
						faem.cnst_mstr_id,
						faem.cnst_prsn_f_nm,
						faem.cnst_prsn_l_nm,
						faem.cnst_line_1_addr,
						faem.cnst_line_2_addr,
						faem.cnst_city_nm,
						faem.cnst_st_cd,
						faem.cnst_zip_5_cd,
						faem.cnst_email,
						faem.list_nm AS list_source_nm,
						'FAEM' AS em_cnst_data_src_cd,
						ble.email_key AS em_email_key,
						COALESCE(ba.assessmnt_ctg, 'Validated') AS em_cnst_email_assessmnt_ctg,
						ep.ok_to_email_flg,
						faem.list_upload_ts
					FROM mktg_ops_tbls.fresh_address_email_append faem
					LEFT JOIN eda.arc_mdm_vws.bz_locator_email ble ON ble.cnst_email_addr = faem.cnst_email
					LEFT JOIN eda.arc_mdm_vws.bz_assessmnt ba ON ble.assessmnt_key = ba.assessmnt_key
					LEFT JOIN mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile ep ON faem.cnst_email = ep.email_addr
					WHERE faem.row_stat_cd <> 'L'
				) a
				LEFT JOIN (
				/*
				This next query is retrieving the FR preferred email from the email ranking table to assess whether the preferred email from the ranking process is ok to email.  we'll compared the assessment
				results between the append email details from the join above to the ranked email details to decide whether the to override the email selected from the CDI ranking process with the append email.
				*/
					SELECT 
						cdi.cnst_mstr_id,
						cdi.cnst_email_key,
						cdi.cnst_email,
						cdi.cnst_email_assessmnt_ctg,
						cdi.cnst_data_src_cd,
						ce.cnst_email_strt_ts,
						CASE WHEN ep.email_addr IS NOT NULL THEN ep.ok_to_email_flg ELSE NULL END AS ok_to_email_flg
					FROM mktg_ops_tbls.cnst_cdi_s_f_p_fr_email cdi
					LEFT JOIN eda.arc_mdm_vws.bzfc_cnst_email ce 
						ON cdi.cnst_mstr_id = ce.cnst_mstr_id 
						AND cdi.cnst_email_key = ce.email_key 
						AND COLLATE(cdi.cnst_data_src_cd, 'CASE_INSENSITIVE') = COLLATE(ce.arc_srcsys_cd, 'CASE_INSENSITIVE')
					LEFT JOIN mktg_ops_vws.gms_bzfc_cnst_cdi_fr_prfr_em_prfl ep 
						ON cdi.cnst_mstr_id = ep.cnst_mstr_id
				) b ON a.cnst_mstr_id = b.cnst_mstr_id
				WHERE (a.ok_to_email_flg IS NULL OR a.ok_to_email_flg = 'Y')
					AND ((COLLATE(a.cnst_email, 'CASE_INSENSITIVE') <> COLLATE(b.cnst_email, 'CASE_INSENSITIVE') 
					AND a.list_upload_ts >= b.cnst_email_strt_ts) 
						 OR (b.cnst_mstr_id IS NULL))
			) ranked
			WHERE rn = 1
		) faem(cnst_mstr_id, em_cnst_prsn_f_nm, em_cnst_prsn_l_nm, em_cnst_line_1_addr, em_cnst_line_2_addr, em_cnst_city_nm, em_cnst_st_cd, em_cnst_zip_5_cd, em_cnst_email, em_list_source_nm, em_cnst_data_src_cd, em_email_key, em_cnst_email_assessmnt_ctg, ok_to_email_flg, list_upload_ts) 
			ON a.cnst_mstr_id = faem.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				cnst_mstr_id,
				fr_last_dntn_dt
			FROM mktg_ops_vws.gms_arc_fr_smry
			WHERE fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE)
		) active ON a.cnst_mstr_id = active.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				cnst_mstr_id,
				ok_to_email_flg,
				MAX(last_em_open_dt) AS last_email_open_dt,
				MAX(last_em_link_click_dt) AS last_email_link_click_dt
			FROM mktg_ops_vws.gms_bzfc_cnst_cdi_fr_prfr_em_prfl
			WHERE last_em_open_dt IS NOT NULL
				OR last_em_link_click_dt IS NOT NULL
			GROUP BY cnst_mstr_id, ok_to_email_flg
		) actem ON a.cnst_mstr_id = actem.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				cnst_mstr_id,
				MAX(intrctn_dt) AS last_email_intrctn_dt
			FROM mktg_ops_vws.bzfc_fact_email_interaction
			WHERE intrctn_status_key = 1
			GROUP BY cnst_mstr_id
		) emi ON a.cnst_mstr_id = emi.cnst_mstr_id
		LEFT JOIN (
			SELECT 
				cnst_mstr_id,
				MAX(intrctn_dt) AS last_dmail_intrctn_dt
			FROM mktg_ops_vws.bzfc_fact_dmail_intrctn_norm
			GROUP BY cnst_mstr_id
		) dmin ON a.cnst_mstr_id = dmin.cnst_mstr_id;
		COMMIT;

		UPDATE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr AS tgt
		SET em_prsn_nm_src_cd = 'STRX'
			,em_cnst_alias_in_saltn_nm = src.bz_cnst_alias_in_saltn_nm
			,em_cnst_alias_out_saltn_nm = src.bz_cnst_alias_out_saltn_nm
			,dm_prsn_nm_src_cd = 'STRX'
			,dm_cnst_alias_in_saltn_nm = src.bz_cnst_alias_in_saltn_nm
			,dm_cnst_alias_out_saltn_nm = src.bz_cnst_alias_out_saltn_nm
		FROM (
			SELECT cnst_mstr_id
				,bz_cnst_alias_out_saltn_nm
				,bz_cnst_alias_in_saltn_nm
			FROM (
				SELECT cnst_mstr_id
					,bz_cnst_alias_out_saltn_nm
					,bz_cnst_alias_in_saltn_nm
					,ROW_NUMBER() OVER (
						PARTITION BY cnst_mstr_id ORDER BY CASE 
								WHEN cnst_prsn_nm_typ_cd = 'ARC'
									THEN 1
								WHEN cnst_prsn_nm_typ_cd = 'PN'
									THEN 2
								WHEN cnst_prsn_nm_typ_cd = 'LN'
									THEN 3
								ELSE 4
								END
						) AS rn
				FROM eda.arc_mdm_vws.bz_cnst_prsn_nm
				WHERE arc_srcsys_cd = 'STRX'
					AND TRIM(bz_cnst_alias_out_saltn_nm) <> TRIM(cnst_prsn_full_nm)
				) sub
			WHERE rn = 1
			) AS src
		WHERE tgt.cnst_mstr_id = src.cnst_mstr_id; --0 records in 1m 8seconds
		COMMIT;

		/*delete the data from the temporary tables */
		TRUNCATE TABLE mktg_stage_tbls.stg_gms_cnst_cdi_smry_fr_prfr_src;

		TRUNCATE TABLE mktg_stage_tbls.bzf_cem_fr_cnst_loc_prefs_tmp;

		TRUNCATE TABLE mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr) as INTEGER)
        WHERE proc_name = 'ld_gms_cnst_cdi_smry_fr_prfr' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_gms_cnst_cdi_smry_fr_prfr: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_gms_cnst_cdi_smry_fr_prfr', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
