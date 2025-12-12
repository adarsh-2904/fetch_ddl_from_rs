CREATE TABLE mktg_ops_tbls.dv_de_accessblty_lifestg (
    run_dt date ENCODE zstd distkey,
    donor_lifestage character varying(14) ENCODE zstd,
    phn_chan_accessible_cnt integer ENCODE zstd,
    txt_chan_accessible_cnt integer ENCODE zstd,
    em_chan_accessible_cnt integer ENCODE zstd,
    dm_chan_accessible_cnt integer ENCODE zstd,
    bz_app_chan_accessible_cnt integer ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( run_dt );