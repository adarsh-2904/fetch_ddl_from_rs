CREATE TABLE mktg_ops_tbls.pbi_bio_demogrphcs (
    donor_key bigint ENCODE az64 distkey,
    dr_contact_key bigint ENCODE az64,
    race_dsc character varying(382) ENCODE lzo COLLATE case_sensitive,
    gndr_cd character varying(30) ENCODE lzo COLLATE case_sensitive,
    cnst_addr_state character varying(50) ENCODE lzo COLLATE case_sensitive,
    age_band_dsc character varying(10) ENCODE lzo COLLATE case_sensitive,
    sickle_cell_dnr_flg character varying(3) ENCODE lzo COLLATE case_sensitive,
    nk_ep_abo_id character varying(150) ENCODE lzo COLLATE case_sensitive,
    row_stat_cd character varying(1) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp with time zone ENCODE az64,
    appl_src_cd character varying(4) ENCODE lzo COLLATE case_sensitive,
    load_id integer ENCODE az64
)
DISTSTYLE KEY;