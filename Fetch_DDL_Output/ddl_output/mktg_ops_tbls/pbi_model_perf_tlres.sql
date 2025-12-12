CREATE TABLE mktg_ops_tbls.pbi_model_perf_tlres (
    src_cd character varying(20) ENCODE raw distkey,
    rn_typ smallint ENCODE az64,
    typ character varying(50) ENCODE lzo,
    run_dt date ENCODE az64,
    cpp double precision ENCODE raw,
    drop_dt date ENCODE az64,
    pct_mature_ numeric(8,6) ENCODE az64,
    recip_cnt integer ENCODE az64,
    mail_cnt_ integer ENCODE az64,
    dntn_cnt_ integer ENCODE az64,
    dntn_amt_ numeric(15,2) ENCODE az64,
    pct_crossover numeric(7,4) ENCODE az64,
    resp_rt numeric(15,4) ENCODE az64,
    avg_gift_amt numeric(15,4) ENCODE az64,
    total_cost double precision ENCODE raw,
    net_rev double precision ENCODE raw,
    npd double precision ENCODE raw,
    ctrd double precision ENCODE raw,
    rpm numeric(15,4) ENCODE az64,
    dntn_cnt_1k integer ENCODE az64,
    dntn_amt_1k numeric(15,2) ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( src_cd );