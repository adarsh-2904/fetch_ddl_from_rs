CREATE OR REPLACE VIEW mktg_ops_vws.srvy_new_vlntr_los AS 
-- drop view mktg_ops_vws.srvy_new_vlntr_los

CREATE OR REPLACE VIEW mktg_ops_vws.srvy_new_vlntr_los
/*
Created By: 	Michael Andrien
Create Date:	09/03/2025
Purpose: This view was modeled after the srvy_vlntr_los view, which reflects a volunteer's current lines of service (LOS).  This view differs
from the srvy_vlntr_los view in that it reflects the volunteer LOS at the time the new volunteer survey was sent to the volunteer.  We created
this view to allow the LOS to be included in the PowerBI (PBI) reporting model.

Modified By:    Michael Andrien
Modified Date: 09/12/2025
Purpose: Added the condition below to the ON clause in left join for table 'e'
   AND e.srvy_sent_dt BETWEEN b.start_dt AND Coalesce(b.end_dt, Current_Date)
*/
as

with srvy_nw_vlntr_loss as (
		
	SELECT
	a.cnst_mstr_id, 
    a.delivery_label, 
    a.srvy_sent_dt,
	CASE WHEN biomed_srvc_cnt > 0 THEN 1 ELSE 0 END AS biomed_srvc_ind, 
	CASE WHEN comm_pa_srvc_cnt > 0 THEN 1 ELSE 0 END AS comm_pa_srvc_ind, 
	CASE WHEN corp_fin_srvc_cnt > 0 THEN 1 ELSE 0 END AS corp_fin_srvc_ind, 
	CASE WHEN corp_mgt_srvc_cnt > 0 THEN 1 ELSE 0 END AS corp_mgt_srvc_ind, 
	CASE WHEN dev_fr_srvc_cnt > 0 THEN 1 ELSE 0 END AS dev_fr_srvc_ind, 
	CASE WHEN distr_srvc_cnt > 0 THEN 1 ELSE 0 END AS distr_srvc_ind, 
	CASE WHEN divrsty_srvc_cnt > 0 THEN 1 ELSE 0 END AS divrsty_srvc_ind,
	CASE WHEN gov_rel_srvc_cnt > 0 THEN 1 ELSE 0 END AS gov_rel_srvc_ind,
	CASE WHEN hr_srvc_cnt > 0 THEN 1 ELSE 0 END AS hr_srvc_ind,
	CASE WHEN hs_srvc_cnt > 0 THEN 1 ELSE 0 END AS hs_srvc_ind, 
	CASE WHEN it_srvc_cnt > 0 THEN 1 ELSE 0 END AS it_srvc_ind,
	CASE WHEN intnl_srvc_cnt > 0 THEN 1 ELSE 0 END AS intnl_srvc_ind,
	CASE WHEN ogc_srvc_cnt > 0 THEN 1 ELSE 0 END AS ogc_srvc_ind,
	CASE WHEN mktg_srvc_cnt > 0 THEN 1 ELSE 0 END AS mktg_srvc_ind,	
	CASE WHEN non_core_cs_cnt > 0 THEN 1 ELSE 0 END AS non_core_cs_ind,
	CASE WHEN ops_cnt > 0 THEN 1 ELSE 0 END AS ops_ind,
	CASE WHEN re_srvc_cnt > 0 THEN 1 ELSE 0 END AS re_srvc_ind,
	CASE WHEN saf_srvc_cnt > 0 THEN 1 ELSE 0 END AS saf_srvc_ind,
	CASE WHEN sustnblty_srvc_cnt > 0 THEN 1 ELSE 0 END AS sustnblty_srvc_ind,
	CASE WHEN ts_srvc_cnt > 0 THEN 1 ELSE 0 END AS ts_srvc_ind,
	CASE WHEN vol_srvc_cnt > 0 THEN 1 ELSE 0 END AS vol_srvc_ind,
	CASE WHEN youth_srvc_cnt > 0 THEN 1 ELSE 0 END AS youth_srvc_ind,
	'(' || (CASE WHEN biomed_srvc_cnt > 0 THEN 'Biomedical Services' ELSE '|' end) 
	|| (CASE WHEN comm_pa_srvc_cnt > 0 THEN 'Communications' ELSE '|' end)
	|| (CASE WHEN corp_fin_srvc_cnt > 0 THEN 'Accounting/Finance' ELSE '|' end) 
	|| (CASE WHEN corp_mgt_srvc_cnt > 0 THEN 'Chapter Leadership (boards, CVLs, etc.)' ELSE '|' end) 
	|| (CASE WHEN dev_fr_srvc_cnt > 0 THEN 'Fundraising/Financial Development' ELSE '|' end) 
	|| (CASE WHEN distr_srvc_cnt > 0 THEN 'Disaster Cycle Services' ELSE '|' end) 
	|| (CASE WHEN divrsty_srvc_cnt > 0 THEN 'Diversity & Inclusion' ELSE '|' end) 
	|| (CASE WHEN gov_rel_srvc_cnt > 0 THEN 'Government Relations' ELSE '|' end) 
	|| (CASE WHEN hr_srvc_cnt > 0 THEN 'Human Resources' ELSE '|' end) 
	|| (CASE WHEN hs_srvc_cnt > 0 THEN 'Humanitarian Operations (goals & metrics)' ELSE '|' end) 
	|| (CASE WHEN it_srvc_cnt > 0 THEN 'Information Technology' ELSE '|' end) 
	|| (CASE WHEN intnl_srvc_cnt > 0 THEN 'International Services' ELSE '|' end) 
	|| (CASE WHEN ogc_srvc_cnt > 0 THEN 'Legal (OGC)/Risk Management' ELSE '|' end) 
	|| (CASE WHEN mktg_srvc_cnt > 0 THEN 'Marketing' ELSE '|' end)
	|| (CASE WHEN non_core_cs_cnt > 0 THEN 'Community Services (FAST, food banks, etc.)' ELSE '|' end)
	|| (CASE WHEN ops_cnt > 0 THEN 'Humanitarian Operations (goals & metrics)' ELSE '|' end)
	|| (CASE WHEN re_srvc_cnt > 0 THEN 'Real Estate Services' ELSE '|' end)
	|| (CASE WHEN saf_srvc_cnt > 0 THEN 'Service to the Armed Forces' ELSE '|' end)
	|| (CASE WHEN sustnblty_srvc_cnt > 0 THEN 'Sustainability' ELSE '|' end)
	|| (CASE WHEN ts_srvc_cnt > 0 THEN 'Training Services (CPR, First Aid, etc.)' ELSE '|' end)
	|| (CASE WHEN vol_srvc_cnt > 0 THEN 'Volunteer Services' ELSE '|' end)
	|| (CASE WHEN youth_srvc_cnt > 0 THEN 'Youth & Young Adult Programs' ELSE '|' end) 
	|| ')'
	AS concat_los_txt,
	Row_Number() Over (PARTITION BY cnst_mstr_id, delivery_label ORDER BY  srvy_sent_dt ASC) as rn
	FROM 
	(
	SELECT 
		vp.cnst_mstr_id,
	    e.delivery_label, 
	    e.srvy_sent_dt,
		Sum(CASE WHEN d.service_name = 'Biomedical Services' THEN 1 ELSE 0 end) AS biomed_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Communications/Public Affairs' THEN 1 ELSE 0 end) AS comm_pa_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Corporate Finance' THEN 1 ELSE 0 end) AS corp_fin_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Corporate Management & Oversight' THEN 1 ELSE 0 end) AS corp_mgt_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Development/Fundraising' THEN 1 ELSE 0 end) AS dev_fr_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Disaster Cycle Services' THEN 1 ELSE 0 end) AS distr_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Diversity & Inclusion' THEN 1 ELSE 0 end) AS divrsty_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Government Relations' THEN 1 ELSE 0 end) AS gov_rel_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Human Resources' THEN 1 ELSE 0 end) AS hr_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Humanitarian Services' THEN 1 ELSE 0 end) AS hs_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Information Technology' THEN 1 ELSE 0 end) AS it_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'International Services' THEN 1 ELSE 0 end) AS intnl_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Legal (OGC)/Risk Management' THEN 1 ELSE 0 end) AS ogc_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Marketing' THEN 1 ELSE 0 end) AS mktg_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Non-Core Community Services' THEN 1 ELSE 0 end) AS non_core_cs_cnt,
		Sum(CASE WHEN d.service_name = 'Operations' THEN 1 ELSE 0 end) AS ops_cnt,
		Sum(CASE WHEN d.service_name = 'Real Estate Services' THEN 1 ELSE 0 end) AS  re_srvc_cnt,
		Sum(CASE WHEN d.service_name IN('Services to Armed Forces', 'Service to the Armed Forces', 'Services for Military and Veteran Communities') THEN 1 ELSE 0 end) AS saf_srvc_cnt ,
		Sum(CASE WHEN d.service_name = 'Sustainability' THEN 1 ELSE 0 end) AS sustnblty_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Training Services' THEN 1 ELSE 0 end) AS ts_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Volunteer Services' THEN 1 ELSE 0 end) AS vol_srvc_cnt,
		Sum(CASE WHEN d.service_name = 'Youth and Young Adults' THEN 1 ELSE 0 end) AS youth_srvc_cnt
	FROM mktg_ops_vws.cnst_cdi_smry_vms_prfr vp
	LEFT JOIN eda.arc_mdm_vws.cnst_mstr_bridge mb ON (vp.cnst_mstr_id = mb.cnst_mstr_id) AND mb.cnst_mstr_subj_area_cd = 'VMS'
	LEFT JOIN eda.vms_vws.dim_volunteer a ON a.vol_key = mb.cnst_mstr_subj_area_id
	LEFT JOIN eda.vms_vws.fact_placement b ON a.vol_key = b.vol_key
	LEFT JOIN eda.vms_vws.dim_position c ON b.position_key = c.position_key
	LEFT JOIN mktg_stage_tbls.lkp_positions_taxonomy_mktg_stg d ON d.placement_id = c.nk_placement_sku
	LEFT JOIN 
	(
	    SELECT c.bicnst_mstr_id, b.delivery_nm, b.delivery_label, Cast(a.tsevent AS DATE)
	    FROM mktg_ops_vws.bz_adb_nmsbroadlogrcp a
	    LEFT JOIN mktg_ops_vws.bz_dim_delivery b ON a.ideliveryid = b.nk_delivery_id
	    LEFT JOIN mktg_ops_vws.bz_adb_nmsrecipient c ON a.irecipientid = c.irecipientid
	    WHERE 
	        b.delivery_label LIKE '%VMS New Volunteer Survey%'
	        AND Cast(a.tsevent AS DATE) >= '07/01/2024'
	) e (cnst_mstr_id, delivery_nm, delivery_label, srvy_sent_dt) ON vp.cnst_mstr_id = e.cnst_mstr_id AND e.srvy_sent_dt BETWEEN b.start_dt AND Coalesce(b.end_dt, Current_Date)
	WHERE 
	    e.srvy_sent_dt IS NOT NULL
	    AND e.srvy_sent_dt BETWEEN b.start_dt AND Coalesce(b.end_dt, Current_Date)
	GROUP BY 1,2,3
	) a (cnst_mstr_id, delivery_label,srvy_sent_dt, biomed_srvc_cnt, comm_pa_srvc_cnt, corp_fin_srvc_cnt, corp_mgt_srvc_cnt, dev_fr_srvc_cnt, distr_srvc_cnt, divrsty_srvc_cnt,gov_rel_srvc_cnt,hr_srvc_cnt,
		hs_srvc_cnt,it_srvc_cnt, intnl_srvc_cnt,ogc_srvc_cnt,mktg_srvc_cnt,non_core_cs_cnt,ops_cnt,re_srvc_cnt,saf_srvc_cnt,
		sustnblty_srvc_cnt,ts_srvc_cnt,vol_srvc_cnt,youth_srvc_cnt)

)
select 
  cnst_mstr_id, 
  delivery_label, 
  srvy_sent_dt, 
  biomed_srvc_ind, 
  comm_pa_srvc_ind, 
  corp_fin_srvc_ind, 
  corp_mgt_srvc_ind, 
  dev_fr_srvc_ind, 
  distr_srvc_ind, 
  divrsty_srvc_ind, 
  gov_rel_srvc_ind, 
  hr_srvc_ind, 
  hs_srvc_ind, 
  it_srvc_ind, 
  intnl_srvc_ind, 
  ogc_srvc_ind, 
  mktg_srvc_ind, 
  non_core_cs_ind, 
  ops_ind, 
  re_srvc_ind, 
  saf_srvc_ind, 
  sustnblty_srvc_ind, 
  ts_srvc_ind, 
  vol_srvc_ind, 
  youth_srvc_ind, 
  concat_los_txt 
from 
  srvy_nw_vlntr_loss
where rn=1


WITH NO SCHEMA BINDING;