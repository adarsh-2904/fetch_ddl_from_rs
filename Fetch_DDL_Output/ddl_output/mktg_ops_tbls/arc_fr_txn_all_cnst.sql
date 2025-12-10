CREATE TABLE mktg_ops_tbls.arc_fr_txn_all_cnst (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    cnst_typ_cd character(2) ENCODE lzo,
    trans_id bigint NOT NULL ENCODE az64,
    cnst_fsa_key integer ENCODE az64,
    nk_ta_acct_id integer ENCODE az64,
    nk_ta_nm_id integer ENCODE az64,
    dntn_gift_dt date ENCODE az64,
    fr_pmt_amt numeric(13,2) ENCODE az64,
    comnictn_src_key integer ENCODE az64,
    act_ind smallint ENCODE az64,
    alt_trans_id character varying(40) ENCODE lzo,
    fcc_key integer ENCODE az64,
    fund_key integer ENCODE az64,
    UNIQUE (cnst_mstr_id, trans_id)
)
DISTSTYLE ALL;