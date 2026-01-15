CREATE TABLE mktg_ops_tbls.bz_arc_fr_smry_atg_first_tm (
    cnst_mstr_id bigint ENCODE az64 distkey,
    nk_order_id character varying(40) ENCODE lzo COLLATE case_sensitive,
    first_time_trans_dt date ENCODE az64,
    cnvo_email character varying(255) ENCODE lzo COLLATE case_sensitive,
    cnvo_bill_to_first_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    cnvo_bill_to_last_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    em_cnst_data_src_cd character varying(10) ENCODE lzo COLLATE case_sensitive,
    em_cnst_email character varying(100) ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE KEY;