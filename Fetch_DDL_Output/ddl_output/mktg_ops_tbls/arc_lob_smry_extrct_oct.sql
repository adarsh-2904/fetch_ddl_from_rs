CREATE TABLE mktg_ops_tbls.arc_lob_smry_extrct_oct (
    hh_la_id character varying(30) ENCODE lzo,
    total_blood_dntn_cnt integer ENCODE az64,
    first_blood_dntn_dt date ENCODE az64,
    recent_blood_dntn_dt date ENCODE az64,
    total_course_cnt integer ENCODE az64,
    first_course_cmpltn_dt date ENCODE az64,
    recent_course_cmpltn_dt date ENCODE az64,
    active_vlntr_cnt integer ENCODE az64,
    lapsed_vlntr_cnt integer ENCODE az64,
    cas_client_cnt integer ENCODE az64
)
DISTSTYLE ALL;