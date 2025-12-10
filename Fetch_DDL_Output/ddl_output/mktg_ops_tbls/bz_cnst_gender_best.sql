CREATE TABLE mktg_ops_tbls.bz_cnst_gender_best (
    cnst_mstr_id bigint NOT NULL ENCODE raw distkey,
    pid character varying(20) NOT NULL ENCODE lzo,
    cnst_srcsys_id character varying(255) NOT NULL ENCODE lzo,
    arc_srcsys_cd character varying(10) NOT NULL ENCODE lzo,
    cnst_gender character varying(1) NOT NULL ENCODE lzo,
    cnst_gender_strt_ts timestamp without time zone ENCODE az64,
    cnst_gender_end_dt date ENCODE az64,
    experian_gender_cd character(1) NOT NULL ENCODE lzo,
    predctd_gender_first_nm character varying(30) NOT NULL ENCODE lzo,
    predctd_gender character varying(1) NOT NULL ENCODE lzo,
    predctd_gender_problty character varying(30) NOT NULL ENCODE lzo,
    simio_gender_cd character varying(1) NOT NULL ENCODE lzo,
    dw_srcsys_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );