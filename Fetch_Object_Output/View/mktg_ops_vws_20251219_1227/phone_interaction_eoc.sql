CREATE OR REPLACE VIEW mktg_ops_vws.phone_interaction_eoc AS
SELECT
    unq_id,
    cmpgn_cd,
    pgm_type,
    sgmnt_dsc,
    fiscal_yr,
    qtr,
    sf_acct_id,
    cnst_mstr_id,
    orig_cnst_mstr_id,
    src_cd,
    appeal_cd,
    dsgntn_cd,
    chnl_cd,
    sf_contact_id,
    acct_nm,
    nk_ecode,
    region_nm,
    first_nm,
    last_nm,
    addr_line1,
    addr_line2,
    city,
    state,
    zip_cd,
    home_phn_num_cln,
    mbl_phn_num_cln,
    call_dt,
    call_start_ts,
    call_end_ts,
    elapsed_call_tm,
    cmpgn_call_atmpt_cnt,
    phn_chng_type,
    scrpt_num,
    afltn_cd,
    gift_amt,
    pledge_amt,
    addr_id,
    email_id,
    name_id,
    phn_id,
    pfx,
    slttn,
    mi,
    sfx,
    dspstn_id,
    dspstn1,
    dspstn2,
    addi_rqst,
    phn_chng_flg,
    addr_chng_flg,
    nm_chng_flg,
    email_chng_flg,
    email_addr,
    is_cell_flg,
    scr1_id,
    scr1_val,
    scr2_id,
    scr2_val,
    scr3_id,
    scr3_val,
    CAST(NULL AS VARCHAR(40)) AS decile,
    cmnt,
    curr_prcsd_file_nm,
    dw_trans_ts
FROM mktg_ops_tbls.phone_interaction_eoc
WITH NO SCHEMA BINDING
;