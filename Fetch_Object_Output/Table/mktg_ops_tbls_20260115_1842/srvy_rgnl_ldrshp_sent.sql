CREATE TABLE mktg_ops_tbls.srvy_rgnl_ldrshp_sent (
    period_dsc character varying(6) ENCODE lzo COLLATE case_insensitive,
    region_ecode character varying(5) ENCODE lzo COLLATE case_insensitive,
    srvy_sent_cnt integer ENCODE az64
)
DISTSTYLE AUTO;