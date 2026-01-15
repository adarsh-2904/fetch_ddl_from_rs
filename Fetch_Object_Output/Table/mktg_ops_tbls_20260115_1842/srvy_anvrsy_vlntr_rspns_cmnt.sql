CREATE TABLE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt (
    snapshot_ts timestamp without time zone ENCODE az64,
    history_record_ts timestamp without time zone ENCODE az64,
    history_record_id integer ENCODE az64,
    adnc_mbr_id integer ENCODE az64,
    cnst_mstr_id bigint ENCODE az64,
    orig_cnst_mstr_id bigint ENCODE az64,
    last_nm character varying(255) ENCODE lzo COLLATE case_insensitive,
    email character varying(255) ENCODE lzo COLLATE case_insensitive,
    survey_nm character varying(255) ENCODE lzo COLLATE case_insensitive,
    other_srvc_cmt character varying(4000) ENCODE lzo COLLATE case_insensitive,
    why_scr_cmt character varying(12000) ENCODE lzo COLLATE case_insensitive,
    why_scr_tmwrk_cmt character varying(12000) ENCODE lzo COLLATE case_insensitive,
    vlntr_exp_cmt character varying(12000) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE AUTO
SORTKEY ( snapshot_ts );