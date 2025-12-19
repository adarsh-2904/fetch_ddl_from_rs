CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_bio_preferred_dmail()
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
Modified Date: August 20 2014
Purpose: To make it BIO compatible

Modified By: Michael Andrien
Modified Date: 2015-06-11
Purpose:  Modified the macro to include the CDIM source and updated the ranking rules to apply to the Biomed sources (DRMS, BADW and CDIM)

Modified By: Majeed Mohammad
Modified Date: 04-19-2016
Purpose:  Explicitly efined the SELECT columnnames in the view subquery arc_mdm_vws.bz_cnst_addr. This was causing an error in the macro 
execution with the errorr message: Failure 3810 Column/Parameter 'arc_mdm_vws.addr.assessmnt_ctg' does not exist
				Explicitly defined the INSERT columnnames. 
				

Modified By:  Majeed Mohammad
Modified Date: 08/08/2016
Purpose: Add the DM address locator , assessment and county information. 

Modified By: Majeed Mohammad
Modified Date: 09/28/2016
Purpose:  Updated the macro to use the view arc_mdm_vws.bzfc_cnst_email  instead of  arc_mdm_vws.bz_cnst_email . 
Also used the corrected email column locator_email_addr

Modified By: Michael Andrien
Modified Date: 10/21/2017
Purpose:  Added dpv_cd from the bzfc_cnst_addr to further qualify the address assessment category coding.  We were getting a high volume of returned mail
				and were told to exclude mailing addresses that have a 'Deliverable' assessment but the dpv_cd is not equal to 'Y'.  

Modified By: Michael Andrien
Modified Date: 10/23/2017
Purpose: Expanded the Address ranking rules to incorporate the DPV code and Address type.
*/	
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_bio_preferred_dmail', 'Stored Procedure', 'Inprogress', v_start_time);

		truncate table mktg_ops_tbls.cnst_cdi_bio_preferred_dmail;
		
		INSERT INTO mktg_ops_tbls.cnst_cdi_bio_preferred_dmail
		(cnst_mstr_id, 
		cnst_hsld_id, 
		cnst_dsp_deceased_cd, 
		cnst_data_src_cd, 
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
		dpv_cd, addr_typ_cd, 
		cnst_line_1_addr, 
		cnst_line_2_addr, 
		cnst_city_nm, 
		cnst_st_cd, 
		cnst_zip_5_cd, 
		cnst_zip_4_cd, 
		cnst_addr_county_nm, 
		cnst_email, 
		cnst_org_nm, 
		cnst_typ_dsc)
		select
		  cnst_mstr.cnst_mstr_id
		, cnst_mstr.cnst_hsld_id  
		, cnst_mstr.cnst_dsp_deceased_cd
		,cnst_addr.arc_srcsys_cd   as    cnst_data_src_cd               
		,P.bz_cnst_prsn_prefix_nm    as     cnst_prsn_prfx_nm
		,P.bz_cnst_prsn_first_nm   as   cnst_prsn_f_nm    
		,P.bz_cnst_prsn_middle_nm   as     cnst_prsn_m_nm
		,P.bz_cnst_prsn_last_nm     as     cnst_prsn_l_nm
		,P.bz_cnst_prsn_suffix_nm    as    cnst_prsn_sfx_nm
		,P.cnst_prsn_full_nm as cnst_prsn_full_nm
		,P.bz_cnst_alias_in_saltn_nm as cnst_alias_in_saltn_nm
		,P.bz_cnst_alias_out_saltn_nm as cnst_alias_out_saltn_nm
		,cnst_addr.locator_addr_key as locator_addr_key
		,cnst_addr.cnst_addr_assessmnt_ctg  as cnst_addr_assessmnt_ctg
		,cnst_addr.dpv_cd as dpv_cd
		,cnst_addr.cnst_addr_typ_cd as cnst_addr_typ_cd
		,cnst_addr.bz_cnst_addr_line1_addr   as    cnst_line_1_addr
		,cnst_addr.bz_cnst_addr_line2_addr   as    cnst_line_2_addr
		,cnst_addr.bz_cnst_addr_city_nm   as   cnst_city_nm    
		,cnst_addr.cnst_addr_state_cd    as    cnst_st_cd    
		,cnst_addr.cnst_addr_zip_5_cd  as   cnst_zip_5_cd       
		,cnst_addr.cnst_addr_zip_4_cd     as     cnst_zip_4_cd  
		,cnst_addr.bz_cnst_addr_county_nm as bz_cnst_addr_county_nm
		,E.locator_email_addr  as    cnst_email  
		,ORG.cnst_org_nm
		,case when cnst_mstr.cnst_typ_cd='IN' then 'Individual'
		           when cnst_mstr.cnst_typ_cd='OR' then 'Organization'
		           when cnst_mstr.cnst_typ_cd='AG' then 'Account Group'
		  end as cnst_typ_dsc
		FROM
		
		(
		select addr.cnst_mstr_id
		,addr.arc_srcsys_cd, addr.locator_addr_key locator_addr_key
		,addr.assessmnt_ctg  cnst_addr_assessmnt_ctg
		,addr.dpv_cd
		,addr.addr_typ_cd  cnst_addr_typ_cd
		,addr.bz_cnst_addr_line1_addr  
		,addr.bz_cnst_addr_line2_addr  
		,addr.bz_cnst_addr_city_nm  
		,addr.cnst_addr_state_cd  
		,addr.cnst_addr_zip_5_cd      
		,addr.cnst_addr_zip_4_cd
		,addr.bz_cnst_addr_county_nm bz_cnst_addr_county_nm 
		,addr.dw_srcsys_trans_ts
		,addr.cnst_addr_prefd_ind
		from eda.arc_mdm_vws.bzfc_cnst_addr as addr  -- 10/21/2017 - Mike Andrien changed the table to bzfc_cnst_addr from the bz_cnst_addr and commented out the locator and assessment joins below.
		--left outer join arc_mdm_tbls.locator_addr loc_addr on addr.locator_addr_key=loc_addr.locator_addr_key
		--left outer join arc_mdm_vws.bz_assessmnt bz_assmnt on loc_addr.assessmnt_key=bz_assmnt.assessmnt_key
		 where 
		( 
		(addr.bz_cnst_addr_line1_addr is not null) or 
		(addr.bz_cnst_addr_line2_addr is not null) or 
		(addr.bz_cnst_addr_city_nm is not null)  or 
		(addr.cnst_addr_state_cd is not null)  or 
		(addr.cnst_addr_zip_5_cd is not null) or 
		(addr.cnst_addr_zip_4_cd is not null) 
		) 
		AND 
		(addr.arc_srcsys_cd in  ('BADW','DRMS', 'CDIM')  
		OR 
		/*  Below condition is to check all BIO LOB source systems*/
		addr.arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='BIO')
		)
		-- limit 5
		 )
		as cnst_addr
		
		
		INNER JOIN
		eda.arc_mdm_vws.bz_cnst_mstr as cnst_mstr
		ON
		cnst_addr.cnst_mstr_id = cnst_mstr.cnst_mstr_id  
		
		
		LEFT OUTER JOIN
		(
		select 
		cnst_mstr_id,arc_srcsys_cd, 
		locator_email_addr,dw_srcsys_trans_ts,
		max(dw_srcsys_trans_ts) over (partitiON by cnst_mstr_id) as max_dw_srcsys_trans_ts,
		CASE 
		when CHARACTER_LENGTH(locator_email_addr) >= 8  
		--AND index(locator_email_addr,'@') > 1
		--AND index(trim(locator_email_addr),' ') = 0 
		AND POSITION('@' IN locator_email_addr) > 1
		AND POSITION(' ' IN TRIM(locator_email_addr)) = 0 
		AND 
		  (  
		              SUBSTRING(locator_email_addr, LENGTH(locator_email_addr) - 3) IN ('.com', '.net', '.org', '.gov', '.mil', '.edu') OR 
		                SUBSTRING(locator_email_addr, LENGTH(locator_email_addr) - 2) IN ('.us', '.ca', '.mx')
		)
		THEN
		'Y'
		else 
		'N'
		END as Valid_email,
		email_key
		FROM
		eda.arc_mdm_vws.bzfc_cnst_email
		WHERE (arc_srcsys_cd in  ('BADW','DRMS', 'CDIM')  
		OR arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='BIO'))
		AND Valid_email = 'Y' 
		
		 )as E
		ON
		cnst_addr.cnst_mstr_id=E.cnst_mstr_id
		AND
		cnst_addr.arc_srcsys_cd=E.arc_srcsys_cd
		
		LEFT OUTER JOIN 
		(
		select
		cnst_mstr_id
		,bz_cnst_prsn_prefix_nm         
		,bz_cnst_prsn_first_nm          
		,bz_cnst_prsn_middle_nm        
		,bz_cnst_prsn_last_nm          
		,bz_cnst_prsn_suffix_nm 
		,cnst_prsn_full_nm
		,bz_cnst_alias_in_saltn_nm
		,bz_cnst_alias_out_saltn_nm
		,cnst_prsn_nm_typ_cd
		,dw_srcsys_trans_ts
		,arc_srcsys_cd
		,cnst_prsn_nm_end_dt
		from 
		eda.arc_mdm_vws.bz_cnst_prsn_nm 
		where cnst_prsn_nm_typ_cd in ('PN','LN')
		AND
		 (arc_srcsys_cd in  ('BADW','DRMS', 'CDIM')  
		OR arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='BIO'))
		)as P
		ON 
		cnst_addr.cnst_mstr_id = P.cnst_mstr_id
		AND 
		cnst_addr.arc_srcsys_cd=P.arc_srcsys_cd
		
		LEFT OUTER JOIN 
		(
		select
		cnst_mstr_id,
		arc_srcsys_cd,
		cnst_org_nm,
		dw_srcsys_trans_ts
		from
		eda.arc_mdm_vws.bz_cnst_org_nm
		where
		cnst_org_nm_typ_cd  in ('PN','LN')
		AND
		 (arc_srcsys_cd in  ('BADW','DRMS', 'CDIM')  
		OR arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='BIO'))
		)as ORG
		ON 
		cnst_addr.cnst_mstr_id = ORG.cnst_mstr_id
		AND 
		cnst_addr.arc_srcsys_cd=ORG.arc_srcsys_cd
		
		--limit 10
		
		 Qualify ROW_NUMBER() OVER (PARTITION BY cnst_addr.cnst_mstr_id  
		ORDER BY
		CASE
		
		-- Prioritize Deliverable Home addresses with a DPV Code = Y 
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 1
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 2
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y'  and cnst_addr.cnst_addr_typ_cd='H') THEN 3
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='LN') THEN 4
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='LN') THEN 5
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 6
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 7
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 8
		-- Prioritize Deliverable non-home addresses with a DPV Code = Y 
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 9
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 10
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y'  and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 11
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'LN') THEN 12
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'LN') THEN 13
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 14
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 15
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 16
		--Now prioritize Deliverable Home addresses where the DPV Code is not equal to Y
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 17
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 18
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y'  and cnst_addr.cnst_addr_typ_cd = 'H') THEN 19
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='LN') THEN 20
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='LN') THEN 21
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 22
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 23
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 24
		--Now prioritize Deliverable non-home addresses where the DPV Code is not equal to Y
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 25
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 26
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y'  and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 27
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'LN') THEN 28
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'LN') THEN 29
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 30
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 31
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 32
		--Now prioritize Undeliverable Home addresses 

		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 33
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 34
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y'  and cnst_addr.cnst_addr_typ_cd = 'H') THEN 35
		WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='LN') THEN 36
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='LN') THEN 37
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='DRMS' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 38
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='DRMS'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 39
		WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='BADW' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 40
		ELSE 41 END
		,cnst_addr.dw_srcsys_trans_ts desc
		,E.dw_srcsys_trans_ts desc
		,P.dw_srcsys_trans_ts desc
		,ORG.dw_srcsys_trans_ts desc
		)=1
		--limit 10
;
		
		
		--audit update	
			v_end_time := CURRENT_TIMESTAMP;
			v_ok_message = cast((select count(*) from mktg_ops_tbls.cnst_cdi_bio_preferred_dmail) as nvarchar)+ ' Records inserted.';
		        UPDATE etl_config.audit_log
		        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
		        WHERE proc_name = 'ld_cnst_cdi_bio_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
		
		--Insert in audit to Error
		    EXCEPTION
		        WHEN OTHERS THEN
		            v_end_time := CURRENT_TIMESTAMP;
					RAISE NOTICE 'NOTICE: An exception occurred.';
					
		    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
		    VALUES ('ld_cnst_cdi_bio_preferred_dmail', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
		

END;

$$
