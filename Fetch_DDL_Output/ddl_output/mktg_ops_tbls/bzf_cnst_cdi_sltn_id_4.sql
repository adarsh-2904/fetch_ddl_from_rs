CREATE TABLE mktg_ops_tbls.bzf_cnst_cdi_sltn_id_4 (
    pn_cnst_mstr_id bigint ENCODE az64 distkey,
    pn_nk_ta_acct_id integer ENCODE az64,
    pn_nk_ta_nm_id integer ENCODE az64,
    sn_cnst_mstr_id bigint ENCODE az64,
    sn_nk_ta_acct_id integer ENCODE az64,
    sn_nk_ta_nm_id integer ENCODE az64
)
DISTSTYLE KEY;