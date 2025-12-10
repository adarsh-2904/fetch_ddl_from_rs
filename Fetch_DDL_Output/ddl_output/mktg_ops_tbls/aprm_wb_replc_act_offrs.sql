CREATE TABLE mktg_ops_tbls.aprm_wb_replc_act_offrs (
    activity_offer_id integer ENCODE az64,
    activity_id integer ENCODE az64,
    offer_id integer ENCODE az64,
    offer_instance_end_date timestamp without time zone ENCODE az64,
    offer_instance_start_date timestamp without time zone ENCODE az64
)
DISTSTYLE ALL;