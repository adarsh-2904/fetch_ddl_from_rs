CREATE TABLE mktg_ops_tbls.bzl_cnst_mstr_fsa_in_primary (
    cnst_mstr_id bigint ENCODE az64 distkey,
    primary_cnst_mstr_id bigint ENCODE az64,
    bzd_cnst_fsa_key bigint ENCODE az64,
    bzd_acct_fsa_key bigint ENCODE az64,
    bzd_ntrl_key character varying(24) ENCODE lzo,
    bzd_chpt_import_id character varying(20) ENCODE lzo,
    nk_ta_acct_id integer ENCODE az64,
    nk_ta_nm_id integer ENCODE az64,
    nk_sf_acct_id character varying(20) ENCODE lzo,
    nk_sf_cntct_id character varying(20) ENCODE lzo,
    bzd_sfid character varying(20) ENCODE lzo,
    cnst_typ_cd character varying(10) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo
)
DISTSTYLE KEY;