CREATE TABLE mktg_ops_tbls.aprm_wb_replc_act_cells (
    activity_cell_id integer ENCODE az64,
    activity_id integer ENCODE az64,
    activity_offer_id integer ENCODE az64,
    cell_type character varying(765) ENCODE lzo COLLATE case_insensitive,
    champion_cell character varying(225) ENCODE lzo COLLATE case_insensitive,
    code character varying(225) ENCODE lzo COLLATE case_insensitive,
    description character varying(765) ENCODE lzo COLLATE case_insensitive,
    last_modified_by character varying(2295) ENCODE lzo COLLATE case_insensitive,
    last_modified_date timestamp without time zone ENCODE az64,
    source_code character varying(225) ENCODE lzo COLLATE case_insensitive,
    title character varying(225) ENCODE lzo COLLATE case_insensitive,
    drop_date timestamp without time zone ENCODE az64
)
DISTSTYLE ALL;