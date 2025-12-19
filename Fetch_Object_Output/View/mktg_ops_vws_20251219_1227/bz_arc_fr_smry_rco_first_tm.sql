CREATE OR REPLACE VIEW mktg_ops_vws.bz_arc_fr_smry_rco_first_tm
AS
SELECT 
    cnst_mstr_id, 
    trans_id, 
    rco_dntn_id, 
    first_time_trans_dt, 
    billing_email, 
    billing_f_nm, 
    billing_l_nm, 
    em_cnst_data_src_cd, 
    em_cnst_email, 
    cnst_mstr_id_cnt, 
    first_cnst_mstr_id, 
    last_cnst_mstr_id
FROM mktg_ops_tbls.bz_arc_fr_smry_rco_first_tm
with no schema binding;