CREATE OR REPLACE VIEW mktg_ops_vws.bz_cnst_cnstcy_affn AS
SELECT DISTINCT
    a.cnst_mstr_id AS "Constituent Master Identifier",
    a.bzd_cnst_fsa_key AS "Constituent Fsa Key",
    a.bzd_acct_fsa_key AS "Account Fsa Key",
    c.cnstcy_affn_typ_cd AS "Constituency Affinity Type Code",
    c.cnstcy_affn_typ_dsc AS "Constituency Affinity Type Description",
    a.bzd_ntrl_key AS "Natural Key",
    a.bzd_chpt_import_id AS "Chapter Import Identifier",
    a.nk_ta_acct_id AS "Nk Ta Account Identifier",
    a.nk_ta_nm_id AS "Nk Ta Name Identifier",
    a.nk_sf_acct_id AS "Nk Sf Account Identifier",
    a.nk_sf_cntct_id AS "Nk Sf Contact Identifier",
    a.bzd_SFID AS "User Friendly SalesForce Identifier",
    a.cnst_typ_cd AS "Constituent Type Code",
    a.appl_src_cd AS "Application Source Code",
    b.cnstcy_affn_typ_key AS "Constituency Affinity Type Key",
    CAST(b.strt_dt AS DATE) AS "Start Date",
    b.nk_ta_clssfctn_cd AS "Nk Ta Classification Code",
    b.nk_ta_rec_seq AS "Nk Ta Record Sequence",
    CAST(b.end_dt AS DATE) AS "End Date",
    b.act_ind AS "Active Indicator",
    CAST(b.srcsys_trans_ts AS TIMESTAMP) AS "Source System Transaction Timestamp",
    b.row_stat_cd AS "Row Status Code",
    b.load_id AS "Load Identifier",
    CAST(b.dw_trans_ts AS TIMESTAMP) AS "Data Warehouse Transaction Timestamp"
FROM eda.arc_mdm_vws.bzl_cnst_mstr_fsa a
JOIN ddcoe_vws.bz_cnst_cnstcy_affn b ON a.bzd_cnst_fsa_key = b.cnst_fsa_key
LEFT JOIN ddcoe_vws.bz_cnstcy_affn_typ c ON b.cnstcy_affn_typ_key = c.cnstcy_affn_typ_key
with no schema binding
;