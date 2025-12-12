CREATE OR REPLACE VIEW mktg_ops_vws.suprsn_ts_cnst_test AS 
-- mktg_ops_vws.suprsn_ts_cnst_test source

create or replace view mktg_ops_vws.suprsn_ts_cnst_test
as
select 
	ts_email.cnst_mstr_id 
	,case when coalesce(ts_email.cnst_mstr_id,0) <> 0 then 1 else 0 end as ts_cnst_match_ind
	,case when coalesce(mstr.cnst_mstr_id,0) <> 0 and coalesce(ts_email.cnst_mstr_id,0) <> 0 then 1 else 0 end   as ts_email_match_ind
	,case when coalesce(mstr.cnst_mstr_id,0) <> 0 and coalesce(ts_email.cnst_mstr_id,0) <> 0 then 1 else 0 end   as ts_addr_match_ind
from eda.arc_mdm_vws.bz_cnst_mstr mstr

left join 
(
		select distinct
			a.cnst_mstr_id
		from 
		(
			select distinct cnst_mstr_id, email_key
			from eda.arc_mdm_vws.bzfc_cnst_email
			where assessmnt_ctg in ('Validated', 'Use with Caution')
		) a (cnst_mstr_id, email_key)
		inner join 
		(
			select distinct b.email_key
			from mktg_ops_vws.cnst_cdi_phss_preferred_email a
			inner join eda.arc_mdm_vws.bzfc_cnst_email b on a.cnst_mstr_id = b.cnst_mstr_id
			where b.assessmnt_ctg in ('Validated', 'Use with Caution')
		) b (email_key) on a.email_key = b.email_key
) ts_email (cnst_mstr_id)  on mstr.cnst_mstr_id = ts_email.cnst_mstr_id
with no schema binding;