CREATE TABLE mktg_ops_tbls.bz_dim_treatmnt (
    treatmnt_key integer ENCODE zstd,
    nk_treatmnt_id integer ENCODE zstd distkey,
    treatmnt_cd character varying(75) ENCODE zstd,
    treatmnt_dsc character varying(75) ENCODE zstd,
    treatmnt_typ character varying(255) ENCODE zstd,
    treatmnt_status character varying(765) ENCODE zstd,
    active_ind smallint ENCODE zstd,
    channel character varying(255) ENCODE zstd,
    actvty_specific character varying(765) ENCODE zstd,
    snapshot_ts timestamp without time zone ENCODE zstd,
    srcsys_ts timestamp without time zone ENCODE zstd,
    dw_updt_ts timestamp without time zone ENCODE zstd,
    row_stat_cd character(1) ENCODE zstd,
    appl_src_cd character varying(4) ENCODE zstd,
    load_id integer ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( snapshot_ts );