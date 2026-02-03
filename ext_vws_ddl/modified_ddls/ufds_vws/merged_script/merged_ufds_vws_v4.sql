CREATE OR REPLACE VIEW mods_bi.ufds_vws.bzl_gift_cnst_mstr_brg AS
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
FROM mods_bi.ufds_vws.gmpbz_gift_cnst_grp_brg AS giftbrid
INNER JOIN mods_bi.ufds_vws.gmpbz_gmp_cnst_cdi_bridge AS cdibrid
ON giftbrid.gmp_cnst_key = cdibrid.gmp_cnst_key
INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge AS mstrbrg
ON cdibrid.gmp_cnst_cdi_key = mstrbrg.cnst_mstr_subj_area_id
AND cdibrid.appl_src_cd = mstrbrg.cnst_mstr_subj_area_cd
INNER JOIN eda.arc_mdm_vws.bz_arc_srcsys AS srcsys
ON srcsys.arc_srcsys_cd = mstrbrg.cnst_mstr_subj_area_cd
AND srcsys.line_of_service_cd = 'FR'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.ufds_vws.bzl_gift_cnst_mstr_brg TO role mods_bi_writer;
GRANT SELECT ON TABLE mods_bi.ufds_vws.bzl_gift_cnst_mstr_brg TO role mods_bi_reader_vt;

CREATE OR REPLACE VIEW mods_bi.ufds_vws.gmpbz_gift_cnst_grp_brg AS
SELECT
gift_cnst_grp_key,
gmp_cnst_hst_key,
gmp_cnst_key,
row_eff_from_ts,
row_eff_to_ts,
cnst_role_cd,
cnst_role_dsc,
active_ind,
backed_out_ind,
back_out_reason_cd,
vendor_src_cd,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM mods_bi.ufds_vws.gmpbza_gift_cnst_grp_brg
WHERE bzd_curr_ind = 1
WITH NO SCHEMA BINDING;
GRANT ALL ON mods_bi.ufds_vws.gmpbz_gift_cnst_grp_brg TO role mods_bi_writer;
GRANT SELECT ON mods_bi.ufds_vws.gmpbz_gift_cnst_grp_brg TO role mods_bi_reader_vt;


CREATE OR REPLACE VIEW mods_bi.ufds_vws.gmpbza_gift_cnst_grp_brg AS
SELECT
gift_cnst_grp_key,
gmp_cnst_hst_key,
gmp_cnst_key,
row_eff_from_ts,
row_eff_to_ts,
cnst_role_cd,
cnst_role_dsc,
active_ind,
backed_out_ind,
back_out_reason_cd,
vendor_src_cd,
srcsys_create_ts ,
srcsys_update_ts ,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd,
CASE WHEN row_eff_to_ts = TIMESTAMP '9999-12-31 00:00:00'THEN 1 ELSE 0 END AS bzd_curr_ind
FROM cdigms_rep.gms_tbls.gift_cnst_grp_brg
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON mods_bi.ufds_vws.gmpbza_gift_cnst_grp_brg TO role mods_bi_writer;
GRANT SELECT ON mods_bi.ufds_vws.gmpbza_gift_cnst_grp_brg TO role mods_bi_reader_vt;
