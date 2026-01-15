CREATE TABLE mktg_ops_tbls.arc_tag_non_fr_extrct_bridge (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    hh_la_id character varying(30) ENCODE lzo COLLATE case_insensitive,
    extract_date date ENCODE az64,
    active_flg character(1) ENCODE lzo COLLATE case_insensitive,
    dw_load_id integer ENCODE az64
)
DISTSTYLE ALL;