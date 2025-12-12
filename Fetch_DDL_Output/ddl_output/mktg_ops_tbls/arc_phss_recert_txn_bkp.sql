CREATE TABLE mktg_ops_tbls.arc_phss_recert_txn_bkp (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    cnst_hsld_id character varying(18) ENCODE lzo,
    person_key integer ENCODE az64,
    component_key integer NOT NULL ENCODE az64,
    component_nm character varying(1020) ENCODE lzo,
    comp_valid_for character varying(20) ENCODE lzo,
    comp_end_dt date ENCODE az64,
    course_key integer NOT NULL ENCODE az64,
    course_nm character varying(1020) ENCODE lzo,
    course_subject_area character varying(100) ENCODE lzo,
    course_focis_pgm character varying(100) ENCODE lzo,
    course_delivery_typ character varying(50) ENCODE lzo,
    course_discontinued_flg character varying(1) ENCODE lzo,
    course_refresher_flg character varying(1) ENCODE lzo,
    offer_id character varying(20) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;