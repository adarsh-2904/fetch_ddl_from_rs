CREATE TABLE mktg_ops_tbls.dim_phone_campgn_src_cd_xref (
    campgn_id integer ENCODE az64,
    campgn_cd character varying(10) ENCODE lzo,
    src_cd character varying(20) ENCODE lzo,
    fulflmnt_chnl character varying(10) ENCODE lzo,
    curr_prcsd_file_nm character varying(100) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;