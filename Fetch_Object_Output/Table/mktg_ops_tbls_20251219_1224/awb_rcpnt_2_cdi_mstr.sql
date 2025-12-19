CREATE TABLE mktg_ops_tbls.awb_rcpnt_2_cdi_mstr (
    cnst_mstr_id bigint ENCODE az64,
    recipient_id integer ENCODE az64,
    isfr_ind smallint ENCODE az64,
    isbio_ind smallint ENCODE az64,
    ists_ind smallint ENCODE az64,
    isvms_ind smallint ENCODE az64,
    last_modified_ts timestamp without time zone ENCODE az64
)
DISTSTYLE ALL;