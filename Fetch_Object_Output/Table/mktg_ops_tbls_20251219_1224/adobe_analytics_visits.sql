CREATE TABLE mktg_ops_tbls.adobe_analytics_visits (
    hour_dsc character varying(25) ENCODE lzo COLLATE case_insensitive,
    cld_vstr_id character varying(50) ENCODE lzo COLLATE case_insensitive,
    vstr_id character varying(50) ENCODE lzo COLLATE case_insensitive,
    prch_id character varying(15) ENCODE lzo COLLATE case_insensitive,
    lst_touch_chnl character varying(25) ENCODE lzo COLLATE case_insensitive,
    curr_prcsd_file_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    dw_trans_ts timestamp without time zone ENCODE az64,
    row_stat_cd character varying(1) ENCODE lzo COLLATE case_insensitive,
    appl_src_cd character varying(4) ENCODE lzo COLLATE case_insensitive,
    load_id integer ENCODE az64
)
DISTSTYLE ALL;