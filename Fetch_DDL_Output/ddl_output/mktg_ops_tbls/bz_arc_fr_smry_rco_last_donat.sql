CREATE TABLE mktg_ops_tbls.bz_arc_fr_smry_rco_last_donat (
    cnst_mstr_id bigint ENCODE raw distkey,
    trans_id character varying(768) ENCODE lzo,
    rco_dntn_id character varying(765) ENCODE lzo,
    last_dntn_regis_dt date ENCODE az64,
    billing_email character varying(765) ENCODE lzo,
    billing_f_nm character varying(765) ENCODE lzo,
    billing_l_nm character varying(765) ENCODE lzo,
    em_cnst_data_src_cd character varying(30) ENCODE lzo,
    em_cnst_email character varying(200) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );