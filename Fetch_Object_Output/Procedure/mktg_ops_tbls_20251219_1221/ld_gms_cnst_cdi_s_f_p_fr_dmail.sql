CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_cnst_cdi_s_f_p_fr_dmail()
 LANGUAGE plpgsql
AS $$
/*
Created By: Rameshbabu Ramachandran
Created Date: 12-Jun-2014
Purpose: This macro inserts the data  into a cnst_cdi_s_f_p_fr_dmail  base table.

Modified By: Rameshbabu Ramachandran
Modified Date: June -17-2014
Purpose:  Included new filter condition cnst_prsn_nm_typ_cd in ('PN','LN') in PERSN_NM table. This is migrated through task # 
224 .

Modified By: Rameshbabu Ramachandran
Modified Date: June -27-2014
Purpose:  Included new org_nm and cnst_typ_desc columns and added new bz_cnst_org_nm table join This is migrated through CCB 
Item # 25.

Modified By: Rameshbabu Ramachandran
Modified Date: July -21-2014
Purpose:  Included new full name, in&out saltn name and email key for both Dmail and Email.This is migrated through CCB Item 
#  

Modified By: Majeed Mohammad
Modified Date: 02/06/2015
Purpose: Added the columns for locator_addr_key, cnst_addr_assessmnt_ctg and county 


Modified By: Majeed Mohammad
Modified Date: 3/19/2015
Purpose: Added the ranking hierarchy based on the rules given by Mehreen


Modified By: Majeed Mohammad
Modified Date: 08/05/2016
Purpose: Removed the ATG and ATGO records.

Modified By: Majeed Mohammad
Modified Date: 09/28/2016
Purpose: Updated the macro to use the view arc_mdm_vws.bzfc_cnst_email  instead of  arc_mdm_vws.bz_cnst_email . 
Also used the corrected email column locator_email_addr


Modified By: Majeed Mohammad
Modified Date: 10/19/2016
Purpose:  
1. Updated the join to the table arc_mdm_tbls.locator_addr and included  the condition locator_addr_end_ts  ='9999-12-31 00:00:00' 
2. Added the logic to get the name locator key and name assessment

Modified By: Majeed Mohammad
Modified Date: 10/20/2016
Purpose:  Updated the timestamp format for 12/31/9999 

Modified By: Michael Andrien
Modified Date 4/7/2017
Purpuse:  Added logic to the name selection section to exclude non-usable names and names where the first and last name were the same.  Also,
				updated the ranking rule logic for the CDIM rule to ensure the first and last names are not null.  This was added to address an issue where 
				the CDIM source rule was selected but the first and last names of the CDIM record were the same.  The new rule forces a difference source rule to be select
				and, in most cases, the name is correct.  We are working on broader rule changes, which will be implemented soon.
				
				Added Details below: 
				 To Name logic: AND bz_nm.bz_cnst_prsn_first_nm <> bz_nm.bz_cnst_prsn_last_nm and (bz_nm.assessmnt_ctg in ('Usable', 'Use With Caution') or bz_nm.assessmnt_ctg is null)

				To rules logic:  NOTE: I added COA1-3 NCOA data source exclusions - we need to design work arounds for the NCOA sources becuase they don't have name records in CDI.				
				WHEN cnst_addr.dw_srcsys_trans_ts>date-365 and coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable' AND cnst_addr.arc_srcsys_cd not in ('SFFS','ATG', 'ATGO','CNVO','TAFS', 'CDIM', 'COA1', 'COA2','COA3')   
and cnst_addr.cnst_addr_prefd_ind = 1 THEN 20
WHEN cnst_addr.dw_srcsys_trans_ts>date-365 and coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable' AND cnst_addr.arc_srcsys_cd not in ('SFFS','ATG', 'ATGO','CNVO','TAFS', 'CDIM', 'COA1', 'COA2','COA3')   
and cnst_addr.cnst_addr_typ_cd='H' THEN 20.1
WHEN cnst_addr.dw_srcsys_trans_ts>date-365 and coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable' AND cnst_addr.arc_srcsys_cd not in ('SFFS','ATG', 'ATGO','CNVO','TAFS', 'CDIM', 'COA1', 'COA2','COA3')   
and cnst_addr.cnst_addr_typ_cd<> 'H' THEN 20.2

and cnst_addr.cnst_addr_prefd_ind = 1 THEN 39
WHEN cnst_addr.dw_srcsys_trans_ts<=date-365 and coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable' AND cnst_addr.arc_srcsys_cd not in ('SFFS','ATG', 'ATGO','CNVO','TAFS', 'CDIM', 'COA1', 'COA2','COA3')   
and cnst_addr.cnst_addr_typ_cd='H' THEN 39.1
WHEN cnst_addr.dw_srcsys_trans_ts<=date-365 and coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable' AND cnst_addr.arc_srcsys_cd not in ('SFFS','ATG', 'ATGO','CNVO','TAFS', 'CDIM', 'COA1', 'COA2','COA3')    
and cnst_addr.cnst_addr_typ_cd<> 'H' THEN 39.2

Modified By: Majeed Mohammad
Modified Date: 06/22/17
Purpose:  Added the condition for the cnst_addr_typ_cd as there are multiple records with cnst_addr_prefd_ind = 1

Modified By: Michael Andrien
Modified Date: 10/21/2017
Purpose:  Added dpv_cd from the bzfc_cnst_addr to further qualify the address assessment category coding.  We were getting a high volume of returned mail
				and were told to exclude mailing addresses that have a 'Deliverable' assessment but the dpv_cd is not equal to 'Y'

Modified By: Majeed Mohammad
Modified Date: 03/20/2018
Purpose:  Added the logic to exclude  the vms records from the group membership view 

Modified By: Mike Andrien
Modified Date: 12/12/2018
Purpose: Added the RCO source to include address records from the AEM/RCO online gift system.  The RCO source was not coded correctly as an FR source in the arc_mdm_vws.bz_arc_srcsys
				view so we needed to explicitly add it to our include list.

Modified By: Mike Andrien
Modified Date: 9/3/2019
Purpose: Updated the ranking logic to include the new CDI source value 'GMFS' for the Gift Management System (GMS) application, which replaces the Team Approach (TA) application.  The TA CDI 
			source is TAFS.  I left the TAFS source in our ranking logic, but place the GMFS source just above each TAFS line in the ranking code.
			
Modified By: Majeed Mohammad
Modified Date: 07/07/2020
Purpose:  Made the below changes:
				1.	Changed the profile to use the locator_address lines instead of bz_cnst_address lines. 
				2.	Add the case to the rank to use the cnst_addr_strt_ts  instead of  dw_srcsys_trans_ts
				3.	Change the date-365 to date   interval '1' year

Modified By: Mike Andrien
Modified Date: 9/10/2020
Purpose:  Added a new layer to the rules that first ranks deliverable addresses with a dpv_cd = ''Y' then applies the same rules to deliverable address but with the dpv_cd = 'S'.  Lastily, the non-deliverable addresses are ranked.  Reordered the ranking
and added GMPS address type cd = 'U' to the rules as well.

Modified By: Mike Andrien
Modified Date: 02/15/2021
Purpose:  Updated the ranking order the elevate the SNHQ source and the rank the H, U and O address types for the SFFS, GMFS, RCO and MDON system above the legacy application source codes (ATG, ATGO, TAFS, CNVO, etc).  Also prioritized the H, U and O addresses for SFFS, GMSF, RCO and MDON
before the W and B address types.

Modified By: Mike Andrien
Modified Date: 07/14/2021
Purpose:  Added logic to the cnst_addr query to exclude address records for which there a Mail Locator DNC exists in the arc_cmm_vws.bz_cnst_dnc_locator table.  This was implemented to help address
an issue with returned mail.  The Donor Services team will add the Mail Locator DNC throught the Stuart interface for all return mail.  Our address select process excludes these from the selection process.

Modified By: Mike Andrien
Modified Date: 08/31/2022
Purpose: Changed date- interval '1' year to add_months(current_date,-12)
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_cnst_cdi_s_f_p_fr_dmail', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN
		
		-- Delete all records from target table
		TRUNCATE TABLE mktg_stage_tbls.cnst_cdi_s_f_p_fr_dmail_stg;

		-- Insert into target table with CTE for QUALIFY logic
		INSERT INTO mktg_stage_tbls.cnst_cdi_s_f_p_fr_dmail_stg (
			cnst_mstr_id
			,cnst_hsld_id
			,cnst_dsp_deceased_cd
			,cnst_data_src_cd
			,locator_prsn_nm_key
			,cnst_prsn_nm_assessmnt_ctg
			,cnst_prsn_prfx_nm
			,cnst_prsn_f_nm
			,cnst_prsn_m_nm
			,cnst_prsn_l_nm
			,cnst_prsn_sfx_nm
			,cnst_prsn_full_nm
			,cnst_alias_in_saltn_nm
			,cnst_alias_out_saltn_nm
			,locator_addr_key
			,cnst_addr_assessmnt_ctg
			,dpv_cd
			,addr_typ_cd
			,cnst_line_1_addr
			,cnst_line_2_addr
			,cnst_city_nm
			,cnst_st_cd
			,cnst_zip_5_cd
			,cnst_zip_4_cd
			,cnst_addr_county_nm
			,cnst_email
			,cnst_org_nm
			,cnst_typ_dsc
		)
		WITH 
		-- Pre-filter group membership to avoid correlated subqueries
		vol_nhq_members AS (
			SELECT DISTINCT 
				a.cnst_mstr_id,
				a.arc_srcsys_cd
			FROM eda.arc_cmm_vws.bz_grp_mbrshp a
			LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key
			WHERE b.grp_typ = 'Vol NHQ LOB'
		),
		-- Get FR source systems once
		fr_source_systems AS (
			SELECT arc_srcsys_cd
			FROM eda.arc_mdm_vws.bz_arc_srcsys
			WHERE line_of_service_cd = 'FR'
		),
		-- DNC list
		dnc_list AS (
			SELECT 
				cnst_mstr_id,
				locator_id
			FROM eda.arc_cmm_vws.bz_cnst_dnc_locator
			WHERE comm_chan = 'Mail'
				AND line_of_service_cd IN ('All', 'FR')
		),
		-- Address CTE
		cnst_addr AS (
			SELECT 
				addr.cnst_mstr_id,
				addr.locator_addr_key,
				addr.assessmnt_ctg AS cnst_addr_assessmnt_ctg,
				addr.dpv_cd,
				addr.addr_typ_cd AS cnst_addr_typ_cd,
				addr.locator_line1_addr,
				addr.locator_line2_addr,
				addr.locator_city,
				addr.locator_state,
				addr.locator_zip_5,
				addr.locator_zip_4,
				addr.bz_cnst_addr_county_nm,
				addr.cnst_addr_strt_ts,
				addr.arc_srcsys_cd,
				addr.cnst_addr_prefd_ind
			FROM eda.arc_mdm_vws.bzfc_cnst_addr addr
			LEFT JOIN dnc_list dnc 
				ON addr.cnst_mstr_id = dnc.cnst_mstr_id
				AND addr.locator_addr_key = dnc.locator_id
			LEFT JOIN vol_nhq_members vol
				ON addr.cnst_mstr_id = vol.cnst_mstr_id
				AND addr.arc_srcsys_cd = vol.arc_srcsys_cd
			WHERE dnc.cnst_mstr_id IS NULL
				AND (
					addr.locator_line1_addr IS NOT NULL
					OR addr.locator_line2_addr IS NOT NULL
					OR addr.locator_city IS NOT NULL
					OR addr.locator_state IS NOT NULL
					OR addr.locator_zip_5 IS NOT NULL
					OR addr.locator_zip_4 IS NOT NULL
				)
				AND (
					addr.arc_srcsys_cd IN ('RCO', 'CNVO', 'CDIM', 'MDON')
					OR (
						addr.arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM fr_source_systems)
						AND vol.cnst_mstr_id IS NULL
					)
				)
		),
		email_data AS (
			SELECT 
				email.cnst_mstr_id,
				email.arc_srcsys_cd,
				email.locator_email_addr,
				email.dw_srcsys_trans_ts,
				CASE 
					WHEN LEN(email.locator_email_addr) >= 8
						AND CHARINDEX('@', email.locator_email_addr) > 1
						AND CHARINDEX(' ', TRIM(email.locator_email_addr)) = 0
						AND (
							SUBSTRING(email.locator_email_addr, LEN(email.locator_email_addr) - 3, 4) IN ('.com', '.net', '.org', '.gov', '.mil', '.edu')
							OR SUBSTRING(email.locator_email_addr, LEN(email.locator_email_addr) - 2, 3) IN ('.us', '.ca', '.mx')
						)
						THEN 'Y'
					ELSE 'N'
				END AS Valid_email,
				email.email_key
			FROM eda.arc_mdm_vws.bzfc_cnst_email email
			WHERE (
				email.arc_srcsys_cd IN ('RCO', 'CNVO', 'CDIM', 'MDON')
				 /*08/05/2016: Majeed : Removed the ATG and ATGO records.  */
--(addr.arc_srcsys_cd in  ('ATG','ATGO','CNVO','CDIM', 'MDON')  /*03-13-2015: Added MDON to include text donors. MM */ 
				OR 
				/*  Below condition is to check all FR LOB source systems*/
				email.arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM fr_source_systems)
			)
		),
		E AS (
			SELECT 
				ed.cnst_mstr_id,
				ed.arc_srcsys_cd,
				ed.locator_email_addr,
				ed.dw_srcsys_trans_ts,
				MAX(ed.dw_srcsys_trans_ts) OVER (PARTITION BY ed.cnst_mstr_id) AS max_dw_srcsys_trans_ts,
				ed.Valid_email,
				ed.email_key
			FROM email_data ed
			LEFT JOIN vol_nhq_members vol
				ON ed.cnst_mstr_id = vol.cnst_mstr_id
				AND ed.arc_srcsys_cd = vol.arc_srcsys_cd
			WHERE vol.cnst_mstr_id IS NULL
				AND ed.Valid_email = 'Y'
		),
		-- Person name CTE
		P AS (
			SELECT 
				bz_nm.cnst_mstr_id,
				bz_nm.locator_prsn_nm_key,
				bz_nm.assessmnt_ctg,
				bz_nm.bz_cnst_prsn_prefix_nm,
				bz_nm.bz_cnst_prsn_first_nm,
				bz_nm.bz_cnst_prsn_middle_nm,
				bz_nm.bz_cnst_prsn_last_nm,
				bz_nm.bz_cnst_prsn_suffix_nm,
				bz_nm.cnst_prsn_full_nm,
				bz_nm.bz_cnst_alias_in_saltn_nm,
				bz_nm.bz_cnst_alias_out_saltn_nm,
				bz_nm.cnst_prsn_nm_typ_cd,
				bz_nm.dw_srcsys_trans_ts,
				bz_nm.arc_srcsys_cd,
				bz_nm.cnst_prsn_nm_end_dt
			FROM eda.arc_mdm_vws.bzfc_cnst_prsn_nm bz_nm
			LEFT JOIN eda.arc_mdm_vws.bz_locator_prsn_nm loca 
				ON bz_nm.locator_prsn_nm_key = loca.locator_prsn_nm_key
				AND loca.locator_prsn_nm_end_ts = '9999-12-31 00:00:00'::TIMESTAMP
			LEFT JOIN eda.arc_mdm_vws.bz_assessmnt assmnt 
				ON loca.assessmnt_key = assmnt.assessmnt_key
			LEFT JOIN vol_nhq_members vol
				ON bz_nm.cnst_mstr_id = vol.cnst_mstr_id
				AND bz_nm.arc_srcsys_cd = vol.arc_srcsys_cd
			WHERE bz_nm.cnst_prsn_nm_typ_cd IN ('PN', 'LN')
				AND (
					bz_nm.arc_srcsys_cd IN ('RCO', 'CNVO', 'CDIM', 'MDON')
					OR bz_nm.arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM fr_source_systems)
				)
				AND vol.cnst_mstr_id IS NULL
				AND bz_nm.bz_cnst_prsn_first_nm <> bz_nm.bz_cnst_prsn_last_nm
				AND (
					bz_nm.assessmnt_ctg IN ('Usable', 'Use With Caution')
					OR bz_nm.assessmnt_ctg IS NULL
				)
		),
		-- Organization name CTE
		ORG AS (
			SELECT 
				org_nm.cnst_mstr_id,
				org_nm.arc_srcsys_cd,
				org_nm.cnst_org_nm,
				org_nm.dw_srcsys_trans_ts
			FROM eda.arc_mdm_vws.bz_cnst_org_nm org_nm
			LEFT JOIN vol_nhq_members vol
				ON org_nm.cnst_mstr_id = vol.cnst_mstr_id
				AND org_nm.arc_srcsys_cd = vol.arc_srcsys_cd
			WHERE org_nm.cnst_org_nm_typ_cd IN ('PN', 'LN')
				AND (
					org_nm.arc_srcsys_cd IN ('RCO', 'CNVO', 'CDIM', 'MDON')
					OR org_nm.arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM fr_source_systems)
				)
				AND vol.cnst_mstr_id IS NULL
		),
		-- Main ranked data
		ranked_data AS (
			SELECT 
				cnst_mstr.cnst_mstr_id,
				cnst_mstr.cnst_hsld_id,
				cnst_mstr.cnst_dsp_deceased_cd,
				cnst_addr.arc_srcsys_cd AS cnst_data_src_cd,
				P.locator_prsn_nm_key,
				P.assessmnt_ctg AS cnst_prsn_nm_assessmnt_ctg,
				P.bz_cnst_prsn_prefix_nm AS cnst_prsn_prfx_nm,
				P.bz_cnst_prsn_first_nm AS cnst_prsn_f_nm,
				P.bz_cnst_prsn_middle_nm AS cnst_prsn_m_nm,
				P.bz_cnst_prsn_last_nm AS cnst_prsn_l_nm,
				P.bz_cnst_prsn_suffix_nm AS cnst_prsn_sfx_nm,
				P.cnst_prsn_full_nm,
				P.bz_cnst_alias_in_saltn_nm AS cnst_alias_in_saltn_nm,
				P.bz_cnst_alias_out_saltn_nm AS cnst_alias_out_saltn_nm,
				cnst_addr.locator_addr_key,
				cnst_addr.cnst_addr_assessmnt_ctg,
				cnst_addr.dpv_cd,
				cnst_addr.cnst_addr_typ_cd,
				cnst_addr.locator_line1_addr AS cnst_line_1_addr,
				cnst_addr.locator_line2_addr AS cnst_line_2_addr,
				cnst_addr.locator_city AS cnst_city_nm,
				cnst_addr.locator_state AS cnst_st_cd,
				cnst_addr.locator_zip_5 AS cnst_zip_5_cd,
				cnst_addr.locator_zip_4 AS cnst_zip_4_cd,
				cnst_addr.bz_cnst_addr_county_nm,
				E.locator_email_addr AS cnst_email,
				ORG.cnst_org_nm
				,CASE 
					WHEN cnst_mstr.cnst_typ_cd = 'IN'
						THEN 'Individual'
					WHEN cnst_mstr.cnst_typ_cd = 'OR'
						THEN 'Organization'
					WHEN cnst_mstr.cnst_typ_cd = 'AG'
						THEN 'Account Group'
					END AS cnst_typ_dsc
				,ROW_NUMBER() OVER (
					PARTITION BY cnst_addr.cnst_mstr_id ORDER BY CASE 
							/* 6/22/17: Majeed: Added the condition for the cnst_addr_typ_cd as there are multiple records with cnst_addr_prefd_ind = 1*/
							WHEN cnst_addr.arc_srcsys_cd = 'SFFS'
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.cnst_addr_prefd_ind = 1
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 1.1
							WHEN cnst_addr.arc_srcsys_cd = 'SFFS'
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.cnst_addr_prefd_ind = 1
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 1.2
							WHEN cnst_addr.arc_srcsys_cd = 'SFFS'
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.cnst_addr_prefd_ind = 1
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 1.3
									/*Ranking based on recency (last year), Deliverable and dpv_cd = 'Y' address rules */
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 3
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 4
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SNHQ'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 5
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 5.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 5.2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 6
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 7
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'MDON'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 8
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CDIM'
								AND cnst_addr.cnst_addr_typ_cd = 'LN'
								AND cnst_addr.dpv_cd = 'Y'
								AND (
									(
										P.bz_cnst_prsn_first_nm IS NOT NULL
										AND P.bz_cnst_prsn_last_nm IS NOT NULL
										)
									OR ORG.cnst_org_nm IS NOT NULL
									)
								THEN 9
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 10
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 11
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 12
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 13
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 14
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 15
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 16
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 17
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATGO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 18
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 19
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 20
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 21
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CNVO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 22
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 23
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 24
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 25
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 26
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.dpv_cd = 'Y'
								AND cnst_addr.cnst_addr_prefd_ind = 1
								THEN 27
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.dpv_cd = 'Y'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 28
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.dpv_cd = 'Y'
								AND cnst_addr.cnst_addr_typ_cd <> 'H'
								THEN 29
									/*Ranking based on recency (previous years), Deliverable address and the rules */
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CDIM'
								AND cnst_addr.cnst_addr_typ_cd = 'LN'
								AND cnst_addr.dpv_cd = 'Y'
								AND (
									(
										P.bz_cnst_prsn_first_nm IS NOT NULL
										AND P.bz_cnst_prsn_last_nm IS NOT NULL
										)
									OR ORG.cnst_org_nm IS NOT NULL
									)
								THEN 30
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 31
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 32
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SNHQ'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 33
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 34
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 35
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 36
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 37
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'MDON'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 38
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 39
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 40
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 41
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 42
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 43
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 44
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 45
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATGO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 46
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 47
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATGO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 48
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 49
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 50
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 51
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 52
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 53
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CNVO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 54
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 55
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 56
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 57
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_prefd_ind = 1
								AND cnst_addr.dpv_cd = 'Y'
								THEN 58
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 59
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_typ_cd <> 'H'
								AND cnst_addr.dpv_cd = 'Y'
								THEN 60
									/* Now rank the deliverable but dpv_cd = 'S' addresses */
									/* 6/22/17: Majeed: Added the condition for the cnst_addr_typ_cd as there are multiple records with cnst_addr_prefd_ind = 1*/
							WHEN cnst_addr.arc_srcsys_cd = 'SFFS'
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.cnst_addr_prefd_ind = 1
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 101.1
							WHEN cnst_addr.arc_srcsys_cd = 'SFFS'
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.cnst_addr_prefd_ind = 1
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 101.2
							WHEN cnst_addr.arc_srcsys_cd = 'SFFS'
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.cnst_addr_prefd_ind = 1
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 101.3
									/*Ranking based on recency (last year), Deliverable address and the rules */
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 102
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 103
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 104
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 105
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 105.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 105.2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 106
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 106.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 107.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 107.2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATGO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 108
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 109.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 109.2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 110
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 110.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 111
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 111.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CDIM'
								AND cnst_addr.cnst_addr_typ_cd = 'LN'
								AND (
									(
										P.bz_cnst_prsn_first_nm IS NOT NULL
										AND P.bz_cnst_prsn_last_nm IS NOT NULL
										)
									OR ORG.cnst_org_nm IS NOT NULL
									)
								THEN 112
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 113
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CNVO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 114
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'MDON'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 115
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 116
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 117.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 117.2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 118
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 118.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_prefd_ind = 1
								THEN 120
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 120.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_typ_cd <> 'H'
								THEN 120.2
									/*Ranking based on recency (previous years), Deliverable address and the rules */
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CDIM'
								AND cnst_addr.cnst_addr_typ_cd = 'LN'
								AND (
									(
										P.bz_cnst_prsn_first_nm IS NOT NULL
										AND P.bz_cnst_prsn_last_nm IS NOT NULL
										)
									OR ORG.cnst_org_nm IS NOT NULL
									)
								THEN 121
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 122
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 123
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 124
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 125
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 125.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 125.2
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 126
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 126.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 127.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 127.2
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATGO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 128
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 129.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 129.2
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 130
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 130.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 131
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 131.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 132
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CNVO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 133
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'MDON'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 134
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 135
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 136.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 136.2
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 137
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_prefd_ind = 1
								THEN 139
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 139.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_typ_cd <> 'H'
								THEN 139.2
									/*Ranking based on recency (last year), Undeliverable address and the rules */
							WHEN cnst_addr.arc_srcsys_cd = 'SFFS'
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.cnst_addr_prefd_ind = 1
								THEN 240
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 240.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 241
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 242
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 243
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 243.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 243.2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 244
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 244.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 245.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 245.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATGO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 246
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 247.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 247.2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 248
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 248.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 249
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 249.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CDIM'
								AND cnst_addr.cnst_addr_typ_cd = 'LN'
								THEN 250
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 251
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CNVO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 252
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'MDON'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 253
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 254
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 255.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 255.2
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 56
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 256.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									,'GMFS'
									)
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 258
									/*Ranking based on recency (previous years), Undeliverable address and the rules */
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 259
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 260
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 261
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 262
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 262.1
							WHEN cnst_addr.cnst_addr_strt_ts > ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') <> 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 262.2
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 263
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 263.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 264.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 264.2
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATGO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 265
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 266.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'B'
								THEN 266.2
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 267
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'W'
								THEN 267.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 268
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 268.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CDIM'
								AND cnst_addr.cnst_addr_typ_cd = 'LN'
								THEN 269
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 270
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'CNVO'
								AND cnst_addr.cnst_addr_typ_cd = 'H'
								THEN 271
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'MDON'
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 272
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'SFFS'
								AND cnst_addr.cnst_addr_typ_cd = 'O'
								THEN 273
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'RCO'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 274.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'ATG'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 274.2
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'GMFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 275
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd = 'TAFS'
								AND cnst_addr.cnst_addr_typ_cd = 'SH'
								THEN 275.1
							WHEN cnst_addr.cnst_addr_strt_ts <= ADD_MONTHS(CURRENT_DATE, - 12)
								AND COALESCE(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Undeliverable'
								AND cnst_addr.arc_srcsys_cd NOT IN (
									'RCO'
									,'SFFS'
									,'ATG'
									,'ATGO'
									,'CNVO'
									,'TAFS'
									,'CDIM'
									,'COA1'
									,'COA2'
									,'COA3'
									)
								AND cnst_addr.cnst_addr_typ_cd = 'U'
								THEN 277
							ELSE 278
							END
						,cnst_addr.cnst_addr_strt_ts DESC
						,E.dw_srcsys_trans_ts DESC
						,P.dw_srcsys_trans_ts DESC
						,ORG.dw_srcsys_trans_ts DESC
					) AS row_num
			FROM cnst_addr
			INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr cnst_mstr 
				ON cnst_addr.cnst_mstr_id = cnst_mstr.cnst_mstr_id
			LEFT JOIN E 
				ON cnst_addr.cnst_mstr_id = E.cnst_mstr_id
				AND cnst_addr.arc_srcsys_cd = E.arc_srcsys_cd
			LEFT JOIN P 
				ON cnst_addr.cnst_mstr_id = P.cnst_mstr_id
				AND cnst_addr.arc_srcsys_cd = P.arc_srcsys_cd
			LEFT JOIN ORG 
				ON cnst_addr.cnst_mstr_id = ORG.cnst_mstr_id
				AND cnst_addr.arc_srcsys_cd = ORG.arc_srcsys_cd
		)
		SELECT 
			cnst_mstr_id,
			cnst_hsld_id,
			cnst_dsp_deceased_cd,
			cnst_data_src_cd,
			locator_prsn_nm_key,
			cnst_prsn_nm_assessmnt_ctg,
			cnst_prsn_prfx_nm,
			cnst_prsn_f_nm,
			cnst_prsn_m_nm,
			cnst_prsn_l_nm,
			cnst_prsn_sfx_nm,
			cnst_prsn_full_nm,
			cnst_alias_in_saltn_nm,
			cnst_alias_out_saltn_nm,
			locator_addr_key,
			cnst_addr_assessmnt_ctg,
			dpv_cd,
			cnst_addr_typ_cd,
			cnst_line_1_addr,
			cnst_line_2_addr,
			cnst_city_nm,
			cnst_st_cd,
			cnst_zip_5_cd,
			cnst_zip_4_cd,
			bz_cnst_addr_county_nm,
			cnst_email,
			cnst_org_nm,
			cnst_typ_dsc
		FROM ranked_data
		WHERE row_num = 1;
		
		TRUNCATE TABLE mktg_ops_tbls.cnst_cdi_s_f_p_fr_dmail;
		
        INSERT INTO mktg_ops_tbls.cnst_cdi_s_f_p_fr_dmail
        SELECT * FROM mktg_stage_tbls.cnst_cdi_s_f_p_fr_dmail_stg;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_ops_tbls.cnst_cdi_s_f_p_fr_dmail) as INTEGER)
        WHERE proc_name = 'ld_gms_cnst_cdi_s_f_p_fr_dmail' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_gms_cnst_cdi_s_f_p_fr_dmail: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_gms_cnst_cdi_s_f_p_fr_dmail', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
