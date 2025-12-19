CREATE OR REPLACE VIEW mktg_ops_vws.bz_aprm_email_remove
AS
SELECT
    cnst_mstr_id,
    hist_rec_id,
    hist_rec_ts,
    optout_form_id,
    optout_form_ttl,
    actvty_id,
    actvty_ttl,
    actvty_typ_id,
    actvty_typ_ttl,
    abstract,
    type_id,
    email_id,
    contxt_cd,
    srcsys_ts,
    dw_create_ts,
    dw_updt_ts,
    row_stat_cd,
    appl_src_cd,
    load_id
FROM mktg_ops_tbls.aprm_email_remove
with no schema binding;