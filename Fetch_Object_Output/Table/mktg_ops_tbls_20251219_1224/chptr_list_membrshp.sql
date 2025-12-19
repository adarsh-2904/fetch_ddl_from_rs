CREATE TABLE mktg_ops_tbls.chptr_list_membrshp (
    list_typ_key integer NOT NULL ENCODE az64,
    cnst_mstr_id bigint NOT NULL ENCODE az64 distkey,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE raw
)
DISTSTYLE KEY
SORTKEY ( dw_trans_ts );