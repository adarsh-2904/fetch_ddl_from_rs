CREATE TABLE mktg_ops_tbls.bz_dim_rpt_cell_cd (
    rpt_cell_cd_key integer ENCODE zstd distkey,
    rpt_cell_cd_id integer ENCODE zstd,
    rpt_cell_cd character varying(40) ENCODE zstd COLLATE case_sensitive,
    low_dt character varying(2) ENCODE zstd COLLATE case_sensitive,
    high_dt character varying(2) ENCODE zstd COLLATE case_sensitive,
    tag_cd character varying(10) ENCODE zstd COLLATE case_sensitive,
    low_dontn character varying(4) ENCODE zstd COLLATE case_sensitive,
    high_dontn character varying(4) ENCODE zstd COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE zstd,
    row_stat_cd character(1) NOT NULL ENCODE zstd COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE zstd COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE zstd
)
DISTSTYLE KEY
SORTKEY ( rpt_cell_cd_key );