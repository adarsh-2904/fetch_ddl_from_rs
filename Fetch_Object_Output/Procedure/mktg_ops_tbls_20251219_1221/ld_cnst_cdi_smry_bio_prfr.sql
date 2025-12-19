CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_smry_bio_prfr()
 LANGUAGE plpgsql
AS $$
/*
Created by: Majeed Mohammad
Created on: 09/18/2017
Purpose: This macro instantiates the Bio Pref profile view. It reads from the source view mktg_ops_vws.cnst_cdi_bio_smry_prfr_src and loads the table mktg_ops_tbls.cnst_cdi_bio_smry_prfr


Modified By: Michael Andrien
Modified Date: 10/23/2017
Purpose:  Added dpv_cd from the bzfc_cnst_addr to further qualify the address assessment category coding.  We were getting a high volume of returned mail
				and were told to exclude mailing addresses that have a 'Deliverable' assessment but the dpv_cd is not equal to 'Y'.  

Modified By: Michael Andrien
Modified Date: 03/11/2021
Purpose: Added the attributes below from the ubds_vws.bz_dim_cnst_unf view.
	last_ep_donor_key, last_dr_contact_key, last_race_cd, last_race_dsc

Modified By: Mike Andrien
Modified Date: 02/18/2022
Purpose: Added the Stuart Salutation UPDATE at the end of the script

Modified By: Mike Andrien
Modified Date: 11/09/2022
Purpose: Modified the Stuart Salutation update section to set the include the em and dm person name source code attributes to STRX.
		em_prsn_nm_src_cd = 'STRX',
		dm_prsn_nm_src_cd = 'STRX',

Modified By: Mike Andrien
Modified Date: 10/04/2024
Purpose: Restructuree the macro to pull in the SQL from mktg_ops_vws.cnst_cdi_smry_bio_prfr_src and restructured
the SQL to apply CEM opt out logic and email validation logic as UPDATE statements.

--This Teradata change below was intentionally left out in Redshift as it works fine in RS.
Modified By: Mike Andrien
Modified Date: 10/09/2025
Purpose: The macro/bteq began failing with the Teradata error INSERT Failed. 9794: (-9794)File system has reported ERRAMPOUTOFPHYSPACE error. So, I removed the email
append (FAEM) join and added a new UPDATE section to apply the email append overrides.  This resolved the issue.
*/	
	

DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_ok_message varchar(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;



--	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
--    VALUES ('ld_cnst_cdi_smry_bio_prfr', 'Stored Procedure', 'Inprogress', v_start_time);


		-- Procedure Start

		--select count(*) from mods_bi.mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr ;
TRUNCATE TABLE mods_bi.mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr;
INSERT INTO mods_bi.mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr (
	    cnst_mstr_id, cnst_hsld_id, cnst_arc_deceased_cd, dm_cnst_data_src_cd,
	    last_ep_donor_key, last_dr_contact_key, last_race_cd, last_race_dsc,
	    dm_cnst_prsn_prfx_nm, dm_cnst_prsn_f_nm, dm_cnst_prsn_m_nm, dm_cnst_prsn_l_nm,
	    dm_cnst_prsn_sfx_nm, dm_cnst_prsn_full_nm, dm_cnst_alias_in_saltn_nm,
	    dm_cnst_alias_out_saltn_nm, dm_locator_addr_key, dm_cnst_addr_assessmnt_ctg, dpv_cd,
	    dm_cnst_line_1_addr, dm_cnst_line_2_addr, dm_cnst_city_nm, dm_cnst_st_cd,
	    dm_cnst_zip_5_cd, dm_cnst_zip_4_cd, dm_cnst_addr_county_nm, dm_cnst_email,
	    dm_cnst_org_nm, dm_cnst_typ_dsc, em_cnst_data_src_cd, em_cnst_prsn_prfx_nm,
	    em_cnst_prsn_f_nm, em_cnst_prsn_m_nm, em_cnst_prsn_l_nm, em_cnst_prsn_sfx_nm,
	    em_cnst_prsn_full_nm, em_cnst_alias_in_saltn_nm, em_cnst_alias_out_saltn_nm,
	    em_locator_addr_key, em_cnst_line_1_addr, em_cnst_line_2_addr,
	    em_cnst_city_nm, em_cnst_st_cd, em_cnst_zip_5_cd, em_cnst_zip_4_cd,
	    em_cnst_addr_county_nm, em_cnst_email, em_email_key, em_cnst_email_assessmnt_ctg,
	    em_cnst_org_nm, em_cnst_typ_dsc, email_dlvrbl_ind, prim_cnst_phn,
	    prim_cnst_phn_source, prim_cnst_phn_typ_dsc,cnst_work_phone , cnst_work_phone_source,
	    cnst_work_phone_type_cd, cnst_mbl_phn, cnst_mbl_phn_source, cnst_mbl_phn_typ_dsc,
	    do_not_call_hm_phn_ind, do_not_call_mbl_phn_ind, do_not_call_work_phn_ind,
	    do_not_email_ind, do_not_mail_ind, do_not_txt_ind, cnst_3rd_prty_segmtn_group_nm,
	    unit_key, affl_lock_ind, nxt_leukoph_rec_dt, nxt_pls_rec_dt,
	    nxt_plt_rec_dt, nxt_wb_rec_dt
	) 




SELECT
    M.cnst_mstr_id AS cnst_mstr_id,
    M.cnst_hsld_id AS cnst_hsld_id,
    M.cnst_arc_deceased_cd AS cnst_arc_deceased_cd,
    DM.cnst_data_src_cd AS dm_cnst_data_src_cd
   ,DNR.ep_donor_key AS last_ep_donor_key,
    DNR.dr_contact_key AS last_dr_contact_key,
    DNR.bz_race_cd AS last_race_cd,
    DNR.ep_race_dsc AS last_race_dsc,
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
    END AS em_cnst_data_src_cd,
    EM.cnst_prsn_prfx_nm AS em_cnst_prsn_prfx_nm,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_prsn_f_nm 
        ELSE EM.cnst_prsn_f_nm 
    END AS em_cnst_prsn_f_nm,
    EM.cnst_prsn_m_nm AS em_cnst_prsn_m_nm,
    CAST(
        CASE 
            WHEN (EM.cnst_typ_dsc = 'Organization' AND EM.cnst_prsn_l_nm IS NULL) THEN EM.cnst_org_nm 
            WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_prsn_l_nm 
            ELSE EM.cnst_prsn_l_nm 
        END AS VARCHAR(50)
    ) AS em_cnst_prsn_l_nm,
    EM.cnst_prsn_sfx_nm AS em_cnst_prsn_sfx_nm,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_prsn_f_nm || ' ' || faem.cnst_prsn_l_nm 
        ELSE EM.cnst_prsn_full_nm 
    END AS em_cnst_prsn_full_nm,
    EM.cnst_alias_in_saltn_nm AS em_cnst_alias_in_saltn_nm,
    EM.cnst_alias_out_saltn_nm AS em_cnst_alias_out_saltn_nm,
    EM.locator_addr_key AS em_locator_addr_key,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_line_1_addr 
        ELSE EM.cnst_line_1_addr 
    END AS em_cnst_line_1_addr,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_line_2_addr 
        ELSE EM.cnst_line_2_addr 
    END AS em_cnst_line_2_addr,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_city_nm 
        ELSE EM.cnst_city_nm 
    END AS em_cnst_city_nm,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_st_cd 
        ELSE EM.cnst_st_cd 
    END AS em_cnst_st_cd,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_zip_5_cd 
        ELSE EM.cnst_zip_5_cd 
    END AS em_cnst_zip_5_cd,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN NULL 
        ELSE EM.cnst_zip_4_cd 
    END AS em_cnst_zip_4_cd,
    EM.cnst_addr_county_nm AS em_cnst_addr_county_nm,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.cnst_email 
        ELSE EM.cnst_email 
    END AS em_cnst_email,
	COALESCE(faem.em_email_key, EM.cnst_email_key, 0) AS em_email_key,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN faem.em_cnst_email_assessmnt_ctg 
        ELSE EM.cnst_email_assessmnt_ctg 
    END AS em_cnst_email_assessmnt_ctg,
    EM.cnst_org_nm AS em_cnst_org_nm,
    CASE 
        WHEN faem.cnst_mstr_id IS NOT NULL THEN 'IN' 
        ELSE EM.cnst_typ_dsc 
    END AS em_cnst_typ_dsc,
	COALESCE(
	    CASE 
	        WHEN EM.cnst_email_assessmnt_ctg IN ('Validated', 'Use With Caution') THEN 1 
	        ELSE 0 
	    END, 0
	) AS email_dlvrbl_ind,
    hphone.prim_cnst_phn AS prim_cnst_phn,
    hphone.prim_cnst_phn_source AS prim_cnst_phn_source,
    hphone.prim_cnst_phn_typ_dsc AS prim_cnst_phn_typ_dsc,
    wphone.cnst_work_phone AS cnst_work_phone,
    wphone.cnst_work_phone_source AS cnst_work_phone_source,
    wphone.cnst_work_phone_type_cd AS cnst_work_phone_type_cd,
    mphone.cnst_mbl_phn AS cnst_mbl_phn,
    mphone.cnst_mbl_phn_source AS cnst_mbl_phn_source,
    mphone.cnst_mbl_phn_typ_dsc AS cnst_mbl_phn_typ_dsc,
    COALESCE(drms_opt_out.drms_home_opt_out_ind, 0) AS do_not_call_hm_phn_ind,
	COALESCE(drms_opt_out.drms_mobile_opt_out_ind, 0) AS do_not_call_mbl_phn_ind,
	COALESCE(drms_opt_out.drms_work_opt_out_ind, 0) AS do_not_call_work_phn_ind,
	COALESCE(drms_opt_out.drms_em_opt_out_ind, 0) AS do_not_email_ind,
	COALESCE(drms_opt_out.drms_dm_opt_out_ind, 0) AS do_not_mail_ind,
	COALESCE(drms_opt_out.drms_txt_opt_out_ind, 0) AS do_not_txt_ind,
    CAST(NULL AS VARCHAR) AS cnst_3rd_prty_segmtn_group_nm,
    prim_chpt.bzd_prim_affl_unit_key AS unit_key,
    prim_chpt.bzd_acct_affl_lock_ind AS affl_lock_ind,
    CAST(nxt_leukoph_rec_dt AS DATE) AS nxt_leukoph_rec_dt
               ,CAST(nxt_pls_rec_dt AS DATE )  AS nxt_pls_rec_dt
               ,CAST(nxt_plt_rec_dt AS DATE )  AS nxt_plt_rec_dt
               ,CAST(nxt_wb_rec_dt AS DATE )  AS nxt_wb_rec_dt
FROM 
eda.arc_mdm_vws.bz_cnst_mstr as M
	inner join (
		SELECT DISTINCT cnst_mstr_id 
		FROM eda.arc_mdm_vws.bz_cnst_mstr_bridge
		--arc_mdm_vws.bz_cnst_mstr_external_brid  (6/11/2015 replace with bz_cnst_mstr_bridge - Mike Andrien)
		WHERE 
			cnst_mstr_subj_area_cd IN ('BADW', 'DRMS') 
			OR cnst_mstr_subj_area_cd IN (
				SELECT arc_srcsys_cd 
				FROM eda.arc_mdm_vws.bz_arc_srcsys 
				WHERE line_of_service_cd = 'BIO'
			) --limit 5
		)BIO_CNST ON BIO_CNST.cnst_mstr_id = M.cnst_mstr_id
	LEFT OUTER JOIN mods_bi.mktg_ops_tbls.cnst_cdi_bio_preferred_dmail as DM ON M.cnst_mstr_id = DM.cnst_mstr_id
	LEFT OUTER JOIN mktg_ops_tbls.cnst_cdi_bio_preferred_email as EM ON M.cnst_mstr_id = EM.cnst_mstr_id
	LEFT OUTER JOIN eda.arc_mdm_vws.bzfc_fr_cnst_affl_prfl prim_chpt ON M.cnst_mstr_id = prim_chpt.cnst_mstr_id
	LEFT OUTER JOIN 
	( 
SELECT *
FROM (
    SELECT
        bz_cnst_phn.CNST_MSTR_ID,
        bz_cnst_phn.cnst_phn_num AS prim_cnst_phn,
        bz_cnst_phn.arc_srcsys_cd AS prim_cnst_phn_source,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd = 'H' THEN 'Home' 
            ELSE 'Other' 
        END AS prim_cnst_phn_typ_dsc,
        COALESCE(bz_arc_srcsys.arc_srcsys_cd, NULL) AS FR_cnst_mstr_subj_area_cd,
        ROW_NUMBER() OVER (
            PARTITION BY bz_cnst_phn.CNST_MSTR_ID 
            ORDER BY 
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'DRMS' THEN 1
                    WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'BADW' THEN 2
                    WHEN bz_cnst_phn.arc_srcsys_cd = 'CDIM' AND bz_cnst_phn.phn_typ_cd = 'LN' THEN 3
                    ELSE 999
                END ASC,
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'DRMS' THEN 1
            WHEN bz_cnst_phn.phn_typ_cd = 'H' AND bz_cnst_phn.arc_srcsys_cd = 'BADW' THEN 2
            WHEN bz_cnst_phn.arc_srcsys_cd = 'CDIM' AND bz_cnst_phn.phn_typ_cd = 'LN' THEN 3
            ELSE 999
        END AS hnum
    FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys 
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd 
        AND bz_arc_srcsys.line_of_service_cd IN ('BIO', 'CDIM')
    WHERE bz_cnst_phn.phn_typ_cd IN ('H', 'LN') 
        AND assessmnt_ctg = 'Usable' 
        AND cnst_phn_end_dt = '12/31/9999'
) AS subquery
WHERE rownum = 1
    AND hnum < 999
)hphone ON M.cnst_mstr_id =  hphone.cnst_mstr_id
	LEFT OUTER JOIN (
		SELECT *
FROM (
    SELECT
        bz_cnst_phn.CNST_MSTR_ID,
        bz_cnst_phn.cnst_phn_num AS cnst_work_phone,
        bz_cnst_phn.arc_srcsys_cd AS cnst_work_phone_source,
        CAST('Work' AS VARCHAR(20)) AS cnst_work_phone_type_cd,
        COALESCE(bz_arc_srcsys.arc_srcsys_cd, NULL) AS FR_cnst_mstr_subj_area_cd,
        ROW_NUMBER() OVER (
            PARTITION BY bz_cnst_phn.CNST_MSTR_ID 
            ORDER BY 
				CASE 
				    WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.cnst_phn_num <> '' THEN
				        CASE 
				            WHEN bz_cnst_phn.arc_srcsys_cd = 'DRMS' THEN 1
				            WHEN bz_cnst_phn.arc_srcsys_cd = 'BADW' THEN 2
				            WHEN bz_arc_srcsys.arc_srcsys_cd <> '' THEN 3
				            ELSE 999
				        END
				    ELSE 999
				END ASC,
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'DRMS' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 1
            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_cnst_phn.arc_srcsys_cd = 'BADW' AND bz_cnst_phn.cnst_phn_num IS NOT NULL THEN 2
            WHEN bz_cnst_phn.phn_typ_cd = 'W' AND bz_arc_srcsys.arc_srcsys_cd <> '' AND bz_cnst_phn.cnst_phn_num <> '' THEN 3
            ELSE 999
        END AS wnum
    FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys 
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd 
        AND bz_arc_srcsys.line_of_service_cd IN ('BIO', 'CDIM')
    WHERE bz_cnst_phn.phn_typ_cd = 'W' 
        AND assessmnt_ctg = 'Usable' 
        AND cnst_phn_end_dt = '12/31/9999'
) AS subquery
WHERE rownum = 1
    AND wnum < 999
)wphone ON M.cnst_mstr_id =  wphone.cnst_mstr_id

	LEFT OUTER JOIN (
		SELECT *
FROM (
    SELECT
        bz_cnst_phn.CNST_MSTR_ID,
        bz_cnst_phn.cnst_phn_num AS cnst_mbl_phn,
        bz_cnst_phn.arc_srcsys_cd AS cnst_mbl_phn_source,
        CAST('Mobile' AS VARCHAR(20)) AS cnst_mbl_phn_typ_dsc,
        COALESCE(bz_arc_srcsys.arc_srcsys_cd, NULL) AS FR_cnst_mstr_subj_area_cd,
        ROW_NUMBER() OVER (
            PARTITION BY bz_cnst_phn.CNST_MSTR_ID 
            ORDER BY 
                CASE 
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'DRMS' AND bz_cnst_phn.cnst_phn_num <> '' THEN 1
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'BADW' AND bz_cnst_phn.cnst_phn_num <> '' THEN 2
                    WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_arc_srcsys.arc_srcsys_cd <> ''AND bz_cnst_phn.cnst_phn_num <> ''THEN 3
                    ELSE 999
                END ASC,
                bz_cnst_phn.dw_srcsys_trans_ts DESC
        ) AS rownum,
        CASE 
            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'DRMS' AND bz_cnst_phn.cnst_phn_num <> '' THEN 1
            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_cnst_phn.arc_srcsys_cd = 'BADW' AND bz_cnst_phn.cnst_phn_num <> '' THEN 2
            WHEN bz_cnst_phn.phn_typ_cd = 'M' AND bz_arc_srcsys.arc_srcsys_cd <> '' AND bz_cnst_phn.cnst_phn_num <> '' THEN 3
            ELSE 999
        END AS mnum
    FROM eda.arc_mdm_vws.bzfc_cnst_phn AS bz_cnst_phn
    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys AS bz_arc_srcsys 
        ON bz_cnst_phn.arc_srcsys_cd = bz_arc_srcsys.arc_srcsys_cd 
        AND bz_arc_srcsys.line_of_service_cd IN ('BIO', 'CDIM')
    WHERE bz_cnst_phn.phn_typ_cd = 'M' 
        AND assessmnt_ctg = 'Usable' 
        AND cnst_phn_end_dt = '12/31/9999'
) AS subquery
WHERE rownum = 1
    AND mnum < 999
)mphone ON M.cnst_mstr_id =  mphone.cnst_mstr_id
	LEFT JOIN 
	(
	select
			eb.cnst_mstr_id,
			Max(CASE WHEN  ( dn_contact_ind= 1 OR dnc_home_ind = 1 OR dn_recruit_ind = 1 ) THEN 1 ELSE 0 end) AS drms_home_opt_out_ind,--drms_home_opt_out_ind,
			Max(CASE WHEN  (dn_contact_ind = 1 OR dnc_mobile_ind = 1 OR dn_recruit_ind = 1 ) THEN 1 ELSE 0 end) AS drms_mobile_opt_out_ind,
			Max(CASE WHEN  (dn_contact_ind = 1 OR dnc_work_ind = 1 OR dn_recruit_ind = 1 ) THEN 1 ELSE 0 end) AS drms_work_opt_out_ind,	
			Max(CASE WHEN  (dn_contact_ind = 1 OR dn_email_ind = 1 OR dn_recruit_ind = 1 ) THEN 1 ELSE 0 end) AS drms_em_opt_out_ind,
			Max(CASE WHEN  (dn_contact_ind = 1 OR dn_mail_ind = 1 OR dn_recruit_ind = 1) THEN 1 ELSE 0 end) AS drms_dm_opt_out_ind,
			Max(CASE WHEN  (bdcf.dn_contact_ind = 1 OR bdcf.opt_in_txt_ind = 0 OR bdcf.dn_recruit_ind = 1) THEN 1 ELSE 0 end) AS drms_txt_opt_out_ind	--NOTE: Text requires an opt in from the donor so we set the opt out ind = 1 if the OPT_IN_TXT_IND = 0
			
from

eda.bio_appointment_vws.bzf_dim_cntct_pref bdcf
left join eda.arc_mdm_vws.bz_cnst_mstr_external_brid eb on eb.cnst_srcsys_scndry_id = bdcf.nk_contact_id and eb.arc_srcsys_cd = 'DRMS'
WHERE  (DN_CONTACT_IND = 1 OR DN_EMAIL_IND = 1 OR DN_RECRUIT_IND = 1 OR DN_MAIL_IND = 1 OR DNC_HOME_IND = 1 OR DNC_MOBILE_IND = 1 OR DNC_WORK_IND = 1)

GROUP by eb.cnst_mstr_id)drms_opt_out ON M.cnst_mstr_id =  drms_opt_out.cnst_mstr_id

	LEFT JOIN 
	(SELECT  
		eb.cnst_mstr_id as cnst_mstr_id,
		max(bddm.nxt_leukoph_rec_dt) as nxt_leukoph_rec_dt, 
        max(bddm.nxt_pls_rec_dt) AS nxt_pls_rec_dt, 
        max(bddm.nxt_plt_rec_dt) AS nxt_plt_rec_dt,  
        max(bddm.nxt_wb_rec_dt) AS nxt_wb_rec_dt
from eda.drms_vws.bz_dim_donor_mktg bddm
left join eda.arc_mdm_vws.bz_cnst_mstr_external_brid eb on eb.cnst_srcsys_scndry_id = bddm.nk_contact_id and arc_srcsys_cd = 'DRMS'
GROUP BY cnst_mstr_id )drms_elig ON M.cnst_mstr_id = drms_elig.cnst_mstr_id

	LEFT JOIN ( with subquery as (

select
	
	d.cnst_mstr_id
	,a.donor_id as ep_donor_key
	,d.contact_key	as dr_contact_key
	,d.race_cd as bz_race_cd
	,c.race_description as ep_race_dsc
	,a.ethnicity_id
	,b.ethicity_cd
	,b.ethnicity
	,a.most_recent_any_visit_dt
	,Row_Number() Over 
	(PARTITION BY cnst_mstr_id 
	ORDER BY 
		a.most_recent_any_visit_dt DESC 
--		,dw_updt_ts DESC 
	)as rn
from eda.bio_donation_vws.bz_dim_donor a
left join eda.bio_donation_vws.bz_dim_ethnicity b on a.ethnicity_id = b.ethnicity_id
left join eda.bio_donation_vws.bz_dim_race c on a.race_id = c.race_id
left join eda.bio_appointment_vws.bzl_dim_contact d on a.donor_external_id = d.nk_key_donor
WHERE cnst_mstr_id IS NOT NULL--partition by caluse is yet to be implemented.
--limit 5
)

select 

	cnst_mstr_id
	,ep_donor_key
	,dr_contact_key	
	,bz_race_cd
	,ep_race_dsc
	,ethnicity_id
	,ethicity_cd
	,ethnicity
	,most_recent_any_visit_dt
	,rn
from 
subquery 
where rn=1)DNR ON M.cnst_mstr_id = DNR.cnst_mstr_id
	LEFT JOIN 
	(
	with PartA as
	(
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
		CASE  WHEN c.assessmnt_ctg IS NULL THEN 'Validated' ELSE c.assessmnt_ctg end AS em_cnst_email_assessmnt_ctg,
		'Y' AS ok_to_email_flg,
		list_upload_ts
		FROM mktg_ops_tbls.pacific_east_email_append as a
		LEFT JOIN eda.arc_mdm_vws.bz_locator_email as b ON b.cnst_email_addr = a.cnst_email
		LEFT JOIN eda.arc_mdm_vws.bz_assessmnt as c ON b.assessmnt_key = c.assessmnt_key
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
		CASE  WHEN c.assessmnt_ctg IS NULL THEN 'Validated' ELSE c.assessmnt_ctg end AS em_cnst_email_assessmnt_ctg,
		'Y' AS ok_to_email_flg,
		list_upload_ts
		FROM mktg_ops_tbls.fresh_address_email_append as a
		LEFT JOIN eda.arc_mdm_vws.bz_locator_email as b ON b.cnst_email_addr = a.cnst_email
		LEFT JOIN eda.arc_mdm_vws.bz_assessmnt as c ON b.assessmnt_key = c.assessmnt_key
		WHERE a.row_stat_cd <> 'L'
		
	),
	/*
		This next query is retrieving the bio preferred email from the email ranking table to assess whether the preferred email from the ranking process is ok to email.  we'll compared the assessment
		results between the append email details from the join above to the ranked email details to decide whether the to override the email selected from the CDI ranking process with the append email.
		*/
	PartB as  
	(
		SELECT 
			a.cnst_mstr_id,
			a.cnst_email_key,
			a.cnst_email, 
			a.cnst_email_assessmnt_ctg, 
			a.cnst_data_src_cd,
			b.cnst_email_strt_ts,
			CASE WHEN c.email_addr IS NOT NULL THEN c.ok_to_email_flg ELSE NULL end AS ok_to_email_flg
		FROM mktg_ops_tbls.cnst_cdi_bio_preferred_email as a
		LEFT JOIN eda.arc_mdm_vws.bzfc_cnst_email as b ON a.cnst_mstr_id = b.cnst_mstr_id AND a.cnst_email_key = b.email_key AND a.cnst_data_src_cd = b.arc_srcsys_cd	
		LEFT JOIN mktg_ops_vws.gms_bzfc_cnst_cdi_fr_prfr_em_prfl as c ON a.cnst_mstr_id = c.cnst_mstr_id
		
	)
	
		SELECT 
				PartA.cnst_mstr_id as cnst_mstr_id, 
				PartA.cnst_prsn_f_nm, 
				PartA.cnst_prsn_l_nm, 
				PartA.cnst_line_1_addr, 
				PartA.cnst_line_2_addr, 
				PartA.cnst_city_nm, 
				PartA.cnst_st_cd, 
				PartA.cnst_zip_5_cd, 
				PartA.cnst_email, 
				PartA.list_source_nm, 
				PartA.em_cnst_data_src_cd, 
				PartA.em_email_key, 
				PartA.em_cnst_email_assessmnt_ctg, 
				PartA.ok_to_email_flg, 
				PartA.list_upload_ts
			FROM PartA
		LEFT JOIN PartB	ON PartA.cnst_mstr_id = PartB.cnst_mstr_id
			WHERE (PartA.ok_to_email_flg IS NULL OR PartA.ok_to_email_flg = 'Y') AND ( (PartA.cnst_email <> PartB.cnst_email AND PartA.list_upload_ts >= PartB.cnst_email_strt_ts) OR (PartB.cnst_mstr_id IS NULL) )		
		QUALIFY Row_Number() Over (PARTITION BY PartA.cnst_mstr_id  ORDER BY PartA.list_upload_ts DESC) = 1
		
		)faem ON M.cnst_mstr_id = faem.cnst_mstr_id;
		
		
					

		
				v_end_time := CURRENT_TIMESTAMP;
		        UPDATE etl_config.audit_log
		        SET status = 'InProgress', end_time = v_end_time,TaskMessage = 'Initial Stage Insert Completed'
		        WHERE proc_name = 'ld_cnst_cdi_bio_preferred_email' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
	
commit;	


	/* Apply Stuart Salutation Updates */
WITH filtered_data AS (
    SELECT cnst_mstr_id, bz_cnst_alias_out_saltn_nm, bz_cnst_alias_in_saltn_nm,cnst_prsn_nm_typ_cd
    FROM eda.arc_mdm_vws.bz_cnst_prsn_nm
    WHERE arc_srcsys_cd = 'STRX'
    AND TRIM(bz_cnst_alias_out_saltn_nm) <> TRIM(cnst_prsn_full_nm)
),
ranked_data AS (
    SELECT cnst_mstr_id, bz_cnst_alias_out_saltn_nm, bz_cnst_alias_in_saltn_nm,
           ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY 
               CASE 
                   WHEN cnst_prsn_nm_typ_cd = 'ARC' THEN 1
                   WHEN cnst_prsn_nm_typ_cd = 'PN' THEN 2
                   WHEN cnst_prsn_nm_typ_cd = 'LN' THEN 3
                   ELSE 4
               END) AS rn
    FROM filtered_data
)
UPDATE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr
SET 
    em_prsn_nm_src_cd = 'STRX',
    em_cnst_alias_in_saltn_nm = ranked_data.bz_cnst_alias_in_saltn_nm,
    em_cnst_alias_out_saltn_nm = ranked_data.bz_cnst_alias_out_saltn_nm,
    dm_prsn_nm_src_cd = 'STRX',
    dm_cnst_alias_in_saltn_nm = ranked_data.bz_cnst_alias_in_saltn_nm,
    dm_cnst_alias_out_saltn_nm = ranked_data.bz_cnst_alias_out_saltn_nm
FROM ranked_data
WHERE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.cnst_mstr_id = ranked_data.cnst_mstr_id
AND ranked_data.rn = 1;



/* Apply CEM/CMM Opt-out updates  */
WITH filtered_data AS (  /*works in redshift-Hitansu.*/
    SELECT 
        cnst_mstr_id,
        bio_do_not_mail_ind, 
        bio_do_not_email_ind, 
        bio_do_not_call_hm_phn_ind, 
        bio_do_not_call_mbl_phn_ind, 
        bio_do_not_call_work_phn_ind, 
        bio_do_not_txt_ind
    FROM mktg_ops_vws.bzf_cem_cnst_opt_outs cnst_cntct_pref
    WHERE bio_do_not_mail_ind = 1 OR bio_do_not_email_ind = 1 OR bio_do_not_call_hm_phn_ind = 1 OR bio_do_not_call_mbl_phn_ind = 1 OR bio_do_not_call_work_phn_ind = 1 OR bio_do_not_txt_ind = 1
)
UPDATE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr
SET
    do_not_call_hm_phn_ind = CASE WHEN filtered_data.bio_do_not_call_hm_phn_ind = 1 THEN filtered_data.bio_do_not_call_hm_phn_ind ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_call_hm_phn_ind END,
    do_not_call_mbl_phn_ind = CASE WHEN filtered_data.bio_do_not_call_mbl_phn_ind = 1 THEN filtered_data.bio_do_not_call_mbl_phn_ind ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_call_mbl_phn_ind END,
    do_not_call_work_phn_ind = CASE WHEN filtered_data.bio_do_not_call_work_phn_ind = 1 THEN filtered_data.bio_do_not_call_work_phn_ind ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_call_work_phn_ind END,
    do_not_email_ind = CASE WHEN filtered_data.bio_do_not_email_ind = 1 THEN filtered_data.bio_do_not_email_ind ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_email_ind END,
    do_not_mail_ind = CASE WHEN filtered_data.bio_do_not_mail_ind = 1 THEN filtered_data.bio_do_not_mail_ind ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_mail_ind END,
    do_not_txt_ind = CASE WHEN filtered_data.bio_do_not_txt_ind = 1 THEN filtered_data.bio_do_not_txt_ind ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_txt_ind END
FROM filtered_data
WHERE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.cnst_mstr_id = filtered_data.cnst_mstr_id;




/* Apply invalid email updates*/

WITH invld_email AS (
    SELECT 
        b.cnst_mstr_id,
        a.contact_key,
        a.cntct_email_addr,
        a.cntct_email_inv_flg,
        1 AS invld_email_ind,
        ROW_NUMBER() OVER (PARTITION BY a.cntct_email_addr ORDER BY a.modified_ts DESC) AS rn
    FROM eda.bio_appointment_vws.bz_dim_cntct_email a  --ubds_vws.drbz_dim_cntct_email alternative
    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge b ON a.contact_key = b.cnst_mstr_subj_area_id AND b.cnst_mstr_subj_area_cd = 'DRMS'
    LEFT JOIN mktg_ops_tbls.cnst_cdi_bio_preferred_email c ON b.cnst_mstr_id = c.cnst_mstr_id
    WHERE a.cntct_email_inv_flg = 'Y' AND a.cntct_email_addr IS NOT NULL AND a.cntct_email_addr = c.cnst_email
)
UPDATE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr
SET 
    do_not_email_ind = CASE WHEN invld_email.invld_email_ind = 1 THEN 1 ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_email_ind END
FROM invld_email
WHERE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.cnst_mstr_id = invld_email.cnst_mstr_id
AND invld_email.rn = 1;
--RAISE NOTICE 'Apply invalid email updates is completed';


/* Now apply Adobe Spam Reject email address updates*/
WITH adb_spam_rejct AS (
    SELECT 
        TRIM(b.saddress) AS email_addr, 
        MIN(a.tsLastModified) AS first_spam_rejct_dt, 
        MAX(a.tsLastModified) AS last_spam_rejct_dt, 
        COUNT(*) AS spam_rejct_cnt
    FROM mktg_ops_tbls.adb_nmsbroadlogmsg a
    LEFT JOIN mktg_ops_tbls.adb_nmsbroadlogrcp b ON a.iBroadLogMsgId = b.ibroadlogid
    LEFT JOIN mktg_ops_tbls.adb_nmsrecipient c ON b.irecipientid = c.irecipientid
    WHERE a.iFailureType = 3 AND COALESCE(b.saddress, '') IS NOT NULL
    GROUP BY 1
)
UPDATE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr
SET do_not_email_ind = CASE 
    WHEN adb_spam_rejct.spam_rejct_cnt > 0 THEN 1 
    ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_email_ind 
END
FROM adb_spam_rejct
WHERE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.em_cnst_email = adb_spam_rejct.email_addr;
--RAISE NOTICE 'Adobe Spam Reject email address updates is completed';



/* Now apply the Validity Email Validation updates */
WITH validity_status AS (
    SELECT 
        email_addr,
        valdtn_status,
        valdtn_dt,
        ROW_NUMBER() OVER (PARTITION BY email_addr ORDER BY valdtn_dt DESC) AS rn
    FROM mktg_ops_tbls.vaidity_email_valdtn
)
UPDATE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr
SET do_not_email_ind = CASE 
    WHEN COALESCE(validity_status.valdtn_status, 'Valid: Valid') <> 'Valid: Valid' THEN 1 
    ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_email_ind 
END
FROM validity_status
WHERE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.em_cnst_email = validity_status.email_addr
AND validity_status.rn = 1;
--RAISE NOTICE 'Validity Email Validation updates is completed';


/* Now apply the Bad/Suspect Domain Check updates */

WITH baddmn AS (
    SELECT 
        DISTINCT
        cnst_email_addr AS email_addr,
        1 AS bad_domain_ind
    FROM eda.arc_mdm_vws.bzfc_cnst_email
    WHERE 
        assessmnt_ctg IN ('Validated', 'Use With Caution')
        AND cnst_email_addr IS NOT NULL 
        AND SUBSTRING(cnst_email_addr, POSITION('@' IN cnst_email_addr) + 1) IN (
            SELECT bad_domain
            FROM mktg_ops_tbls.suspect_domains
        )
)
UPDATE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr
SET do_not_email_ind = CASE 
    WHEN baddmn.bad_domain_ind = 1 THEN 1 
    ELSE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.do_not_email_ind 
END
FROM baddmn
WHERE mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr.em_cnst_email = baddmn.email_addr;



TRUNCATE TABLE mktg_ops_tbls.cnst_cdi_smry_bio_prfr;

INSERT INTO mktg_ops_tbls.cnst_cdi_smry_bio_prfr
SELECT *
FROM mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr;

--Update the same record in audit to Completed
			v_end_time := CURRENT_TIMESTAMP;
			v_ok_message = cast((select count(*) from mktg_stage_tbls.stg_cnst_cdi_smry_bio_prfr ) as nvarchar)+ ' Records inserted/updated.';

			

			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
		    VALUES ('ld_cnst_cdi_smry_bio_prfr', 'Stored Procedure', 'Complete', v_start_time,v_end_time,v_ok_message);
commit;	
		
		
--Update the same record in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
								
								
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
		    VALUES ('ld_cnst_cdi_smry_bio_prfr', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

END;

$$
