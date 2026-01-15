CREATE TABLE mktg_ops_tbls.scr (
    scr_id integer ENCODE az64,
    scr_strt_ts character varying(50) ENCODE lzo COLLATE case_sensitive,
    scr_end_ts character varying(50) ENCODE lzo COLLATE case_sensitive,
    nk_scr_cd character varying(50) ENCODE lzo COLLATE case_sensitive,
    scr_dsc character varying(128) ENCODE lzo COLLATE case_sensitive,
    scr_versn real ENCODE raw,
    dw_srcsys_trans_ts character varying(50) ENCODE lzo COLLATE case_sensitive,
    row_stat_cd character varying(50) ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(50) ENCODE lzo COLLATE case_sensitive,
    load_id integer ENCODE az64
)
DISTSTYLE AUTO;