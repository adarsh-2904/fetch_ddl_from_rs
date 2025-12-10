CREATE TABLE mktg_ops_tbls.pg_response_log_exclusion (
    email_addr character varying(100) ENCODE lzo distkey,
    active_exclusion_ind smallint ENCODE az64,
    create_ts timestamp without time zone ENCODE az64,
    update_ts timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE raw,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );