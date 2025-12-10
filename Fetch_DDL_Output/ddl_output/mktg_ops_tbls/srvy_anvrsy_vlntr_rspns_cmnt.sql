CREATE TABLE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt (
    snapshot_ts timestamp without time zone ENCODE az64,
    history_record_ts timestamp without time zone ENCODE az64,
    history_record_id integer ENCODE az64,
    adnc_mbr_id integer ENCODE az64,
    cnst_mstr_id bigint ENCODE az64,
    orig_cnst_mstr_id bigint ENCODE az64,
    last_nm character varying(255) ENCODE lzo,
    email character varying(255) ENCODE lzo,
    survey_nm character varying(255) ENCODE lzo,
    other_srvc_cmt character varying(4000) ENCODE lzo,
    why_scr_cmt character varying(12000) ENCODE lzo,
    why_scr_tmwrk_cmt character varying(12000) ENCODE lzo,
    vlntr_exp_cmt character varying(12000) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( snapshot_ts );