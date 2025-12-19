CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_smry_phss_prfr()
 LANGUAGE plpgsql
AS $$
	/*
Created By: Madhusudhan Reddy Sureddy
Created Date: 28-Mar-2014
Purpose: CDI PHSS Summary preferred view.

Modified By: Michael Andrien
Modified Date: 9/22/2015
Purpose: 			Replaced the external master bridge query with the CDI master bridge and added the line of service = PHSS check.  The original query
						was not picking up the SABO - SABA Orgs and the PHSF source records from CDI, which includes the PHSS SalesForce contacts and orgs.  Also 
						added EM and DM org name and constituent type columns to the profile.

Modified By: Majeed Mohammad
Modified Date: 10/19/2015
Purpose: Added the columns for locator_addr_key, cnst_addr_assessmnt_ctg, addr_typ_cd 


Modified By: Majeed Mohammad
Modified Date: 09/16/2016
Purpose: Added the logic to set the MAIL and EMAIL indicators 

Modified By: Michael Andrien
Modified Date: 12/14/2016
Purpose: 	Modified the logic for setting the PHSS do not contact indicators.  First, I removed (commented out)  the section that was checking for the Biomed (DRMS) contact preferencess.  Second,
				I changed the CDI DNC preferences to reference PHSS rather than BIO.  
				Removed the drms portion of the lines below.
				  ,zeroifnull(case when cnst_cntct_pref.do_not_email_ind = 1 or drms_opt_out.drms_em_opt_out_ind = 1 then 1 else 0 end)  (TITLE 'Do Not Email Indicator')  
                ,zeroifnull(case when cnst_cntct_pref.do_not_mail_ind = 1 or drms_opt_out.drms_dm_opt_out_ind = 1 then 1 else 0 end)  (TITLE 'Do Not Mail Indicator')        

Modified By: Mike Andrien
Modified Date: 08/25/2017 
Purpose:  Updated the contact preference and DNC logic to pull the information from mktg_ops_vws.bzf_cnst_cem_opt_outs view. 

Modified By: Michael Andrien
Modified Date: 10/23/2017
Purpose:  Added dpv_cd from the bzfc_cnst_addr to further qualify the address assessment category coding.  We were getting a high volume of returned mail
				and were told to exclude mailing addresses that have a 'Deliverable' assessment but the dpv_cd is not equal to 'Y'.  

Modified By: Michael Andrien
Modified Date: 08/31/2018
Purpose: Added unit_key, unit_cd, mktg_unit_key and mktg_unit_cd attributes to match the other LOB profiles.  Set the unit and mktg unit attribute to be the same base on the direct mail zip code associated with the donor.  We didn't have 
			the unit details in the PHSS profile and have no rules for associating the chapter unit for PHSS constituent so I used the zip code for both.

Modified By: Michael Andrien
Modified Date: 03/12/2019
Purpose: Added logic to populate the primary phone attributes.

Modified By: Michael Andrien
Modified Date: 10/28/2021
Purpose: Added the FAEM join to include the Email append logic into the EM preferred email settings.  The FAEM email address will override the ranked CDI email if the 
append date is more recent than the CDI start date.

Modified By: Michael Andrien
Modified Date: 11/09/2022
Purpose: Notice the Fresh Address email select was missing from the FAEM join,  Modified the FAEM join to include both
Fresh Address and Pacific East email append data.
*/
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_smry_phss_prfr', 'Stored Procedure', 'Inprogress', v_start_time);

begin

truncate table mktg_ops_tbls.cnst_cdi_smry_phss_prfr_stg;

insert into mktg_ops_tbls.cnst_cdi_smry_phss_prfr_stg

with cte as ( SELECT
               PHSS_CNST.cnst_mstr_id                      
                ,M.cnst_hsld_id                       
                ,M.cnst_arc_deceased_cd               
                ,DM.cnst_data_src_cd                  
                ,DM.cnst_prsn_prfx_nm                 
                ,DM.cnst_prsn_f_nm                    
                ,DM.cnst_prsn_m_nm                   
                ,DM.cnst_prsn_l_nm                    
                ,DM.cnst_prsn_sfx_nm                  
                ,DM.locator_addr_key		 
				,DM.cnst_addr_assessmnt_ctg	
				,DM.dpv_cd               
				,DM.cnst_addr_typ_cd	
                ,DM.cnst_line_1_addr                  
                ,DM.cnst_line_2_addr                  
                ,DM.cnst_city_nm                      
                ,DM.cnst_st_cd                        
                ,DM.cnst_zip_5_cd                     
                ,DM.cnst_zip_4_cd                     
                ,DM.cnst_email                       
                ,DM.cnst_org_nm					
                ,DM.cnst_typ_dsc								
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_data_src_cd else EM.cnst_data_src_cd end as em_cnst_data_src_cd              
             --   ,EM.cnst_data_src_cd                  
                ,EM.cnst_prsn_prfx_nm                
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_prsn_f_nm else EM.cnst_prsn_f_nm end as em_cnst_prsn_f_nm  		
--                ,EM.cnst_prsn_f_nm                   
                ,EM.cnst_prsn_m_nm                   
				,cast(case when (EM.cnst_typ_dsc = 'Organization' and  EM.cnst_prsn_l_nm  is null) then EM.cnst_org_nm 
				 					when faem.cnst_mstr_id is not null then faem.em_cnst_prsn_l_nm 
				 					 else EM.cnst_prsn_l_nm  
						end as varchar(50)) as em_cnst_prsn_l_nm	
--                ,EM.cnst_prsn_l_nm                    
                ,EM.cnst_prsn_sfx_nm                  			
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_line_1_addr else EM.cnst_line_1_addr end as em_cnst_line_1_addr
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_line_2_addr else EM.cnst_line_2_addr end as em_cnst_line_2_addr
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_city_nm else EM.cnst_city_nm end as em_cnst_city_nm
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_st_cd else EM.cnst_st_cd end as em_cnst_st_cd
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_zip_5_cd else EM.cnst_zip_5_cd end as em_cnst_zip_5_cd
				,case when faem.cnst_mstr_id is not null then NULL else EM.cnst_zip_4_cd end as em_cnst_zip_4_cd
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_email else EM.cnst_email end as em_cnst_email  /* 4/25/17 MTA added for Fresh Address override */
				,case when faem.cnst_mstr_id is not null then COALESCE(faem.em_email_key,0) else  COALESCE(EM.cnst_email_key,0) end as em_cnst_email_key  /* 2/10/17 Webi universe was using em_cnst_email_key, but Adobe is using em_locator_addr_key  :  4/25/17 MTA added for Fresh Address override */
				,case when faem.cnst_mstr_id is not null then faem.em_cnst_email_assessmnt_ctg else EM.cnst_email_assessmnt_ctg end as em_cnst_email_assessmnt_ctg  /* 4/25/17 MTA added for Fresh Address override */
				,EM.cnst_org_nm  as em_cnst_org_nm 
				,case when faem.cnst_mstr_id is not null then 'IN' else EM.cnst_typ_dsc end as em_cnst_typ_dsc					
 --               ,EM.cnst_line_1_addr                  (TITLE 'EM Constituent Line 1 Address')
 --               ,EM.cnst_line_2_addr                  (TITLE 'EM Constituent Line 2 Address')
 --               ,EM.cnst_city_nm                      (TITLE 'EM Constituent City Name')
 --               ,EM.cnst_st_cd                        (TITLE 'EM Constituent State Code')
 --               ,EM.cnst_zip_5_cd                     (TITLE 'EM Constituent Zip 5 Code')
 --               ,EM.cnst_zip_4_cd                     (TITLE 'EM Constituent Zip 4 Code')
 --               ,EM.cnst_email                        (TITLE 'EM Constituent Email')
 --               ,EM.cnst_email_key                         (TITLE 'EM Constituent Email Key')
 --               ,EM.cnst_email_assessmnt_ctg  (TITLE 'EM Constituent Email Assessmnt Category')
 --               ,EM.cnst_org_nm					(TITLE 'DM Constituent Org Name')
 --               ,EM.cnst_typ_dsc					(TITLE 'DM Constituent Type')
                ,0 as email_dlvrbl_ind           
    			,hphone.prim_cnst_phn  
    			,hphone.prim_cnst_phn_source 
   				 ,hphone.prim_cnst_phn_typ_dsc  
             /*        
                ,'0000000000     '      (TITLE 'Primary Constituent Phone')    
                ,'NULL '        (TITLE 'Primary Constituent Phone Type Description')           
			*/
                ,cast('0000000000     ' as varchar(15))as cnt_mobl_phn 
                ,cast(NULL as varchar(5))  as cnst_mbl_typ_desc 
                ,cnst_cntct_pref.phss_do_not_call_hm_phn_ind   
			    ,cnst_cntct_pref.phss_do_not_call_mbl_phn_ind 
			    ,cnst_cntct_pref.phss_do_not_call_work_phn_ind 
			    ,cnst_cntct_pref.phss_do_not_email_ind	
			    ,cnst_cntct_pref.phss_do_not_mail_ind	  
			    ,cnst_cntct_pref.phss_do_not_txt_ind            
               ,cast(NULL as varchar(4)) as cnt_tshrd_prty_sgmnt_grp_nm                        
             ,COALESCE(c.unit_key,0) as unit_key
			 ,c.nk_ecode as unit_cd
             ,COALESCE(c.unit_key,0) as mktg_unit_key
			 ,c.nk_ecode as mktg_unit_cd
FROM 

/*(select distinct  cnst_mstr_id from eda.arc_mdm_vws.cnst_mstr_external_brid where arc_srcsys_cd = 'SABA' ) PHSS_CNST  
MTA 9/22/15 Replaced with the master bridge select below and added line of service code = PHSS check to include SF contacts/orgs and SABA Orgs
*/
(select distinct  cnst_mstr_id from eda.arc_mdm_vws.bz_cnst_mstr_bridge
where (cnst_mstr_subj_area_cd in  ('SABA', 'HSIP') 
OR cnst_mstr_subj_area_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='PHSS'))
) PHSS_CNST 

LEFT OUTER JOIN eda.arc_mdm_vws.cnst_mstr M on PHSS_CNST.cnst_mstr_id = M.cnst_mstr_id

LEFT OUTER JOIN mktg_ops_tbls.cnst_cdi_phss_preferred_dmail DM
  ON M.cnst_mstr_id = DM.cnst_mstr_id
                   
LEFT OUTER JOIN mktg_ops_tbls.cnst_cdi_phss_preferred_email EM
  ON M.cnst_mstr_id = EM.cnst_mstr_id
  
  /* 9/16/2016: Majeed --Added the logic below to calculate the MAIL and EMAIL indicators. The logic was copied from the Bio profile*/ 
LEFT JOIN  mktg_ops_vws.bzf_cem_cnst_opt_outs cnst_cntct_pref on M.cnst_mstr_id =  cnst_cntct_pref.cnst_mstr_id
LEFT JOIN mktg_ops_vws.bz_geo_zip_code_to_chapter b on DM.cnst_zip_5_cd = b.ZIP
LEFT JOIN mktg_ops_vws.bz_dim_unit c on b.ecode = c.nk_ecode
/* The next join gets the email append data to compare to the ranked CDI email addr and is used to override the ranked email selection if the append date is 
more recent than the CDI start date of the ranked email.
*/
LEFT JOIN 
(
	select 
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
		a.list_upload_ts
	from	
	(
		select 
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
			'PEEM' as em_cnst_data_src_cd,
			b.email_key as em_email_key,
			case  when c.assessmnt_ctg is null then 'Validated' else c.assessmnt_ctg end as em_cnst_email_assessmnt_ctg,
			'Y' as ok_to_email_flg,
			list_upload_ts
		from mktg_ops_tbls.pacific_east_email_append a
		left join eda.arc_mdm_vws.bz_locator_email b on b.cnst_email_addr = a.cnst_email
		left join eda.arc_mdm_vws.bz_assessmnt c on b.assessmnt_key = c.assessmnt_key
    	where a.row_stat_cd <> 'L'		
	union all
		select 
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
			'FAEM' as em_cnst_data_src_cd,
			b.email_key as em_email_key,
			case  when c.assessmnt_ctg is null then 'Validated' else c.assessmnt_ctg end as em_cnst_email_assessmnt_ctg,
			'Y' as ok_to_email_flg,
			list_upload_ts
		from mktg_ops_tbls.fresh_address_email_append a
		left join eda.arc_mdm_vws.bz_locator_email b on b.cnst_email_addr = a.cnst_email
		left join eda.arc_mdm_vws.bz_assessmnt c on b.assessmnt_key = c.assessmnt_key
		where a.row_stat_cd <> 'L'
		) a (cnst_mstr_id, cnst_prsn_f_nm, cnst_prsn_l_nm, cnst_line_1_addr, cnst_line_2_addr, cnst_city_nm, cnst_st_cd, cnst_zip_5_cd, cnst_email, list_source_nm, em_cnst_data_src_cd, em_email_key, em_cnst_email_assessmnt_ctg, ok_to_email_flg, list_upload_ts)	left join 
	/*
	This next query is retrieving the phss preferred email from the email ranking table to assess whether the preferred email from the ranking process is ok to email.  we'll compared the assessment
	results between the append email details from the join above to the ranked email details to decide whether the to override the email selected from the CDI ranking process with the append email.
	*/
	(
		select 
			a.cnst_mstr_id,
			a.cnst_email_key,
			a.cnst_email, 
			a.cnst_email_assessmnt_ctg, 
			a.cnst_data_src_cd,
			b.cnst_email_strt_ts,
			case when c.email_addr is not null then c.ok_to_email_flg else NULL end as ok_to_email_flg
		from mktg_ops_tbls.cnst_cdi_phss_preferred_email a
		left join eda.arc_mdm_vws.bzfc_cnst_email b on a.cnst_mstr_id = b.cnst_mstr_id and a.cnst_email_key = b.email_key and a.cnst_data_src_cd = b.arc_srcsys_cd	
		left join mktg_ops_vws.bzfc_cnst_cdi_phss_email_prfl c on a.cnst_mstr_id = c.cnst_mstr_id
	) b (cnst_mstr_id, cnst_email_key, cnst_email, cnst_email_assessmnt_ctg, cnst_data_src_cd, cnst_email_strt_ts, ok_to_email_flg) on a.cnst_mstr_id = b.cnst_mstr_id
	where (a.ok_to_email_flg is null or a.ok_to_email_flg = 'Y') and ( (a.cnst_email <> b.cnst_email and a.list_upload_ts >= b.cnst_email_strt_ts) or (b.cnst_mstr_id is null) )		
	qualify row_number() over (partition by a.cnst_mstr_id  order by a.list_upload_ts desc) = 1
)  faem (cnst_mstr_id, em_cnst_prsn_f_nm, em_cnst_prsn_l_nm, em_cnst_line_1_addr, em_cnst_line_2_addr, em_cnst_city_nm, em_cnst_st_cd, em_cnst_zip_5_cd, em_cnst_email, em_list_source_nm, em_cnst_data_src_cd, em_email_key, em_cnst_email_assessmnt_ctg, ok_to_email_flg, list_upload_ts) on M.cnst_mstr_id = faem.cnst_mstr_id

LEFT OUTER JOIN
(
select
bz_cnst_phn.CNST_MSTR_ID,
bz_cnst_phn.cnst_phn_num as prim_cnst_phn,
bz_cnst_phn.arc_srcsys_cd as prim_cnst_phn_source,
cast(case when bz_cnst_phn.phn_typ_cd='H' then 'Home' else 'LN' end as varchar(20)) as prim_cnst_phn_typ_dsc,
case when bz_arc_srcsys.arc_srcsys_cd is not null then bz_arc_srcsys.arc_srcsys_cd end as FR_arc_srcsys_cd,
row_number() over (partition by cnst_mstr_id order by 
CASE WHEN bz_cnst_phn.phn_typ_cd='H' and bz_cnst_phn.arc_srcsys_cd='SFCO' and bz_cnst_phn.cnst_phn_num is not null then  1
             WHEN bz_cnst_phn.phn_typ_cd='H' and bz_cnst_phn.arc_srcsys_cd='SFCC' and bz_cnst_phn.cnst_phn_num is not null then  2
            When bz_cnst_phn.phn_typ_cd='H' and bz_arc_srcsys.arc_srcsys_cd  = 'SABA' and bz_cnst_phn.cnst_phn_num is not null then  3
             When bz_cnst_phn.phn_typ_cd='H' and bz_arc_srcsys.arc_srcsys_cd  = 'SABA' and bz_cnst_phn.cnst_phn_num is not null then  4
			WHEN bz_cnst_phn.phn_typ_cd='H' and bz_cnst_phn.arc_srcsys_cd='PHSF'and bz_cnst_phn.cnst_phn_num is not null then 5
            WHEN bz_cnst_phn.phn_typ_cd='H' and bz_cnst_phn.arc_srcsys_cd='RCSO'and bz_cnst_phn.cnst_phn_num is not null then 6
            WHEN bz_cnst_phn.phn_typ_cd='H' and  bz_cnst_phn.arc_srcsys_cd='RCST' and bz_cnst_phn.cnst_phn_num is not null then 7
            when bz_cnst_phn.arc_srcsys_cd='CDIM' and bz_cnst_phn.phn_typ_cd='LN' and  bz_cnst_phn.cnst_phn_num is not null then 8
        else 999
END asc,
bz_cnst_phn.dw_srcsys_trans_ts desc
) as rownum,
CASE WHEN bz_cnst_phn.phn_typ_cd='H' and bz_cnst_phn.arc_srcsys_cd='SFCO' and bz_cnst_phn.cnst_phn_num is not null then  1
             WHEN bz_cnst_phn.phn_typ_cd='H' and bz_cnst_phn.arc_srcsys_cd='SFCC' and bz_cnst_phn.cnst_phn_num is not null then  2
            When bz_cnst_phn.phn_typ_cd='H' and bz_arc_srcsys.arc_srcsys_cd = 'SABA' and bz_cnst_phn.cnst_phn_num is not null then  3
            WHEN bz_cnst_phn.phn_typ_cd='H' and bz_cnst_phn.arc_srcsys_cd='SABO'and bz_cnst_phn.cnst_phn_num is not null then 4
            WHEN bz_cnst_phn.phn_typ_cd='H' and bz_cnst_phn.arc_srcsys_cd='PHSF'and bz_cnst_phn.cnst_phn_num is not null then 5
            WHEN bz_cnst_phn.phn_typ_cd='H' and  bz_cnst_phn.arc_srcsys_cd='RCSO' and bz_cnst_phn.cnst_phn_num is not null then 6
            WHEN bz_cnst_phn.phn_typ_cd='H' and  bz_cnst_phn.arc_srcsys_cd='RCST' and bz_cnst_phn.cnst_phn_num is not null then 7
			when bz_cnst_phn.arc_srcsys_cd='CDIM' and bz_cnst_phn.phn_typ_cd='LN' and  bz_cnst_phn.cnst_phn_num is not null then 8
             else 999
END as hnum
  FROM 
eda.arc_mdm_vws.bzfc_cnst_phn  bz_cnst_phn
left join
eda.arc_mdm_vws.bz_arc_srcsys bz_arc_srcsys
on
bz_cnst_phn.arc_srcsys_cd=bz_arc_srcsys.arc_srcsys_cd
and
bz_arc_srcsys.line_of_service_cd='PHSS'
WHERE bz_cnst_phn.phn_typ_cd in ('H','LN') and hnum<999 and assessmnt_ctg = 'Usable' and cnst_phn_end_dt = '12/31/9999' 
QUALIFY rownum=1
) hphone
on
M.cnst_mstr_id =  hphone.cnst_mstr_id
)
select * from cte;

truncate table mktg_ops_tbls.cnst_cdi_smry_phss_prfr;
insert into mktg_ops_tbls.cnst_cdi_smry_phss_prfr select * from mktg_ops_tbls.cnst_cdi_smry_phss_prfr_stg; 
--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = 'Records inserted.';
        UPDATE mods_bi.etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message , recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.cnst_cdi_smry_phss_prfr) as INTEGER)
        WHERE proc_name = 'ld_cnst_cdi_smry_phss_prfr' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log(proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_cnst_cdi_smry_phss_prfr', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
