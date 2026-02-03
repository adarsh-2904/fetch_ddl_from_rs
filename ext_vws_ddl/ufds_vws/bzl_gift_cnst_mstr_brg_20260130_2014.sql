CREATE OR REPLACE VIEW ufds_vws.bzl_gift_cnst_mstr_brg AS
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Created By:  GMS Power BI
Created On: April 6 2020
Purpose: View created on top of ufds_vws.gmpbz_gift_cnst_grp_brg for Power BI reporting Purpose

Updated By: GMS Dev Team
Updated On: June 29, 2023
Purpose: Added ufds_vws.gmpbz_gmp_cnst_cdi_bridge to fetch all the gmp_cnst_key's of each donor for GMS-34984
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT
mstrbrg.cnst_mstr_id,
giftbrid.gift_cnst_grp_key
FROM eda.ufds_vws.gmpbz_gift_cnst_grp_brg AS giftbrid
INNER JOIN eda.ufds_vws.gmpbz_gmp_cnst_cdi_bridge AS cdibrid
ON giftbrid.gmp_cnst_key = cdibrid.gmp_cnst_key
INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge AS mstrbrg
ON cdibrid.gmp_cnst_cdi_key = mstrbrg.cnst_mstr_subj_area_id
AND cdibrid.appl_src_cd = mstrbrg.cnst_mstr_subj_area_cd
INNER JOIN eda.arc_mdm_vws.bz_arc_srcsys AS srcsys
ON srcsys.arc_srcsys_cd = mstrbrg.cnst_mstr_subj_area_cd
AND srcsys.line_of_service_cd = 'FR'
WITH NO SCHEMA BINDING;