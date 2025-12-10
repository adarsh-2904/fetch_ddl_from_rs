CREATE TABLE mktg_ops_tbls.pacific_east_phone_append (
    cnst_mstr_id bigint ENCODE az64,
    orig_cnst_mstr_id bigint ENCODE az64,
    cnst_prsn_f_nm character varying(200) ENCODE lzo,
    cnst_prsn_l_nm character varying(50) ENCODE lzo,
    cnst_prsn_full_nm character varying(50) ENCODE lzo,
    dm_locator_addr_key integer ENCODE az64,
    cnst_line_1_addr character varying(200) ENCODE lzo,
    cnst_line_2_addr character varying(200) ENCODE lzo,
    cnst_city_nm character varying(200) ENCODE lzo,
    cnst_st_cd character varying(200) ENCODE lzo,
    cnst_zip_5_cd character varying(5) ENCODE lzo,
    locator_dnc_ind smallint ENCODE az64,
    arc_provided_phone_num character varying(14) ENCODE lzo,
    addr_typ character varying(5) ENCODE lzo,
    append_phone_num character varying(14) ENCODE lzo,
    append_status character varying(25) ENCODE lzo,
    line_typ character varying(8) ENCODE lzo,
    list_source_nm character varying(90) ENCODE lzo,
    list_upload_ts timestamp without time zone ENCODE az64,
    row_stat_cd character varying(4) ENCODE lzo
)
DISTSTYLE AUTO;