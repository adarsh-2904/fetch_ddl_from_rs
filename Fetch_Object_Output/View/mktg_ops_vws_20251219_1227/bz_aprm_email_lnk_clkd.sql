CREATE OR REPLACE VIEW mktg_ops_vws.bz_aprm_email_lnk_clkd
AS
SELECT
    cnst_mstr_id,
    hist_rec_id,
    hist_rec_ts,
    abstract,
    email_id,
    brwsr,
    op_sys,
    mbl_dvc,
    lnk_url,
    is_first_clk,
    lnk_clk_typ,
    contxt_cd,
    srcsys_ts,
    dw_create_ts,
    dw_updt_ts,
    row_stat_cd,
    appl_src_cd,
    load_id
FROM mktg_ops_tbls.aprm_email_lnk_clkd
with no schema binding;