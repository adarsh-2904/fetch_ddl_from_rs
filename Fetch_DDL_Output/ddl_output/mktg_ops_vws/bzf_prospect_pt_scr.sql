CREATE OR REPLACE VIEW mktg_ops_vws.bzf_prospect_pt_scr AS 
-- mktg_ops_vws.bzf_prospect_pt_scr source

create or REPLACE VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Hall
Created date: 2018-01-30
Purpose: This is a  *dedeuped* view of the annual High Touch/ProspectPoint score data sent 
from Target Analytics for all ARC financial and non-financial constituents (where cnst_mstr_id = 0).  
ProspectPoint data contains a summary of  predictive attributes, 
including annual, major, planned, and target gift range scores across the ARC constituent population.
				
Note: This view joins the mktg_ops_vws.cnst_mstr_id_map view
          which is the CDI merge crosswalk view that maps any merged constituent ids.
		  This join was causing duplication as several different constituent master ID's
		  were merged into a single new constiuent master id. So, the MAX function was
		  applied across the numeric scores to yield a unique golden record with the highest scores
		  from multiple dupe rows.
		  
 Modified By:  Michael Hall
 Modified Date: 2020-06-30
 Purpose: Modified view to accommodate 2020 Target Analytics contract SOW changes.
                  - The Planned Giving Likelihood  (PGL) model score was removed.
                  - This was replaced with the Annuity Likelihood (AL) and Charitable Remainder Trust Likelihood (CRTL) scores.
				  
Modified By: Michael Hall
Modified Date: 2021-06-04
Purpose:  Removed unused score columns ann_like (Annual Gift Likelihood) and pg_like (Planned Giving Likelihood).
		  
------------------------------------------------------------------------------------------------------------------------------------ */
mktg_ops_vws.bzf_prospect_pt_scr
AS 
SELECT 
cnst_mstr_id, 
cnst_typ_cd,
MAX(past_gvr_typ_rtng) AS past_gvr_typ_rtng, 
MAX(vlcty_rtng) AS vlcty_rtng,
MAX(annuity_like) AS annuity_like, /* Annuity Likelihood (AL) score */
MAX(crt_like) AS crt_like, /* Charitable Remainder Trust Likelihood (CRTL) score */
MAX(pg_resp_like) AS pg_resp_like, /* Bequest Likelihood (BL) score */
MAX(maj_like) AS maj_like,  /* Major Giving Likelihood (MGL) score */
MAX(tgt_gft_rng_scr) AS tgt_gft_rng_scr,
MAX(prncpl_sltn_rtng) AS prncpl_sltn_rtng
FROM mktg_ops_vws.bz_prospect_pt_scr
GROUP BY 1,2
with no schema binding;