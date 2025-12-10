CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.bz_email_src_cd AS
SELECT
    src_key,
    src_cd, 
    src_dsc, 
    comnictn_src_key, 
    nk_comnictn_src_cd, 
    comnictn_src_dsc, 
    channel,
    appl_src_cd
FROM mods_bi.mktg_ops_tbls.bz_email_src_cd
WITH NO SCHEMA BINDING;