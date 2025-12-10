CREATE OR REPLACE VIEW

/* ---------------------------------------------------------------------------------------------------------------------------

Created by; Michael Andrien
Created date; 18-April-2014
Purpose; This view selects links arc_mdm_vws.bzl_cnst_mstr_fsa to the FSA bz_cnst_cnstcy_affn view in ddcoe_vws.


Modified by;  Ramesh Babu Ramachandran
Created date; 11-Jul-2014
Purpose; To remove duplicate records, included Distinct Clause in Select.

------------------------------------------------------------------------------------------------------------------------------------ */
mktg_ops_vws.bz_cnst_cnstcy_affn
AS
SELECT	
DISTINCT
  a.cnst_mstr_id ,
  a.bzd_cnst_fsa_key,
  a.bzd_acct_fsa_key ,
  c.cnstcy_affn_typ_cd ,
  c.cnstcy_affn_typ_dsc,
  a.bzd_ntrl_key,
  a.bzd_chpt_import_id ,
  a.nk_ta_acct_id,
  a.nk_ta_nm_id ,
  a.nk_sf_acct_id,
  a.nk_sf_cntct_id ,
  a.bzd_SFID,
  a.cnst_typ_cd,
  a.appl_src_cd,
	b.cnstcy_affn_typ_key,
	CAST(b.strt_dt AS DATE) AS strt_dt,
	b.nk_ta_clssfctn_cd ,
	b.nk_ta_rec_seq,
	CAST(b.end_dt AS DATE) AS end_dt,
	b.act_ind ,
	CAST(b.srcsys_trans_ts AS TIMESTAMP(0)) AS srcsys_trans_ts,
	b.row_stat_cd ,
	b.load_id,
	CAST(b.dw_trans_ts AS TIMESTAMP(0)) AS dw_trans_ts
FROM 
eda.arc_mdm_vws.bzl_cnst_mstr_fsa a 
JOIN ddcoe_vws.bz_cnst_cnstcy_affn  b ON a.bzd_cnst_fsa_key = b.cnst_fsa_key 
LEFT JOIN ddcoe_vws.bz_cnstcy_affn_typ c ON b.cnstcy_affn_typ_key=c.cnstcy_affn_typ_key
with no schema binding;