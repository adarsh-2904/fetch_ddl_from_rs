CREATE TABLE mktg_ops_tbls.aprm_wb_replc_act_cells (
    activity_cell_id integer ENCODE az64,
    activity_id integer ENCODE az64,
    activity_offer_id integer ENCODE az64,
    cell_type character varying(765) ENCODE lzo,
    champion_cell character varying(225) ENCODE lzo,
    code character varying(225) ENCODE lzo,
    description character varying(765) ENCODE lzo,
    last_modified_by character varying(2295) ENCODE lzo,
    last_modified_date timestamp without time zone ENCODE az64,
    source_code character varying(225) ENCODE lzo,
    title character varying(225) ENCODE lzo,
    drop_date timestamp without time zone ENCODE az64
)
DISTSTYLE ALL;