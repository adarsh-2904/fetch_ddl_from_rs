CREATE TABLE mktg_ops_tbls.campgn_prospct_list (
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    orig_cnst_mstr_id bigint NOT NULL ENCODE az64,
    cell_src_cd character varying(14) ENCODE lzo COLLATE case_sensitive,
    email_src_cd character varying(14) ENCODE lzo COLLATE case_sensitive,
    digitall_src_cd character varying(14) ENCODE lzo COLLATE case_sensitive,
    motivtn_cd character varying(20) ENCODE lzo COLLATE case_sensitive,
    list_typ character varying(20) ENCODE lzo COLLATE case_sensitive,
    list_nm character varying(40) ENCODE lzo COLLATE case_sensitive,
    list_dsc character varying(255) ENCODE lzo COLLATE case_sensitive,
    list_owner_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    list_uploaded_by_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    treatmnt_cd character varying(20) ENCODE lzo COLLATE case_sensitive,
    treatmnt_dsc character varying(100) ENCODE lzo COLLATE case_sensitive,
    segmnt_cd character varying(20) ENCODE lzo COLLATE case_sensitive,
    segmnt_dsc character varying(100) ENCODE lzo COLLATE case_sensitive,
    test_grp_ind smallint ENCODE az64,
    vc_scr_id bigint ENCODE az64,
    vc_scr_val character varying(9) ENCODE lzo COLLATE case_sensitive,
    dec_scr_id bigint ENCODE az64,
    dec_scr_val numeric(8,2) ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64
)
DISTSTYLE KEY;