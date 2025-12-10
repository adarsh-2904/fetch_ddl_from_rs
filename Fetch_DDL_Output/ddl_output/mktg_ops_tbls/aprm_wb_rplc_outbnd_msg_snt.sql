CREATE TABLE mktg_ops_tbls.aprm_wb_rplc_outbnd_msg_snt (
    history_record_id integer ENCODE az64,
    history_record_date timestamp without time zone ENCODE az64,
    email_id integer ENCODE az64,
    audience_member_id integer ENCODE az64,
    subscriber_key character varying(108) ENCODE lzo,
    email_address character varying(765) ENCODE lzo,
    form_id integer ENCODE az64,
    form_title character varying(225) ENCODE lzo,
    reply_to_address character varying(765) ENCODE lzo,
    email_domain character varying(765) ENCODE lzo,
    segment_id integer ENCODE az64,
    segmentation_id integer ENCODE az64,
    interaction_id integer ENCODE az64,
    sent_date timestamp without time zone ENCODE az64,
    delivered_date timestamp without time zone ENCODE az64
)
DISTSTYLE ALL;