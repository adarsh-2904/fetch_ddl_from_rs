CREATE OR REPLACE VIEW mktg_ops_vws.dim_recipient
AS
SELECT 
    recipient_key, 
    nk_recipient_id, 
    cnst_mstr_id, 
    email_addr, 
    recipient_first_nm, 
    recipient_midl_nm, 
    recipient_last_nm, 
    recipient_line_1_addr, 
    recipient_line_2_addr, 
    recipient_city_nm, 
    recipient_st_cd, 
    recipient_zip_5_cd, 
    recipient_zip_4_cd, 
    srcsys_trans_ts, 
    dw_trans_ts, 
    row_stat_cd, 
    appl_src_cd, 
    load_id
FROM mktg_ops_tbls.dim_recipient 
with no schema binding;