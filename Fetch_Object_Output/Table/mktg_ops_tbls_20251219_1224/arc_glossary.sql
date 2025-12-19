CREATE TABLE mktg_ops_tbls.arc_glossary (
    attr_id integer NOT NULL ENCODE az64,
    src_db character varying(30) ENCODE lzo COLLATE case_insensitive,
    src_tbl character varying(30) ENCODE lzo COLLATE case_insensitive,
    var_nm character varying(30) ENCODE lzo COLLATE case_insensitive,
    var_dsc character varying(250) ENCODE lzo COLLATE case_insensitive,
    var_val_cd character varying(10) ENCODE lzo COLLATE case_insensitive,
    var_val_dsc character varying(250) ENCODE lzo COLLATE case_insensitive,
    eff_start_dt date ENCODE az64,
    eff_end_dt date ENCODE az64,
    src_sys_id character varying(10) ENCODE lzo COLLATE case_insensitive,
    src_sys_nm character varying(30) ENCODE lzo COLLATE case_insensitive,
    term_own_cd character varying(10) ENCODE lzo COLLATE case_insensitive,
    term_own_nm character varying(50) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE ALL;