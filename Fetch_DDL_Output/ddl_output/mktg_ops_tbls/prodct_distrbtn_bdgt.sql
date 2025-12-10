CREATE TABLE mktg_ops_tbls.prodct_distrbtn_bdgt (
    mstr_cust_cd character varying(20) NOT NULL ENCODE lzo distkey,
    product_family character varying(20) ENCODE lzo,
    bdgt_dt date ENCODE az64,
    bdgt_distrbtns numeric(10,4) ENCODE az64,
    forcst_distrbtns numeric(10,4) ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    PRIMARY KEY (mstr_cust_cd)
)
DISTSTYLE KEY;