CREATE TABLE mktg_ops_tbls.arc_vms_txn (
    cnst_mstr_id bigint NOT NULL ENCODE raw distkey,
    cnst_hsld_id character varying(18) ENCODE lzo,
    vol_key integer ENCODE az64,
    nk_hrs_summary_sku integer ENCODE az64,
    tot_hrs_cnt integer ENCODE az64,
    hrs_wrkd_dt date ENCODE az64,
    unit_key integer ENCODE az64,
    vol_geo_zip_cd character varying(10) ENCODE lzo,
    disaster_assignment_flg character(1) ENCODE lzo,
    lob_nm character varying(50) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id, vol_key );