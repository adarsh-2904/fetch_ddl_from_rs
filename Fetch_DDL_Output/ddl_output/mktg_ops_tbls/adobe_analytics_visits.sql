CREATE TABLE mktg_ops_tbls.adobe_analytics_visits (
    hour_dsc character varying(25) ENCODE lzo,
    cld_vstr_id character varying(50) ENCODE lzo,
    vstr_id character varying(50) ENCODE lzo,
    prch_id character varying(15) ENCODE lzo,
    lst_touch_chnl character varying(25) ENCODE lzo,
    curr_prcsd_file_nm character varying(50) ENCODE lzo,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character varying(1) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64
)
DISTSTYLE ALL;