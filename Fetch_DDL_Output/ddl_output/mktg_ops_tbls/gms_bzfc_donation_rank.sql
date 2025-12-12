CREATE TABLE mktg_ops_tbls.gms_bzfc_donation_rank (
    giftran_key bigint NOT NULL ENCODE az64,
    nk_gift_id character varying(20) ENCODE lzo,
    campgn_src_cd character varying(20) ENCODE lzo,
    gift_src_cd character varying(20) ENCODE lzo,
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    dntn_gift_dt date ENCODE az64,
    mailed_ind integer ENCODE az64,
    email_link_click_ind integer ENCODE az64,
    email_open_ind integer ENCODE az64,
    email_sent_ind integer ENCODE az64,
    dm_sent_cnt integer ENCODE az64,
    email_open_cnt integer ENCODE az64,
    email_sent_cnt integer ENCODE az64,
    email_intrctn_cnt integer ENCODE az64,
    gift_cnt integer ENCODE az64,
    rco_gift_cnt integer ENCODE az64
)
DISTSTYLE AUTO;