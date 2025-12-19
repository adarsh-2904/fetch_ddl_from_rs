CREATE TABLE mktg_ops_tbls.nhqmktg_cdrp_enrllmnt_sts (
    chapter_cd character varying(5) ENCODE lzo COLLATE case_sensitive,
    cdrp_enrollment_sts integer ENCODE az64,
    chapter_supp_flg character(1) ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE AUTO;