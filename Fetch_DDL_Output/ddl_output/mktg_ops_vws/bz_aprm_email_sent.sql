CREATE OR REPLACE VIEW mktg_ops_vws.bz_aprm_email_sent
AS
SELECT
    cnst_mstr_id, 
    hist_rec_id, 
    hist_rec_ts, 
    eml_gen_run_id,
    outbnd_id, 
    outbnd_ttl, 
    sent_ts, 
    dlvrd_ts, 
    actvty_id, 
    actvty_ttl,
    sgmtn_id, 
    sgmtn_title, 
    sgmt_id, 
    sgmt_title, 
    from_display_nm,
    from_email, 
    reply_to_email, 
    to_email, 
    to_display_nm, 
    to_domain,
    is_forwarded, 
    forwarding_email, 
    abstract,  
    email_id, 
    contxt_cd,
    srcsys_ts, 
    dw_create_ts, 
    dw_updt_ts, 
    row_stat_cd, 
    appl_src_cd,
    load_id
FROM mktg_ops_tbls.aprm_email_sent
with no schema binding;