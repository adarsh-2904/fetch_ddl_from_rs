CREATE TABLE mktg_ops_tbls.bz_arc_fr_smry_atg_first_tm (
    cnst_mstr_id bigint ENCODE az64 distkey,
    nk_order_id character varying(40) ENCODE lzo,
    first_time_trans_dt date ENCODE az64,
    cnvo_email character varying(255) ENCODE lzo,
    cnvo_bill_to_first_nm character varying(50) ENCODE lzo,
    cnvo_bill_to_last_nm character varying(50) ENCODE lzo,
    em_cnst_data_src_cd character varying(10) ENCODE lzo,
    em_cnst_email character varying(100) ENCODE lzo
)
DISTSTYLE KEY;