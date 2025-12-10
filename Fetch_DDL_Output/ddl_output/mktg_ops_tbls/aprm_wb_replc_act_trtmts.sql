CREATE TABLE mktg_ops_tbls.aprm_wb_replc_act_trtmts (
    activity_treatment_id integer ENCODE az64,
    activity_id integer ENCODE az64,
    treatment_id integer ENCODE az64,
    currency_code character varying(765) ENCODE lzo,
    treatment_instance_end_date timestamp without time zone ENCODE az64,
    treatment_instance_start_date timestamp without time zone ENCODE az64
)
DISTSTYLE ALL;