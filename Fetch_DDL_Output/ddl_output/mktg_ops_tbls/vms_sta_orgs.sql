CREATE TABLE mktg_ops_tbls.vms_sta_orgs (
    team_id integer ENCODE raw distkey,
    hierarchy_name character varying(255) ENCODE lzo,
    team_name character varying(255) ENCODE lzo,
    team_type character varying(255) ENCODE lzo,
    is_archived character varying(255) ENCODE lzo,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( team_id );