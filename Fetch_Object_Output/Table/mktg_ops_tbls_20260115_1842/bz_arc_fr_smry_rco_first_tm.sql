CREATE TABLE mktg_ops_tbls.bz_arc_fr_smry_rco_first_tm (
    cnst_mstr_id bigint ENCODE raw distkey,
    trans_id character varying(256) ENCODE raw COLLATE case_sensitive,
    rco_dntn_id character varying(40) ENCODE lzo COLLATE case_sensitive,
    first_time_trans_dt date ENCODE az64,
    billing_email character varying(255) ENCODE lzo COLLATE case_sensitive,
    billing_f_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    billing_l_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    em_cnst_data_src_cd character varying(10) ENCODE lzo COLLATE case_sensitive,
    em_cnst_email character varying(100) ENCODE lzo COLLATE case_sensitive,
    cnst_mstr_id_cnt integer ENCODE az64,
    first_cnst_mstr_id bigint ENCODE az64,
    last_cnst_mstr_id bigint ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id, trans_id );