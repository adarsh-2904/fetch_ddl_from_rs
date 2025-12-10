CREATE TABLE mktg_ops_tbls.dv_de_accessblty_overall (
    run_dt date ENCODE az64 distkey,
    cnst_cnt bigint ENCODE az64,
    phn_chan_accessible_cnt bigint ENCODE az64,
    phn_chan_prct numeric(38,15) ENCODE az64,
    txt_chan_accessible_cnt bigint ENCODE az64,
    txt_chan_prct numeric(38,15) ENCODE az64,
    em_chan_accessible_cnt bigint ENCODE az64,
    em_chan_prct numeric(38,15) ENCODE az64,
    dm_chan_accessible_cnt bigint ENCODE az64,
    dm_chan_prct numeric(38,15) ENCODE az64,
    bz_app_chan_accessible_cnt bigint ENCODE az64,
    app_chan_prct numeric(38,15) ENCODE az64
)
DISTSTYLE AUTO;