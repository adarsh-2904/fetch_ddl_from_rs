CREATE TABLE mktg_ops_tbls.aprm_wb_rplc_fr_prf_cntr_lt (
    history_record_id integer ENCODE az64,
    history_record_date timestamp without time zone ENCODE az64,
    abstract character varying(765) ENCODE lzo,
    audience_member_id integer ENCODE az64,
    pref_cntr_lt_cnst_mstr_id integer ENCODE az64,
    pref_cntr_lt_obm character varying(30) ENCODE lzo,
    pref_cntr_lt_first_name character varying(225) ENCODE lzo,
    pref_cntr_lt_last_name character varying(225) ENCODE lzo,
    pref_cntr_lt_email_address character varying(765) ENCODE lzo,
    pref_cntr_lt_cntc_pref character varying(225) ENCODE lzo
)
DISTSTYLE ALL;