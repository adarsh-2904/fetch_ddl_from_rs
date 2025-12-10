CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_prospect_pt_scr_fin AS 
-- mktg_ops_vws.bzfc_prospect_pt_scr_fin source

create or REPLACE VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Hall
Created date: 2018-01-31
Purpose: This is a  *deduped* view of the annual High Touch/ProspectPoint score data sent 
from Target Analytics for all ARC Financial prospects.  
ProspectPoint data contains a summary of  predictive attributes, including annual, major, planned, 
and target gift range scores across the ARC constituent population.
				
Note: This view joins the mktg_ops_vws.cnst_mstr_id_map view
          which is the CDI merge crosswalk view that maps any merged constituent ids.
		  This join was causing duplication as several different constituent master ID's
		  were merged into a single new constiuent master id. So, the MAX function was
		  applied across the numeric scores to yield a unique golden record with the highest scores
		  from multiple dupe rows. This aggregattion function is applied in the source view named 
		  mktg_ops_vws.bzf_prospect_pt_scr.
		  
Modified By: Michael Andrien
Modified Date:	08/20/2021
Purpose: The view definition references the bzfc_prospect_pt_scr view and was selecting an ann_like attribute, which has been renamed to annuity_like.  Updated the view as shown below rather than renaming the 
attribute to avoid having the update the Adobe Campaign schema and other reports referencing the original column name.  Also, changed the pg_like row the crt_like.
	 annuity_like (TITLE 'Annual Gift Likelihood (0-1000)') as ann_like, 
	crt_like (TITLE 'Planned Gift Likelihood (0-1000)'), -- alias for crtlike (Charitable Remainder Trust Likelihood)
------------------------------------------------------------------------------------------------------------------------------------ */
mktg_ops_vws.bzfc_prospect_pt_scr_fin
AS 
SELECT 
cnst_mstr_id, 
past_gvr_typ_rtng,
CASE
   WHEN past_gvr_typ_rtng = 1 THEN 'Regular'
   WHEN past_gvr_typ_rtng = 2 THEN 'Occasional'
   WHEN past_gvr_typ_rtng = 3 THEN 'Non-Donor'
   END AS past_gvr_typ_dsc , 
vlcty_rtng,
CASE
   WHEN vlcty_rtng = 1   THEN 'Rising Star'
   WHEN vlcty_rtng = 2	THEN 'Slow and Steady'
   WHEN vlcty_rtng = 3	THEN 'At Risk'
   WHEN vlcty_rtng = 4	THEN 'NA'
   END AS vlcty_rtng_dsc , 
 annuity_like as ann_like, 
crt_like , -- alias for crtlike (Charitable Remainder Trust Likelihood)
pg_resp_like, -- alias for beqlike (Bequest Gift Likelihood)
maj_like, 
tgt_gft_rng_scr,
CASE
   WHEN tgt_gft_rng_scr  = 1   THEN  '$1-$50'
   WHEN  tgt_gft_rng_scr = 2   THEN  '$51-$100'
   WHEN  tgt_gft_rng_scr = 3   THEN  '$101-$250'
   WHEN  tgt_gft_rng_scr = 4   THEN  '$251-$500'
   WHEN  tgt_gft_rng_scr = 5   THEN  '$501-$1,000'
   WHEN  tgt_gft_rng_scr = 6   THEN  '$1,001-$2,500'
   WHEN  tgt_gft_rng_scr = 7   THEN  '$2,501-$5,000'
   WHEN  tgt_gft_rng_scr = 8   THEN  '$5,001-$10,000'
   WHEN  tgt_gft_rng_scr = 9   THEN  '$10,001-$25,000'
   WHEN  tgt_gft_rng_scr = 10 THEN  '$25,001-$50,000'
   WHEN  tgt_gft_rng_scr = 11 THEN  '$50,001-$100,000'
   WHEN  tgt_gft_rng_scr = 12 THEN  '$100,001 +'
   END AS tgt_gft_rng_dsc,
prncpl_sltn_rtng,
CASE
   WHEN prncpl_sltn_rtng = 1 THEN 'Tier 1'
   WHEN prncpl_sltn_rtng = 2 THEN 'Tier 2'
   WHEN prncpl_sltn_rtng = 3 THEN 'Tier 3'
   WHEN prncpl_sltn_rtng = 4 THEN 'Tier 4'
   END AS prncpl_sltn_dsc
FROM mktg_ops_vws.bzf_prospect_pt_scr
WHERE cnst_typ_cd = 'F' -- Financial prospects only;;
with no schema binding;