CREATE TABLE mktg_ops_tbls.srvy_hsptl_respondents_hst_b4072825 (
    respondent_id smallint NOT NULL ENCODE az64,
    respondent_nm character varying(100) ENCODE lzo COLLATE case_sensitive,
    respondent_email character varying(100) ENCODE lzo COLLATE case_sensitive,
    respondent_role character varying(50) ENCODE lzo COLLATE case_sensitive,
    hopital_id character varying(20) ENCODE lzo COLLATE case_sensitive,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64,
    UNIQUE (respondent_id)
)
DISTSTYLE AUTO;