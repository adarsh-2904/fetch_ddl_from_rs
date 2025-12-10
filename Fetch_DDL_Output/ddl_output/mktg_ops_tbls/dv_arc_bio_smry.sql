CREATE TABLE mktg_ops_tbls.dv_arc_bio_smry (
    chap_cd character varying(5) ENCODE lzo,
    gen_sgmnt_cd character(1) ENCODE lzo,
    gen_sgmnt_dsc character varying(100) ENCODE lzo,
    engmnt_yr integer ENCODE az64,
    engmnt_mnth integer ENCODE az64,
    engmnt_wk integer ENCODE az64,
    distnct_dntn_cnt bigint ENCODE az64,
    walkin_cnt bigint ENCODE az64,
    first_dntn_cnt bigint ENCODE az64,
    phleb_cnt bigint ENCODE az64,
    doubl_rbc_cnt numeric(38,0) ENCODE az64
)
DISTSTYLE AUTO;