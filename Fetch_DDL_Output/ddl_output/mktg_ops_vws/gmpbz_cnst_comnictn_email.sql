CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_cnst_comnictn_email AS
-- Created By: Michael Andrien
-- Create Date: 07/28/2023
-- Modified Date: 09/18/2023
-- Purpose: Contains email acknowledgement request data for Adobe Campaign. 
-- Includes updates to column names and additional attributes.

SELECT
    nk_cnst_comnictn_id,
    nk_gift_id,
    prse_cd,
    comnictn_cd,
    gift_dt,
    gift_amt,
    src_cd,
    src_dsc,
    dnr_advs_fnd_nm,
    donorMasterID1,
    donorMasterID2,
    org_nm,
    email_address,
    salutn,
    addressee,
    addr_line1,
    addr_line2,
    city,
    state_cd,
    zipcode,
    trbt_nm,
    trbt_typ_cd,
    trbt_from,
    trbt_typ_dsc,
    giftran_typ_dsc,
    personalizationLine,
    trbt_card_typ_cd,
    prem_cd,
    prem_count,
    comnictn_dw_extr_dt,
    fund_dsc,
    revenue_dsc,
    ira,
    cdrp_flg,
    dlvry_mthd_cd,
    lang_cd,
    inkind_dsc,
    totl_stock_gift_amt,
    srcsys_created_by,
    srcsys_modified_by,
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
FROM eda.ufds_vws.gmpbz_cnst_comnictn_email
with no schema binding
;