CREATE OR REPLACE VIEW mktg_ops_vws.dim_unit AS 
-----------------------------------------------------------------------------------------------------------
-------------=======mktg_ops_vws.dim_unit source======================================--------------------
-----------------------------------------------------------------------------------------------------------
--drop view if exists VIEW mktg_ops_vws.dim_unit
CREATE OR REPLACE VIEW mktg_ops_vws.dim_unit AS
/* Created By Micael Andrien - Original Create date - unknown
Modified 07/17/14 - Added 'TR' to the Unit Type constraint to include Regional Unit Type Records.  Requested by Alex Fulton
to support Crossroads Newletter.

Created By:	 	Michael Andrien
Create Date:	08/01/2018
Purpose:			Added AFES Stations ('M') to the unit type codes to include in the view

Modified By:  Michael Andrien
Modified Date: 4/4/2019
Purpose: Added NHQ unit record (unit_type_cd = 'N'

Modified By:  Michael Andrien
Modified Date: 08/28/2019
Purpose: Added join to the mktg_ops_tbls.dim_unit_military_station_zips table to set a default zip code value for SAF/Military Stations.  The FOCIS team provided the default zip value and the MODS team
loaded the data from a spreadsheet.  We applied this update for our Vol Survey reports to ensure credit is applied the the correct chapter codes in reporting.  The business unit needs the zip code to match the chapter.
Since the zip code on the original dim_unit SAF Station records was NULL, the reports were assigning the volunteer zip, which in many cases does not align with the unit zip.  This caused issues in Vol reports.

Modified by: Michael Andrien
Modified date: 10/16/2020
Purpose: Replaced aprimo_wrk_tbls reference in view header and added table alias to cs resion attributes.

Modified By: Michael Andrien
Modified Date: 12/18/2024
Purpose:	Added unit type 'R' to the view definition to inclde ecode 30140, 
which appears to be miscoded.
*/
SELECT 
    unit_key, a.nk_ecode, nk_branch_cd, branch_cd, branch_typ,
    branch_short_dsc, branch_long_dsc, hcms_co_cd, unit_typ_cd, unit_typ_dsc,
    a.unit_nm, sd_region_cd, sd_region_nm, srvc_area_cd, srvc_area_nm,
    hq_cd, hq_nm, state_grp_cd, state_grp_nm, peer_grp_cd, unit_addr,
    unit_city_nm, unit_state_cd, unit_state_nm,
    CASE WHEN a.unit_zip IS NULL AND c.zip_cd IS NOT NULL THEN c.zip_cd ELSE a.unit_zip END AS unit_zip, 
    accntng_dsc,
    status_dsc, status_dt, status2_dsc, status2_dt, merged_cd, prin_chapt,
    prim_chapt, active_flg, scope_cd, metro_flg, UIN_flg, BCD_flg,
    size_fld, srvc_area_city_nm, srvc_area_phone_num, srvc_area_exec_nm,
    main_unit_city_nm, main_unit_state_cd, main_unit_state_nm, a.cs_region_cd,
    a.cs_region_nm, a.cs_region_typ_dsc, a.division_cd, a.division_dsc, a.prior_division_cd,
    prior_division_dsc, coe_cd, coe_typ, coe_nm, hster_div_cd, hster_cd,
    hster_nm, prreg_cd, prreg_typ, prreg_nm, gl_loc_cd, gl_phss_loc_cd,
    row_stat_cd, dw_srcsys_ts, appl_src_cd, load_id, 
    b.cdrp_enrollment_sts,
    b.cdrp_enrollment_sts_desc,
    b.chapter_supp_flg
FROM eda.dw_common_vws.dim_unit a
LEFT JOIN mktg_ops_vws.nhqmktg_cdrp_enrllmnt_sts b ON a.nk_ecode = b.chapter_cd AND a.appl_src_cd = 'focs' AND a.unit_typ_cd = 'c'
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips c ON a.nk_ecode = c.nk_ecode
WHERE a.appl_src_cd = 'FOCS'
AND a.unit_typ_cd IN ('C', 'TR', 'M', 'N', 'R')
with no schema binding;