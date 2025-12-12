CREATE TABLE mktg_ops_tbls.sw_email_unsubscrb (
    client_id integer ENCODE az64,
    send_id integer ENCODE az64,
    subscr_key character varying(100) ENCODE lzo distkey,
    email_addr character varying(100) ENCODE lzo,
    subscr_id integer ENCODE az64,
    list_id integer ENCODE az64,
    event_ts timestamp without time zone ENCODE raw,
    event_typ character varying(15) ENCODE lzo,
    curr_prcsd_file_nm character varying(255) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( event_ts );