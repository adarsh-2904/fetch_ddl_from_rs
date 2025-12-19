CREATE TABLE mktg_ops_tbls.bzfc_sponsor_journey_smry (
    spon_ext_nm character varying(125) ENCODE lzo COLLATE case_sensitive distkey,
    nk_spon_ext_id character varying(9) ENCODE lzo COLLATE case_sensitive,
    spon_con_full_nm character varying(101) ENCODE lzo COLLATE case_sensitive,
    email_address character varying(100) ENCODE lzo COLLATE case_sensitive,
    customer_nm1 character varying(360) ENCODE lzo COLLATE case_sensitive,
    customer_nm2 character varying(360) ENCODE lzo COLLATE case_sensitive,
    customer_nm3 character varying(360) ENCODE lzo COLLATE case_sensitive,
    customer_nm4 character varying(360) ENCODE lzo COLLATE case_sensitive,
    customer_nm5 character varying(360) ENCODE lzo COLLATE case_sensitive,
    drive_start_dt date ENCODE raw,
    weekly_start_dt date ENCODE az64,
    weekly_end_dt date ENCODE az64,
    list_run_dt date ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( drive_start_dt );