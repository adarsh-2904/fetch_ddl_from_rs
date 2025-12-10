CREATE TABLE mktg_ops_tbls.dim_recipient (
    recipient_key bigint ENCODE az64,
    nk_recipient_id bigint ENCODE az64 distkey,
    cnst_mstr_id bigint ENCODE az64,
    email_addr character varying(128) ENCODE lzo,
    recipient_first_nm character varying(100) ENCODE lzo,
    recipient_midl_nm character varying(50) ENCODE lzo,
    recipient_last_nm character varying(100) ENCODE lzo,
    recipient_line_1_addr character varying(150) ENCODE lzo,
    recipient_line_2_addr character varying(150) ENCODE lzo,
    recipient_city_nm character varying(100) ENCODE lzo,
    recipient_st_cd character varying(3) ENCODE lzo,
    recipient_zip_5_cd character varying(5) ENCODE lzo,
    recipient_zip_4_cd character varying(5) ENCODE lzo,
    srcsys_trans_ts timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64
)
DISTSTYLE KEY;