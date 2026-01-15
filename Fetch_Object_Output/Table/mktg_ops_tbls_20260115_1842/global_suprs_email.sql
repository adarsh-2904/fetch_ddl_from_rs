CREATE TABLE mktg_ops_tbls.global_suprs_email (
    email_addr character varying(100) ENCODE lzo COLLATE case_sensitive,
    suprs_reason_txt character varying(255) ENCODE lzo COLLATE case_sensitive,
    act_ind smallint ENCODE az64,
    suprs_start_dt date ENCODE az64,
    suprs_end_dt date ENCODE az64,
    requested_by character varying(80) ENCODE lzo COLLATE case_sensitive,
    requested_dt date ENCODE az64,
    created_by character varying(80) ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;