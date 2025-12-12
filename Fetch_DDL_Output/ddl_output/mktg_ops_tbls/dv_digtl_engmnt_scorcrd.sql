CREATE TABLE mktg_ops_tbls.dv_digtl_engmnt_scorcrd (
    appt_dt date ENCODE raw distkey,
    division_dsc character varying(30) ENCODE lzo,
    calendar_mth_abbr character(3) ENCODE lzo,
    calendar_mth smallint ENCODE az64,
    fiscal_mth smallint ENCODE az64,
    fiscal_yr smallint ENCODE az64,
    mobl_appt_cnt integer ENCODE az64,
    self_appt_cnt integer ENCODE az64,
    digital_appt_cnt integer ENCODE az64,
    total_appt_cnt integer ENCODE az64,
    digital_show_cnt integer ENCODE az64,
    digital_prodctv_proc_cnt integer ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( appt_dt );