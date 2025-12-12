CREATE TABLE mktg_ops_tbls.bz_arc_fr_smry_rco_last_sustnr_donat (
    cnst_mstr_id bigint ENCODE raw distkey,
    trans_id character varying(256) ENCODE raw,
    rco_dntn_id character varying(40) ENCODE lzo,
    last_dntn_regis_dt date ENCODE az64,
    billing_email character varying(255) ENCODE lzo,
    billing_f_nm character varying(50) ENCODE lzo,
    billing_l_nm character varying(50) ENCODE lzo,
    em_cnst_data_src_cd character varying(10) ENCODE lzo,
    em_cnst_email character varying(100) ENCODE lzo,
    rco_subscription_id character varying(255) NOT NULL ENCODE lzo,
    subscription_stat character varying(40) ENCODE lzo,
    online_channel_cd character varying(5) ENCODE lzo,
    nk_public_cd character varying(255) ENCODE lzo,
    ocu_email character varying(255) ENCODE lzo,
    ocu_active_ind smallint ENCODE az64,
    ocu_expiry_ts timestamp without time zone ENCODE az64,
    subscription_last_upgraded timestamp without time zone ENCODE az64,
    magic_link_last_created timestamp without time zone ENCODE az64,
    PRIMARY KEY (rco_subscription_id)
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id, trans_id );