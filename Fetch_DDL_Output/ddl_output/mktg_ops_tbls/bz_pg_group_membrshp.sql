CREATE TABLE mktg_ops_tbls.bz_pg_group_membrshp (
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    pg_group_key integer NOT NULL ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64
)
DISTSTYLE KEY;