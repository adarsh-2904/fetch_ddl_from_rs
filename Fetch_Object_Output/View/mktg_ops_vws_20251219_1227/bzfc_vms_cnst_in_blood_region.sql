create or REPLACE VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 02-04-2116
Purpose: This view is an extension to the cnst_cdi_smry_vms_prfr view.  The view has a 1:1 relationship with the cnst_cdi_smry_vms_prfr view.
    The view uses the zip code from the cnst direct mail address in the VMS Preferred  view and the zip code from the unit affiliated with the VMS cnst 
    and determines whether a blood region is associated with either zip code.  If the preferred address zip is populated, then we use this to set the 
    in_blood_region_ind.  Otherwise we set the indicator based on the unit zip code.  NOTE: Some chapters are not associated with a blood region.  This 
    view is joined to the chapter affiliation unit key in the cnst_cdi_smry_vms_prfr (VMS Preferred) view to determine whether the chapter associated with the
    VMS constituent is serviced by a blood region.  The Marketing Ops team uses this to send blood donation appeals to fundraising constituents.  
    We don't want to send the appeals to VMS constituents that are not in a region that collects blood.  The in_blood_region_ind indicator reflects whether the cnst is in a blood region (1) or not in a blood region (0).  

Modified by: Michael Andrien
Modified date: 02/20/2019
Purpose: Modified the zi and z2 joins to do an inner join to the dim_region table. We added these joins because we discovered the dim_zip_codes view had many rows with invalid, but non-NULL region code details.

 Modified by: Michael Andrien
Modified date: 10/16/2020
Purpose:	Replaced reference to aprimo_wrk_tbls.dim_unit with mktg_ops_vws.dim_unit.  Retired aprimo_wrk_tbls.
----------------------------------------------------------------------- 
*/
mktg_ops_vws.bzfc_vms_cnst_in_blood_region AS
SELECT
    cnst_mstr_id,
    vms.unit_key,
    
    -- This indicator reflects whether a blood region is associated with the VMS DM preferred address zip code
    CASE WHEN z1.region_code IS NULL THEN 0 ELSE 1 END AS in_dm_zip_region_ind,
    
    -- This indicator reflects whether a blood region is associated with the chapter address zip code
    CASE WHEN z2.region_code IS NULL THEN 0 ELSE 1 END AS unit_zip_in_region_ind,
    
    -- This indicator reflects whether the constituent is in a blood region based on preferred DM zip or unit zip
    COALESCE(
        CASE 
            WHEN vms.dm_cnst_zip_5_cd IS NOT NULL THEN 
                CASE WHEN z1.region_code IS NULL THEN 0 ELSE 1 END
            ELSE 
                CASE WHEN z2.region_code IS NULL THEN 0 ELSE 1 END
        END,
        0
    ) AS in_blood_region_ind

FROM mktg_ops_vws.cnst_cdi_smry_vms_prfr vms 

LEFT JOIN mktg_ops_vws.dim_unit b 
    ON vms.unit_key = b.unit_key

LEFT JOIN (
    SELECT x.zip, x.region_code
    FROM eda.dw_common_vws.dim_zipcodes x
    INNER JOIN eda.dw_common_vws.dim_region y 
        ON x.region_code = y.nk_region_id
) z1 
    ON vms.dm_cnst_zip_5_cd = z1.zip

LEFT JOIN (
    SELECT x.zip, x.region_code
    FROM eda.dw_common_vws.dim_zipcodes x
    INNER JOIN eda.dw_common_vws.dim_region y 
        ON x.region_code = y.nk_region_id
) z2 
    ON b.unit_zip = z2.zip
with no schema binding;