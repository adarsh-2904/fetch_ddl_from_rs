CREATE TABLE mktg_ops_tbls.global_suprs_email (
    email_addr character varying(100) ENCODE lzo,
    suprs_reason_txt character varying(255) ENCODE lzo,
    act_ind smallint ENCODE az64,
    suprs_start_dt date ENCODE az64,
    suprs_end_dt date ENCODE az64,
    requested_by character varying(80) ENCODE lzo,
    requested_dt date ENCODE az64,
    created_by character varying(80) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    dw_trans_ts timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;