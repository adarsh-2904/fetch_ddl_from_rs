create or replace VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Created By: Mike Andrien
Created date: 18-Mar-2015
Purpose:This view selects all the arcpg characteristics related fields. NOTE: We need to replace the FROM 
 arc_mdm_vws.bzf_cnst_chrctrstc_arcpg  with aprimo_lndng_tbls.bzf_cnst_chrctrstc_arcpg
				once the ARCPG data in migrated to production.  This is a temporary view to satisfy ARC PG Testing.
Filters:NA

Modified By: Mike Andrien
Modified Date: 05/25/2016
Purpose:  Repointed the view definition to reference  aprimo_lndng_tbls.bzf_cnst_chrctrstc_arcpg rather than the arc_mdm_vws view.

Modified By: Mike Andrien
Modified Date: 08/31/2016
Purpose:  This view was created to mirror the views from the MKTG 2580 as part of the 2700 merge effort, we repointed the views
------------------------------------------------------------------------------------------------------------------------------------ */

mktg_ops_vws.bzf_cnst_chrctrstc_arcpg
AS

SELECT
  cnst_mstr_id,
  cnst_typ_cd,
  bzd_disability, 
  bzd_discount, 
 null as bzd_ethnicity,
  bzd_pg_arc_in_will,
  bzd_pg_closed_cga,
  bzd_pg_closed_pg,
  bzd_pg_closed_resp,
  bzd_pg_prev_resp,
  bzd_pg_seg_cga,  
  bzd_pg_seg_beq,  
  bzd_pg_seg_wg
FROM mktg_ops_vws.bzf_cnst_chrctrstc with no schema binding;