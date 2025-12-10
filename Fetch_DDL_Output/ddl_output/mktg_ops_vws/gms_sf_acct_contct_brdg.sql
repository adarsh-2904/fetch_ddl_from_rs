create or REPLACE VIEW mktg_ops_vws.gms_sf_acct_contct_brdg
 /*
 Created By: Michael Andrien
 Create Date 06/01/2020
 Purpose:  This view references the bzl_cnst_mstr_fsa view in the GMS ufds_vws database to provide a view that links the CDI Master id to SalesForce (SF) Account and to each SF contact within the account.
 The view will be added to the GMS CE reporting universe so that SF account and contact ids can be included in SF Ask reports for the Planned Giving team.
 */
 as
select 
	distinct 
	b.cnst_mstr_id, 
	a.cnst_key as sf_acct_key, 
	a.frf_acct_id, 
	b.frf_cntct_id
from  eda.ufds_vws.bzl_cnst_mstr_fsa a -- This join links the ask to the SF Acct
left join eda.ufds_vws.bzl_cnst_mstr_fsa b on b.acct_key = a.cnst_key and b.cnst_typ_cd = 'IN' and b.appl_src_cd = 'SFFS'  -- This join linke the SF Contact to the SF Account 
where a.cnst_typ_cd = 'AG' and a.appl_src_cd = 'SFFS'
with no schema binding;