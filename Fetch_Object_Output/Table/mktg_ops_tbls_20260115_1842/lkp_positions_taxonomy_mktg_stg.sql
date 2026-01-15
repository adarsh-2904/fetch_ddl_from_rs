CREATE TABLE mktg_ops_tbls.lkp_positions_taxonomy_mktg_stg (
    placement_id integer ENCODE raw distkey,
    placement_name character varying(200) ENCODE lzo COLLATE case_sensitive,
    hierarchy_id integer ENCODE az64,
    is_archived character varying(5) ENCODE lzo COLLATE case_sensitive,
    service_name character varying(100) ENCODE lzo COLLATE case_sensitive,
    service_area_name character varying(100) ENCODE lzo COLLATE case_sensitive,
    position_type_name character varying(100) ENCODE lzo COLLATE case_sensitive,
    sub_type_name character varying(100) ENCODE lzo COLLATE case_sensitive,
    biomed_manuf_site character varying(100) ENCODE lzo COLLATE case_sensitive,
    biomed_region character varying(100) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( placement_id );