CREATE OR REPLACE VIEW mktg_ops_vws.srvy_vlntr_geogrphy_taxo
/*
Created By: Michael Andrien
Create Date: 12/17/2024
Purpose:  This view contains the humanitarian geography and is referenced in the normalized versions of the New Volunteer
and Volunteer Anniversary survey PBI reporting models.
*/
AS
SELECT 
	svp.cnst_mstr_id,
	CASE
		WHEN um1.nk_ecode <> '00000' AND um1.unit_zip IS NOT NULL THEN Coalesce(um1.unit_zip, '00000') 
		WHEN um2.nk_ecode <> '00000' AND um2.unit_zip IS NOT NULL THEN Coalesce(um2.unit_zip,'00000') 
		WHEN Coalesce(um1.unit_zip, '00000') = '00000' AND Coalesce(um2.unit_zip, '00000') = '00000' THEN svp.dm_cnst_zip_5_cd
		ELSE '00000'
	END AS attribtn_zip_5_cd,
	svp.unit_key,
	svp.mktg_unit_key,
	svp.mktg_unit_cd,
	gs.chapter_name AS unit_nm,
	Coalesce(gs.region_cd,'NHQ') AS region_cd,
	Coalesce(gs.region_name,'National Headquarters') AS region_nm,
	Coalesce(gs.division_cd, 'NHQ') AS division_cd,
	Coalesce(gs.division_name,'National Headquarters') AS division_dsc,
	dz.district_cd district_cd, 
	dz.district_name district_nm,
	dz.zip unit_zip,
	dz.orc_division_id, 
	dz.orc_division_name, 
	dz.ds_region_id, 
	dz.ds_region_name,
	dz.geo_lat_lon_ID, 
	dz.geo_centriod_lat, 
	dz.geo_centriod_lon,
	reg.region_nm AS bio_region_nm, 
	reg.division_dsc AS bio_division_dsc, 
	reg.ldrshp_nm
FROM mktg_ops_vws.cnst_cdi_smry_vms_prfr svp
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz ON svp.unit_cd= msz.nk_ecode /* 10/30/2019 - MTA modifiied the join svp.unit_cd = msz.nk_ecode */
LEFT JOIN mktg_ops_tbls.dim_unit_military_station_zips msz_mktg ON svp.mktg_unit_cd = msz_mktg.nk_ecode
LEFT JOIN mktg_ops_vws.dim_unit_merged um1 ON CASE /* This join gets the unit info based on the Military Station zip associated with the response */
		WHEN Coalesce(msz.nk_ecode,'00000') <> '00000' THEN msz.nk_ecode 
		WHEN Coalesce(msz_mktg.nk_ecode,'00000') <> '00000' THEN msz_mktg.nk_ecode
		ELSE '00000'
		END = um1.nk_ecode
LEFT JOIN mktg_ops_vws.dim_unit_merged um2 ON CASE /* This join gets the unit info based on the unit and mktg unit from the Volunteer preferred profile associated with the response */
		WHEN Coalesce(svp.unit_key,0) <> 0 THEN svp.unit_key
		WHEN Coalesce(svp.mktg_unit_key,0) <> 0 THEN svp.mktg_unit_key 
		ELSE '00000' 
		END = um2.orig_unit_key
LEFT JOIN eda.arc_goats_subscr_vws.bzfc_taxo_humanitarian_curr gs ON gs.zipcode_cd = CASE WHEN um1.nk_ecode <> '00000' AND um1.unit_zip IS NOT NULL THEN Coalesce(um1.unit_zip, '00000')
		WHEN um2.nk_ecode <> '00000' AND um2.unit_zip IS NOT NULL THEN Coalesce(um2.unit_zip,'00000')
		ELSE svp.dm_cnst_zip_5_cd
		END
LEFT JOIN eda.dw_common_vws.dim_zipcodes dz ON dz.zip = CASE WHEN um1.unit_zip IS NOT NULL THEN um1.unit_zip ELSE um2.unit_zip END
LEFT JOIN eda.dw_common_vws.dim_region reg ON Substring(dz.region_code,1,3) = reg.nk_region_id
WITH NO SCHEMA BINDING;