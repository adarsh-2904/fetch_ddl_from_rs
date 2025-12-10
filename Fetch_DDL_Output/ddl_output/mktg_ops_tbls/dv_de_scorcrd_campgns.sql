CREATE TABLE mktg_ops_tbls.dv_de_scorcrd_campgns (
    chanl character varying(50) ENCODE lzo,
    scr_mnth timestamp without time zone ENCODE az64,
    life_stage_dsc character varying(23) ENCODE lzo,
    tot_contcts bigint ENCODE az64,
    del_contcts bigint ENCODE az64,
    net_contcts bigint ENCODE az64,
    distnct_contcts bigint ENCODE az64,
    avg_tch_pnts numeric(13,2) ENCODE az64,
    dw_trans_ts timestamp with time zone ENCODE az64,
    row_stat_cd character varying(1) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( scr_mnth );