CREATE TABLE mktg_ops_tbls.dv_arc_vms_smry (
    chap_cd character(5) ENCODE lzo,
    gen_sgmnt_cd character(1) ENCODE lzo,
    gen_sgmnt_dsc character varying(100) ENCODE lzo,
    engmnt_yr integer ENCODE az64,
    engmnt_mnth integer ENCODE az64,
    engmnt_wk integer ENCODE az64,
    hrs_wrkd_cnt bigint ENCODE az64
)
DISTSTYLE AUTO;