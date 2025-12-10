CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.bz_gms_arc_fr_txn_segmnt AS
SELECT
    cnst_mstr_id,
    giftran_key,
    dntn_gift_dt,
    last_dntn_gift_dt,
    email_segmnt_key,
    active_email_segmnt_ind
FROM mods_bi.mktg_ops_tbls.bz_gms_arc_fr_txn_segmnt
WITH NO SCHEMA BINDING;