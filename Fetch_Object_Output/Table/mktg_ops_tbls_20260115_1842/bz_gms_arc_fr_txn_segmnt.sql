CREATE TABLE mktg_ops_tbls.bz_gms_arc_fr_txn_segmnt (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    giftran_key bigint NOT NULL ENCODE raw distkey,
    dntn_gift_dt date ENCODE az64,
    last_dntn_gift_dt date ENCODE az64,
    email_segmnt_key integer ENCODE az64,
    active_email_segmnt_ind smallint ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( giftran_key );