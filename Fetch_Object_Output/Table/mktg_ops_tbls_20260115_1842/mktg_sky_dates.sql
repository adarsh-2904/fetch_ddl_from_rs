CREATE TABLE mktg_ops_tbls.mktg_sky_dates (
    calendar_key integer ENCODE az64,
    calendar_dt date ENCODE az64,
    sky_typ character varying(10) ENCODE lzo COLLATE case_insensitive,
    disastr1_nm character varying(100) ENCODE lzo COLLATE case_insensitive,
    disastr1_typ character varying(30) ENCODE lzo COLLATE case_insensitive,
    disastr2_nm character varying(100) ENCODE lzo COLLATE case_insensitive,
    disastr3_nm character varying(100) ENCODE lzo COLLATE case_insensitive,
    disastr4_nm character varying(100) ENCODE lzo COLLATE case_insensitive,
    disastr5_nm character varying(100) ENCODE lzo COLLATE case_insensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_insensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( calendar_key );