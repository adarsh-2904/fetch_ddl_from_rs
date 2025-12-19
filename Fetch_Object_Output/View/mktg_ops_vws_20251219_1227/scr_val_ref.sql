CREATE OR REPLACE VIEW mktg_ops_vws.scr_val_ref
AS
/* 

Created by: Majeed Mohammad
Created date: 09/20/2017
Purpose: This view does the union of the score value reference table from the mktg_ops_tbls and the data_lab_mktg_tbls database.

Modified by: Majeed Mohammad
Modified date: 06/18/2018
Purpose: Added the trim to the scr_val column 
  */

SELECT 
	scr_id, trim(scr_val) as scr_val, 
	scr_val_dsc, active_ind, 
	scr_strt_ts, scr_end_ts, 
	dw_srcsys_trans_ts, 
	row_stat_cd, 
	appl_src_cd, 
	load_id 
FROM mktg_ops_tbls.scr_val_ref 
UNION
SELECT 
	scr_id, trim(scr_val) as scr_val, 
	scr_val_dsc, active_ind, 
	scr_strt_ts, scr_end_ts, 
	dw_srcsys_trans_ts, 
	row_stat_cd, 
	appl_src_cd, 
	load_id 
FROM data_lab_mktg_tbls.scr_val_ref 
WITH NO SCHEMA BINDING
;