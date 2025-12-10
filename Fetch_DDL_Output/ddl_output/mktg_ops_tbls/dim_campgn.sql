CREATE TABLE mktg_ops_tbls.dim_campgn (
    campgn_key integer ENCODE az64,
    nk_campgn_id integer ENCODE az64 distkey,
    campgn_cd character varying(64) ENCODE lzo,
    campgn_nm character varying(128) ENCODE lzo,
    campgn_plan_id integer ENCODE az64,
    campgn_plan_nm character varying(128) ENCODE lzo,
    campgn_lob_id integer ENCODE az64,
    campgn_lob_nm character varying(128) ENCODE lzo,
    campgn_channel_id integer ENCODE az64,
    campgn_channel_nm character varying(128) ENCODE lzo,
    campgn_program_id integer ENCODE az64,
    campgn_program_nm character varying(128) ENCODE lzo,
    is_triggrd_campgn smallint ENCODE az64,
    srcsys_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY;