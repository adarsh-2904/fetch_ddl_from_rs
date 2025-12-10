CREATE OR REPLACE VIEW mktg_ops_vws.cnst_mstr_id_map 
/*
Created By Michael Andrien
Create Date 5/1/2016
Purpose: 	The view provides access to the Stuart view that maps merged CDI master id records to the proper new_cnst_mstr_id
*/
AS
SELECT 
	constituent_id as cnst_mstr_id,
	new_cnst_mstr_id
FROM eda.dw_stuart_vws.cnst_mstr_id_map
with no schema binding;