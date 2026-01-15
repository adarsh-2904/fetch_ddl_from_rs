CREATE TABLE mktg_ops_tbls.awb_rcpnt_2_cdi_mstr_xtrct (
    cnst_mstr_id character varying(255) ENCODE lzo COLLATE case_insensitive,
    recipient_id character varying(255) ENCODE lzo COLLATE case_insensitive,
    isfr_ind character varying(255) ENCODE lzo COLLATE case_insensitive,
    isbio_ind character varying(255) ENCODE lzo COLLATE case_insensitive,
    ists_ind character varying(255) ENCODE lzo COLLATE case_insensitive,
    isvms_ind character varying(255) ENCODE lzo COLLATE case_insensitive,
    last_modified_ts character varying(255) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;