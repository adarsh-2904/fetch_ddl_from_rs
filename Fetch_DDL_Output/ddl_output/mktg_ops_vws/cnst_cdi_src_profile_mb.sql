CREATE OR REPLACE VIEW mktg_ops_vws.cnst_cdi_src_profile_mb AS 
-- mktg_ops_vws.cnst_cdi_src_profile_mb source

create or REPLACE VIEW mktg_ops_vws.cnst_cdi_src_profile_mb
/* 2014-10-08 Mike Andrien - Created a test version to compare against the original CDI profile view.  The test version uses the CDI Master Bridge
                                               table wereas the original view used the External Bridge table.  Also, added logic to include the FR chapter 
                                               source codes in the FR LOB
--2015-08-06 Mike Andrien - Added the mGive Flag and added MDON as a source to the FR LOB  code.  

Modified By: Mike Andrien
Modified Date: 10/31/2018
Purpose: Added new CDI sources and the following attributes:
	    in_rcso_flg,
	    in_rcst_flg,
	    in_sfco_flg,
	    in_sfcc_flg,
		fr_lob_ind
		bio_lnd
		phss_lob_ind
		vms_lob_ind
		multi_lob_ind
		multi_lob_flg

Modified By: Mike Andrien
Modified Date: 12/18/2018
Purpose:  Added the RCO flag attribute and added the RCO source to the FR Flad and FR Ind attributes.

Modified By: Mike Andrien
Modified Date: 04/08/2020
Purpose: Add GMFS source to include the GMS system for FR'

Modified By: Mike Andrien
Modified Date: 09/15/2022
Purpose: Simplified the view by making it a straight select.
*/
/*
     ( cnst_mstr_id ,
      in_atg_flg ,
      in_atgo_flg ,
      in_cnvo_flg ,
      in_phsf_flg,
      in_saba_flg ,
	  in_rcso_flg,
	  in_rcst_flg,
	  in_sfco_flg,
	  in_sfcc_flg,
      in_sffs_flg ,
      in_tafs_flg ,
      in_vms_flg ,
      in_ep_flg ,
      in_drms_flg ,
      in_cas_flg ,      
      in_mgive_flg,
	  in_rco_flg,
	  in_gms_flg,
      fr_lob_flg ,
	  fr_lob_ind,
      phss_lob_flg ,
	  phss_lob_ind,
      bio_lob_flg ,
	  bio_lob_ind,
      vms_lob_flg ,
	  vms_lob_ind,
      dstr_lob_flg,
	  multi_lob_flg,
	  multi_lob_ind,
      srcsys_cnt  )
AS
LOCK TABLE arc_mdm_vws.bz_cnst_mstr_bridge FOR ACCESS
LOCK TABLE arc_mdm_vws.bz_arc_srcsys FOR ACCESS
*/
AS
 SELECT 
 z.cnst_mstr_id 
,max(case             when z.cnst_mstr_subj_area_cd = 'ATG' then 'Y' else 'N' end) as in_atg_flg --(TITLE 'In ATG Registrant Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'ATGO' then 'Y' else 'N' end) as in_atgo_flg --(TITLE 'In ATG Order Billing Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'CNVO' then 'Y' else 'N' end) as in_cnvo_flg --(TITLE 'In Convio Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'PHSF' then 'Y' else 'N' end) as in_phsf_flg --(TITLE 'In PHSS Salesforce Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'SABA' then 'Y' else 'N' end) as in_saba_flg --(TITLE 'In SABA Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'RCSO' then 'Y' else 'N' end) as in_rcso_flg --(TITLE 'In Red Cross Store Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'RCST' then 'Y' else 'N' end) as in_rcst_flg --(TITLE 'In Red Cross Store Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'SFCO' then 'Y' else 'N' end) as in_sfco_flg --(TITLE 'In SF Mktg Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'SFCC' then 'Y' else 'N' end) as in_sfcc_flg --(TITLE 'In SF Mktg Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'SFFS' then 'Y' else 'N' end) as in_sffs_flg --(TITLE 'In FR Salesforce Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'TAFS' then 'Y' else 'N' end) as in_tafs_flg --(TITLE 'In Team Approach Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'VMS' then 'Y' else 'N' end) as in_vms_flg --(TITLE 'In Volunteer Mgt System Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'BADW' then 'Y' else 'N' end) as in_ep_flg --(TITLE 'In eProgesa Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'DRMS' then 'Y' else 'N' end) as in_drms_flg --(TITLE 'In DRMS Flag'),
,max(case             when z.cnst_mstr_subj_area_cd = 'CAS2' then 'Y' else 'N' end) as in_cas_flg --(TITLE 'In CAS Flag'), 
,max(case             when z.cnst_mstr_subj_area_cd = 'MDON' then 'Y' else 'N' end) as in_mgive_flg --(TITLE 'In mGive Flag'), 
,max(case             when z.cnst_mstr_subj_area_cd = 'RCO' then 'Y' else 'N' end) as in_rco_flg --(TITLE 'In RCO Flag'), 
,max(case             when z.cnst_mstr_subj_area_cd = 'GMFS' then 'Y' else 'N' end) as in_gms_flg --(TITLE 'In GMS Flag'), 
,max(case 			  when z.cnst_mstr_subj_area_cd in  ('RCO','ATG', 'ATGO','CNVO', 'TAFS','SFFS','MDON', 'GMFS') or z.line_of_service_cd = 'FR'  then 'Y' else 'N' end) as fr_lob_flg --(TITLE 'Fundraising LOBFlag'),
,max(case 			  when z.cnst_mstr_subj_area_cd in  ( 'RCO','ATG', 'ATGO','CNVO', 'TAFS','SFFS','MDON', 'GMFS') or z.line_of_service_cd = 'FR'  then 1 else 0 end) as fr_lob_ind --(TITLE 'Fundraising LOB Ind),
,max(case             when z.cnst_mstr_subj_area_cd in ('PHSF', 'SABA', 'RCSO', 'RCST', 'SFCC', 'SFCO') or  z.line_of_service_cd = 'PHSS' then 'Y' else 'N' end)  as phss_lob_flg --(TITLE 'PHSS LOBFlag'),
,max(case             when z.cnst_mstr_subj_area_cd in ('PHSF', 'SABA', 'RCSO', 'RCST', 'SFCC', 'SFCO') or  z.line_of_service_cd = 'PHSS' then 1 else 0 end)  as phss_lob_ind --(TITLE 'PHSS LOB Ind'),
,max(case             when z.cnst_mstr_subj_area_cd in ('DRMS', 'BADW', 'ePID', 'NBCS', 'HEMO') or  z.line_of_service_cd = 'BIO' then 'Y' else 'N' end) as bio_lob_flg --(TITLE 'Biomed LOBFlag'),
,max(case             when z.cnst_mstr_subj_area_cd in ('DRMS', 'BADW', 'ePID', 'NBCS', 'HEMO') or  z.line_of_service_cd = 'BIO' then 1 else 0 end) as bio_lob_ind --(TITLE 'Biomed LOB Ind'),
,max(case             when z.cnst_mstr_subj_area_cd = 'VMS' or  z.line_of_service_cd = 'VMS' then 'Y' else 'N' end) as vms_lob_flg --(TITLE 'Volunteer LOBFlag')
,max(case             when z.cnst_mstr_subj_area_cd = 'VMS' or  z.line_of_service_cd = 'VMS' then 1 else 0 end)  as vms_lob_ind --(TITLE 'Volunteer LOB Ind')
,max(case             when z.cnst_mstr_subj_area_cd = 'CAS2' or  z.line_of_service_cd = 'DIS' then 'Y' else 'N' end) as dstr_lob_flg --(TITLE 'Disaster LOBFlag' )  
,case when fr_lob_ind + phss_lob_ind + bio_lob_ind + vms_lob_ind > 1 then 'Y' else 'N' end as multi_lob_flg
,case when fr_lob_ind + phss_lob_ind + bio_lob_ind + vms_lob_ind > 1 then 1 else 0 end as multi_lob_ind
,count( distinct z.cnst_mstr_subj_area_cd) as srcsys_cnt --(TITLE 'Source System Count')
from
(select distinct a.cnst_mstr_id, a.cnst_mstr_subj_area_cd, b.line_of_service_cd 
from eda.arc_mdm_vws.bz_cnst_mstr_bridge  a 
left join eda.arc_mdm_vws.bz_arc_srcsys b on a.cnst_mstr_subj_area_cd = b.arc_srcsys_cd
where a.row_stat_cd <>'L' 
) z
group by z.cnst_mstr_id
with no schema binding;