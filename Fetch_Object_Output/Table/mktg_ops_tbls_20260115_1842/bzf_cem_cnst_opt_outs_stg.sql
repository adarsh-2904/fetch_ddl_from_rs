CREATE TABLE mktg_ops_tbls.bzf_cem_cnst_opt_outs_stg (
    cnst_mstr_id bigint ENCODE az64 distkey,
    fr_do_not_mail_ind integer ENCODE az64,
    fr_do_not_email_ind integer ENCODE az64,
    fr_do_not_call_hm_phn_ind integer ENCODE az64,
    fr_do_not_call_mbl_phn_ind integer ENCODE az64,
    fr_do_not_call_work_phn_ind integer ENCODE az64,
    fr_do_not_txt_ind integer ENCODE az64,
    bio_do_not_mail_ind integer ENCODE az64,
    bio_do_not_email_ind integer ENCODE az64,
    bio_do_not_call_hm_phn_ind integer ENCODE az64,
    bio_do_not_call_mbl_phn_ind integer ENCODE az64,
    bio_do_not_call_work_phn_ind integer ENCODE az64,
    bio_do_not_txt_ind integer ENCODE az64,
    phss_do_not_mail_ind integer ENCODE az64,
    phss_do_not_email_ind integer ENCODE az64,
    phss_do_not_call_hm_phn_ind integer ENCODE az64,
    phss_do_not_call_mbl_phn_ind integer ENCODE az64,
    phss_do_not_call_work_phn_ind integer ENCODE az64,
    phss_do_not_txt_ind integer ENCODE az64,
    vms_do_not_mail_ind integer ENCODE az64,
    vms_do_not_email_ind integer ENCODE az64,
    vms_do_not_call_hm_phn_ind integer ENCODE az64,
    vms_do_not_call_mbl_phn_ind integer ENCODE az64,
    vms_do_not_call_work_phn_ind integer ENCODE az64,
    vms_do_not_txt_ind integer ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );