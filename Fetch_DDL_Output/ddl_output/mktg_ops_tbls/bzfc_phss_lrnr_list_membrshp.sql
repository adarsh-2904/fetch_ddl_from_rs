CREATE TABLE mktg_ops_tbls.bzfc_phss_lrnr_list_membrshp (
    list_typ_key integer NOT NULL ENCODE az64,
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    cert_expire_dt date ENCODE az64,
    membrshp_start_dt date ENCODE az64,
    membrshp_end_dt date ENCODE az64,
    course_nm character varying(250) ENCODE lzo,
    earliestexpmth character varying(27) ENCODE lzo,
    subject_area character varying(100) ENCODE lzo,
    focis_pgm character varying(100) ENCODE lzo,
    lrnrcert_comp1 character varying(250) ENCODE lzo,
    lrnrcert_exp_dt1 date ENCODE az64,
    lrnrcert_comp2 character varying(250) ENCODE lzo,
    lrnrcert_exp_dt2 date ENCODE az64,
    lrnrcert_comp3 character varying(250) ENCODE lzo,
    lrnrcert_exp_dt3 date ENCODE az64,
    lrnrcert_comp4 character varying(250) ENCODE lzo,
    lrnrcert_exp_dt4 date ENCODE az64,
    lrnrcert_comp5 character varying(250) ENCODE lzo,
    lrnrcert_exp_dt5 date ENCODE az64,
    list_run_dt date ENCODE az64,
    dw_create_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_update_ts timestamp without time zone NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( list_typ_key, cnst_mstr_id );