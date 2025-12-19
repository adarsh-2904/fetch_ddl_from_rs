CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_cnst_cdi_s_f_p_fr_email()
 LANGUAGE plpgsql
AS $$
/*
Created By: Rameshbabu Ramachandran
Created Date: 27-Mar-2014
Purpose: This macro inserts the data  into a cnst_cdi_s_f_p_fr_email  base table.

Modified By: Rameshbabu Ramachandran
Modified Date: June -17-2014
Purpose:  Included new filter condition cnst_prsn_nm_typ_cd in ('PN','LN') in PERSN_NM table. This is migrated through task # 224 .

Modified By: Rameshbabu Ramachandran
Modified Date: June -27-2014
Purpose:  Included new org_nm and cnst_typ_desc columns and added new bz_cnst_org_nm table join.This is migrated through CCB Item # 25.


Modified By: Rameshbabu Ramachandran
Modified Date: June -27-2014
Purpose:  Included new full name, in&out saltn name and email key for both Dmail and Email.This is migrated through CCB Item #  


Modified By: Rameshbabu Ramachandran
Modified Date: Aug -06-2014
Purpose:  Included  Assessmnt_ctg Null values in filter condition.

Modified By: Mike Andrien
Modified Date: Nov 06 2014
Purpose:  Added the Youthwire 'YWLT' source for LOB upploads. This will be revised once the final LOB solution has been implemented.

Modified By: Majeed Mohammad
Modified Date: 02/06/2015
Purpose: Added the columns for locator_addr_key, cnst_addr_assessmnt_ctg and county 

Modified By: Mike Andrien
Modified Date: 04/25/2015
Purpose:  Added the 'SNHQ' source for the Stuart group membership Chapter List uploads. 

Modified By: Mike Andrien
Modified Date: 04/28/2015
Purpose:  Added the 'EMLT' source for the Stuart group membership Email Only List uploads. 

Modified By: Mike Andrien
Modified Date: 06/9/2015
Purpose:  Revised the ranking rules in the Qualify statement to correct issue with the ranking rules. 

Modified By: Majeed Mohammad
Modified Date: Jun -10-2015
Purpose:  The column assessmnt_ctg has been removed in the view arc_mdm_vws.bz_cnst_email by EDW for query optimizations. The macro now uses the new view arc_mdm_vws.bzfc_cnst_email that contains 
the assessmnt_ctg column 

Modified By: Majeed Mohammad
Modified Date: 08/05/2016
Purpose: Removed the ATG and ATGO records.
 
Modified By: Majeed Mohammad
Modified Date: 09/28/2016
Purpose: Updated the macro to use the corrected email column locator_email_addr


Modified By: Majeed Mohammad
Modified Date: 10/19/2016
Purpose:  
1. Updated the join to the table arc_mdm_tbls.locator_addr and included  the condition locator_addr_end_ts  ='9999-12-31 00:00:00' 
2. Added the logic to get the name locator key and name assessment

Modified By: Majeed Mohammad
Modified Date: 10/20/2016
Purpose:  Updated the timestamp format for 12/31/9999 . Added the date condition to get only the active emails

Modified By: Mike Andrien
Modified Date: 09/13/2017
Purpose:  Add ATG and ATGO sources back to the email select logic and now reference the mktg_ops_vws.atg_registrants view to limit the ATG and ATGO consituents are limited to FR and not PHSS Course takers.

Modified By: Mike Andrien
Modified Date: 11/21/2017
Purpose:  Modified the email prioritizations to make rank ATGO higher than CNVO and added more detailed time-based criteria. Also modified the ATG and ATGO queries to pull from 
				the mktg_ops_vws.atg_order_registrants and mktg_ops_vws.atg_registrants views.
				
				
Modified By: Majeed Mohammad
Modified Date: 03/20/2018
Purpose:  Added the logic to exclude  the vms records from the group membership view 

Modified By: Mike Andrien
Modified Date: 06/04/2018
Purpose: Change the main query for the email source records 'E' from and  not in to an in 'or cnst_email.cnst_mstr_id  in (select cnst_mstr_id from arc_cmm_vws.bz_grp_mbrshp a left join arc_cmm_vws.grp_ref b on a.grp_key = b.grp_key where grp_typ not in ('Vol NHQ LOB',  'Bio NHQ LOB', 'PHSS NHQ LOB') and a.arc_srcsys_cd=cnst_email.arc_srcsys_cd) ' 
				to exclude the master ids that are only in      Vol, PHSS or biomed.  The original query was excluding master ids that were in Vol but this was incorrectly excluding master id that were in both FR and Vol.  Change the select logic for the names and org names as well.

Modified By: Mike Andrien
Modified Date: 12/12/2018
Purpose: Added the RCO source to include email records from the AEM/RCO online gift system.  The RCO source was not coded correctly as an FR source in the arc_mdm_vws.bz_arc_srcsys
				view so we needed to explicitly add it to our include list.

Modified by: Michael Andrien
Modified date:  05/28/2019
Purpose:  Added Mobile Commons/mGive data source (MDON)

Modified By: Mike Andrien
Modified Date: 9/3/2019
Purpose: Updated the ranking logic to include the new CDI source value 'GMFS' for the Gift Management System (GMS) application, which replaces the Team Approach (TA) application.  The TA CDI 
			source is TAFS.  I left the TAFS source in our ranking logic, but place the GMFS source just above each TAFS line in the ranking code.

Modified By: Mike Andrien
Modified Date: 9/15/2020
Purpose: Updated the email ranking rules to prioritze the SFFS system above retired systems such as CNVO, TAFS, ATG, ATGO.

Modified By: Mike Andrien
Modified Date: 10/30/2021
Purpose:  Added the DNC join to exclude email locator DNC directives from the CMM database from the email selection ranking group. 

Modified By: Mike Andrien
Modified Date: 11/23/2021
Purpose: 	Added the epl join to include logic to select and prioritize the email locator preference directive capture from Stuart in the cmm_vws database

Modified By: Majeed Mohammad
Modified Date: 11/29/2021
Purpose: 	Added the explicit cast as timestamp to the end date in  the EPL join. 

Modified By: Majeed Mohammad
Modified Date: 11/19/2024
Purpose: 	Added the logic  to identify the Tiffany Donors and use their SFFS Email Address as Preferred Email per teamwork ticket # 11391932.
					Added the email_key in the Qualify statement to break the tie for records with same src_cd and email_typ_cd

Modified By: Majeed Mohammad
Modified Date: 12/05/2024
Purpose: 	Removed this condition from Tiffany Donors - qualify row_number() over (partition by indv.cnst_mstr_id order by strt_dt desc)=1
					Added the join to the email address to the Tiffany Donors. Changed the order of  the sort to use Tiffany as top priority. The email is selected from E subquery and the join to email  and sort order ensures TIFFANY email is selected when available. 
					Updated the order by in the EMAIL_TYP_CD as EH, O, U, EW 
					
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_error_message VARCHAR(500);
    v_ok_message VARCHAR(500);
BEGIN
    v_start_time := GETDATE();
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_cnst_cdi_s_f_p_fr_email', 'Stored Procedure', 'Inprogress', v_start_time);
	
	BEGIN

    	TRUNCATE TABLE mktg_stage_tbls.cnst_cdi_s_f_p_fr_email_stg;

		INSERT INTO mktg_stage_tbls.cnst_cdi_s_f_p_fr_email_stg (
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
			cnst_line_1_addr, 
			cnst_line_2_addr,
			cnst_city_nm, 
			cnst_st_cd, 
			cnst_zip_5_cd, 
			cnst_zip_4_cd, 
			cnst_addr_county_nm,
			cnst_email,
			cnst_email_key, 
			cnst_email_assessmnt_ctg, 
			cnst_org_nm, 
			cnst_typ_dsc
		)
		WITH E AS (
			SELECT 
				cnst_email.cnst_mstr_id,
				cnst_email.arc_srcsys_cd, 
				locator_email_addr,
				dw_srcsys_trans_ts,
				MAX(dw_srcsys_trans_ts) OVER (PARTITION BY cnst_email.cnst_mstr_id) AS max_dw_srcsys_trans_ts,
				CASE 
					WHEN LENGTH(locator_email_addr) >= 8  
						AND POSITION('@' IN locator_email_addr) > 1
						AND POSITION(' ' IN TRIM(locator_email_addr)) = 0 
						AND (
							RIGHT(locator_email_addr, 4) IN ('.com','.net','.org','.gov','.mil','.edu')
							OR RIGHT(locator_email_addr, 3) IN ('.us','.ca','.mx')
						)
					THEN 'Y'
					ELSE 'N'
				END AS Valid_email,
				email_typ_cd, 
				email_key,
				assessmnt_ctg AS cnst_email_assessmnt_ctg
			FROM eda.arc_mdm_vws.bzfc_cnst_email cnst_email
			LEFT JOIN (
				SELECT 
					cnst_mstr_id,
					locator_id
				FROM eda.arc_cmm_vws.bz_cnst_dnc_locator dnc 
				WHERE comm_chan = 'Email' 
					AND line_of_service_cd IN ('All', 'FR')
			) dnc ON cnst_email.cnst_mstr_id = dnc.cnst_mstr_id 
				AND cnst_email.email_key = dnc.locator_id
			LEFT JOIN (
				SELECT 
					cnst_mstr_id, 
					arc_srcsys_cd
				FROM mktg_ops_vws.bz_grp_mbrshp a 
				LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
				WHERE grp_typ NOT IN ('Vol NHQ LOB', 'Bio NHQ LOB', 'PHSS NHQ LOB') 
			) fr_list ON cnst_email.cnst_mstr_id = fr_list.cnst_mstr_id 
				AND cnst_email.arc_srcsys_cd = fr_list.arc_srcsys_cd
			WHERE    
				dnc.cnst_mstr_id IS NULL 
				AND cnst_email_end_dt = '9999-12-31'::DATE /*10/201/2016: Majeed: Added the date condition to get only the active emails */
				AND (
					cnst_email.arc_srcsys_cd IN ('RCO', 'CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'MDON')
					  /*08/05/2016: Majeed : Removed the ATG and ATGO records.  */
--(arc_srcsys_cd in  ('ATG','ATGO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT') 
					OR cnst_email.arc_srcsys_cd IN (
						SELECT arc_srcsys_cd 
						FROM eda.arc_mdm_vws.bz_arc_srcsys 
						WHERE line_of_service_cd = 'FR'
					) 
					OR (cnst_email.cnst_mstr_id = fr_list.cnst_mstr_id 
						AND cnst_email.arc_srcsys_cd = fr_list.arc_srcsys_cd) 
					OR (cnst_email.cnst_mstr_id IN (
							SELECT DISTINCT cnst_mstr_id 
							FROM mktg_ops_vws.atg_order_registrants 
							WHERE atg_gift_cnt > 0
						) 
						AND cnst_email.arc_srcsys_cd IN ('ATGO'))
					OR (cnst_email.cnst_mstr_id IN (
							SELECT DISTINCT cnst_mstr_id 
							FROM mktg_ops_vws.atg_registrants 
							WHERE atg_gift_cnt > 0
						) 
						AND cnst_email.arc_srcsys_cd IN ('ATG'))
				)
				AND (
					CASE 
						WHEN LENGTH(locator_email_addr) >= 8  
							AND POSITION('@' IN locator_email_addr) > 1
							AND POSITION(' ' IN TRIM(locator_email_addr)) = 0 
							AND (
								RIGHT(locator_email_addr, 4) IN ('.com','.net','.org','.gov','.mil','.edu')
								OR RIGHT(locator_email_addr, 3) IN ('.us','.ca','.mx')
							)
						THEN 'Y'
						ELSE 'N'
					END
				) = 'Y'
				AND (assessmnt_ctg IN ('Validated','Use With Caution') OR assessmnt_ctg IS NULL)
		),
		FR_main AS (
			SELECT 
				cnst_mstr_id,
				cnst_hsld_id,
				cnst_dsp_deceased_cd,
				cnst_typ_cd 
			FROM eda.arc_mdm_vws.bz_cnst_mstr
		),
		/*Majeed: 11/19/2024: Added these to identify the Tiffany Donors and use their SFFS Email Address as Preferred Email per teamwork ticket # 11391932*/
		tiffny AS (
		SELECT 
			indv.cnst_mstr_id, 
			indv.prefd_email_addr, 
			indv.prefd_email_locator_key 
		FROM eda.ufds_vws.bzfc_dim_unf_fr_indv indv 
		INNER JOIN mktg_ops_vws.gms_bzf_cnst_cnstcy_curnt cnstcy 
			ON indv.cnst_mstr_id = cnstcy.cnst_mstr_id 
		WHERE 
			indv.appl_src_cd = 'SFFS'  
			AND indv.prefd_email_addr IS NOT NULL 
			AND indv.prefd_email_addr <> ''
			AND indv.prefd_email_addr <> 'PRIVATE'
			AND (cnstcy.tifny_crcle_bmh_mmbr_ind + cnstcy.tifny_crcle_bmh_slvr_mmbr_ind + 
				 cnstcy.tifny_crcle_bmh_gold_mmbr_ind + cnstcy.tifny_crcle_bmh_pltnm_mmbr_ind + 
				 cnstcy.tifny_crcle_lftm_mmbr_ind + cnstcy.tifny_crcle_mmbr_ind + 
				 cnstcy.tifny_crcle_ntnl_cncl_ind) > 0
		),
		P AS (
			SELECT 
				bz_nm.cnst_mstr_id,
				bz_nm.locator_prsn_nm_key,
				assmnt.assessmnt_ctg, 
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
			FROM eda.arc_mdm_vws.bz_cnst_prsn_nm bz_nm 
			LEFT JOIN eda.arc_mdm_vws.bz_locator_prsn_nm loca 
				ON bz_nm.locator_prsn_nm_key = loca.locator_prsn_nm_key 
				AND locator_prsn_nm_end_ts = '9999-12-31 00:00:00'::TIMESTAMP
			LEFT JOIN eda.arc_mdm_vws.bz_assessmnt assmnt 
				ON loca.assessmnt_key = assmnt.assessmnt_key
			LEFT JOIN (
				SELECT 
					cnst_mstr_id, 
					arc_srcsys_cd
				FROM mktg_ops_vws.bz_grp_mbrshp a 
				LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
				WHERE grp_typ NOT IN ('Vol NHQ LOB', 'Bio NHQ LOB', 'PHSS NHQ LOB') 
			) fr_list ON bz_nm.cnst_mstr_id = fr_list.cnst_mstr_id 
				AND bz_nm.arc_srcsys_cd = fr_list.arc_srcsys_cd
			WHERE (
				bz_nm.arc_srcsys_cd IN ('RCO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'ATG', 'ATGO', 'MDON')
				/* 09/13/2017 - MTA - Added back the ATG and ATGO sources. */
	/*08/05/2016: Majeed : Removed the ATG and ATGO records.  */
	-- arc_srcsys_cd in  ('ATG','ATGO','CNVO','TAFS','SFFS', 'YWLT',  'SNHQ', 'EMLT') 
	 /* 03/06/2018: Majeed: Per directive from Mike A, added the join to volunteer list from the group membership */
				OR (bz_nm.cnst_mstr_id = fr_list.cnst_mstr_id 
					AND bz_nm.arc_srcsys_cd = fr_list.arc_srcsys_cd) 
				OR bz_nm.arc_srcsys_cd IN (
					SELECT arc_srcsys_cd 
					FROM eda.arc_mdm_vws.bz_arc_srcsys 
					WHERE line_of_service_cd = 'FR'
				)
			)
			AND cnst_prsn_nm_typ_cd IN ('PN','LN') 
			AND cnst_prsn_nm_end_dt = '9999-12-31'::DATE
		),
		ORG AS (
			SELECT
				org_nm.cnst_mstr_id,
				org_nm.arc_srcsys_cd,
				cnst_org_nm,
				dw_srcsys_trans_ts
			FROM eda.arc_mdm_vws.bz_cnst_org_nm org_nm
			LEFT JOIN (
				SELECT 
					cnst_mstr_id, 
					arc_srcsys_cd
				FROM mktg_ops_vws.bz_grp_mbrshp a 
				LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
				WHERE grp_typ NOT IN ('Vol NHQ LOB', 'Bio NHQ LOB', 'PHSS NHQ LOB') 
			) fr_list ON org_nm.cnst_mstr_id = fr_list.cnst_mstr_id 
				AND org_nm.arc_srcsys_cd = fr_list.arc_srcsys_cd
			WHERE cnst_org_nm_typ_cd IN ('PN','LN')
			AND (
				org_nm.arc_srcsys_cd IN ('RCO','CNVO','TAFS','SFFS', 'YWLT', 'SNHQ', 'EMLT', 'ATG', 'ATGO', 'MDON')
				/* 09/13/2017 - MTA - Added back the ATG and ATGO sources. */
	/*08/05/2016: Majeed : Removed the ATG and ATGO records.  */
	-- (arc_srcsys_cd in  ('ATG','ATGO','CNVO','TAFS','SFFS', 'YWLT',  'SNHQ', 'EMLT') /* 4/28/15 mta replaced the list to match source list for person.*/
				OR (org_nm.cnst_mstr_id = fr_list.cnst_mstr_id 
					AND org_nm.arc_srcsys_cd = fr_list.arc_srcsys_cd) 
				OR org_nm.arc_srcsys_cd IN (
					SELECT arc_srcsys_cd 
					FROM eda.arc_mdm_vws.bz_arc_srcsys 
					WHERE line_of_service_cd = 'FR'
				)
			)
		),
		/*The epl join below was added by Mike Andrien to include logic to select and prioritize the email locator preference directive capture from Stuart in the cmm_vws database. */
		epl AS (
		SELECT
			a.cnst_mstr_id,
			b.cnst_email_addr,
			b.arc_srcsys_cd,
			b.assessmnt_ctg,
			ROW_NUMBER() OVER (PARTITION BY a.cnst_mstr_id ORDER BY b.dw_srcsys_trans_ts DESC) AS rn
		FROM eda.arc_cmm_vws.bzf_cnst_pref_loc a
		LEFT JOIN eda.arc_mdm_vws.bzfc_cnst_email b ON 
			CASE 
				WHEN a.bzd_pref_loc_fr_email_loc_id IS NOT NULL THEN a.bzd_pref_loc_fr_email_loc_id
				WHEN a.bzd_pref_loc_all_email_loc_id IS NOT NULL THEN a.bzd_pref_loc_all_email_loc_id
				ELSE NULL
			END = b.email_key
		WHERE 
			(a.bzd_pref_loc_fr_email_loc_id IS NOT NULL OR a.bzd_pref_loc_all_email_loc_id IS NOT NULL)
			-- AND b.arc_srcsys_cd = 'STRX'
		),
		epl_filtered AS (
			SELECT 
				cnst_mstr_id,
				cnst_email_addr,
				arc_srcsys_cd,
				assessmnt_ctg
			FROM epl
			WHERE rn = 1
		),
		ranked_data AS (
			SELECT
				FR_main.cnst_mstr_id,
				FR_main.cnst_hsld_id,
				FR_main.cnst_dsp_deceased_cd,
				E.arc_srcsys_cd,
				P.locator_prsn_nm_key,
				P.assessmnt_ctg AS cnst_prsn_nm_assessmnt_ctg,
				P.bz_cnst_prsn_prefix_nm,
				P.bz_cnst_prsn_first_nm,
				P.bz_cnst_prsn_middle_nm,
				P.bz_cnst_prsn_last_nm,
				P.bz_cnst_prsn_suffix_nm,
				P.cnst_prsn_full_nm,
				P.bz_cnst_alias_in_saltn_nm AS cnst_alias_in_saltn_nm,
				P.bz_cnst_alias_out_saltn_nm AS cnst_alias_out_saltn_nm,
				A.locator_addr_key,
				bz_assmnt.assessmnt_ctg AS cnst_addr_assessmnt_ctg,
				A.bz_cnst_addr_line1_addr,
				A.bz_cnst_addr_line2_addr,
				A.bz_cnst_addr_city_nm,
				A.cnst_addr_state_cd,
				A.cnst_addr_zip_5_cd,
				A.cnst_addr_zip_4_cd,
				A.bz_cnst_addr_county_nm AS cnst_addr_county_nm,
				E.locator_email_addr,
				E.email_key,
				E.cnst_email_assessmnt_ctg,
				ORG.cnst_org_nm,
				CASE 
					WHEN FR_main.cnst_typ_cd = 'IN' THEN 'Individual'
					WHEN FR_main.cnst_typ_cd = 'OR' THEN 'Organization'
					WHEN FR_main.cnst_typ_cd = 'AG' THEN 'Account Group'
				END AS cnst_typ_desc,
				ROW_NUMBER() OVER (
					PARTITION BY FR_main.cnst_mstr_id  
					ORDER BY
						CASE 	
							WHEN tiffny.cnst_mstr_id IS NOT NULL THEN 1
							WHEN epl_filtered.cnst_mstr_id IS NOT NULL THEN 1.01		
							WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - 365 AND E.arc_srcsys_cd = 'RCO' THEN 1.1
							WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - 365 AND E.arc_srcsys_cd = 'SFFS' THEN 2
							WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - 365 AND E.arc_srcsys_cd = 'GMFS' THEN 3
							WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - 365 AND E.arc_srcsys_cd = 'ATGO' THEN 4
							WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - 365 AND E.arc_srcsys_cd = 'ATG' THEN 4.1
							WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - 365 AND E.arc_srcsys_cd = 'TAFS' THEN 5
							WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - 365 AND E.arc_srcsys_cd = 'CNVO' THEN 6
							WHEN E.dw_srcsys_trans_ts = E.max_dw_srcsys_trans_ts AND E.arc_srcsys_cd = 'RCO' THEN 7
							WHEN E.dw_srcsys_trans_ts = E.max_dw_srcsys_trans_ts AND E.arc_srcsys_cd = 'SFFS' THEN 8
							WHEN E.dw_srcsys_trans_ts = E.max_dw_srcsys_trans_ts AND E.arc_srcsys_cd = 'GMFS' THEN 9
							WHEN E.dw_srcsys_trans_ts = E.max_dw_srcsys_trans_ts AND E.arc_srcsys_cd = 'ATGO' THEN 10
							WHEN E.dw_srcsys_trans_ts = E.max_dw_srcsys_trans_ts AND E.arc_srcsys_cd = 'ATG' THEN 11
							WHEN E.dw_srcsys_trans_ts = E.max_dw_srcsys_trans_ts AND E.arc_srcsys_cd = 'TAFS' THEN 12
										/* The next 4 entries are ranked by sources SFFS, TAFS, ATG and ATGO   If the most recent DW CDI update was not for these sources, then we rank the sources ahead of the Chapter and Stuart list 
			upload sources */
							WHEN E.arc_srcsys_cd = 'SFFS' AND E.dw_srcsys_trans_ts <> E.max_dw_srcsys_trans_ts THEN 13
							WHEN E.arc_srcsys_cd = 'GMFS' AND E.dw_srcsys_trans_ts <> E.max_dw_srcsys_trans_ts THEN 14
							WHEN E.arc_srcsys_cd = 'RCO' AND E.dw_srcsys_trans_ts <> E.max_dw_srcsys_trans_ts THEN 15
							WHEN E.arc_srcsys_cd = 'TAFS' AND E.dw_srcsys_trans_ts <> E.max_dw_srcsys_trans_ts THEN 16
							WHEN E.arc_srcsys_cd = 'ATGO' AND E.dw_srcsys_trans_ts <> E.max_dw_srcsys_trans_ts THEN 17
							WHEN E.arc_srcsys_cd = 'ATG' AND E.dw_srcsys_trans_ts <> E.max_dw_srcsys_trans_ts THEN 18
							WHEN E.arc_srcsys_cd NOT IN ('ATG','ATGO','TAFS','SFFS', 'SNHQ', 'EMLT', 'YWLT', 'RCO', 'GMFS') THEN 19  -- This line is for the migrated chapter codes
							WHEN E.arc_srcsys_cd = 'SNHQ' THEN 20  -- MTA 2015-04-25 added SNHQ, which is the source used for the Stuart group membership chapter list upload data.
							WHEN E.arc_srcsys_cd = 'EMLT' THEN 21 -- MTA 2015-04-28 added EMLT, which is the source used for the Stuart group membership email only upload data.
							WHEN E.arc_srcsys_cd = 'YWLT' THEN 22  -- MTA 2014-11-06 added Youthwire source type and will need to add other LOB sources later
							WHEN E.arc_srcsys_cd = 'MDON' AND E.dw_srcsys_trans_ts <> E.max_dw_srcsys_trans_ts THEN 23
							ELSE 24
						END,
						/* Added the below CASE statement to define a logic to select the email based on the type code */ 
						CASE 
							WHEN E.email_typ_cd = 'EH' THEN 1 
							WHEN E.email_typ_cd = 'O' THEN 2
							WHEN E.email_typ_cd = 'U' THEN 3
							WHEN E.email_typ_cd = 'EW' THEN 4 
							ELSE 5 
						END,
						E.dw_srcsys_trans_ts DESC,
						P.dw_srcsys_trans_ts DESC,
						A.dw_srcsys_trans_ts DESC,
						ORG.dw_srcsys_trans_ts DESC,
						E.email_key DESC
						/*Added the email_key to break the tie for records with same src_cd and email_typ_cd */ 
				) AS rn
			FROM E
			INNER JOIN FR_main ON FR_main.cnst_mstr_id = E.cnst_mstr_id
			LEFT JOIN tiffny ON E.cnst_mstr_id = tiffny.cnst_mstr_id 
				AND E.locator_email_addr = tiffny.prefd_email_addr
			LEFT JOIN P ON E.cnst_mstr_id = P.cnst_mstr_id
				AND P.arc_srcsys_cd = E.arc_srcsys_cd
			LEFT JOIN ORG ON E.cnst_mstr_id = ORG.cnst_mstr_id
				AND E.arc_srcsys_cd = ORG.arc_srcsys_cd
			LEFT JOIN eda.arc_mdm_vws.bz_cnst_addr A
				ON E.cnst_mstr_id = A.cnst_mstr_id
				AND E.arc_srcsys_cd = A.arc_srcsys_cd
				AND A.cnst_addr_end_dt = '9999-12-31'::DATE
			LEFT JOIN eda.arc_mdm_vws.bza_locator_addr loc_addr 
				ON A.locator_addr_key = loc_addr.locator_addr_key 
				AND locator_addr_end_ts = '9999-12-31 00:00:00'::TIMESTAMP
			LEFT JOIN eda.arc_mdm_vws.bz_assessmnt bz_assmnt 
				ON loc_addr.assessmnt_key = bz_assmnt.assessmnt_key
			LEFT JOIN epl_filtered ON epl_filtered.cnst_mstr_id = E.cnst_mstr_id
		)
		SELECT
			cnst_mstr_id,
			cnst_hsld_id,
			cnst_dsp_deceased_cd,
			arc_srcsys_cd,
			locator_prsn_nm_key,
			cnst_prsn_nm_assessmnt_ctg,
			bz_cnst_prsn_prefix_nm,
			bz_cnst_prsn_first_nm,
			bz_cnst_prsn_middle_nm,
			bz_cnst_prsn_last_nm,
			bz_cnst_prsn_suffix_nm,
			cnst_prsn_full_nm,
			cnst_alias_in_saltn_nm,
			cnst_alias_out_saltn_nm,
			locator_addr_key,
			cnst_addr_assessmnt_ctg,
			bz_cnst_addr_line1_addr,
			bz_cnst_addr_line2_addr,
			bz_cnst_addr_city_nm,
			cnst_addr_state_cd,
			cnst_addr_zip_5_cd,
			cnst_addr_zip_4_cd,
			cnst_addr_county_nm,
			locator_email_addr,
			email_key,
			cnst_email_assessmnt_ctg,
			cnst_org_nm,
			cnst_typ_desc
		FROM ranked_data
		WHERE rn = 1;
		
		TRUNCATE TABLE mktg_ops_tbls.cnst_cdi_s_f_p_fr_email;

		-- Insert data from staging to target
        INSERT INTO mods_bi.mktg_ops_tbls.cnst_cdi_s_f_p_fr_email
        SELECT * FROM mods_bi.mktg_stage_tbls.cnst_cdi_s_f_p_fr_email_stg;
		
		v_end_time := GETDATE();
		v_ok_message = 'Records inserted.';
        
        UPDATE etl_config.audit_log
		SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mktg_ops_tbls.cnst_cdi_s_f_p_fr_email) as INTEGER)
        WHERE proc_name = 'ld_gms_cnst_cdi_s_f_p_fr_email' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_gms_cnst_cdi_s_f_p_fr_email: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_gms_cnst_cdi_s_f_p_fr_email', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
