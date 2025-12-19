CREATE OR REPLACE VIEW mktg_ops_vws.bz_aprm_wb_apnd_unsubs_rplc
AS
SELECT 
    history_record_id AS hist_rec_id,
    history_record_dt AS hist_rec_ts,
    audience_member_id AS audience_member_id,
    cnst_mstr_id AS cnst_mstr_id,
    fst_nm AS first_nm,
    lst_nm AS last_nm,
    email_addr AS email_addr,
    contact_pref AS contact_pref,
    obm_id AS outbnd_id
FROM mktg_ops_tbls.aprm_wb_apnd_unsubs_rplc
with no schema binding;