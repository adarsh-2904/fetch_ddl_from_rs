CREATE TABLE mktg_ops_tbls.mktg_sky_dates (
    calendar_key integer ENCODE az64,
    calendar_dt date ENCODE az64,
    sky_typ character varying(10) ENCODE lzo,
    disastr1_nm character varying(100) ENCODE lzo,
    disastr1_typ character varying(30) ENCODE lzo,
    disastr2_nm character varying(100) ENCODE lzo,
    disastr3_nm character varying(100) ENCODE lzo,
    disastr4_nm character varying(100) ENCODE lzo,
    disastr5_nm character varying(100) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    calendar_key	calendar_dt	sky_typ	disastr1_nm	disastr1_typ	disastr2_nm	disastr3_nm	disastr4_nm	disastr5_nm	dw_trans_ts	row_stat_ character varying(128) ENCODE lzo
)
DISTSTYLE AUTO;