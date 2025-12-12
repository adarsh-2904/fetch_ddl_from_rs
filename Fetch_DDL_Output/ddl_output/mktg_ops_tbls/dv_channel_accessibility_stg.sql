CREATE TABLE mktg_ops_tbls.dv_channel_accessibility_stg (
    cnst_mstr_id bigint ENCODE az64 distkey,
    do_not_phone_ind integer ENCODE az64,
    do_not_email_ind integer ENCODE az64,
    do_not_mail_ind integer ENCODE az64,
    do_not_txt_ind integer ENCODE az64,
    fr_ok_to_email_flg character varying(1) ENCODE lzo,
    phss_ok_to_email_flg character varying(1) ENCODE lzo
)
DISTSTYLE KEY;