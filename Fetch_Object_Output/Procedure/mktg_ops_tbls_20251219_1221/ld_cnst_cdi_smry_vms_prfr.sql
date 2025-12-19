CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_smry_vms_prfr()
 LANGUAGE plpgsql
AS $$	
	
/*
Created by: Majeed Mohammad
Created on: 05/24/2018
Purpose: This macro instantiates the VMS Pref profile table.  The view for this table is referenced in macro ld_dv_channel_accessibility

Modified By: Michael Andrien
Modified Date: 9/27/2018 
Purpose:  Add the 'N' to the unit type code qualifier in the prim_chpt join to pick up NHQ records.  We were missing the member number for some volunteer records because the NHQ chaper code = 'N'
		LEFT OUTER JOIN 
		  ( SELECT mb.cnst_mstr_id, dv.unit_cd, du.unit_key,  vol_status, status_typ, member_num as last_member_num  FROM vms_vws.dim_volunteer dv
		  LEFT JOIN arc_mdm_vws.bz_cnst_mstr_bridge mb on dv.vol_key = mb.cnst_mstr_subj_area_id
		  LEFT JOIN dw_common_vws.dim_unit du on du.nk_ecode = dv.unit_cd
		  WHERE mb.cnst_mstr_subj_area_cd = 'VMS' and  du.unit_typ_cd in ('C', 'TR', 'M', 'N')
		  QUALIFY ROW_NUMBER() OVER (PARTITION BY mb.cnst_mstr_id ORDER BY dv.status_effect_dt DESC) = 1
		  ) prim_chpt (cnst_mstr_id, unit_cd, unit_key,  vol_status, status_typ, last_member_num)
		  
Modified By: Majeed Mohammad
Modified Date: 9/28/2018 
Purpose:  Updated the subquery for grp_unit. This query was returning multiple rows per cnst_mstr_id. Added the where unit_key>0 and the qualify statement to pick the latest record. 

Modified By: Majeed Mohammad
Modified Date: 02/26/2019
Purpose:  Added the UPDATE statement to populate the column inactivation_reason_dsc

Modified By: Michael Andrien
Modified Date: 9/11/2019
Purpose:  Modified the VMS_CNST join to correct a product join that was causing performance issues with the macro.  				
				select cnst_mstr_id
				from arc_cmm_vws.bz_grp_mbrshp a 
				left join arc_cmm_vws.grp_ref b on a.grp_key = b.grp_key 
				where grp_typ = 'Vol NHQ LOB' --and a.arc_srcsys_cd=exb.cnst_mstr_subj_area_cd (NOTE: 9/11/2019 commented out the subject area code qualifier.  This was causing a product join.
				
Modified By: Majeed Mohammad
Modified Date: 09/11/2019
Purpose:   Converted the OR to a Union. Also, changed the reference to the external bridge and used an IN clause

Modified By: Michael Andrien
Modified Date: 11/27/2019
Purpose:  Added logic to the prim_chpt Join to include the active indicator and added the active_ind to the ORDER BY in the QUALIFY statement to prioritize active volunteer records over inactive records.  This impacts approximately 54K volunteers that have
more than one volunteer record in the Volunteer Connection (VCN) system.  This was affect the status and member record details we chose for the VMS Preferred profile and consequently imacted our 'Active'counts and our new and anniversary survey send in cases where the volunteer 
had duplicated records in the system.  Our profile had been sorting on the Status Effective date, so if the last update was applied to the inactive record, our profile would select the inactive record details rather than the active record details.
		  ( 
			  SELECT 
					mb.cnst_mstr_id, 
					dv.unit_cd, du.unit_key,  
					vol_status, status_typ, 
					member_num as last_member_num,   
					case when 	status_typ= 'Volunteer' and vol_status in ('DCS - HPDD Member', 'Event Based - Youth Under 18', 'Event Based Volunteer', 'General Partner Member', 'General Volunteer',
					'Harvey DRO - EBV', 'Harvey DRO - Health Professional', 'Harvey DRO - Partner Member', 'Harvey DRO - Youth Under 18', 'Irma DRO - EBV',
					'Irma DRO - Youth Under 18', 'Maria DRO - EBV', 'Maria DRO - Youth Under 18', 'RWTC Member', 'STA/HFC Volunteer - South Carolina', 
					'STA/HFC Youth Volunteer - South Carolina', 'Youth Under 18') then 1 else 0 
					end as active_ind
			FROM vms_vws.dim_volunteer dv
			  LEFT JOIN arc_mdm_vws.bz_cnst_mstr_bridge mb on dv.vol_key = mb.cnst_mstr_subj_area_id
			  LEFT JOIN dw_common_vws.dim_unit du on du.nk_ecode = dv.unit_cd
			  WHERE mb.cnst_mstr_subj_area_cd = 'VMS' and  du.unit_typ_cd in ('C', 'TR', 'M', 'N')
			  QUALIFY ROW_NUMBER() OVER (PARTITION BY mb.cnst_mstr_id ORDER BY active_ind desc, dv.status_effect_dt DESC) = 1
		  ) prim_chpt (cnst_mstr_id, unit_cd, unit_key,  vol_status, status_typ, last_member_num)
		  
Modified By: Michael Andrien
Modified Date: 11/23/2021
Purpose:  Added the FAEM join to include email override logic into the EM section of the profile.

Modified By: Michael Andrien
Modified Date: 02/14/2023
Purpose: Modified the prim_chapt join logic - to move the unit type qualification to the join on clause with dim_unit versus in the WHERE cluase.  
This was causing some records to be excluded from the query.
	Replaced
		LEFT JOIN dw_common_vws.dim_unit du on du.nk_ecode = dv.unit_cd 
	  WHERE mb.cnst_mstr_subj_area_cd = 'VMS'' and  du.unit_typ_cd in ('C', 'TR', 'M', 'N')
	With
	  LEFT JOIN dw_common_vws.dim_unit du on du.nk_ecode = dv.unit_cd and  du.unit_typ_cd in ('C', 'TR', 'M', 'N')
	  WHERE mb.cnst_mstr_subj_area_cd = 'VMS' 

*/
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_smry_vms_prfr', 'Stored Procedure', 'Inprogress', v_start_time);


begin

/*Execution time: 15m*/
Truncate TABLE mktg_ops_tbls.cnst_cdi_smry_vms_prfr_stg;



INSERT INTO 
mktg_ops_tbls.cnst_cdi_smry_vms_prfr_stg
(cnst_mstr_id, cnst_hsld_id, cnst_arc_deceased_cd, 
dm_cnst_data_src_cd, dm_cnst_prsn_prfx_nm, dm_cnst_prsn_f_nm, dm_cnst_prsn_m_nm, dm_cnst_prsn_l_nm, dm_cnst_prsn_sfx_nm, 
dm_cnst_prsn_full_nm, dm_cnst_alias_in_saltn_nm, dm_cnst_alias_out_saltn_nm, dm_locator_addr_key, dm_cnst_addr_assessmnt_ctg, 
dpv_cd, dm_cnst_line_1_addr, dm_cnst_line_2_addr, dm_cnst_city_nm, dm_cnst_st_cd, 
dm_cnst_zip_5_cd, dm_cnst_zip_4_cd, dm_cnst_addr_county_nm, dm_cnst_email, dm_cnst_org_nm, dm_cnst_typ_dsc, 
em_cnst_data_src_cd, em_cnst_prsn_prfx_nm, em_cnst_prsn_f_nm, em_cnst_prsn_m_nm, em_cnst_prsn_l_nm, em_cnst_prsn_sfx_nm, 
em_cnst_prsn_full_nm, em_cnst_alias_in_saltn_nm, em_cnst_alias_out_saltn_nm, 
em_locator_addr_key, em_cnst_line_1_addr, em_cnst_line_2_addr, em_cnst_city_nm, em_cnst_st_cd, em_cnst_zip_5_cd, em_cnst_zip_4_cd, 
em_cnst_addr_county_nm, em_cnst_email, em_cnst_email_key, em_cnst_email_assessmnt_ctg, 
em_cnst_org_nm, em_cnst_typ_dsc, email_dlvrbl_ind, 
prim_cnst_phn, prim_cnst_phn_source, prim_cnst_phn_typ_dsc, cnst_work_phn, cnst_work_phn_source, cnst_work_phn_typ_dsc, 
cnst_mbl_phn, cnst_mbl_phn_source, cnst_mbl_phn_typ_dsc, 
do_not_call_hm_phn_ind, do_not_call_mbl_phn_ind, do_not_call_work_phn_ind, do_not_email_ind, do_not_mail_ind, do_not_txt_ind, 
cnst_3rd_prty_segmtn_group_nm, unit_key, affl_lock_ind, unit_cd, 
vol_status, status_typ, last_member_num, initial_vol_dt, --inactivation_reason_dsc, 
ethnicity, is_hispanic)




--select count(*) from mktg_ops_tbls.cnst_cdi_smry_vms_prfr_stg;--2249199 rows inserted in 4mins.


/*---Starting CTE calculations---*/

with vms_cnst as (
		with vms_cnst_subquery as (
	
					SELECT cnst_mstr_id 
					FROM eda.arc_mdm_vws.bz_cnst_mstr_external_brid exb
					WHERE arc_srcsys_cd IN ('VMS') 
					OR arc_srcsys_cd IN (
					SELECT arc_srcsys_cd 
					FROM eda.arc_mdm_vws.bz_arc_srcsys 
					WHERE line_of_service_cd = 'VMS'
				)

		UNION
		
				-- Step 2: Select cnst_mstr_id from arc_cmm_vws.bz_grp_mbrshp with a join to arc_cmm_vws.grp_ref
				SELECT cnst_mstr_id 
				FROM eda.arc_cmm_vws.bz_grp_mbrshp a 
				LEFT JOIN eda.arc_cmm_vws.grp_ref b 
				ON a.grp_key = b.grp_key 
				WHERE grp_typ = 'Vol NHQ LOB' 
				AND a.arc_srcsys_cd IN (
				    SELECT arc_srcsys_cd 
				    FROM eda.arc_mdm_vws.bz_cnst_mstr_external_brid 
				    GROUP BY arc_srcsys_cd)
		UNION    
				SELECT subquery.cnst_mstr_id as cnst_mstr_id 
				FROM (
					    SELECT
					        cnst_email.cnst_mstr_id,
					        ROW_NUMBER() OVER (PARTITION BY grp_ref.grp_key, cnst_email.cnst_mstr_id, cnst_prsn_nm.cnst_mstr_id ORDER BY cnst_email.dw_srcsys_trans_ts DESC) AS rn
					    FROM eda.dw_stuart_vws.cnst_grp_mbrshp cnst_grp_mbrshp
					    INNER JOIN eda.arc_mdm_vws.bzfc_cnst_email cnst_email 
					        ON cnst_email.cnst_email_addr = cnst_grp_mbrshp.cnst_email1_addr
					    INNER JOIN eda.arc_mdm_vws.bz_cnst_prsn_nm cnst_prsn_nm 
					        ON SUBSTRING(cnst_prsn_nm.bz_cnst_prsn_first_nm, 1, 1) = SUBSTRING(cnst_grp_mbrshp.cnst_first_nm, 1, 1)
					        AND cnst_prsn_nm.bz_cnst_prsn_last_nm = cnst_grp_mbrshp.cnst_last_nm
					        AND cnst_email.cnst_mstr_id = cnst_prsn_nm.cnst_mstr_id
					        AND cnst_email.cnst_srcsys_id = cnst_prsn_nm.cnst_srcsys_id
					    INNER JOIN eda.arc_cmm_vws.grp_ref grp_ref 
					        ON cnst_grp_mbrshp.grp_cd = grp_ref.grp_cd
					        AND grp_ref.row_stat_cd <> 'L'
					    INNER JOIN eda.arc_cmm_vws.grp_mbrshp grp
					        ON grp.cnst_mstr_id = cnst_email.cnst_mstr_id
					        AND grp.grp_key = grp_ref.grp_key
					    WHERE cnst_grp_mbrshp.transaction_key = 5600118 
					        AND (cnst_email.assessmnt_ctg IN ('Validated', 'Use With Caution') OR cnst_email.assessmnt_ctg IS NULL)
					) subquery
			WHERE rn = 1

) select M.cnst_mstr_id as cnst_mstr_id,
M.cnst_hsld_id as cnst_hsld_id,
M.cnst_arc_deceased_cd as cnst_arc_deceased_cd 
from vms_cnst_subquery 
inner JOIN eda.arc_mdm_vws.bz_cnst_mstr M on vms_cnst_subquery.cnst_mstr_id = cast (M.cnst_mstr_id AS INTEGER) --limit 500
),

/*----------- Starting Stuart joins------------*/
stuart_unit as(
			with stuart_unit_subquery AS (
			    SELECT 
			        cnst_email.cnst_mstr_id as cnst_mstr_id,
			        cnst_grp_mbrshp.unit_key,
			        cnst_grp_mbrshp.cnst_prefix_nm, 
			        cnst_prsn_nm.bz_cnst_prsn_first_nm,
			        cnst_prsn_nm.bz_cnst_prsn_last_nm,
			        cnst_grp_mbrshp.cnst_middle_nm,
			        ROW_NUMBER() OVER (PARTITION BY grp_ref.grp_key, cnst_email.cnst_mstr_id, cnst_prsn_nm.cnst_mstr_id ORDER BY cnst_email.dw_srcsys_trans_ts DESC) AS rn
			    FROM eda.dw_stuart_vws.cnst_grp_mbrshp cnst_grp_mbrshp
			    INNER JOIN eda.arc_mdm_vws.bzfc_cnst_email cnst_email 
			        ON cnst_email.cnst_email_addr = cnst_grp_mbrshp.cnst_email1_addr
			    INNER JOIN eda.arc_mdm_vws.bz_cnst_prsn_nm cnst_prsn_nm 
			        ON SUBSTRING(cnst_prsn_nm.bz_cnst_prsn_first_nm, 1, 1) = SUBSTRING(cnst_grp_mbrshp.cnst_first_nm, 1, 1)
			        AND cnst_prsn_nm.bz_cnst_prsn_last_nm = cnst_grp_mbrshp.cnst_last_nm
			        AND cnst_email.cnst_mstr_id = cnst_prsn_nm.cnst_mstr_id
			        AND cnst_email.cnst_srcsys_id = cnst_prsn_nm.cnst_srcsys_id
			    INNER JOIN eda.arc_cmm_vws.grp_ref grp_ref 
			        ON cnst_grp_mbrshp.grp_cd = grp_ref.grp_cd
			        AND grp_ref.row_stat_cd <> 'L'
			    INNER JOIN eda.arc_cmm_vws.grp_mbrshp grp
			        ON grp.cnst_mstr_id = cnst_email.cnst_mstr_id
			        AND grp.grp_key = grp_ref.grp_key
			    WHERE cnst_grp_mbrshp.transaction_key = 5600118 
			        AND (cnst_email.assessmnt_ctg IN ('Validated', 'Use With Caution') OR cnst_email.assessmnt_ctg IS NULL)
			)
			SELECT 
			    M.cnst_mstr_id as cnst_mstr_id,
			    stuart_unit_subquery.unit_key,
			    stuart_unit_subquery.cnst_prefix_nm,
			    stuart_unit_subquery.bz_cnst_prsn_first_nm,
			    stuart_unit_subquery.bz_cnst_prsn_last_nm,
			    stuart_unit_subquery.cnst_middle_nm
--			    DM.cnst_mstr_id AS dm_cnst_mstr_id,
--			    EM.cnst_mstr_id AS em_cnst_mstr_id
			FROM eda.arc_mdm_vws.bz_cnst_mstr M
			INNER JOIN stuart_unit_subquery 
			    ON M.cnst_mstr_id = stuart_unit_subquery.cnst_mstr_id
			    AND stuart_unit_subquery.rn = 1
),
/*----------- Starting prim_chpt------------*/
			    
prim_chpt_vw as (WITH prim_chpt AS (
    SELECT 
        mb.cnst_mstr_id as cnst_mstr_id, 
        dv.unit_cd, 
        du.unit_key,  
        dv.vol_status, 
        dv.status_typ, 
        dv.member_num AS last_member_num,   
        CASE 
            WHEN dv.status_typ = 'Volunteer' AND dv.vol_status IN (
                'DCS - HPDD Member', 'Event Based - Youth Under 18', 'Event Based Volunteer', 'General Partner Member', 'General Volunteer',
                'Harvey DRO - EBV', 'Harvey DRO - Health Professional', 'Harvey DRO - Partner Member', 'Harvey DRO - Youth Under 18', 'Irma DRO - EBV',
                'Irma DRO - Youth Under 18', 'Maria DRO - EBV', 'Maria DRO - Youth Under 18', 'RWTC Member', 'STA/HFC Volunteer - South Carolina', 
                'STA/HFC Youth Volunteer - South Carolina', 'Youth Under 18'
            ) THEN 1 ELSE 0 
        END AS active_ind,
        dv.ethnicity,
        dv.is_hispanic,
        ROW_NUMBER() OVER (PARTITION BY mb.cnst_mstr_id ORDER BY active_ind DESC, dv.status_effect_dt DESC) AS rn
    FROM eda.vms_vws.dim_volunteer dv
    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge mb 
        ON dv.vol_key = mb.cnst_mstr_subj_area_id
    LEFT JOIN eda.dw_common_vws.dim_unit du 
        ON du.nk_ecode = dv.unit_cd 
        AND du.unit_typ_cd IN ('C', 'TR', 'M', 'N')
    WHERE mb.cnst_mstr_subj_area_cd = 'VMS'
)
SELECT 
    M.cnst_mstr_id as cnst_mstr_id,
    prim_chpt.unit_cd,
    prim_chpt.unit_key,
    prim_chpt.vol_status,
    prim_chpt.status_typ,
    prim_chpt.last_member_num,
    prim_chpt.active_ind,
    prim_chpt.ethnicity,
    prim_chpt.is_hispanic
FROM eda.arc_mdm_vws.bz_cnst_mstr M
LEFT OUTER JOIN prim_chpt 
    ON M.cnst_mstr_id = prim_chpt.cnst_mstr_id
    AND prim_chpt.rn = 1),
    
    /*------hphone----------*/
hphone AS(
		WITH hphone_subquery AS (
		SELECT 
		       
		bz_cnst_phn.CNST_MSTR_ID,
        bz_cnst_phn.cnst_phn_num AS prim_cnst_phn,
        bz_cnst_phn.arc_srcsys_cd AS prim_cnst_phn_source,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd = 'H' THEN 'Home' 
            ELSE 'Other' 
        END AS prim_cnst_phn_typ_dsc,
        CASE 
            WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd 
        END  AS FR_arc_srcsys_cd,
        ROW_NUMBER() OVER (
            PARTITION BY bz_cnst_phn.cnst_mstr_id 
            ORDER BY 
                CASE /* replaced 'bz_cnst_phn.cnst_phn_num' IS NOT NULL due to correlated subquery error:COALESCE(cnst_phn_num, '') <> '' ensures that cnst_phn_num is not null or empty*/
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'VMS' AND COALESCE(cnst_phn_num, '') <> '' THEN 1
                    WHEN bz_cnst_phn.arc_srcsys_cd = 'CDIM' AND bz_cnst_phn.phn_typ_cd = 'LN' AND COALESCE(cnst_phn_num, '') <> '' THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 4
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND COALESCE(cnst_phn_num, '') <> '' THEN 5
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' AND COALESCE(cnst_phn_num, '') <> '' THEN 6
                    ELSE 999
                END ASC,
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum,
        CASE 
		            WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'VMS' AND COALESCE(cnst_phn_num, '') <> '' THEN 1
		            WHEN bz_cnst_phn.arc_srcsys_cd = 'CDIM' AND bz_cnst_phn.phn_typ_cd = 'LN' AND COALESCE(cnst_phn_num, '') <> '' THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 4
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND COALESCE(cnst_phn_num, '') <> '' THEN 5
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' AND COALESCE(cnst_phn_num, '') <> '' THEN 6
            ELSE 999
        END AS hnum
    FROM eda.arc_mdm_vws.bz_cnst_phn bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys bz_arc_srcsys
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
        AND bz_arc_srcsys.line_of_service_cd = 'VMS'
    WHERE bz_cnst_phn.phn_typ_cd IN ('H', 'LN')
)
SELECT 
    hphone_subquery.CNST_MSTR_ID as CNST_MSTR_ID,
    hphone_subquery.prim_cnst_phn,
    hphone_subquery.prim_cnst_phn_source,
    hphone_subquery.prim_cnst_phn_typ_dsc,
    hphone_subquery.FR_arc_srcsys_cd
FROM hphone_subquery
WHERE hphone_subquery.rownum = 1
AND hphone_subquery.hnum < 999
),

wphone as (WITH wphone_subquery AS (
    SELECT 
        bz_cnst_phn.CNST_MSTR_ID,
        bz_cnst_phn.cnst_phn_num AS cnst_work_phone,
        bz_cnst_phn.arc_srcsys_cd AS cnst_work_phone_source,
        CAST('Work' AS VARCHAR(20)) AS cnst_work_phone_type_cd,
        CASE 
            WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd 
        END AS FR_arc_srcsys_cd,
        ROW_NUMBER() OVER (
            PARTITION BY bz_cnst_phn.cnst_mstr_id 
            ORDER BY 
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'VMS' AND COALESCE(cnst_phn_num, '') <> '' THEN 1
                    WHEN bz_cnst_phn.arc_srcsys_cd = 'CDIM' AND bz_cnst_phn.phn_typ_cd = 'LN' AND COALESCE(cnst_phn_num, '') <> '' THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 4
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND COALESCE(cnst_phn_num, '') <> '' THEN 5
                    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' AND COALESCE(cnst_phn_num, '') <> '' THEN 6
                    ELSE 999
                END ASC,
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'VMS' AND COALESCE(cnst_phn_num, '') <> '' THEN 1
            WHEN bz_cnst_phn.arc_srcsys_cd = 'CDIM' AND bz_cnst_phn.phn_typ_cd = 'LN' AND COALESCE(cnst_phn_num, '') <> '' THEN 2
            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 3
            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 4
            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND COALESCE(cnst_phn_num, '') <> '' THEN 5
            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' AND COALESCE(cnst_phn_num, '') <> '' THEN 6
            ELSE 999
        END AS wnum
    FROM eda.arc_mdm_vws.bz_cnst_phn bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys bz_arc_srcsys
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
        AND bz_arc_srcsys.line_of_service_cd = 'VMS'
    WHERE bz_cnst_phn.phn_typ_cd = 'W'
		)
		SELECT 
		    wphone_subquery.CNST_MSTR_ID,
		    wphone_subquery.cnst_work_phone,
		    wphone_subquery.cnst_work_phone_source,
		    wphone_subquery.cnst_work_phone_type_cd,
		    wphone_subquery.FR_arc_srcsys_cd
		FROM wphone_subquery
		WHERE wphone_subquery.rownum = 1
		AND wphone_subquery.wnum < 999),

/*-----mphone-*/
 mphone as 
(
	WITH mphone_subquery AS (
    SELECT 
        bz_cnst_phn.CNST_MSTR_ID,
        bz_cnst_phn.cnst_phn_num AS cnst_mbl_phn,
        bz_cnst_phn.arc_srcsys_cd AS cnst_mbl_phn_source,
        CAST('Mobile' AS VARCHAR(20)) AS cnst_mbl_phn_typ_dsc,
        CASE 
            WHEN bz_arc_srcsys.arc_srcsys_cd IS NOT NULL THEN bz_arc_srcsys.arc_srcsys_cd 
        END AS FR_arc_srcsys_cd,
        ROW_NUMBER() OVER (
            PARTITION BY bz_cnst_phn.cnst_mstr_id 
            ORDER BY 
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'VMS' AND COALESCE(cnst_phn_num, '') <> '' THEN 1
                    WHEN bz_cnst_phn.arc_srcsys_cd = 'CDIM' AND bz_cnst_phn.phn_typ_cd = 'LN' AND COALESCE(cnst_phn_num, '') <> '' THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 3
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 4
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND COALESCE(cnst_phn_num, '') <> '' THEN 5
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' AND COALESCE(cnst_phn_num, '') <> '' THEN 6
                    ELSE 999
                END ASC,
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'VMS' AND COALESCE(cnst_phn_num, '') <> '' THEN 1
            WHEN bz_cnst_phn.arc_srcsys_cd = 'CDIM' AND bz_cnst_phn.phn_typ_cd = 'LN' AND COALESCE(cnst_phn_num, '') <> '' THEN 2
            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'SFFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 3
            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'TAFS' AND COALESCE(cnst_phn_num, '') <> '' THEN 4
            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_arc_srcsys.arc_srcsys_cd IS NOT NULL AND COALESCE(cnst_phn_num, '') <> '' THEN 5
            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'ATG' AND COALESCE(cnst_phn_num, '') <> '' THEN 6
            ELSE 999
        END AS mnum
    FROM eda.arc_mdm_vws.bz_cnst_phn bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys bz_arc_srcsys
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd
        AND bz_arc_srcsys.line_of_service_cd = 'VMS'
    WHERE bz_cnst_phn.phn_typ_cd = 'M'
)
SELECT 
    mphone_subquery.CNST_MSTR_ID,
    mphone_subquery.cnst_mbl_phn,
    mphone_subquery.cnst_mbl_phn_source,
    mphone_subquery.cnst_mbl_phn_typ_dsc,
    mphone_subquery.FR_arc_srcsys_cd
FROM mphone_subquery
WHERE mphone_subquery.rownum = 1
AND mphone_subquery.mnum < 999
),

/*-----vol_init--------*/
vol_init as (
		SELECT cnst_mstr_id, MIN(initial_vol_dt) AS initial_vol_dt
		FROM eda.arc_mdm_vws.cnst_mstr_bridge BRDG
		INNER JOIN eda.vms_vws.dim_volunteer bx 
		    ON bx.vol_key = BRDG.cnst_mstr_subj_area_id 
		    AND BRDG.cnst_mstr_subj_area_cd = 'VMS'
		GROUP BY cnst_mstr_id
),

/*-----grp_unit--------*/
grp_unit as (
			SELECT cnst_mstr_id, unit_key
			FROM (
			    SELECT cnst_mstr_id, unit_key,
			           ROW_NUMBER() OVER (
			               PARTITION BY cnst_mstr_id 
			               ORDER BY cnst_mstr_id, grp_mbrshp_eff_strt_dt DESC, grp_mbrshp_eff_end_dt DESC
			           ) AS rn
			    FROM eda.arc_cmm_vws.bz_grp_mbrshp a
			    LEFT JOIN eda.arc_cmm_vws.grp_ref b 
			        ON a.grp_key = b.grp_key
			    WHERE grp_typ = 'Vol NHQ LOB' 
			        AND a.unit_key > 0
			) sub
			WHERE rn = 1
),

faem as (

WITH a AS (
    SELECT 
        cnst_mstr_id, 
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
        CASE WHEN c.assessmnt_ctg IS NULL THEN 'Validated' ELSE c.assessmnt_ctg END AS em_cnst_email_assessmnt_ctg,
        d.ok_to_email_flg AS ok_to_email_flg,
        list_upload_ts,
        ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY list_upload_ts DESC) AS rn
    FROM mktg_ops_tbls.pacific_east_email_append a
    LEFT JOIN eda.arc_mdm_vws.bz_locator_email b ON b.cnst_email_addr = a.cnst_email
    LEFT JOIN eda.arc_mdm_vws.bz_assessmnt c ON b.assessmnt_key = c.assessmnt_key
    LEFT JOIN mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile d ON a.cnst_email = d.email_addr
    WHERE a.row_stat_cd <> 'L'
    
    UNION ALL
    
    SELECT 
        cnst_mstr_id, 
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
        CASE WHEN c.assessmnt_ctg IS NULL THEN 'Validated' ELSE c.assessmnt_ctg END AS em_cnst_email_assessmnt_ctg,
        d.ok_to_email_flg AS ok_to_email_flg,
        list_upload_ts,
        ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY list_upload_ts DESC) AS rn
    FROM mktg_ops_tbls.fresh_address_email_append a
    LEFT JOIN eda.arc_mdm_vws.bz_locator_email b ON b.cnst_email_addr = a.cnst_email
    LEFT JOIN eda.arc_mdm_vws.bz_assessmnt c ON b.assessmnt_key = c.assessmnt_key
    LEFT JOIN mktg_ops_tbls.gms_bzfc_cdi_fr_prfr_email_profile d ON a.cnst_email = d.email_addr
    WHERE a.row_stat_cd <> 'L'
),
b AS (
    SELECT 
        a.cnst_mstr_id,
        a.cnst_email_key,
        a.cnst_email, 
        a.cnst_email_assessmnt_ctg, 
        a.cnst_data_src_cd,
        b.cnst_email_strt_ts,
        CASE WHEN c.email_addr IS NOT NULL THEN c.ok_to_email_flg ELSE NULL END AS ok_to_email_flg
    FROM mktg_ops_tbls.cnst_cdi_s_f_p_fr_email a
    LEFT JOIN eda.arc_mdm_vws.bzfc_cnst_email b ON a.cnst_mstr_id = b.cnst_mstr_id AND a.cnst_email_key = b.email_key AND collate(a.cnst_data_src_cd, 'case_insensitive') = collate(b.arc_srcsys_cd, 'case_insensitive')
    LEFT JOIN mktg_ops_vws.gms_bzfc_cnst_cdi_fr_prfr_em_prfl c ON a.cnst_mstr_id = c.cnst_mstr_id
)



SELECT 
    a.cnst_mstr_id as cnst_mstr_id, 
    a.cnst_prsn_f_nm as em_cnst_prsn_f_nm, 
    a.cnst_prsn_l_nm as em_cnst_prsn_l_nm, 
    a.cnst_line_1_addr as em_cnst_line_1_addr, 
    a.cnst_line_2_addr as em_cnst_line_2_addr, 
    a.cnst_city_nm as em_cnst_city_nm, 
    a.cnst_st_cd as em_cnst_st_cd, 
    a.cnst_zip_5_cd as em_cnst_zip_5_cd, 
    a.cnst_email as em_cnst_email, 
    a.list_source_nm as em_list_source_nm, 
    a.em_cnst_data_src_cd as em_cnst_data_src_cd,
    a.em_email_key as em_email_key,
    a.em_cnst_email_assessmnt_ctg as em_cnst_email_assessmnt_ctg,
    a.ok_to_email_flg,
    a.list_upload_ts
FROM a
LEFT JOIN b ON a.cnst_mstr_id = b.cnst_mstr_id
WHERE (a.ok_to_email_flg IS NULL OR a.ok_to_email_flg = 'Y') 
  AND ((collate(a.cnst_email,'case_insensitive') <> collate(b.cnst_email,'case_insensitive')
  AND a.list_upload_ts >= b.cnst_email_strt_ts) 
  OR (b.cnst_mstr_id IS NULL))
AND a.rn = 1)



select 
vms_cnst.cnst_mstr_id AS cnst_mstr_id,
 vms_cnst.cnst_hsld_id AS cnst_hsld_id,
 vms_cnst.cnst_arc_deceased_cd AS cnst_arc_deceased_cd,
 DM.cnst_data_src_cd AS dm_cnst_data_src_cd,
 DM.cnst_prsn_prfx_nm AS dm_cnst_prsn_prfx_nm,
 DM.cnst_prsn_f_nm AS dm_cnst_prsn_f_nm,
 DM.cnst_prsn_m_nm AS dm_cnst_prsn_m_nm,
 DM.cnst_prsn_l_nm AS dm_cnst_prsn_l_nm,
 DM.cnst_prsn_sfx_nm AS dm_cnst_prsn_sfx_nm,
 DM.cnst_prsn_full_nm AS dm_cnst_prsn_full_nm,
 DM.cnst_alias_in_saltn_nm AS dm_cnst_alias_in_saltn_nm,
 DM.cnst_alias_out_saltn_nm AS dm_cnst_alias_out_saltn_nm,
 DM.locator_addr_key AS dm_locator_addr_key,
 DM.cnst_addr_assessmnt_ctg AS dm_cnst_addr_assessmnt_ctg,
 DM.dpv_cd AS dpv_cd,
 DM.cnst_line_1_addr AS dm_cnst_line_1_addr,
 DM.cnst_line_2_addr AS dm_cnst_line_2_addr,
 DM.cnst_city_nm AS dm_cnst_city_nm,
 DM.cnst_st_cd AS dm_cnst_st_cd,
 DM.cnst_zip_5_cd AS dm_cnst_zip_5_cd,
 DM.cnst_zip_4_cd AS dm_cnst_zip_4_cd,
 DM.cnst_addr_county_nm AS dm_cnst_addr_county_nm,
 DM.cnst_email AS dm_cnst_email,
 DM.cnst_org_nm AS dm_cnst_org_nm,
 DM.cnst_typ_dsc AS dm_cnst_typ_dsc,
 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_data_src_cd 
 ELSE EM.cnst_data_src_cd 
 END AS em_cnst_data_src_cd,--fine till here
 CASE 
 WHEN EM.cnst_prsn_prfx_nm IS NULL THEN collate(stuart_unit.cnst_prefix_nm, 'CASE_INSENSITIVE') 
 ELSE EM.cnst_prsn_prfx_nm 
 END AS em_cnst_prsn_prfx_nm,--fine till here
 CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE') 
    WHEN EM.cnst_prsn_f_nm IS NULL THEN COLLATE(stuart_unit.bz_cnst_prsn_first_nm, 'CASE_INSENSITIVE') 
    ELSE EM.cnst_prsn_f_nm 
END AS em_cnst_prsn_f_nm,
CASE 
    WHEN EM.cnst_prsn_m_nm IS NULL THEN COLLATE(stuart_unit.cnst_middle_nm, 'CASE_INSENSITIVE') 
    ELSE EM.cnst_prsn_m_nm 
END AS em_cnst_prsn_m_nm,
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE') 
    WHEN EM.cnst_prsn_l_nm IS NULL THEN COLLATE(stuart_unit.bz_cnst_prsn_last_nm, 'CASE_INSENSITIVE') 
    ELSE EM.cnst_prsn_l_nm 
END AS em_cnst_prsn_l_nm,
EM.cnst_prsn_sfx_nm AS em_cnst_prsn_sfx_nm,--fine till here
CASE 
    WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_prsn_f_nm, 'CASE_INSENSITIVE') || ' ' || collate(faem.em_cnst_prsn_l_nm, 'CASE_INSENSITIVE') 
    WHEN EM.cnst_prsn_full_nm IS NULL THEN COLLATE(stuart_unit.bz_cnst_prsn_first_nm, 'CASE_INSENSITIVE') || ' ' || COLLATE(stuart_unit.cnst_middle_nm, 'CASE_INSENSITIVE') || ' ' || COLLATE(stuart_unit.bz_cnst_prsn_last_nm, 'CASE_INSENSITIVE') 
    ELSE EM.cnst_prsn_full_nm 
END AS em_cnst_prsn_full_nm,

 EM.cnst_alias_in_saltn_nm AS em_cnst_alias_in_saltn_nm,
 EM.cnst_alias_out_saltn_nm AS em_cnst_alias_out_saltn_nm,
 EM.locator_addr_key AS em_locator_addr_key,
 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_line_1_addr, 'CASE_INSENSITIVE') 
 ELSE EM.cnst_line_1_addr 
 END AS em_cnst_line_1_addr,
 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_line_2_addr, 'CASE_INSENSITIVE') 
 ELSE EM.cnst_line_2_addr 
 END AS em_cnst_line_2_addr,
 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_city_nm, 'CASE_INSENSITIVE')  
 ELSE EM.cnst_city_nm 
 END AS em_cnst_city_nm,
 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_st_cd, 'CASE_INSENSITIVE')  
 ELSE EM.cnst_st_cd 
 END AS em_cnst_st_cd,
 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_zip_5_cd, 'CASE_INSENSITIVE')  
 ELSE EM.cnst_zip_5_cd 
 END AS em_cnst_zip_5_cd,
 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN NULL 
 ELSE EM.cnst_zip_4_cd 
 END AS em_cnst_zip_4_cd,
 EM.cnst_addr_county_nm AS em_cnst_addr_county_nm,--fine till here
 
	 CASE 
	 WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_email, 'CASE_INSENSITIVE') 
	 ELSE EM.cnst_email 
	 END AS em_cnst_email,
 
	CASE 
	WHEN faem.cnst_mstr_id IS NOT NULL THEN COALESCE(faem.em_email_key, 0) ELSE COALESCE(EM.cnst_email_key, 0)
	END AS em_cnst_email_key,

 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN collate(faem.em_cnst_email_assessmnt_ctg, 'CASE_INSENSITIVE') 
 ELSE EM.cnst_email_assessmnt_ctg 
 END AS em_cnst_email_assessmnt_ctg,--fine till here
 EM.cnst_org_nm AS em_cnst_org_nm,
 CASE 
 WHEN faem.cnst_mstr_id IS NOT NULL THEN 'IN' 
 ELSE EM.cnst_typ_dsc 
 END AS em_cnst_typ_dsc,
 0 AS email_dlvrbl_ind,--fine till here
 hphone.prim_cnst_phn AS prim_cnst_phn,
hphone.prim_cnst_phn_source AS prim_cnst_phn_source,
hphone.prim_cnst_phn_typ_dsc AS prim_cnst_phn_typ_dsc,
wphone.cnst_work_phone AS cnst_work_phn,
wphone.cnst_work_phone_source AS cnst_work_phn_source,
wphone.cnst_work_phone_type_cd AS cnst_work_phn_typ_dsc,
mphone.cnst_mbl_phn AS cnst_mbl_phn,
mphone.cnst_mbl_phn_source AS cnst_mbl_phn_source,
mphone.cnst_mbl_phn_typ_dsc AS cnst_mbl_phn_typ_dsc,
cnst_cntct_pref.vms_do_not_call_hm_phn_ind AS do_not_call_hm_phn_ind,
cnst_cntct_pref.vms_do_not_call_mbl_phn_ind AS do_not_call_mbl_phn_ind,
cnst_cntct_pref.vms_do_not_call_work_phn_ind AS do_not_call_work_phn_ind,
cnst_cntct_pref.vms_do_not_email_ind AS do_not_email_ind,
cnst_cntct_pref.vms_do_not_mail_ind AS do_not_mail_ind,
cnst_cntct_pref.vms_do_not_txt_ind AS do_not_txt_ind,
'NULL' AS cnst_3rd_prty_segmtn_group_nm,
 CASE 
 WHEN COALESCE(prim_chpt_vw.unit_key, 0) = 0 AND stuart_unit.unit_key IS NOT NULL THEN stuart_unit.unit_key
 WHEN prim_chpt_vw.unit_key IS NOT NULL AND prim_chpt_vw.unit_key <> 0 THEN prim_chpt_vw.unit_key
 WHEN grp_unit.unit_key IS NOT NULL THEN grp_unit.unit_key
 ELSE 0 
 END AS unit_key,
 0 AS affl_lock_ind,
 prim_chpt_vw.unit_cd AS unit_cd,
 prim_chpt_vw.vol_status AS vol_status,
 prim_chpt_vw.status_typ AS status_typ,
 prim_chpt_vw.last_member_num AS last_member_num,
 vol_init.initial_vol_dt AS initial_vol_dt,
 prim_chpt_vw.ethnicity AS ethnicity,
 prim_chpt_vw.is_hispanic AS is_hispanic



	from vms_cnst 		/* vms_cnst has inner join on the arc_mdm_vws.bz_cnst_mstr M so we will do left joins to vms_cnst cte*/
	left join  stuart_unit  on vms_cnst.cnst_mstr_id=stuart_unit.cnst_mstr_id 		--where stuart_unit.cnst_mstr_id =52517
	left outer join prim_chpt_vw on vms_cnst.cnst_mstr_id=prim_chpt_vw.cnst_mstr_id
	left outer join hphone on vms_cnst.cnst_mstr_id=hphone.cnst_mstr_id
	left outer join wphone on vms_cnst.cnst_mstr_id =  wphone.cnst_mstr_id
	left outer join mphone on vms_cnst.cnst_mstr_id =  mphone.cnst_mstr_id
	left join vol_init on vms_cnst.cnst_mstr_id = vol_init.cnst_mstr_id
	left join grp_unit on vms_cnst.cnst_mstr_id = grp_unit.cnst_mstr_id
	left join faem on vms_cnst.cnst_mstr_id = faem.cnst_mstr_id
	LEFT OUTER JOIN mods_bi.mktg_ops_tbls.cnst_cdi_vms_preferred_dmail DM ON vms_cnst.cnst_mstr_id = DM.cnst_mstr_id
	LEFT OUTER JOIN mods_bi.mktg_ops_tbls.cnst_cdi_vms_preferred_email EM ON vms_cnst.cnst_mstr_id = EM.cnst_mstr_id
	LEFT JOIN mktg_ops_tbls.bzf_cem_cnst_opt_outs_stg cnst_cntct_pref on vms_cnst.cnst_mstr_id = cnst_cntct_pref.cnst_mstr_id;

	
 /* 2/26/2019:Majeed:Update the Inactivation reason code */

	UPDATE mktg_ops_tbls.cnst_cdi_smry_vms_prfr_stg
	SET inactivation_reason_dsc = xx.inactivation_reason_dsc
	FROM (
		SELECT cnst_mstr_id, reason_for_change AS inactivation_reason_dsc
		FROM (
			SELECT distinct BRDG.cnst_mstr_id, a.reason_for_change,
				   ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY b.dw_trans_ts DESC, b.status_effect_dt DESC) AS rn
			FROM mktg_ops_tbls.dim_vol_inactvtn_rsn_cd a
			INNER JOIN eda.vms_vws.dim_volunteer b ON a.contact_id = b.nk_contact_id
			INNER JOIN eda.arc_mdm_vws.cnst_mstr_bridge BRDG ON b.vol_key = BRDG.cnst_mstr_subj_area_id
			AND BRDG.cnst_mstr_subj_area_cd = 'VMS'
		) subquery
		WHERE subquery.rn = 1
	) xx
	WHERE mktg_ops_tbls.cnst_cdi_smry_vms_prfr_stg.cnst_mstr_id = xx.cnst_mstr_id;

truncate table mktg_ops_tbls.cnst_cdi_smry_vms_prfr;
insert into mktg_ops_tbls.cnst_cdi_smry_vms_prfr select * from mktg_ops_tbls.cnst_cdi_smry_vms_prfr_stg;





	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.cnst_cdi_smry_vms_prfr_stg) as nvarchar)+ ' Records inserted.';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_cnst_cdi_smry_vms_prfr' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_cnst_cdi_smry_vms_prfr', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE etl_config.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;

$$
