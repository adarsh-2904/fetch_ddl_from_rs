CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fr_cnst_in_blood_region AS 
-- mktg_ops_vws.bzfc_fr_cnst_in_blood_region source
/* View mktg_ops_vws.bzfc_fr_cnst_in_blood_region  */
create or REPLACE VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 02-04-2116
Purpose: This view is an extension to the cnst_cdi_smry_fr_prfr view.  The view has a 1:1 relationship with the cnst_cdi_smry_fr_prfr view.
    The view uses the zip code from the cnst direct mail address in the FR Preferred  view and the zip code from the unit affiliated with the FR cnst 
    and determines whether a blood region is associated with either zip code.  If the preferred address zip is populated, then we use this to set the 
    in_blood_region_ind.  Otherwise we set the indicator based on the unit zip code.  NOTE: Some chapters are not associated with a blood region.  This 
    view is joined to the chapter affiliation unit key in the cnst_cdi_smry_fr_prfr (FR Preferred) view to determine whether the chapter associated with the
    FR constituent is serviced by a blood region.  The Marketing Ops team uses this to send blood donation appeals to fundraising constituents.  
    We don't want to send the appeals to FR constituents that are not in a region that collects blood.  The in_blood_region_ind indicator reflects whether the cnst is in a blood region (1) or not in a blood region (0).  

Modified by: Majeed Mohammad
Modified date: 12/16/2016
Purpose: Copied from 2580

Modified by: Michael Andrien
Modified date: 02/20/2019
Purpose: Modified the zi and z2 joins to do an inner join to the dim_region table. We added these joins because we discovered the dim_zip_codes view had many rows with invalid, but non-NULL region code details.

 Modified by: Michael Andrien
Modified date: 10/16/2020
Purpose:	Replaced reference to aprimo_wrk_tbls.dim_unit with mktg_ops_vws.dim_unit.  Retired aprimo_wrk_tbls.  Also replaced aprimo_wrk_tbls.cnst_cdi_smry_fr_prfr with mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr
------------------------------------------------------------------------------------------------------------------------------------ */
mktg_ops_vws.bzfc_fr_cnst_in_blood_region AS
select 
 frp.cnst_mstr_id, 
 frp.unit_key, 
 case when z1.Region_Code is null then 0 else 1 end  as in_dm_zip_region_ind, -- This indicator reflects whether a blood region is associated with the FR DM preferred address zip code
 case when z2.Region_Code is null then 0 else 1 end  as unit_zip_in_region_ind , -- This indicator reflects whether a blood region is associated with the chapter address zip code
 coalesce(case when frp.dm_cnst_zip_5_cd is not null then in_dm_zip_region_ind else unit_zip_in_region_ind end,0)  as in_blood_region_ind
from  mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr frp
left join mktg_ops_vws.dim_unit b on frp.unit_key = b.unit_key
left join (select zip, region_code from eda.dw_common_vws.dim_zipcodes x
                inner join eda.dw_common_vws.dim_region y on x.Region_Code=y.nk_region_id) z1 on collate(frp.dm_cnst_zip_5_cd::text,'CS')=collate(z1.zip::text,'CS') -- this join is used to derive the in_blood_region_ind based on the FR Preferred DM zip code
left join (select zip, region_code from eda.dw_common_vws.dim_zipcodes x
                inner join eda.dw_common_vws.dim_region y on x.Region_Code=y.nk_region_id) z2 on z2.zip = b.unit_zip
with no schema binding;