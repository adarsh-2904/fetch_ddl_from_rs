CREATE OR REPLACE VIEW mktg_ops_vws.bz_aprm_wb_rplc_fr_prf_cntr_lt
AS
SELECT 
    history_record_id AS hist_rec_id,
    history_record_date AS hist_rec_ts,
    abstract AS abstract_txt,
    audience_member_id AS audience_member_id,
    pref_cntr_lt_cnst_mstr_id AS cnst_mstr_id,
    pref_cntr_lt_first_name AS first_nm,
    pref_cntr_lt_last_name AS last_nm,
    pref_cntr_lt_email_address AS email_addr,
    pref_cntr_lt_cntc_pref AS contact_pref,
    pref_cntr_lt_obm AS outbnd_id
FROM mktg_ops_tbls.aprm_wb_rplc_fr_prf_cntr_lt
with no schema BINDING;