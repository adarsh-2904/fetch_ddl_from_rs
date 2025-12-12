CREATE TABLE mktg_ops_tbls.mktg_load_cntl (
    mktg_file_nm character varying(256) NOT NULL ENCODE lzo,
    mktg_file_pfx character(30) NOT NULL ENCODE lzo,
    mktg_file_sfx character(3) NOT NULL ENCODE lzo,
    recvd_from_vndr_ind smallint DEFAULT 0 ENCODE az64,
    recvd_from_vndr_flg character(1) DEFAULT 'N'::bpchar ENCODE lzo,
    recvd_dt date ENCODE az64,
    recs_recvd_cnt integer ENCODE az64,
    processed_flg character(1) DEFAULT 'N'::bpchar ENCODE lzo,
    processed_ind smallint DEFAULT 0 ENCODE az64,
    processed_dt date ENCODE az64,
    recs_processed_cnt integer ENCODE az64,
    reprocess_flg character(1) DEFAULT 'N'::bpchar ENCODE lzo,
    reprocess_ind smallint DEFAULT 0 ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo
)
DISTSTYLE AUTO;