CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_cnst_fr_prfr_flags AS 
-- mktg_ops_vws.bzfc_cnst_fr_prfr_flags source



create or replace view 

/* ---------------------------------------------------------------------------------------------------------------------------

Created by: Michael Andrien
Created date: 29-Jul-2014
Purpose: This view was created for the Marketing Consumer Fundraising online team and provides a flattened email constituent donor record with yes/no (Y/N) flags to
indicate whether an email donor belongs to a specific group.  The flattened record simplifies the donor selection criteria when building
Aprimo segmetation dfinitions.
*******
Version 1.0 was built entirely from the Convio constituent group membership details.  Future releases will include additional 8 to 10 flags and additional rules 
will be added to update the flags based on Aprimo, CDI and other DW data sources. 
*/
mktg_ops_vws.bzfc_cnst_fr_prfr_flags as 
select
prfr.cnst_mstr_id,
case when (yw.cnvo_cnst_cnt is not null or ywgm.cnst_cnt is not null) then 'Y' else 'N' end as youthwire_flg,
case when saf.cnvo_cnst_cnt is not null then 'Y' else 'N' end as saf_flg,
case when nhq.cnvo_cnst_cnt is not null then 'Y' else 'N' end as nhq_master_flg
from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr prfr
left join (select cc.cnst_mstr_id,count(gm.cnvo_cnst_id)
         from  mktg_ops_vws.cnvo_cnst cc 
         join mktg_ops_vws.cnvo_group_members gm on cc.cnvo_cnst_id = gm.cnvo_cnst_id 
	    where cnvo_group_id = 37308 group by 1) yw(cnst_mstr_id, cnvo_cnst_cnt) on prfr.cnst_mstr_id = yw.cnst_mstr_id 
-- join to the arc_cmm_tbls group membership table to get YW constituents
left join ( select cnst_mstr_id, count(*)
		from mktg_ops_vws.bz_grp_mbrshp
		where grp_key = 1
		group by 1) ywgm(cnst_mstr_id, cnst_cnt) on prfr.cnst_mstr_id = ywgm.cnst_mstr_id
left join (select cc.cnst_mstr_id,count(gm.cnvo_cnst_id)
         from  mktg_ops_vws.cnvo_cnst cc 
         join mktg_ops_vws.cnvo_group_members gm on cc.cnvo_cnst_id = gm.cnvo_cnst_id 
	 where cnvo_group_id in (39208, 40066, 39211) group by 1) saf(cnst_mstr_id, cnvo_cnst_cnt)  on prfr.cnst_mstr_id = saf.cnst_mstr_id 
left join (select cc.cnst_mstr_id,count(gm.cnvo_cnst_id)
         from  mktg_ops_vws.cnvo_cnst cc 
         join mktg_ops_vws.cnvo_group_members gm on cc.cnvo_cnst_id = gm.cnvo_cnst_id 
	 where cnvo_group_id = 35438 group by 1) nhq(cnst_mstr_id, cnvo_cnst_cnt)  on prfr.cnst_mstr_id = nhq.cnst_mstr_id
with no schema binding;