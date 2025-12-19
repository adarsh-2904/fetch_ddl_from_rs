CREATE TABLE mktg_ops_tbls.aprm_wb_replc_activities (
    activity_id integer ENCODE az64,
    title character varying(225) ENCODE lzo COLLATE case_insensitive,
    activity_type character varying(765) ENCODE lzo COLLATE case_insensitive,
    activity_type_status character varying(765) ENCODE lzo COLLATE case_insensitive,
    begin_date timestamp without time zone ENCODE az64,
    end_date timestamp without time zone ENCODE az64,
    owner character varying(2295) ENCODE lzo COLLATE case_insensitive,
    administrator character varying(2295) ENCODE lzo COLLATE case_insensitive,
    activity_sub_type character varying(765) ENCODE lzo COLLATE case_insensitive,
    campaign_frequency character varying(765) ENCODE lzo COLLATE case_insensitive,
    email_preference_type character varying(765) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;