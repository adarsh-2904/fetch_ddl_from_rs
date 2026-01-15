CREATE TABLE mktg_ops_tbls.gms_cnst_behvrl_segmnt (
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    hhla_id character varying(18) ENCODE lzo COLLATE case_sensitive,
    bsd_cd character varying(2) ENCODE lzo COLLATE case_sensitive,
    bsd_dsc character varying(30) ENCODE bytedict COLLATE case_sensitive
)
DISTSTYLE KEY;