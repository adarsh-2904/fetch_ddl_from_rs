CREATE TABLE mktg_ops_tbls.vms_sta_indivs (
    hierarchy_name character varying(255) ENCODE lzo COLLATE case_sensitive,
    registration_type_name character varying(255) ENCODE lzo COLLATE case_sensitive,
    registration_id integer ENCODE raw distkey,
    registration_name character varying(255) ENCODE lzo COLLATE case_sensitive,
    registration_start_datetime timestamp without time zone ENCODE az64,
    account_id integer ENCODE az64,
    registration_status_lookup character varying(255) ENCODE lzo COLLATE case_sensitive,
    relationship_status character varying(255) ENCODE lzo COLLATE case_sensitive,
    status_name character varying(255) ENCODE lzo COLLATE case_sensitive,
    team_id integer ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( registration_id );