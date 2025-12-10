CREATE TABLE mktg_ops_tbls.bzf_cnst_cdi_sltn_id (
    pn_cnst_mstr_id bigint ENCODE zstd distkey,
    pn_nk_ta_acct_id integer ENCODE zstd,
    pn_nk_ta_nm_id integer ENCODE zstd,
    sn_cnst_mstr_id bigint ENCODE zstd,
    sn_nk_ta_acct_id integer ENCODE zstd,
    sn_nk_ta_nm_id integer ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( pn_cnst_mstr_id );