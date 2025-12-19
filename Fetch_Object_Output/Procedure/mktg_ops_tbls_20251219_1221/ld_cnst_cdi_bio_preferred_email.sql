CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_bio_preferred_email()
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

Modified By Stephen Knilans
Modified Date: August 20 2014
Purpose: Support BIO

Modified By: Majeed Mohammad
Modified Date: Jun -10-2015
Purpose:  The column assessmnt_ctg has been removed in the view arc_mdm_vws.bz_cnst_email by EDW for query optimizations. The macro now uses the new view arc_mdm_vws.bzfc_cnst_email that contains the assessmnt_ctg column 



Modified By:  Majeed Mohammad
Modified Date: 08/08/2016
Purpose: Add the DM address locator , assessment and county information. 

Modified By: Majeed Mohammad
Modified Date: 09/28/2016
Purpose: Updated the macro to use the corrected email column locator_email_addr

Modified By: Michael Andrien
Modified Date: 8/28/2017
Purpose:  Corrected the email ranking rules.  The rules had been referencing non-biomed sources and were not correct.
*/	
	
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_bio_preferred_email', 'Stored Procedure', 'Inprogress', v_start_time);

truncate table mktg_ops_tbls.cnst_cdi_bio_preferred_email;

INSERT INTO mktg_ops_tbls.cnst_cdi_bio_preferred_email
(cnst_mstr_id, 
cnst_hsld_id, 
cnst_dsp_deceased_cd, 
cnst_data_src_cd, 
cnst_prsn_prfx_nm, 
cnst_prsn_f_nm, 
cnst_prsn_m_nm, 
cnst_prsn_l_nm, 
cnst_prsn_sfx_nm, 
cnst_prsn_full_nm, cnst_alias_in_saltn_nm, 
cnst_alias_out_saltn_nm, locator_addr_key, 
cnst_addr_assessmnt_ctg, cnst_line_1_addr, cnst_line_2_addr, 
cnst_city_nm, cnst_st_cd, cnst_zip_5_cd, 
cnst_zip_4_cd, cnst_addr_county_nm, cnst_email, 
cnst_email_key, cnst_email_assessmnt_ctg, cnst_org_nm, cnst_typ_dsc)

SELECT
    FR_main.cnst_mstr_id,
    FR_main.cnst_hsld_id,
    FR_main.cnst_dsp_deceased_cd,
    E.arc_srcsys_cd,
    P.bz_cnst_prsn_prefix_nm,
    P.bz_cnst_prsn_first_nm,
    P.bz_cnst_prsn_middle_nm,
    P.bz_cnst_prsn_last_nm,
    P.bz_cnst_prsn_suffix_nm,
    P.cnst_prsn_full_nm AS cnst_prsn_full_nm,
    P.bz_cnst_alias_in_saltn_nm AS cnst_alias_in_saltn_nm,
    P.bz_cnst_alias_out_saltn_nm AS cnst_alias_out_saltn_nm,
    A.locator_addr_key AS locator_addr_key,
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
    E.assessmnt_ctg,
    ORG.cnst_org_nm,
    CASE 
        WHEN FR_main.cnst_typ_cd = 'IN' THEN 'Individual'
        WHEN FR_main.cnst_typ_cd = 'OR' THEN 'Organization'
        WHEN FR_main.cnst_typ_cd = 'AG' THEN 'Account Group'
    END AS cnst_typ_desc
FROM (
    SELECT 
        cnst_mstr_id,
        arc_srcsys_cd,
        locator_email_addr,
        dw_srcsys_trans_ts,
        MAX(dw_srcsys_trans_ts) OVER (PARTITION BY cnst_mstr_id) AS max_dw_srcsys_trans_ts,
        email_key,
        assessmnt_ctg
    FROM
        eda.arc_mdm_vws.bzfc_cnst_email
    WHERE 
        arc_srcsys_cd IN ('BADW', 'DRMS') 
        OR arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd = 'BIO')
        AND (assessmnt_ctg IN ('Validated', 'Use With Caution') OR assessmnt_ctg IS NULL)
) as E
INNER JOIN (
    SELECT 
        cnst_mstr_id,
        cnst_hsld_id,
        cnst_dsp_deceased_cd,
        cnst_typ_cd 
    FROM 
        eda.arc_mdm_vws.bz_cnst_mstr
) as FR_main
ON FR_main.cnst_mstr_id = E.cnst_mstr_id
LEFT OUTER JOIN (
    SELECT * 
    FROM eda.arc_mdm_vws.bz_cnst_prsn_nm 
    WHERE 
        arc_srcsys_cd IN ('BADW', 'DRMS', 'CDIM') 
        OR arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd = 'BIO')
        AND cnst_prsn_nm_typ_cd IN ('PN', 'LN') 
        AND cnst_prsn_nm_end_dt = '9999-12-31'
) as P 
ON E.cnst_mstr_id = P.cnst_mstr_id
AND P.arc_srcsys_cd = E.arc_srcsys_cd
LEFT OUTER JOIN (
    SELECT
        cnst_mstr_id,
        arc_srcsys_cd,
        cnst_org_nm,
        dw_srcsys_trans_ts
    FROM
        eda.arc_mdm_vws.bz_cnst_org_nm
    WHERE
        cnst_org_nm_typ_cd IN ('PN', 'LN')
        AND (arc_srcsys_cd IN ('BADW', 'DRMS', 'CDIM') 
        OR arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd = 'BIO'))
) as ORG
ON E.cnst_mstr_id = ORG.cnst_mstr_id
AND E.arc_srcsys_cd = ORG.arc_srcsys_cd
LEFT OUTER JOIN eda.arc_mdm_vws.bz_cnst_addr as A
ON E.cnst_mstr_id = A.cnst_mstr_id
AND E.arc_srcsys_cd = A.arc_srcsys_cd
AND A.cnst_addr_end_dt = '9999-12-31'
LEFT OUTER JOIN eda.arc_mdm_vws.bz_locator_addr as loc_addr
ON A.locator_addr_key = loc_addr.locator_addr_key
LEFT OUTER JOIN eda.arc_mdm_vws.bz_assessmnt as bz_assmnt
ON loc_addr.assessmnt_key = bz_assmnt.assessmnt_key
QUALIFY ROW_NUMBER() OVER (PARTITION BY FR_main.cnst_mstr_id ORDER BY
    CASE
        WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND E.arc_srcsys_cd = 'DRMS' THEN 1
        WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND E.arc_srcsys_cd = 'BADW' THEN 2
        WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND E.arc_srcsys_cd NOT IN ('DRMS', 'BADW', 'CDIM') THEN 3
        WHEN E.dw_srcsys_trans_ts > CURRENT_DATE - INTERVAL '365 days' AND E.arc_srcsys_cd = 'CDIM' THEN 4
        WHEN E.dw_srcsys_trans_ts < CURRENT_DATE - INTERVAL '365 days' AND E.arc_srcsys_cd = 'CDIM' THEN 5
        WHEN E.dw_srcsys_trans_ts <= CURRENT_DATE - INTERVAL '365 days' AND E.arc_srcsys_cd = 'DRMS' THEN 6
        WHEN E.dw_srcsys_trans_ts <= CURRENT_DATE - INTERVAL '365 days' AND E.arc_srcsys_cd = 'BADW' THEN 7
        WHEN E.dw_srcsys_trans_ts <= CURRENT_DATE - INTERVAL '365 days' AND E.arc_srcsys_cd NOT IN ('DRMS', 'BADW', 'CDIM') THEN 8
        ELSE 9
    END,
    E.dw_srcsys_trans_ts DESC,
    P.dw_srcsys_trans_ts DESC,
    A.dw_srcsys_trans_ts DESC,
    ORG.dw_srcsys_trans_ts DESC
) = 1 ;

		--audit update	
			v_end_time := CURRENT_TIMESTAMP;
			v_ok_message = cast((select count(*) from mktg_ops_tbls.cnst_cdi_bio_preferred_email) as nvarchar)+ ' Records inserted.';
		        UPDATE etl_config.audit_log
		        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
		        WHERE proc_name = 'ld_cnst_cdi_bio_preferred_email' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
		
		--Insert in audit to Error
		    EXCEPTION
		        WHEN OTHERS THEN
		            v_end_time := CURRENT_TIMESTAMP;
					RAISE NOTICE 'NOTICE: An exception occurred.';
					
		    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
		    VALUES ('ld_cnst_cdi_bio_preferred_email', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
		

END;

$$
