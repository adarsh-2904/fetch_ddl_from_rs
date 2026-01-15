CREATE TABLE mktg_ops_tbls.suprsn_ts_cnst (
    cnst_mstr_id bigint ENCODE raw distkey,
    ts_cnst_match_ind smallint ENCODE az64,
    ts_email_match_ind smallint ENCODE az64,
    ts_addr_match_ind smallint ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );