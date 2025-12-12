CREATE OR REPLACE VIEW  mktg_ops_vws.bzfc_taxo_subscr_gplg 
/*
Created By:		Michael Andrien
Create Date:	06/06/2024
Purpose:	This view is a copy of the GOATS Gift Planning Lead Generation taxonomy created for 
and managed by the Planned Giving team.  We need to view in mktg_ops_vws to expose the view to 
the Adobe Campaign schema.  The view enables the MODS Ops team to personalize Planned Giving appeals at a 
chapter and regional grain.
*/
AS 
SELECT	
	zip_cd, zip_nm, gp_terr_cd, gp_terr_nm, gp_div_dir_cd, gp_div_dir_nm, gp_vp_cd, 
	gp_vp_nm, chapter_id, chapter_nm, region_id, region_nm, division_id, division_nm, 
	zipcode_city, zipcode_state, gpo_fnm, gpo_lnm, gpo_ttl, gpo_em, gpo_pn, gp_div_dir_fnm, gp_div_dir_lnm, 
	gp_div_dir_ttl, gp_div_dir_pn, gp_div_dir_em, gp_vp_fnm, gp_vp_lnm, gp_vp_ttl, gp_vp_pn, gp_vp_em, 
	region_city_nm, region_state_cd
FROM	eda.arc_goats_subscr_vws.bzfc_taxo_subscr_gplg
WITH NO SCHEMA BINDING;