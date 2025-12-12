CREATE TABLE mktg_ops_tbls.scr (
    scr_id integer ENCODE az64,
    scr_strt_ts character varying(50) ENCODE lzo,
    scr_end_ts character varying(50) ENCODE lzo,
    nk_scr_cd character varying(50) ENCODE lzo,
    scr_dsc character varying(128) ENCODE lzo,
    scr_versn real ENCODE raw,
    dw_srcsys_trans_ts character varying(50) ENCODE lzo,
    row_stat_cd character varying(50) ENCODE lzo,
    appl_src_cd character varying(50) ENCODE lzo,
    load_id integer ENCODE az64
)
DISTSTYLE AUTO;