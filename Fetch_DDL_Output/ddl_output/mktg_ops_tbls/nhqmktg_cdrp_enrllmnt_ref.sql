CREATE TABLE mktg_ops_tbls.nhqmktg_cdrp_enrllmnt_ref (
    cdrp_enrollment_sts integer ENCODE az64,
    cdrp_enrollment_sts_desc character varying(100) ENCODE lzo
)
DISTSTYLE AUTO;