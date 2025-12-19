CREATE TABLE mktg_ops_tbls.aprm_wb_apnd_unsubs_rplc (
    history_record_id integer ENCODE az64,
    history_record_dt timestamp without time zone ENCODE az64,
    audience_member_id integer ENCODE az64,
    cnst_mstr_id integer ENCODE az64,
    fst_nm character varying(75) ENCODE lzo COLLATE case_insensitive,
    lst_nm character varying(75) ENCODE lzo COLLATE case_insensitive,
    email_addr character varying(135) ENCODE lzo COLLATE case_insensitive,
    contact_pref character varying(195) ENCODE lzo COLLATE case_insensitive,
    obm_id character varying(765) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;