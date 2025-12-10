CREATE OR REPLACE VIEW mktg_ops_vws.arc_biomed_gender_race AS 
-- mktg_ops_vws.arc_biomed_gender_race source

CREATE OR REPLACE VIEW mktg_ops_vws.arc_biomed_gender_race
/*
Created by:	Michael Andrien
Created Date 06/25/2018
Purpose:	Expose biomed gender and race data to Adobe.  Data pulled from record in ubds_vws.bzl_dim_cnst_unf view with the most recent transaction date.  Other 
			attributes from the unf view can be included if needed in future lists.
			
Updated by:	  Adarsh Ram
Updated Date: 09/19/2025
Purpose:	  Renamed race_cd to race_id, used most_recent_any_visit_dt instead of bz_volntr_visit_dt_last 
*/


as 
select 
			cnst_mstr_id,
			gender_cd, 
			--b.bz_race_cd, 
			race_id,
			race_description
			
from (

			select 
			a.cnst_mstr_id,
			b.gender_cd, 
			--b.bz_race_cd, 
			b.race_id,
			b.race_description,
			ROW_NUMBER() OVER (PARTITION BY a.cnst_mstr_id ORDER BY  b.most_recent_any_visit_dt desc) as rn
			
from mktg_ops_vws.cnst_cdi_smry_bio_prfr a
left join(
	select eb.cnst_mstr_id, dn.donor_external_id, dn.gender_id,dn.race_id,rc.race_description, gn.gender_cd, dn.most_recent_any_visit_dt
	from eda.arc_mdm_vws.bz_cnst_mstr_external_brid eb join eda.bio_donation_vws.bz_dim_donor dn on eb.cnst_srcsys_scndry_id=dn.donor_external_id
	join eda.bio_donation_vws.bz_dim_gender gn on dn.gender_id = gn.gender_id
	join eda.bio_donation_vws.bz_dim_race rc on dn.race_id = rc.race_id
	) b (cnst_mstr_id,donor_external_id,gender_id,race_id,race_description,gender_cd,most_recent_any_visit_dt) on a.cnst_mstr_id = b.cnst_mstr_id


	) as subqry
	
	where subqry.rn=1
	with no schema binding;