CREATE TABLE mktg_ops_tbls.aprm_dim_activity (
    activity_id integer ENCODE az64,
    activity_title character varying(225) ENCODE lzo COLLATE case_insensitive,
    activity_typ character varying(765) ENCODE lzo COLLATE case_insensitive,
    activity_title_cat character varying(60) ENCODE lzo COLLATE case_insensitive,
    activity_typ_status character varying(765) ENCODE lzo COLLATE case_insensitive,
    activity_begin_dt timestamp without time zone ENCODE az64,
    activity_end_dt timestamp without time zone ENCODE az64,
    activity_owner character varying(2295) ENCODE lzo COLLATE case_insensitive,
    activity_sub_typ character varying(765) ENCODE lzo COLLATE case_insensitive,
    campgn_freq character varying(765) ENCODE lzo COLLATE case_insensitive,
    emal_pref_typ character varying(765) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;