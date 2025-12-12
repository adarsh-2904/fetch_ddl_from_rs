CREATE TABLE mktg_ops_tbls.awb_rcpnt_2_cdi_mstr_xtrct (
    cnst_mstr_id character varying(255) ENCODE lzo,
    recipient_id character varying(255) ENCODE lzo,
    isfr_ind character varying(255) ENCODE lzo,
    isbio_ind character varying(255) ENCODE lzo,
    ists_ind character varying(255) ENCODE lzo,
    isvms_ind character varying(255) ENCODE lzo,
    last_modified_ts character varying(255) ENCODE lzo
)
DISTSTYLE ALL;