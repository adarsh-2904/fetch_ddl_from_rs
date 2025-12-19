CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_vms_preferred_email()
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
Modified Date: August 6 2014
Purpose: Support vms

Modified By: Majeed Mohammad
Modified Date: Jun -10-2015
Purpose:  The column assessmnt_ctg has been removed in the view arc_mdm_vws.bz_cnst_email by EDW for query optimizations. The macro now uses the new view arc_mdm_vws.bzfc_cnst_email that contains the assessmnt_ctg column 

Modified By: Michael Andrien
Modified Date: May-12-2016
Purpose: Modified the ranking rules to include the email type codes to ensure we select the primary VMS email over the Secondary.  The VMS primary email has the email type = 'U' and the 
				secondary is set to 'O'.
				

Modified By:  Majeed Mohammad
Modified Date: 08/08/2016
Purpose: Add the DM address locator , assessment and county information. 

Modified By: Majeed Mohammad
Modified Date: 09/28/2016
Purpose: Updated the macro to use the corrected email column locator_email_addr

Modified By: Michael Andrien
Modified Date: 08/22/2017
Purpose: Added logic to include constituents from theVolunteer list uploaded through the Stuart upload process.  The list name is 'FY18 STA Sign up form submission' , which is group membership key  272.

Modified By: Majeed Mohammad
Modified Date: 08/23/2017
Purpose: Updated the database from arc_cmm_vws to mktg_ops_vws

Modified By: Michael Andrien
Modified Date: 08/24/2017
Purpose: Commented out the code used to assess valid_email and are relying on the email assessment category from the CDI data.

				
Modified By: Majeed Mohammad
Modified Date: 03/20/2018
Purpose:  Added the logic to select the records from the group membership view 

Modified By: Majeed Mohammad
Modified Date: 03/22/2019
Purpose:  Added the join to the cnst_mstri_id in the subquery join to the view arc_cmm_vws.bz_grp_mbrshp. Without this, this macro was running for long time of about 2hrs. 
*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_vms_preferred_email', 'Stored Procedure', 'Inprogress', v_start_time);


begin

DROP TABLE IF EXISTS cnst_cdi_vms_preferred_email_temp;




create temp table cnst_cdi_vms_preferred_email_temp as (

/*Execution time 47s*/
with E as (
	SELECT 
	    cnst_mstr_id,
	    arc_srcsys_cd,
	    email_typ_cd,
	    locator_email_addr,
	    dw_srcsys_trans_ts,
	    MAX(dw_srcsys_trans_ts) OVER (PARTITION BY cnst_mstr_id) AS max_dw_srcsys_trans_ts,
	    email_key, 
	    assessmnt_ctg
	FROM eda.arc_mdm_vws.bzfc_cnst_email email 
	WHERE 
	    arc_srcsys_cd IN ('VMS') 
	    OR arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd='VMS') 
	    OR cnst_mstr_id IN (SELECT cnst_mstr_id FROM mktg_ops_vws.bz_grp_mbrshp WHERE grp_key = 272) 
	    OR cnst_mstr_id IN (SELECT cnst_mstr_id FROM eda.arc_cmm_vws.bz_grp_mbrshp a 
	                        LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
	                        WHERE grp_typ = 'Vol NHQ LOB' 
	                        AND a.arc_srcsys_cd=email.arc_srcsys_cd 
	                        AND a.cnst_mstr_id=email.cnst_mstr_id)
	    AND (assessmnt_ctg IN ('Validated', 'Use With Caution') OR assessmnt_ctg IS NULL)
		--limit 5
	UNION
	SELECT 
	    subquery.cnst_mstr_id,
	    subquery.arc_srcsys_cd, 
	    subquery.email_typ_cd, 
	    subquery.locator_email_addr,
	    subquery.dw_srcsys_trans_ts,
	    subquery.dw_srcsys_trans_ts,
	    subquery.email_key, 
	    subquery.assessmnt_ctg
	FROM (
	    SELECT 
	        cnst_email.cnst_mstr_id,
	        cnst_email.arc_srcsys_cd, 
	        cnst_email.email_typ_cd, 
	        cnst_email.locator_email_addr,
	        cnst_email.dw_srcsys_trans_ts,
	        cnst_email.email_key, 
	        cnst_email.assessmnt_ctg,
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
	WHERE subquery.rn = 1 
	--limit 5
	),

	/*Execution time 6secs*/
FR_main as (
		select 
		cnst_mstr_id,
		cnst_hsld_id,
		cnst_dsp_deceased_cd,
		cnst_typ_cd 
		  from 
		eda.arc_mdm_vws.bz_cnst_mstr),
		
/*Execution time 5m50s*/		
P as (
		SELECT * 
		FROM eda.arc_mdm_vws.bz_cnst_prsn_nm prsn
		WHERE 
		(
		    arc_srcsys_cd IN ('VMS') OR 
		    arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd = 'VMS') OR
		    cnst_mstr_id IN (SELECT cnst_mstr_id FROM mktg_ops_vws.bz_grp_mbrshp WHERE grp_key = 272) OR
		    cnst_mstr_id IN (
		        SELECT a.cnst_mstr_id 
		        FROM eda.arc_cmm_vws.bz_grp_mbrshp a 
		        LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
		        WHERE grp_typ = 'Vol NHQ LOB' 
		        AND a.arc_srcsys_cd = prsn.arc_srcsys_cd 
		        AND a.cnst_mstr_id = prsn.cnst_mstr_id)) 
				AND cnst_prsn_nm_typ_cd IN ('PN', 'LN') 
				AND cnst_prsn_nm_end_dt = '9999-12-31'
		),
		
/*Executed 6s no data*/		
ORG as (SELECT
    cnst_mstr_id,
    arc_srcsys_cd,
    cnst_org_nm,
    dw_srcsys_trans_ts
FROM eda.arc_mdm_vws.bz_cnst_org_nm org
WHERE
    cnst_org_nm_typ_cd IN ('PN', 'LN')
    AND (
        arc_srcsys_cd IN ('VMS') OR 
        arc_srcsys_cd IN (SELECT arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys WHERE line_of_service_cd = 'VMS') OR
        cnst_mstr_id IN (SELECT cnst_mstr_id FROM mktg_ops_vws.bz_grp_mbrshp WHERE grp_key = 272) OR
        cnst_mstr_id IN (
            SELECT a.cnst_mstr_id 
            FROM eda.arc_cmm_vws.bz_grp_mbrshp a 
            LEFT JOIN eda.arc_cmm_vws.grp_ref b ON a.grp_key = b.grp_key 
            WHERE grp_typ = 'Vol NHQ LOB' 
            AND a.arc_srcsys_cd = org.arc_srcsys_cd 
            AND a.cnst_mstr_id = org.cnst_mstr_id
        )
    )
),
		
v as (
	select 
	  FR_main.cnst_mstr_id
, FR_main.cnst_hsld_id  
, FR_main.cnst_dsp_deceased_cd
,E.arc_srcsys_cd                     
,P.bz_cnst_prsn_prefix_nm         
,P.bz_cnst_prsn_first_nm          
,P.bz_cnst_prsn_middle_nm        
,P.bz_cnst_prsn_last_nm          
,P.bz_cnst_prsn_suffix_nm        
,P.cnst_prsn_full_nm cnst_prsn_full_nm
,P.bz_cnst_alias_in_saltn_nm cnst_alias_in_saltn_nm
,P.bz_cnst_alias_out_saltn_nm cnst_alias_out_saltn_nm
,A.locator_addr_key as  locator_addr_key
,bz_assmnt.assessmnt_ctg cnst_addr_assessmnt_ctg
,A.bz_cnst_addr_line1_addr       
,A.bz_cnst_addr_line2_addr       
,A.bz_cnst_addr_city_nm          
,A.cnst_addr_state_cd            
,A.cnst_addr_zip_5_cd            
,A.cnst_addr_zip_4_cd       
,A.bz_cnst_addr_county_nm cnst_addr_county_nm             
,E.locator_email_addr 
,E.email_key 
,E.assessmnt_ctg
,ORG.cnst_org_nm
,case when FR_main.cnst_typ_cd='IN' then 'Individual'
           when FR_main.cnst_typ_cd='OR' then 'Organization'
           when FR_main.cnst_typ_cd='AG' then 'Account Group'
  end as cnst_typ_desc,
	ROW_NUMBER() OVER (PARTITION BY FR_main.cnst_mstr_id  
	ORDER BY
	/* Original Ranking rules from FR commented out by Mike Andrien 3/12/16 
	case when E.dw_srcsys_trans_ts>date-365 and E.arc_srcsys_cd = 'ATG' then 1
	when E.arc_srcsys_cd = 'CNVO' then 2
	when E.dw_srcsys_trans_ts=E.max_dw_srcsys_trans_ts and E.arc_srcsys_cd in ('ATG','ATGO','TAFS','SFFS')  then 3
	else 4 end
	*/
	case when E.arc_srcsys_cd = 'VMS' and E.email_typ_cd = 'U' then 1 --- This cooresponds to the primary email column from the dim_volunteer table from the Volunteer Connection system
		  when E.arc_srcsys_cd = 'VMS' and E.email_typ_cd = 'O' then 2 --- This cooresponds to the secondary email column from the dim_volunteer table from the Volunteer Connection system
		  when E.arc_srcsys_cd = 'VMS' and E.email_typ_cd = 'EH' then 3 --- This cooresponds to home email entries captured through the Stuart interface
 		  when E.arc_srcsys_cd = 'VMS' and E.email_typ_cd = 'EW' then 4 --- This cooresponds to work email entries captured through the Stuart interface
		  when E.arc_srcsys_cd = 'VMS' and E.email_typ_cd = 'W' then 5 --- This cooresponds to work email entries captured through the Stuart interface
		  else 6
	end
	,E.dw_srcsys_trans_ts desc
	,P.dw_srcsys_trans_ts desc
	,A.dw_srcsys_trans_ts desc
	,ORG.dw_srcsys_trans_ts desc) as rn
	from E
	inner join FR_main ON FR_main.cnst_mstr_id = E.cnst_mstr_id
	left outer join P ON E.cnst_mstr_id = P.cnst_mstr_id AND P.arc_srcsys_cd = E.arc_srcsys_cd
	left outer join ORG ON E.cnst_mstr_id = ORG.cnst_mstr_id AND E.arc_srcsys_cd = ORG.arc_srcsys_cd
	LEFT OUTER JOIN eda.arc_mdm_vws.bz_cnst_addr A ON E.cnst_mstr_id = A.cnst_mstr_id 	AND E.arc_srcsys_cd = A.arc_srcsys_cd 	AND A.cnst_addr_end_dt = DATE '9999-12-31'
  	left outer join eda.arc_mdm_vws.bza_locator_addr loc_addr on A.locator_addr_key=loc_addr.locator_addr_key
  	--Hitansu substituting arc_mdm_vws.bza_locator_addr for arc_mdm_tbls.locator_addr
	left outer join eda.arc_mdm_vws.bz_assessmnt bz_assmnt on loc_addr.assessmnt_key=bz_assmnt.assessmnt_key)

 

SELECT 
 cnst_mstr_id,
 cnst_hsld_id,
 cnst_dsp_deceased_cd,
 arc_srcsys_cd,
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
 assessmnt_ctg,
 cnst_org_nm,
 cnst_typ_desc
from v where rn=1);

truncate table mktg_ops_tbls.cnst_cdi_vms_preferred_email;

insert into  mktg_ops_tbls.cnst_cdi_vms_preferred_email 
(cnst_mstr_id, cnst_hsld_id, cnst_dsp_deceased_cd, cnst_data_src_cd,
		cnst_prsn_prfx_nm, cnst_prsn_f_nm, cnst_prsn_m_nm, cnst_prsn_l_nm,
		cnst_prsn_sfx_nm, cnst_prsn_full_nm, cnst_alias_in_saltn_nm,
		cnst_alias_out_saltn_nm,   locator_addr_key, cnst_addr_assessmnt_ctg,cnst_line_1_addr, cnst_line_2_addr,
		cnst_city_nm, cnst_st_cd, cnst_zip_5_cd, cnst_zip_4_cd,cnst_addr_county_nm, cnst_email,
		cnst_email_key, cnst_email_assessmnt_ctg, cnst_org_nm, cnst_typ_dsc)
		select * from cnst_cdi_vms_preferred_email_temp;
--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.cnst_cdi_vms_preferred_email) as nvarchar)+ ' Records inserted.';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_cnst_cdi_vms_preferred_email' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_cnst_cdi_vms_preferred_email', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE etl_config.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_email' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;
$$
