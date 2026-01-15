CREATE TABLE mktg_ops_tbls.vms_sta_orgs (
    team_id integer ENCODE raw distkey,
    hierarchy_name character varying(255) ENCODE lzo COLLATE case_sensitive,
    team_name character varying(255) ENCODE lzo COLLATE case_sensitive,
    team_type character varying(255) ENCODE lzo COLLATE case_sensitive,
    is_archived character varying(255) ENCODE lzo COLLATE case_sensitive,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( team_id );