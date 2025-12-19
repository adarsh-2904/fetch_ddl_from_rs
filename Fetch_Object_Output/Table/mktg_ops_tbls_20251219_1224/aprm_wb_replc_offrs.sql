CREATE TABLE mktg_ops_tbls.aprm_wb_replc_offrs (
    offer_id integer ENCODE az64,
    title character varying(225) ENCODE lzo COLLATE case_insensitive,
    offer_code character varying(225) ENCODE lzo COLLATE case_insensitive,
    offer_type character varying(765) ENCODE lzo COLLATE case_insensitive,
    status character varying(2295) ENCODE lzo COLLATE case_insensitive,
    activity_specific character varying(2295) ENCODE lzo COLLATE case_insensitive,
    business_unit character varying(765) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;