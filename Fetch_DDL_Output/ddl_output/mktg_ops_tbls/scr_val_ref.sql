CREATE TABLE mktg_ops_tbls.scr_val_ref (
    scr_id bigint NOT NULL ENCODE raw distkey,
    scr_val character varying(9) ENCODE raw,
    scr_val_dsc character varying(100) ENCODE lzo,
    active_ind smallint ENCODE az64,
    scr_strt_ts timestamp without time zone ENCODE az64,
    scr_end_ts timestamp without time zone ENCODE az64,
    dw_srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( scr_id, scr_val );