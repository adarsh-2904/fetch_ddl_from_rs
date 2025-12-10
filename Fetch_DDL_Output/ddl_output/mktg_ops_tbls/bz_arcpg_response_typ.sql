CREATE TABLE mktg_ops_tbls.bz_arcpg_response_typ (
    response_typ_key bigint NOT NULL ENCODE az64,
    response_typ_cd character varying(10) ENCODE lzo,
    response_typ_dsc character varying(100) ENCODE lzo,
    response_ctg_cd character varying(10) ENCODE lzo,
    response_ctg_dsc character varying(100) ENCODE lzo,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    PRIMARY KEY (response_typ_key)
)
DISTSTYLE AUTO;