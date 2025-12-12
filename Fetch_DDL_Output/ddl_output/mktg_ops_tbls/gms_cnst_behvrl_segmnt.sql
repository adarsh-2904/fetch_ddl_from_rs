CREATE TABLE mktg_ops_tbls.gms_cnst_behvrl_segmnt (
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    hhla_id character varying(18) ENCODE lzo,
    bsd_cd character varying(2) ENCODE lzo,
    bsd_dsc character varying(30) ENCODE bytedict
)
DISTSTYLE KEY;