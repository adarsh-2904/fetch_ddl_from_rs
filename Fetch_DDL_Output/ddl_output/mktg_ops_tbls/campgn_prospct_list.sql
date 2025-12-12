CREATE TABLE mktg_ops_tbls.campgn_prospct_list (
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    orig_cnst_mstr_id bigint NOT NULL ENCODE az64,
    cell_src_cd character varying(14) ENCODE lzo,
    email_src_cd character varying(14) ENCODE lzo,
    digitall_src_cd character varying(14) ENCODE lzo,
    motivtn_cd character varying(20) ENCODE lzo,
    list_typ character varying(20) ENCODE lzo,
    list_nm character varying(40) ENCODE lzo,
    list_dsc character varying(255) ENCODE lzo,
    list_owner_nm character varying(50) ENCODE lzo,
    list_uploaded_by_nm character varying(50) ENCODE lzo,
    treatmnt_cd character varying(20) ENCODE lzo,
    treatmnt_dsc character varying(100) ENCODE lzo,
    segmnt_cd character varying(20) ENCODE lzo,
    segmnt_dsc character varying(100) ENCODE lzo,
    test_grp_ind smallint ENCODE az64,
    vc_scr_id bigint ENCODE az64,
    vc_scr_val character varying(9) ENCODE lzo,
    dec_scr_id bigint ENCODE az64,
    dec_scr_val numeric(8,2) ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64
)
DISTSTYLE KEY;