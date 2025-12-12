CREATE TABLE mktg_ops_tbls.gms_bz_pg_group_membrshp (
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    pg_group_key integer NOT NULL ENCODE raw,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( pg_group_key, dw_trans_ts );