CREATE TABLE mktg_ops_tbls.bzfc_pg_response_log_ref (
    pg_response_log_key integer ENCODE az64 distkey,
    first_response_dt date ENCODE az64,
    org_nm character varying(150) ENCODE lzo COLLATE case_sensitive,
    clnsd_first_nm character varying(20) ENCODE lzo COLLATE case_sensitive,
    clnsd_last_nm character varying(80) ENCODE lzo COLLATE case_sensitive,
    clnsd_email_addr character varying(100) ENCODE lzo COLLATE case_sensitive,
    derived_campaign character varying(50) ENCODE lzo COLLATE case_sensitive,
    response_group_dsc character varying(10) ENCODE lzo COLLATE case_sensitive,
    cds_image_id character varying(120) ENCODE lzo COLLATE case_sensitive,
    frwl_gift_id character varying(30) ENCODE lzo COLLATE case_sensitive,
    src_cd character varying(20) ENCODE lzo COLLATE case_sensitive,
    hist_seqnum bigint ENCODE az64,
    history_record_id integer ENCODE az64,
    pgc_response_id integer ENCODE az64,
    mds_unq_id character varying(30) ENCODE lzo COLLATE case_sensitive,
    dw_create_ts timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone ENCODE raw,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    row_insert_ts timestamp without time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );