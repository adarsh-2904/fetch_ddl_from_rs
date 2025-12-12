CREATE TABLE mktg_ops_tbls.arc_missing_script_numbers (
    cnst_mstr_id bigint ENCODE az64,
    script_num smallint ENCODE az64,
    campgn_cd character varying(10) ENCODE lzo
)
DISTSTYLE ALL;