CREATE TABLE mktg_ops_tbls.aprm_wb_replc_offrs (
    offer_id integer ENCODE az64,
    title character varying(225) ENCODE lzo,
    offer_code character varying(225) ENCODE lzo,
    offer_type character varying(765) ENCODE lzo,
    status character varying(2295) ENCODE lzo,
    activity_specific character varying(2295) ENCODE lzo,
    business_unit character varying(765) ENCODE lzo
)
DISTSTYLE ALL;