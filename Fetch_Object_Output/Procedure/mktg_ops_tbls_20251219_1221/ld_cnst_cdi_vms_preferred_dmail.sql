CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_vms_preferred_dmail()
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
Modified By: Stephen Knilans
Modified Date: August 6 2014
Purpose: To make it VMS compatible

Modified By:  Majeed Mohammad
Modified Date: 08/08/2016
Purpose: Add the DM address locator , assessment and county information. 

Modified By: Majeed Mohammad
Modified Date: 09/28/2016
Purpose: Updated the macro to use the view arc_mdm_vws.bzfc_cnst_email  instead of  arc_mdm_vws.bz_cnst_email . 
Also used the corrected email column locator_email_addr

Modified By: Michael Andrien
Modified Date: 08/22/2017
Purpose: Added logic to include constituents from theVolunteer list uploaded through the Stuart upload process.  The list name is 'FY18 STA Sign up form submission' , which is group membership key  272.

Modified By: Michael Andrien
Modified Date: 08/22/2017
Purpose: Commented out the changes from 8/22/2017 because the cnsts from the list only apply to email.  The DM section of these records should be null unless the cnst already has an entry from VMS.

Modified By: Michael Andrien
Modified Date: 10/26/2017
Purpose:  Added dpv_cd from the bzfc_cnst_addr to further qualify the address assessment category coding.  We were getting a high volume of returned mail
				and were told to exclude mailing addresses that have a 'Deliverable' assessment but the dpv_cd is not equal to 'Y'
				
Modified By: Majeed Mohammad
Modified Date: 03/20/2018
Purpose:  Added the logic to select the records from the group membership view 

Modified By: Majeed Mohammad
Modified Date: 03/22/2019
Purpose:  Added the join to the cnst_mstri_id in the subquery join to the view arc_cmm_vws.bz_grp_mbrshp. Without this, this macro was running for long time of about 2hrs. 

Modified By: Michael Andrien
Modified Date: 08/01/2019
Purpose: Fix the column select order in the macro to correct an issue with zip4 and county name attributes being in reverse order in the DM section of the profile

Modified By: Michael Andrien
Modified Date: 06/24/2020
Purpose: Modified the ranking rules to boost the CDIM DM Addr ranking higher when a VMS address is not present with a change date within one year.  Also, removed the preferred address logic from the previous rules.
	Below are the former rules: 
			CASE
		---- Prioritize Deliverable Home addresses with a DPV Code = Y 
		WHEN cnst_addr.dw_srcsys_trans_ts>date-365 AND cnst_addr.arc_srcsys_cd='VMS'  and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H')THEN 1
		WHEN cnst_addr.dw_srcsys_trans_ts>date-365 AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='LN')THEN 2
		--WHEN cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='LN') and ((P.bz_cnst_prsn_first_nm is not null and P.bz_cnst_prsn_last_nm is not null) or ORG.cnst_org_nm is not null) THEN 2
		---- Prioritize Deliverable Non-Home addresses with a DPV Code = Y 
		WHEN cnst_addr.dw_srcsys_trans_ts>date-365 AND cnst_addr.arc_srcsys_cd='VMS'   and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')THEN 3
		---- Prioritize Deliverable Home addresses with a DPV Code = Y  that are older than 1 year
		WHEN cnst_addr.dw_srcsys_trans_ts<date-365 AND cnst_addr.arc_srcsys_cd='CDIM'   and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='LN')THEN 3.5
		WHEN cnst_addr.dw_srcsys_trans_ts<=date-365 AND cnst_addr.arc_srcsys_cd='VMS'   and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 4
		---- Prioritize Deliverable Non-Home addresses with a DPV Code = Y  that are older than 1 year
		WHEN cnst_addr.dw_srcsys_trans_ts<=date-365 AND cnst_addr.arc_srcsys_cd='VMS'   and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 5
		---- Prioritize Deliverable Home addresses with a DPV Code <> Y 
		WHEN cnst_addr.dw_srcsys_trans_ts>date-365 AND cnst_addr.arc_srcsys_cd='VMS'  and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H')THEN 6
		--WHEN cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='LN') and ((P.bz_cnst_prsn_first_nm is not null and P.bz_cnst_prsn_last_nm is not null) or ORG.cnst_org_nm is not null) THEN 8
		---- Prioritize Deliverable Non-Home addresses with a DPV Code<> Y 
		WHEN cnst_addr.dw_srcsys_trans_ts>date-365 AND cnst_addr.arc_srcsys_cd='VMS' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')THEN 7
		---- Prioritize Deliverable Home addresses with a DPV Code <> Y  that are older than 1 year
		WHEN cnst_addr.dw_srcsys_trans_ts<=date-365 AND cnst_addr.arc_srcsys_cd='VMS'  and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 8
		---- Prioritize Deliverable Non-Home addresses with a DPV Code <> Y  that are older than 1 year
		WHEN cnst_addr.dw_srcsys_trans_ts<=date-365 AND cnst_addr.arc_srcsys_cd='VMS'   and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 9

Modified By: Majeed Mohammad
Modified Date: 07/08/2020
Purpose:  Updated the subqueries to include the source code CDIM. 
*/	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_vms_preferred_dmail', 'Stored Procedure', 'Inprogress', v_start_time);


begin

/*Execution time: 15m*/
DROP TABLE IF EXISTS cnst_cdi_vms_preferred_dmail_temp;

create temp table  cnst_cdi_vms_preferred_dmail_temp as (
--truncate table mktg_ops_tbls.cnst_cdi_vms_preferred_dmail;
--drop table mktg_ops_tbls.cnst_cdi_vms_preferred_dmail;
--select * from mktg_ops_tbls.cnst_cdi_vms_preferred_dmail;

/*insert into  mktg_ops_tbls.cnst_cdi_vms_preferred_dmail 
(cnst_mstr_id, cnst_hsld_id, cnst_dsp_deceased_cd, cnst_data_src_cd,
		cnst_prsn_prfx_nm, cnst_prsn_f_nm, cnst_prsn_m_nm, cnst_prsn_l_nm,
		cnst_prsn_sfx_nm, cnst_prsn_full_nm, cnst_alias_in_saltn_nm,
		cnst_alias_out_saltn_nm, locator_addr_key, cnst_addr_assessmnt_ctg, dpv_cd, cnst_addr_typ_cd, 
		cnst_line_1_addr, cnst_line_2_addr,
		cnst_city_nm, cnst_st_cd, cnst_zip_5_cd, cnst_zip_4_cd,	cnst_addr_county_nm, cnst_email,
		cnst_org_nm, cnst_typ_dsc) */
---------------------------------------------------------------------------------
/*Execution time: 5m5s*/

with cnst_addr as (SELECT 
	 cnst_mstr.cnst_mstr_id as cnst_mstr_id,
	 cnst_mstr.cnst_hsld_id as cnst_hsld_id,
	 cnst_mstr.cnst_dsp_deceased_cd as cnst_dsp_deceased_cd,
	 cnst_mstr.cnst_typ_cd,
    --addr.cnst_mstr_id AS cnst_mstr_id, 
    addr.locator_addr_key AS locator_addr_key,
    addr.assessmnt_ctg AS cnst_addr_assessmnt_ctg,
    addr.dpv_cd,
    addr.addr_typ_cd AS cnst_addr_typ_cd,
    addr.bz_cnst_addr_line1_addr AS bz_cnst_addr_line1_addr,
    addr.bz_cnst_addr_line2_addr AS bz_cnst_addr_line2_addr,
    addr.bz_cnst_addr_city_nm AS bz_cnst_addr_city_nm,
    addr.cnst_addr_state_cd AS cnst_addr_state_cd,
    addr.cnst_addr_zip_5_cd AS cnst_addr_zip_5_cd,
    addr.cnst_addr_zip_4_cd AS cnst_addr_zip_4_cd,
    addr.bz_cnst_addr_county_nm AS bz_cnst_addr_county_nm,
    addr.dw_srcsys_trans_ts AS dw_srcsys_trans_ts,
    addr.arc_srcsys_cd AS arc_srcsys_cd,
    addr.cnst_addr_prefd_ind AS cnst_addr_prefd_ind,
    
    CASE
 WHEN addr.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'VMS' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd = 'Y' AND addr.addr_typ_cd = 'H') THEN 1
 WHEN addr.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'CDIM' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd = 'Y' AND addr.addr_typ_cd = 'LN') THEN 2
 WHEN addr.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'VMS' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd = 'Y' AND addr.addr_typ_cd <> 'H') THEN 3
 WHEN addr.dw_srcsys_trans_ts < CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'CDIM' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd = 'Y' AND addr.addr_typ_cd = 'LN') THEN 3.5
 WHEN addr.dw_srcsys_trans_ts <= CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'VMS' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd = 'Y' AND addr.addr_typ_cd = 'H') THEN 4
 WHEN addr.dw_srcsys_trans_ts <= CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'VMS' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd = 'Y' AND addr.addr_typ_cd <> 'H') THEN 5
 WHEN addr.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'VMS' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd <> 'Y' AND addr.addr_typ_cd = 'H') THEN 6
 WHEN addr.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'VMS' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd <> 'Y' AND addr.addr_typ_cd <> 'H') THEN 7
 WHEN addr.dw_srcsys_trans_ts <= CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'VMS' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd <> 'Y' AND addr.addr_typ_cd = 'H') THEN 8
 WHEN addr.dw_srcsys_trans_ts <= CURRENT_DATE - INTERVAL '365 days' AND addr.arc_srcsys_cd = 'VMS' AND (COALESCE(addr.assessmnt_ctg, '') = 'Deliverable' AND addr.dpv_cd <> 'Y' AND addr.addr_typ_cd <> 'H') THEN 9
 ELSE 10
 end as addr_orderval
    
FROM eda.arc_mdm_vws.bzfc_cnst_addr addr
INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr cnst_mstr ON addr.cnst_mstr_id = cnst_mstr.cnst_mstr_id
WHERE 
    (/*addr.bz_cnst_addr_line1_addr IS NOT NULL OR 
    addr.bz_cnst_addr_line2_addr IS NOT NULL OR 
    addr.bz_cnst_addr_city_nm IS NOT NULL OR 
    addr.cnst_addr_state_cd IS NOT NULL OR 
    addr.cnst_addr_zip_5_cd IS NOT NULL OR 
    addr.cnst_addr_zip_4_cd IS NOT NULL*/
    
		COALESCE(addr.bz_cnst_addr_line1_addr, '') <> '' OR 
		COALESCE(addr.bz_cnst_addr_line2_addr, '') <> '' OR 
		COALESCE(addr.bz_cnst_addr_city_nm, '') <> '' OR 
		COALESCE(addr.cnst_addr_state_cd, '') <> '' OR 
		COALESCE(addr.cnst_addr_zip_5_cd, '') <> '' OR 
		COALESCE(addr.cnst_addr_zip_4_cd, '') <> ''
		) 
    AND 
    (addr.arc_srcsys_cd IN ('VMS', 'CDIM') OR 
    addr.arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='VMS') OR 
    addr.cnst_mstr_id IN (SELECT cnst_mstr_id FROM eda.arc_cmm_vws.bz_grp_mbrshp a LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key WHERE grp_typ = 'Vol NHQ LOB' AND a.arc_srcsys_cd=addr.arc_srcsys_cd AND a.cnst_mstr_id=addr.cnst_mstr_id))
--limit 5
),
/*Execution time: 54s*/
E as (   
		SELECT 
        cnst_mstr_id,
        arc_srcsys_cd,
        locator_email_addr,
        dw_srcsys_trans_ts,
        MAX(dw_srcsys_trans_ts) OVER (PARTITION BY cnst_mstr_id) AS max_dw_srcsys_trans_ts,
        CASE 
            WHEN LENGTH(locator_email_addr) >= 8 AND POSITION('@' IN locator_email_addr) > 1 AND POSITION(' ' IN TRIM(locator_email_addr)) = 0 AND 
            (SUBSTRING(locator_email_addr FROM LENGTH(locator_email_addr) - 3) IN ('.com','.net','.org','.gov','.mil','.edu') OR 
            SUBSTRING(locator_email_addr FROM LENGTH(locator_email_addr) - 2) IN ('.us','.ca','.mx'))
            THEN 'Y'
            ELSE 'N'
        END AS Valid_email,
        email_key
    FROM eda.arc_mdm_vws.bzfc_cnst_email cnst_email
    WHERE 
        (arc_srcsys_cd IN ('VMS', 'CDIM') OR 
        arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='VMS') OR 
        cnst_mstr_id IN (SELECT cnst_mstr_id FROM eda.arc_cmm_vws.bz_grp_mbrshp a LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key WHERE grp_typ = 'Vol NHQ LOB' AND a.arc_srcsys_cd=cnst_email.arc_srcsys_cd AND a.cnst_mstr_id=cnst_email.cnst_mstr_id))
        AND Valid_email = 'Y'),
        
/*Execution time: 5m28s*/
P as ( 
		SELECT 
        cnst_mstr_id,
        bz_cnst_prsn_prefix_nm,
        bz_cnst_prsn_first_nm,
        bz_cnst_prsn_middle_nm,
        bz_cnst_prsn_last_nm,
        bz_cnst_prsn_suffix_nm,
        cnst_prsn_full_nm,
        bz_cnst_alias_in_saltn_nm,
        bz_cnst_alias_out_saltn_nm,
        cnst_prsn_nm_typ_cd,
        dw_srcsys_trans_ts,
        arc_srcsys_cd,
        cnst_prsn_nm_end_dt
    FROM eda.arc_mdm_vws.bz_cnst_prsn_nm prsn_nm
    WHERE cnst_prsn_nm_typ_cd IN ('PN','LN') AND 
        (arc_srcsys_cd IN ('VMS', 'CDIM') OR 
        arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='VMS') OR 
        cnst_mstr_id IN (SELECT cnst_mstr_id FROM eda.arc_cmm_vws.bz_grp_mbrshp a LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key WHERE grp_typ = 'Vol NHQ LOB' AND a.arc_srcsys_cd=prsn_nm.arc_srcsys_cd AND a.cnst_mstr_id=prsn_nm.cnst_mstr_id))
),

/*Execution time: 13s*/
ORG as (
    SELECT
        cnst_mstr_id,
        arc_srcsys_cd,
        cnst_org_nm,
        dw_srcsys_trans_ts
    FROM
        eda.arc_mdm_vws.bz_cnst_org_nm org
    WHERE
        cnst_org_nm_typ_cd IN ('PN', 'LN')
        AND (
            arc_srcsys_cd IN ('VMS', 'CDIM') OR
            arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd = 'VMS') OR
            cnst_mstr_id IN (
                SELECT cnst_mstr_id
                FROM eda.arc_cmm_vws.bz_grp_mbrshp a
                LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key
                WHERE grp_typ = 'Vol NHQ LOB' AND a.arc_srcsys_cd = org.arc_srcsys_cd AND a.cnst_mstr_id = org.cnst_mstr_id
            )
        )
),

v as (

		with subquery as (select 
		 cnst_addr.cnst_mstr_id,
		 cnst_addr.cnst_hsld_id,
		 cnst_addr.cnst_dsp_deceased_cd,
		 cnst_addr.arc_srcsys_cd AS cnst_data_src_cd,
		P.bz_cnst_prsn_prefix_nm AS cnst_prsn_prfx_nm,
		 P.bz_cnst_prsn_first_nm AS cnst_prsn_f_nm,
		 P.bz_cnst_prsn_middle_nm AS cnst_prsn_m_nm,
		 P.bz_cnst_prsn_last_nm AS cnst_prsn_l_nm,
		 P.bz_cnst_prsn_suffix_nm AS cnst_prsn_sfx_nm,
		 P.cnst_prsn_full_nm AS cnst_prsn_full_nm,
		 P.bz_cnst_alias_in_saltn_nm AS cnst_alias_in_saltn_nm,
		 P.bz_cnst_alias_out_saltn_nm AS cnst_alias_out_saltn_nm,
		 cnst_addr.locator_addr_key AS locator_addr_key,
		 cnst_addr.cnst_addr_assessmnt_ctg AS cnst_addr_assessmnt_ctg,
		 cnst_addr.dpv_cd,
		 cnst_addr.cnst_addr_typ_cd AS cnst_addr_typ_cd,
		 cnst_addr.bz_cnst_addr_line1_addr AS cnst_line_1_addr,
		 cnst_addr.bz_cnst_addr_line2_addr AS cnst_line_2_addr,
		 cnst_addr.bz_cnst_addr_city_nm AS cnst_city_nm,
		 cnst_addr.cnst_addr_state_cd AS cnst_st_cd,
		 cnst_addr.cnst_addr_zip_5_cd AS cnst_zip_5_cd,
		 cnst_addr.cnst_addr_zip_4_cd AS cnst_zip_4_cd,
		 cnst_addr.bz_cnst_addr_county_nm AS bz_cnst_addr_county_nm,
		 E.locator_email_addr AS cnst_email,
		 ORG.cnst_org_nm,
			 CASE 
					 WHEN cnst_addr.cnst_typ_cd = 'IN' THEN 'Individual'
					 WHEN cnst_addr.cnst_typ_cd = 'OR' THEN 'Organization'
					 WHEN cnst_addr.cnst_typ_cd = 'AG' THEN 'Account Group'
			 END 
		 AS cnst_typ_dsc,
		 ROW_NUMBER() OVER (PARTITION BY cnst_addr.cnst_mstr_id ORDER BY
			 cnst_addr.addr_orderval,
			 cnst_addr.dw_srcsys_trans_ts DESC,
			 E.dw_srcsys_trans_ts DESC,
			 P.dw_srcsys_trans_ts DESC,
			 ORG.dw_srcsys_trans_ts DESC
		) as rn
		FROM cnst_addr
		LEFT JOIN P ON cnst_addr.cnst_mstr_id = P.cnst_mstr_id AND cnst_addr.arc_srcsys_cd = P.arc_srcsys_cd
		LEFT JOIN E ON cnst_addr.cnst_mstr_id = E.cnst_mstr_id AND cnst_addr.arc_srcsys_cd = E.arc_srcsys_cd
		LEFT JOIN ORG ON cnst_addr.cnst_mstr_id = ORG.cnst_mstr_id AND cnst_addr.arc_srcsys_cd = ORG.arc_srcsys_cd)
	
		SELECT 
		 cnst_mstr_id,
		 cnst_hsld_id,
		 cnst_dsp_deceased_cd,
		 cnst_data_src_cd, cnst_prsn_prfx_nm, cnst_prsn_f_nm, cnst_prsn_m_nm, cnst_prsn_l_nm, 
		 cnst_prsn_sfx_nm, cnst_prsn_full_nm, cnst_alias_in_saltn_nm, cnst_alias_out_saltn_nm, 
		 locator_addr_key, cnst_addr_assessmnt_ctg, dpv_cd, cnst_addr_typ_cd, cnst_line_1_addr, cnst_line_2_addr, cnst_city_nm, cnst_st_cd, cnst_zip_5_cd, cnst_zip_4_cd, 
		 bz_cnst_addr_county_nm,cnst_email,cnst_org_nm, cnst_typ_dsc from subquery
		where rn = 1)
		
		
		
		select * from v);
		truncate table mktg_ops_tbls.cnst_cdi_vms_preferred_dmail;
		insert into  mktg_ops_tbls.cnst_cdi_vms_preferred_dmail
		(cnst_mstr_id, cnst_hsld_id, cnst_dsp_deceased_cd, cnst_data_src_cd,
		cnst_prsn_prfx_nm, cnst_prsn_f_nm, cnst_prsn_m_nm, cnst_prsn_l_nm,
		cnst_prsn_sfx_nm, cnst_prsn_full_nm, cnst_alias_in_saltn_nm,
		cnst_alias_out_saltn_nm, locator_addr_key, cnst_addr_assessmnt_ctg, dpv_cd, addr_typ_cd, 
		cnst_line_1_addr, cnst_line_2_addr,
		cnst_city_nm, cnst_st_cd, cnst_zip_5_cd, cnst_zip_4_cd,	cnst_addr_county_nm, cnst_email,
		cnst_org_nm, cnst_typ_dsc) select * from cnst_cdi_vms_preferred_dmail_temp;
	
	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.cnst_cdi_vms_preferred_dmail) as nvarchar)+ ' Records inserted.';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_cnst_cdi_vms_preferred_dmail', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE etl_config.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
