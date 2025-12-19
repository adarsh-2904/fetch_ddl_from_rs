CREATE TABLE mktg_ops_tbls.pacific_east_phone_append (
    cnst_mstr_id bigint ENCODE az64,
    orig_cnst_mstr_id bigint ENCODE az64,
    cnst_prsn_f_nm character varying(200) ENCODE lzo COLLATE case_insensitive,
    cnst_prsn_l_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    cnst_prsn_full_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    dm_locator_addr_key integer ENCODE az64,
    cnst_line_1_addr character varying(200) ENCODE lzo COLLATE case_insensitive,
    cnst_line_2_addr character varying(200) ENCODE lzo COLLATE case_insensitive,
    cnst_city_nm character varying(200) ENCODE lzo COLLATE case_insensitive,
    cnst_st_cd character varying(200) ENCODE lzo COLLATE case_insensitive,
    cnst_zip_5_cd character varying(5) ENCODE lzo COLLATE case_insensitive,
    locator_dnc_ind smallint ENCODE az64,
    arc_provided_phone_num character varying(14) ENCODE lzo COLLATE case_insensitive,
    addr_typ character varying(5) ENCODE lzo COLLATE case_insensitive,
    append_phone_num character varying(14) ENCODE lzo COLLATE case_insensitive,
    append_status character varying(25) ENCODE lzo COLLATE case_insensitive,
    line_typ character varying(8) ENCODE lzo COLLATE case_insensitive,
    list_source_nm character varying(90) ENCODE lzo COLLATE case_insensitive,
    list_upload_ts timestamp without time zone ENCODE az64,
    row_stat_cd character varying(4) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE AUTO;