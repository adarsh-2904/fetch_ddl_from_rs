CREATE TABLE mktg_ops_tbls.global_suprs_cnst_email (
    cnst_mstr_id bigint NOT NULL ENCODE raw distkey,
    email_addr character varying(100) ENCODE lzo,
    suprs_reason_txt character varying(255) ENCODE lzo,
    act_ind smallint ENCODE az64,
    suprs_start_dt date ENCODE az64,
    suprs_end_dt date DEFAULT '9999-12-31'::date ENCODE az64,
    requested_by character varying(80) ENCODE lzo,
    requested_dt date ENCODE az64,
    created_by character varying(80) ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );