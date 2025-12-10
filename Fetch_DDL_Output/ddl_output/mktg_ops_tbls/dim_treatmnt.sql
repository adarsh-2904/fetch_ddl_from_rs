CREATE TABLE mktg_ops_tbls.dim_treatmnt (
    treatmnt_key integer ENCODE zstd,
    nk_treatmnt_id integer ENCODE zstd distkey,
    treatmnt_cd character varying(255) ENCODE zstd,
    report_cell_cd_id character varying(255) ENCODE zstd,
    active_ind smallint ENCODE zstd,
    treatmnt_dsc character varying(255) ENCODE zstd,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE zstd,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE zstd,
    row_stat_cd character(1) NOT NULL ENCODE zstd,
    appl_src_cd character varying(4) NOT NULL ENCODE zstd,
    load_id integer NOT NULL ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( srcsys_trans_ts );