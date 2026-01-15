CREATE TABLE mktg_ops_tbls.srvy_anvrsy_vlntr_rspns_cmnt_curnt (
    iwebappid integer ENCODE az64,
    iwebapplogid integer ENCODE az64,
    respns_ts timestamp without time zone ENCODE az64,
    cnst_mstr_id bigint ENCODE az64,
    orig_cnst_mstr_id bigint ENCODE az64,
    email character varying(255) ENCODE lzo COLLATE case_insensitive,
    survey_nm character varying(255) ENCODE lzo COLLATE case_insensitive,
    why_backgrnd_scr_cmt character varying(4000) ENCODE lzo COLLATE case_insensitive,
    why_recgnzd_aprctd_scr_cmt character varying(12000) ENCODE lzo COLLATE case_insensitive,
    why_suprt_suprvsr_scr_cmt character varying(12000) ENCODE lzo COLLATE case_insensitive,
    why_teamwrk_scr_cmt character varying(12000) ENCODE lzo COLLATE case_insensitive,
    exprnc_cmt character varying(12000) ENCODE lzo COLLATE case_insensitive,
    dw_trans_ts timestamp without time zone ENCODE az64,
    srcsys_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) ENCODE lzo COLLATE case_insensitive,
    load_id integer ENCODE az64
)
DISTSTYLE AUTO;