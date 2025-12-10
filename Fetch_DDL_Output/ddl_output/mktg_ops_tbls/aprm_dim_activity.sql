CREATE TABLE mktg_ops_tbls.aprm_dim_activity (
    activity_id integer ENCODE az64,
    activity_title character varying(225) ENCODE lzo,
    activity_typ character varying(765) ENCODE lzo,
    activity_title_cat character varying(60) ENCODE lzo,
    activity_typ_status character varying(765) ENCODE lzo,
    activity_begin_dt timestamp without time zone ENCODE az64,
    activity_end_dt timestamp without time zone ENCODE az64,
    activity_owner character varying(2295) ENCODE lzo,
    activity_sub_typ character varying(765) ENCODE lzo,
    campgn_freq character varying(765) ENCODE lzo,
    emal_pref_typ character varying(765) ENCODE lzo
)
DISTSTYLE ALL;