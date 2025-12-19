create or REPLACE VIEW mktg_ops_vws.bz_pg_src_convrsn 
/*

Created by: Michael Andrien
Create date: 10/04/2019
Purpose: The purpose of the Planned Giving (PG) Source Code Conversion table is to remap legacy PG source codes to the new source code format that was adopted in 2019.  The data teams were not able to apply
the updates to the Team Approach source system and agrees the best method for capturing the updates for reporting purposes was to create a conversion table in the Marketing subject area in the EDW.  The translation 
table was provided by Rich Reider from the PG team and loaded by the MODS team into the mktg_ops_tbls database.  This view is referenced in the following Marketing views that expose the Fundraising/Gift source codes to our Mktg resporting environment
	- mktg_ops_vws.bz_comnictn_src
	- mktg_ops_vws.bzfc_comnictn_src
The GMS replacement view will reference the table/view as well - mktg_ops_vws.gmpbz_dim_src

*/
AS 
SELECT	
	orig_src_cd, 
	orig_src_dsc, 
	new_src_cd, 
	new_src_dsc
FROM mktg_ops_tbls.pg_src_convrsn
with no schema BINDING;