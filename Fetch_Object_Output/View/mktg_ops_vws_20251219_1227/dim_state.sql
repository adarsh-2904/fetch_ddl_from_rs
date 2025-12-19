CREATE OR REPLACE VIEW mktg_ops_vws.dim_state AS 
create or REPLACE  VIEW mktg_ops_vws.dim_state  
/*
	Created By:  Michael Andrien
	Create Date: 6/7/2018
	Purpose: MODS Ops team needs to include state name/description in some email messages.  They need the view in mktg_ops_vws to import the view definition
				into the Adobe schema definition.

*/
AS 
SELECT 
	state_key, 
	state_cd, 
	state_dsc, 
	row_stat_cd, 
	dw_trans_ts, 
	appl_src_cd, 
	load_id	
FROM  eda.dw_common_vws.dim_state with no schema binding;