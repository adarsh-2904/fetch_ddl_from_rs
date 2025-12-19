CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_operator
/*
Modified By: Michael Andrien
Modified Date: 11/25/24
Purpose: Updated the view to replace the ISP staff attributes fomerly loaded from the ISP staff external file posting on our 
shared SFTP site with staff data from the unified labor views found in ulds_vws.  The MODS team leveraged SQL from a PBI staff model provided by the ABI team.
*/
AS
 
SELECT 
--	bio_op.operator_key, 
	bio_op.operator_id,
	bio_op.operator_cd,-- as nk_operator_cd, 
	bio_op.first_nm, 
	bio_op.last_nm, 
	bio_op.operator_nm,
--	bio_op.suffix,
--	bio_op.cln_first_nm, 
--	bio_op.cln_last_nm, 
--	bio_op.cln_suffix, 
--	bio_op.valid_flg, 
	bio_op.preferred_language as language_cd,
--	bio_op.language_dsc, 
--	bio_op.site_cd, 
--	bio_op.lab_id, 
--	bio_op.status_cd, 
--	bio_op.status_dsc, 
--	bio_op.job_title,
--	bio_op.email_address, 
--	bio_op.operator_lvl, 
--	bio_op.avail_site_cd, 
--	bio_op.eff_from_ts, 
--	bio_op.eff_to_ts,
--	bio_op.eff_ts_key, 
--	bio_op.current_flg, 
--	bio_op.chng_reason_cd, 
--	bio_op.srcsys_ts, 
--	bio_op.dw_create_ts,
--	bio_op.dw_updt_ts, 
--	bio_op.row_stat_cd, 
--	bio_op.appl_src_cd, 
--	bio_op.load_id,
	labor.labor_key,
	labor.empl_id,
	labor.nk_region_id, 
	labor.labor_job_title, 
	labor.staff_nm,
	labor.staff_prefd_first_nm,
	labor.staff_prefd_last_nm,
	labor.staff_email_addr, 
	labor.staff_zip, 
	labor.mgr_labor_key,
	labor.staff_role, 
	labor.aphrss_wb_dsc, 
	labor.supervisor_nm, 
	labor.sl_supervisor_nm, 
	labor.isp_active_flg
FROM eda.bio_shipment_vws.bzl_dim_operator bio_op
LEFT JOIN  mods_bi.mktg_ops_vws.dim_isp_labor labor ON rtrim(upper(bio_op.operator_cd)) = rtrim(upper(labor.most_used_ebdrid))
WHERE 
	bio_op.operator_id <> 0 and labor.labor_key is not null 
--	AND bio_op.row_stat_cd <> 'L'
QUALIFY Row_Number() Over (PARTITION BY bio_op.operator_id /*ORDER BY bio_op.srcsys_ts DESC */ ) = 1
WITH NO SCHEMA BINDING

;