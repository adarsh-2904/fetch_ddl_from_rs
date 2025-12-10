create or REPLACE VIEW mktg_ops_vws.dim_volunteer 
/*
Created By; Michael Andrien
Create Date:08/16/2023
Purpose: Creating a version of this view in the mktg_ops_vws database so the MODS team can move the
Enterprise Cross-Mktg/Contact PBI model to the premium workspace.  The MODS team can only reference views from the mktg_ops_vws database
through the PBI gateway connection established for the team.  Note, the primary view definition is in vms_vws.
*/
AS 
SELECT	* 
FROM eda.vms_vws.dim_volunteer
with no schema binding;