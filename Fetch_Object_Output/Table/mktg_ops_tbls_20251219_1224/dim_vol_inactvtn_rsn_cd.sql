CREATE TABLE mktg_ops_tbls.dim_vol_inactvtn_rsn_cd (
    first_name character varying(1020) ENCODE lzo COLLATE case_sensitive,
    last_name character varying(1020) ENCODE lzo COLLATE case_sensitive,
    email character varying(1020) ENCODE lzo COLLATE case_sensitive,
    account_id integer ENCODE az64,
    status_name character varying(1020) ENCODE lzo COLLATE case_sensitive,
    status_type character varying(1020) ENCODE lzo COLLATE case_sensitive,
    relationship_status character varying(1020) ENCODE lzo COLLATE case_sensitive,
    hierarchy_name character varying(1020) ENCODE lzo COLLATE case_sensitive,
    member_number integer ENCODE az64,
    effective_date timestamp without time zone ENCODE az64,
    reason_for_change character varying(1020) ENCODE lzo COLLATE case_sensitive,
    contact_id integer ENCODE az64 distkey,
    volunteer_id integer ENCODE az64,
    row_stat_cd character(100) NOT NULL ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(16) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );