CREATE TABLE mktg_ops_tbls.bz_google_analytics_txn (
    trans_id character varying(12) ENCODE raw COLLATE case_sensitive distkey,
    source1 character varying(100) ENCODE lzo COLLATE case_sensitive,
    medium1 character varying(300) ENCODE lzo COLLATE case_sensitive,
    campaign character varying(100) ENCODE lzo COLLATE case_sensitive,
    device character varying(10) ENCODE lzo COLLATE case_sensitive,
    channel_grp character varying(50) ENCODE lzo COLLATE case_sensitive
)
DISTSTYLE KEY
SORTKEY ( trans_id );