CREATE OR REPLACE VIEW mktg_ops_vws.bz_prospect_pt_scr AS 
-- mktg_ops_vws.bz_prospect_pt_scr source

create or REPLACE VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Hall
Created date: 2017-01-05
Purpose: This is a view of the annual High Touch/ProspectPoint score data sent from Target Analytics for all
ARC financial and non-financial constituents (where cnst_mstr_id = 0).  
ProspectPoint data contains a summary of  predictive attributes, including 
annual, major, planned, and target gift range scores across the ARC constituent population.
				
Note: This view joins the mktg_ops_vws.cnst_mstr_id_map view
          which is the CDI merge crosswalk view that maps any merged constituent ids.
		  
 Modified By:  Michael Hall
 Modified Date:  2017-01-11
 Purpose: Modifed view to add new column for Household Id and 
                  to create a union for the two separate physical tables 
                  containing Financial and Non-financial constituents.
				  
 Modified By:  Michael Hall
 Modified Date:  2017-01-12
 Purpose: Modifed view to rename column Household Id  to 
                 Household Locator Address Id (hh_la_id).
				 
 Modified By:  Michael Hall
 Modified Date:  2018-01-30
 Purpose: Renamed original view from bzfc_prospect_pt_scr to bz_prospect_pt_scr
                 to account for constituent master id duplicates due to constituent merges and 
				 miscellaneous duplicate rows found in the Non-financial prospect data.
				 
  Modified By:  Michael Hall
 Modified Date:  2018-04-07
 Purpose: Modified view to pull data from new tables for financial and non-financial for 2017 transactions.
                  Financial rows are now located in the data_lab_mktg_tbls.prospect_pt_scr_fin table.
				  
  Modified By:  Michael Hall
 Modified Date:  2020-06-30
 Purpose: Modified view to accommodate 2020 Target Analytics contract SOW changes.
                  - The Planned Giving Likelihood  (PGL) model score was removed.
                  - This was replaced with the Annuity Likelihood (AL) and Charitable Remainder Trust Likelihood (CRTL) scores.
				  
 Modified By: Michael Hall
 Modified Date: 2021-06-04
 Purpose:  Removed unused score columns ann_like (Annual Gift Likelihood) and pg_like (Planned Giving Likelihood).

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ */
mktg_ops_vws.bz_prospect_pt_scr
as
SELECT 
CASE
WHEN cmm.new_cnst_mstr_id IS NOT NULL THEN cmm.new_cnst_mstr_id -- a merge has occurred, use new mstr id
ELSE pp.cnst_mstr_id END AS cnst_mstr_id, -- no merge, use given cnst_mstr_id
pp.cnst_mstr_id AS orig_cnst_mstr_id,
hh_la_id,
past_gvr_typ_rtng, 
past_gvr_typ_dsc, 
vlcty_rtng,
vlcty_rtng_dsc, 
annuity_like, /* Annuity Likelihood (AL) score */
crt_like, /* Charitable Remainder Trust Likelihood (CRTL) score */
pg_resp_like, /* Bequest Likelihood (BL) score */
maj_like, /* Major Giving Likelihood (MGL) score */
tgt_gft_rng_scr,
tgt_gft_rng_dsc, 
prncpl_sltn_rtng, 
prncpl_sltn_dsc,
cnst_typ_cd /* Financial constituent ('F') */
FROM data_lab_mktg_tbls.prospect_pt_scr_fin pp /*  PP scores for Financial constituents */
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map cmm /* join to master ID mapping table for any merges */
ON pp.cnst_mstr_id = cmm.cnst_mstr_id
UNION ALL
SELECT 
CASE
WHEN cmm.new_cnst_mstr_id IS NOT NULL THEN cmm.new_cnst_mstr_id /* a merge has occurred, use new mstr id */
ELSE pp.cnst_mstr_id END AS cnst_mstr_id, /* no merge, use given cnst_mstr_id */
pp.cnst_mstr_id AS orig_cnst_mstr_id,
hh_la_id,
past_gvr_typ_rtng, 
past_gvr_typ_dsc, 
vlcty_rtng,
vlcty_rtng_dsc, 
annuity_like, /* Annuity Likelihood (AL) score */
crt_like, /* Charitable Remainder Trust Likelihood (CRTL) score */
pg_resp_like,  /* Bequest Likelihood (BL) score */
maj_like, /* Major Giving Likelihood (MGL) score */
tgt_gft_rng_scr,
tgt_gft_rng_dsc, 
prncpl_sltn_rtng, 
prncpl_sltn_dsc,
cnst_typ_cd /* Non-financial constituent ('N') */
FROM data_lab_mktg_tbls.prospect_pt_scr_nf pp  /* PP scores for Non-financial constituents */
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map cmm /* join to master ID mapping table for any merges */
ON pp.cnst_mstr_id = cmm.cnst_mstr_id
with no schema binding;