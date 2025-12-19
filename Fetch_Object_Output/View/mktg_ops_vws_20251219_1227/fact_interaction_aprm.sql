CREATE OR REPLACE VIEW mktg_ops_vws.fact_interaction_aprm

AS
SELECT
    cnst_mstr_id,
    orig_cnst_mstr_id,
    cnst_hsld_id,
    finder_number,
    cell_src_cd,
    cell_subsrc_cd,
    motivtn_cd,
    fr_last_ta_acct_id,
    offer_id,
    treatment_id,
    activity_id,
    segementation_id,
    segment_id,
    segmnt_dsc,
    outbnd_id,
    email_id,
    email_sent_dt,
    to_domain,
    drop_dt,
    update_dt,
    last_dntn_dt,
    last_dntn_amt,
    chpt_affl,
    submitter_nm,
    chpt_id,
    cntct_dt,
    run_dt,
    run_id,
    mailed_ind,
    supressed_ind,
    call_ind,
    call_result,
    do_not_call_ind,
    target_tag_scr,
    vigintile,
    mods_fr_scr,
    row_stat_cd,
    appl_src_cd,
    load_id,
    dw_trans_ts
FROM mods_bi_rep.mktg_ops_tbls.fact_interaction_aprm
with no schema binding;