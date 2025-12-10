CREATE TABLE mktg_ops_tbls.dim_phone_campgn_bkp (
    campgn_id integer ENCODE az64,
    campgn_cd character varying(10) ENCODE lzo distkey,
    campgn_typ character varying(30) ENCODE lzo,
    campgn_dsc character varying(100) ENCODE lzo,
    program_typ character varying(30) ENCODE lzo,
    fyr integer ENCODE raw,
    qtr smallint ENCODE raw,
    start_dt date ENCODE raw,
    end_dt date ENCODE az64,
    billing_typ character varying(20) ENCODE lzo,
    bill_rate smallint ENCODE az64,
    rcrd_cnt integer ENCODE az64,
    cmpltd_cnt integer ENCODE az64,
    pldgd_gift_cnt integer ENCODE az64,
    pldgd_rev_amt numeric(15,2) ENCODE az64,
    flfld_gift_cnt integer ENCODE az64,
    flfld_rev_amt numeric(15,2) ENCODE az64,
    elctrnc_gift_cnt integer ENCODE az64,
    elctrnc_gift_rev_amt numeric(15,2) ENCODE az64,
    pldgd_rcrng_gift_cnt integer ENCODE az64,
    pldgd_rcrng_gift_rev_amt numeric(15,2) ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( fyr, qtr, start_dt );