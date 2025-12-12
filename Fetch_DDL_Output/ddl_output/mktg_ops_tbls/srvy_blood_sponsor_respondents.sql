CREATE TABLE mktg_ops_tbls.srvy_blood_sponsor_respondents (
    respondent_id smallint NOT NULL ENCODE az64,
    sponsor_key integer NOT NULL ENCODE az64,
    sf_contact_id character varying(100) ENCODE lzo,
    respondent_nm character varying(100) ENCODE lzo,
    respondent_email character varying(100) ENCODE lzo,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    UNIQUE (respondent_id)
)
DISTSTYLE AUTO;