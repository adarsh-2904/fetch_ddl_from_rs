CREATE TABLE mktg_ops_tbls.arc_cdi_smry_email_tmp (
    hh_la_id character varying(30) ENCODE lzo,
    dw_srcsys_trans_ts timestamp without time zone ENCODE az64,
    arc_srcsys_cd character varying(10) ENCODE lzo,
    email_key bigint ENCODE az64,
    cnst_email_addr character varying(100) ENCODE lzo
)
DISTSTYLE ALL;