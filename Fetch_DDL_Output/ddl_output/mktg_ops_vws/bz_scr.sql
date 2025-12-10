CREATE OR REPLACE VIEW mktg_ops_vws.bz_scr
AS

/* --------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 8/24/2016
Purpose: Created view in mktg_ops_vws to ensure all the views and tables exposed in the Aprimo universe are 
			replicated or available in the mktg_ops_vws database for Adobe Campaign to access.
Filters: 

Modified by: Majeed Mohammad
Modified date: 3/7/2017
Purpose: Updated the view to read the table mktg_ops_tbls.scr instead of the view arc_mdm_vws.bz_scr
-------------------------------------------------------------------------------- */

SELECT
	scr_id, --(TITLE 'Score Id'), 
	scr_strt_ts, --(TITLE 'Score Start Timestamp') AS scr_strt_ts,
	scr_end_ts, --(TITLE 'Score End Timestamp') AS scr_end_ts,
	nk_scr_cd, --(TITLE 'Nk Score Code'), 
	scr_dsc, --(TITLE 'Score Description'), 
	scr_versn, --(TITLE 'Score Version'), 
	dw_srcsys_trans_ts, --(TITLE 'Data Warehouse Source System Transaction Timestamp') AS dw_srcsys_trans_ts, 
	row_stat_cd, --(TITLE 'Row Status Code'), 
	appl_src_cd, --(TITLE 'Application Source Code'), 
	load_id --(TITLE 'Load Identifier')
FROM mktg_ops_tbls.scr 
WITH NO SCHEMA BINDING;