CREATE TABLE mktg_ops_tbls.pbi_cfremappend_cnst (
    grp_key smallint ENCODE az64 distkey,
    list_nm character varying(40) ENCODE lzo,
    list_source_nm character varying(30) ENCODE lzo,
    cnst_mstr_id bigint ENCODE raw,
    cnst_email character varying(200) ENCODE lzo,
    email_key bigint ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );