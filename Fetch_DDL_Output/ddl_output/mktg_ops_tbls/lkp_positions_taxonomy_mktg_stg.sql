CREATE TABLE mktg_ops_tbls.lkp_positions_taxonomy_mktg_stg (
    placement_id integer ENCODE raw distkey,
    placement_name character varying(200) ENCODE lzo,
    hierarchy_id integer ENCODE az64,
    is_archived character varying(5) ENCODE lzo,
    service_name character varying(100) ENCODE lzo,
    service_area_name character varying(100) ENCODE lzo,
    position_type_name character varying(100) ENCODE lzo,
    sub_type_name character varying(100) ENCODE lzo,
    biomed_manuf_site character varying(100) ENCODE lzo,
    biomed_region character varying(100) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( placement_id );