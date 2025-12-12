CREATE TABLE mktg_ops_tbls.bzl_cnst_fsa_acqstn (
    cnst_mstr_id bigint NOT NULL ENCODE raw distkey,
    primary_cnst_mstr_id bigint NOT NULL ENCODE az64,
    intrctn_cnst_mstr_id bigint ENCODE az64,
    intrctn_primary_cnst_mstr_id bigint ENCODE az64,
    acct_fsa_key bigint ENCODE az64,
    nk_ta_acct_id integer ENCODE az64,
    acqstn_id character varying(12) ENCODE lzo,
    orig_comnictn_src_key bigint ENCODE az64,
    srcsys_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64,
    dw_trans_ts timestamp without time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );