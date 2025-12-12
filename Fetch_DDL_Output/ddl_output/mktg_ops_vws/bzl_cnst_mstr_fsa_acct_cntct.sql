CREATE OR REPLACE VIEW mktg_ops_vws.bzl_cnst_mstr_fsa_acct_cntct AS 
-- mktg_ops_vws.bzl_cnst_mstr_fsa_acct_cntct source

create or replace VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Modified By:  Michael Andrien
Modified Date: 06/26/2018
Purpose: This view links the FSA Account records to each Contact record.  The view leverages the bzl_cnst_mstr_fsa
				CDI view and joins the view to itself to link the Account Group (AG) row to each Individual row.  We separated the Org and ndividual 'IN'  queries
				to address duplicates in the Org query.  We take the row with the highest Master id and UNION the results to the IN query.
				
Modified By:  Michael Andrien
Modified Date: 10/17/2019
Purpose: Added join to ddcoe_vws.bz_cnst_fsa to add the FSA Account Active Indicator and the inactive reason details.
---------------------------------------------------------------------------------------------------------------------------- */
mktg_ops_vws.bzl_cnst_mstr_fsa_acct_cntct
AS

select 
	cntct.cnst_mstr_id as cntct_cnst_mstr_id, 
	cntct.bzd_cnst_fsa_key as cntct_bzd_cnst_fsa_key, 
	cntct.bzd_acct_fsa_key as cntct_bzd_acct_fsa_key, 
	cntct.bzd_ntrl_key as cntct_bzd_ntrl_key, 
	cntct.bzd_chpt_import_id as cntct_bzd_chpt_import_id, 
	cntct.nk_ta_acct_id as cntct_nk_ta_acct_id, 
	cntct.nk_ta_nm_id as cntct_nk_ta_nm_id, 
	cntct.nk_sf_acct_id as cntct_nk_sf_acct_id, 
	cntct.nk_sf_cntct_id as cntct_nk_sf_cntct_id, 
	cntct.bzd_SFID as cntct_bzd_SFID, 
	cntct.bzd_SFID_2 as cntct_bzd_SFID_2, 
	cntct.cnst_typ_cd as cntct_cnst_typ_cd, 
	cntct.appl_src_cd as cntct_appl_src_cd, 
	fsa.act_ind,
	fsa.inactvtn_reason_cd,
	fsa.inactvtn_reason_dsc,
	fsa.inactvtn_dt,
	ag.cnst_mstr_id as ag_cnst_mstr_id, 
	ag.bzd_cnst_fsa_key as ag_bzd_cnst_fsa_key, 
	ag.bzd_acct_fsa_key as ag_bzd_acct_fsa_key, 
	ag.bzd_ntrl_key as ag_bzd_ntrl_key, 
	ag.bzd_chpt_import_id as ag_bzd_chpt_import_id, 
	ag.nk_ta_acct_id as ag_nk_ta_acct_id, 
	ag.nk_ta_nm_id as ag_nk_ta_nm_id, 
	ag.nk_sf_acct_id as ag_nk_sf_acct_id, 
	ag.nk_sf_cntct_id as ag_nk_sf_cntct_id, 
	ag.bzd_SFID as ag_bzd_SFID, 
	ag.bzd_SFID_2 as ag_bzd_SFID_2, 
	ag.cnst_typ_cd as ag_cnst_typ_cd, 
	ag.appl_src_cd as ag_appl_src_cd
from eda.arc_mdm_vws.bzl_cnst_mstr_fsa cntct
left join eda.arc_mdm_vws.bzl_cnst_mstr_fsa ag on cntct.bzd_acct_fsa_key = ag.bzd_cnst_fsa_key
left join ddcoe_vws.bz_cnst_fsa fsa on cntct.bzd_cnst_fsa_key = fsa.cnst_fsa_key
where cntct.cnst_typ_cd in ( 'IN') and ag.cnst_typ_cd = 'AG'
QUALIFY ROW_NUMBER() OVER (PARTITION BY cntct.bzd_cnst_fsa_key  ORDER BY  ag.cnst_mstr_id DESC) = 1
UNION ALL
select 
	cntct.cnst_mstr_id as cntct_cnst_mstr_id, 
	cntct.bzd_cnst_fsa_key as cntct_bzd_cnst_fsa_key, 
	cntct.bzd_acct_fsa_key as cntct_bzd_acct_fsa_key, 
	cntct.bzd_ntrl_key as cntct_bzd_ntrl_key, 
	cntct.bzd_chpt_import_id as cntct_bzd_chpt_import_id, 
	cntct.nk_ta_acct_id as cntct_nk_ta_acct_id, 
	cntct.nk_ta_nm_id as cntct_nk_ta_nm_id, 
	cntct.nk_sf_acct_id as cntct_nk_sf_acct_id, 
	cntct.nk_sf_cntct_id as cntct_nk_sf_cntct_id, 
	cntct.bzd_SFID as cntct_bzd_SFID, 
	cntct.bzd_SFID_2 as cntct_bzd_SFID_2, 
	cntct.cnst_typ_cd as cntct_cnst_typ_cd, 
	cntct.appl_src_cd as cntct_appl_src_cd, 
	fsa.act_ind,
	fsa.inactvtn_reason_cd,
	fsa.inactvtn_reason_dsc,
	fsa.inactvtn_dt,
	ag.cnst_mstr_id as ag_cnst_mstr_id, 
	ag.bzd_cnst_fsa_key as ag_bzd_cnst_fsa_key, 
	ag.bzd_acct_fsa_key as ag_bzd_acct_fsa_key, 
	ag.bzd_ntrl_key as ag_bzd_ntrl_key, 
	ag.bzd_chpt_import_id as ag_bzd_chpt_import_id, 
	ag.nk_ta_acct_id as ag_nk_ta_acct_id, 
	ag.nk_ta_nm_id as ag_nk_ta_nm_id, 
	ag.nk_sf_acct_id as ag_nk_sf_acct_id, 
	ag.nk_sf_cntct_id as ag_nk_sf_cntct_id, 
	ag.bzd_SFID as ag_bzd_SFID, 
	ag.bzd_SFID_2 as ag_bzd_SFID_2, 
	ag.cnst_typ_cd as ag_cnst_typ_cd, 
	ag.appl_src_cd as ag_appl_src_cd
from eda.arc_mdm_vws.bzl_cnst_mstr_fsa cntct
left join eda.arc_mdm_vws.bzl_cnst_mstr_fsa ag on cntct.bzd_acct_fsa_key = ag.bzd_cnst_fsa_key
left join ddcoe_vws.bz_cnst_fsa fsa on cntct.bzd_cnst_fsa_key = fsa.cnst_fsa_key
where cntct.cnst_typ_cd in ( 'OR') 
QUALIFY ROW_NUMBER() OVER (PARTITION BY cntct.bzd_cnst_fsa_key  ORDER BY  ag.cnst_mstr_id DESC) = 1
with no schema binding
;