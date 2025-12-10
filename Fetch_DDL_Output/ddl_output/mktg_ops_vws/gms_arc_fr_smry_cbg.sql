CREATE OR REPLACE VIEW mktg_ops_vws.gms_arc_fr_smry_cbg
AS
/*
---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 02/11/2020
Purpose:  This view reflects the data that is loaded bthe the ld_gms_arc_fr_smry_cbg macro.  The view reflects which FR constituents are eligible for the Clara Barton Gold (CBG) program.  The macro calucuates the cumulative gift amount for the 
                                                                current and prior 2 years and returns one row per constituent master id with the date they qualified for the CBG program.  The macro will run daily and will trucate and
                                                                reload the mktg_ops_tbls.arc_fr_smry_cbg table.  This table is referenced in the mktg_ops_vws.arc_fr_smry view definition to set the respective CBG attributes in the 
                                                                arc_fr_smry view.

*/

SELECT	
	cnst_mstr_id, 
	cbg_eligblty_cym0_dt, 
	cbg_eligblty_cym1_dt,
	cbg_eligblty_cym2_dt
FROM mktg_ops_tbls.gms_arc_fr_smry_cbg
WITH NO SCHEMA BINDING;