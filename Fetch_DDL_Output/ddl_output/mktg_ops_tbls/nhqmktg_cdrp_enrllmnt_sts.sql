CREATE TABLE mktg_ops_tbls.nhqmktg_cdrp_enrllmnt_sts (
    chapter_cd character varying(5) ENCODE lzo,
    cdrp_enrollment_sts integer ENCODE az64,
    chapter_supp_flg character(1) ENCODE lzo
)
DISTSTYLE AUTO;