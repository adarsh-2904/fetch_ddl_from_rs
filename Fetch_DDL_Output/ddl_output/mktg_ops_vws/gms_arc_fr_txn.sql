CREATE OR REPLACE VIEW mktg_ops_vws.gms_arc_fr_txn AS
SELECT
    a.cnst_mstr_id, 
    CAST(NULL AS VARCHAR(18)) AS cnst_hsld_id, 
    bzd_unique_trans_id, 
    alt_trans_id, 
    ta_acct_id, 
    a.nk_gift_id, 
    nk_ta_gift_seq,
    nk_sf_gift_id,
    rco_dntn_id,
    rco_subscription_id,
    subscription_id,
    gift_grp_id, 
    a.dntn_entity_url, 

    -- Dimension keys
    a.giftran_key, 
    gift_cnst_grp_key,
    dim_giftran_key, 
    pmt_typ_key,
    email_segmnt_key,
    channel_typ_key, 
    online_channel_key, 
    gift_tran_typ_key, 
    pmt_mthd_key,
    dntn_chan_key, 
    sustnr_typ_key, 
    gl_debit_acct_key,
    gl_credit_acct_key, 
    trans_fund_key, 
    giftran_src_key, 
    gift_src_key, 
    orig_gift_src_key, 
    treatmnt_key, 
    campgn_src_key,
    orig_campgn_src_key,  
    fr_affl_unit_key,
    gift_amt_tier_key,
    vendor_key, 
    merchant_key, 

    fcc_key, 
    sc_affl_unit_key, 
    dim_gift_sku_key, 
    dim_gift_premium_key, 

    -- Date keys
    gift_rec_dt_key, 
    dntn_gift_dt_key, 
    released_dt_key, 
    orig_released_dt_key, 
    deposit_dt_key, 
    orig_deposit_dt_key,

    -- Date columns
    gift_rec_dt,
    CAST(a.dntn_gift_dt AS DATE) AS dntn_gift_dt,
    released_dt,
    orig_released_dt,
    deposit_dt,
    orig_deposit_dt,
    CAST(recurng_start_dt AS DATE) AS recurng_start_dt,

    -- Denormalized attributes
    gift_versn, 
    gift_num, 
    online_channel_cd, 
    txn_channel, 
    trans_fund_cd, 
    trans_fund_dsc,
    a.gift_src_cd, 
    gift_sub_src_cd, 
    a.campgn_src_cd,
    gift_src_dsc, 
    treatmnt_cd, 
    fr_affl_cd, 
    giftran_typ_dsc, 
    sc_affl_unit_cd, 
    cnvo_cnst_id,
    NULL AS fr_cnst_intl_sustnr_enrl, 
    fr_merchant_id, 
    cnst_typ_cd, 

    arc_fr_txn_seq_num, 
    CASE 
        WHEN b.cnst_mstr_id IS NULL THEN 1
        WHEN b.cnst_mstr_id IS NOT NULL AND a.cnst_mstr_id = b.cnst_mstr_id THEN 1
        ELSE 0 
    END AS primary_gift_ind, 

    recurring_ind, 

    CASE 
        WHEN c.gl_fcc_cd = '27760' 
         AND SUBSTRING(a.gift_src_cd, 1, 3) = 'RSG' 
         AND SUBSTRING(a.gift_src_cd, 9, 1) = 'M' 
         AND a.trans_fund_cd = '4900' THEN 0 
        ELSE fr_distr_dntn_ind 
    END AS fr_distr_dntn_ind,

    fr_impctd_area_dntn_ind, 
    a.active_ind, 
    ack_ind, 
    thankyou_ind, 
    soft_credit_ind, 
    gift_anon_ind,
    split_gift_ind, 
    trbt_gift_ind, 
    installment_ind, 
    confidence_ind,
    gift_ask_mult_lnk_ind, 
    dnr_geogrphc_intrst_local_ind, 
    gift_in_care_of_ind,
    a.evnt_benefit_ind, 
    conv_trans_ind, 
    ta_trans_ind, 
    do_not_feed_gl_ind, 
    adj_ind, 
    bdgt_rlvng_ind, 
    released_ind,
    manual_entry_ind,
    reject_ind, 
    misdirected_ind, 
    vsblty_ind,
    fr_credit_ind, 
    prior_prd_ind,
    gl_override_ind, 
    stock_gift_ind, 
    inkind_gift_ind, 
    dnr_adv_gift_ind,
    episodic_gift_ind, 
    fmd_txn_ind, 
    prvt_ind, 

    -- Amounts
    fr_pmt_amt, 
    totl_gift_amt,
    gift_exps_amt, 

    -- Timestamps
    a.srcsys_create_ts, 
    a.srcsys_update_ts, 
    a.trans_update_dt,

    -- Metadata
    a.dw_trans_ts, 
    a.appl_src_cd,
    a.load_id

FROM mktg_ops_tbls.gms_arc_fr_txn a
LEFT JOIN mktg_ops_vws.gms_bzfc_donation_rank b 
    ON a.giftran_key = b.giftran_key
LEFT JOIN mktg_ops_vws.gmpbz_dim_gl_fcc c 
    ON a.fcc_key = c.gl_fcc_key
WITH NO SCHEMA BINDING
;