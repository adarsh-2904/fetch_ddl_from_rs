CREATE TABLE mktg_ops_tbls.aprm_wb_replc_activities (
    activity_id integer ENCODE az64,
    title character varying(225) ENCODE lzo,
    activity_type character varying(765) ENCODE lzo,
    activity_type_status character varying(765) ENCODE lzo,
    begin_date timestamp without time zone ENCODE az64,
    end_date timestamp without time zone ENCODE az64,
    owner character varying(2295) ENCODE lzo,
    administrator character varying(2295) ENCODE lzo,
    activity_sub_type character varying(765) ENCODE lzo,
    campaign_frequency character varying(765) ENCODE lzo,
    email_preference_type character varying(765) ENCODE lzo
)
DISTSTYLE ALL;