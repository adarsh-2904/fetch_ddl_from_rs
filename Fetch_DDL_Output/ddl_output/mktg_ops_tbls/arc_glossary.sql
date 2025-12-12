CREATE TABLE mktg_ops_tbls.arc_glossary (
    attr_id integer NOT NULL ENCODE az64,
    src_db character varying(30) ENCODE lzo,
    src_tbl character varying(30) ENCODE lzo,
    var_nm character varying(30) ENCODE lzo,
    var_dsc character varying(250) ENCODE lzo,
    var_val_cd character varying(10) ENCODE lzo,
    var_val_dsc character varying(250) ENCODE lzo,
    eff_start_dt date ENCODE az64,
    eff_end_dt date ENCODE az64,
    src_sys_id character varying(10) ENCODE lzo,
    src_sys_nm character varying(30) ENCODE lzo,
    term_own_cd character varying(10) ENCODE lzo,
    term_own_nm character varying(50) ENCODE lzo
)
DISTSTYLE ALL;