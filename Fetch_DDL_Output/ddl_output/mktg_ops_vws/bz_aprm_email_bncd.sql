CREATE OR REPLACE VIEW mktg_ops_vws.bz_aprm_email_bncd
AS
SELECT
    cnst_mstr_id,
    hist_rec_id, 
    hist_rec_ts,
    abstract,  
    email_id, 
    bncd_ctgy_id,
    bncd_ctgy_ttl,
    bncd_subctgy_ttl,
    contxt_cd,
    srcsys_ts, 
    dw_create_ts, 
    dw_updt_ts, 
    row_stat_cd, 
    appl_src_cd,
    load_id
FROM mktg_ops_tbls.aprm_email_bncd
with no schema binding;