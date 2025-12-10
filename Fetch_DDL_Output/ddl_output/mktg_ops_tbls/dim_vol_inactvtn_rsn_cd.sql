CREATE TABLE mktg_ops_tbls.dim_vol_inactvtn_rsn_cd (
    first_name character varying(1020) ENCODE lzo,
    last_name character varying(1020) ENCODE lzo,
    email character varying(1020) ENCODE lzo,
    account_id integer ENCODE az64,
    status_name character varying(1020) ENCODE lzo,
    status_type character varying(1020) ENCODE lzo,
    relationship_status character varying(1020) ENCODE lzo,
    hierarchy_name character varying(1020) ENCODE lzo,
    member_number integer ENCODE az64,
    effective_date timestamp without time zone ENCODE az64,
    reason_for_change character varying(1020) ENCODE lzo,
    contact_id integer ENCODE az64 distkey,
    volunteer_id integer ENCODE az64,
    row_stat_cd character(100) NOT NULL ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(16) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );