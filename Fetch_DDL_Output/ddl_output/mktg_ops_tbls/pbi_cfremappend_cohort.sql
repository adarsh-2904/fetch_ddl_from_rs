CREATE TABLE mktg_ops_tbls.pbi_cfremappend_cohort (
    fy character(4) ENCODE lzo,
    grp_key smallint ENCODE az64 distkey,
    cohort_cd character varying(16) ENCODE lzo,
    append_dt date ENCODE az64,
    list_load_dt date ENCODE az64,
    list_upload_dt date ENCODE az64,
    append_data_src_cd character varying(4) ENCODE lzo,
    list_nm character varying(40) ENCODE lzo,
    list_source_nm character varying(30) ENCODE lzo,
    run_dt date ENCODE az64
)
DISTSTYLE KEY;