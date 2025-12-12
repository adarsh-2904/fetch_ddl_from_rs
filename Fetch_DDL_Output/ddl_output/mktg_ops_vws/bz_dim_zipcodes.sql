create or replace view mktg_ops_vws.bz_dim_zipcodes
/*
Modified by: Majeed Mohammad
Modified date: 12/16/2016
Purpose: Copied from 2580. Updated to point to dw_common_vws instead of the aprimo_lndng_tbls 

Modified By:		Mike Andrien
Modified Date:	12/19/2016
Purpose: 			ADM Team modified the dw_common_vw.dim_zipcodes view and change column names A,B,C,D,E and F to segment_grp_a, segment_grp_b, etc)

Purpose: Added the new One Red Cross (ORC) Division and Donor Services (DS) regions details to the view plus the attributes below.
	 default_city_nm, 
	 area_cd, 
	 county_cd, 
	 county_nm, 
	 TIMEZONE, 
	 utc_offset, 
	 dst_flg, 
	 orc_division_id, 
	 orc_division_name, 
	 ds_region_id, 
	 ds_region_name*/ 
as  
select	
	zip, 
	city, 
	state,
	 segment_grp_a, 
	 segment_grp_b, 
	 segment_grp_c,
	 segment_grp_d, 
	 segment_grp_e, 
	 segment_grp_f, 
	 loc_key, 
	 district_cd,
	 district_name, 
	 region_code, 
	 bcode, 
	 region_desc, 
	 geo_lat_lon_id,
	 geo_centriod_lat, 
	 geo_centriod_lon, 
	 default_city_nm, 
	 area_cd, 
	 county_cd, 
	 county_nm, 
	 TIMEZONE, 
	 utc_offset, 
	 dst_flg, 
	 orc_division_id, 
	 orc_division_name, 
	 ds_region_id, 
	 ds_region_name,
	 dw_create_by, 
	 dw_create_ts,
	 dw_updt_by, 
	 dw_updt_ts,
	 row_stat_cd, 
	 appl_src_cd, 
	 load_id
from	eda.dw_common_vws.dim_zipcodes
with no schema binding;