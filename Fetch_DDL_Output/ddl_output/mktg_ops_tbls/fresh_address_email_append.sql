CREATE TABLE mktg_ops_tbls.fresh_address_email_append (
    cnst_mstr_id bigint NOT NULL ENCODE raw distkey,
    orig_cnst_mstr_id bigint ENCODE az64,
    cnst_prsn_f_nm character varying(200) ENCODE lzo,
    cnst_prsn_m_nm character varying(50) ENCODE lzo,
    cnst_prsn_l_nm character varying(50) ENCODE lzo,
    cnst_line_1_addr character varying(200) ENCODE lzo,
    cnst_line_2_addr character varying(200) ENCODE lzo,
    cnst_city_nm character varying(200) ENCODE lzo,
    cnst_st_cd character varying(200) ENCODE lzo,
    cnst_zip_5_cd character varying(5) ENCODE lzo,
    match_typ_cd character varying(5) ENCODE lzo,
    cnst_email character varying(200) ENCODE lzo,
    list_nm character varying(30) ENCODE lzo,
    list_upload_ts timestamp without time zone ENCODE az64,
    locator_dnc_ind smallint ENCODE az64,
    append_comnt character varying(200) ENCODE lzo,
    row_stat_cd character varying(4) ENCODE lzo,
    PRIMARY KEY (cnst_mstr_id)
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );