CREATE TABLE mktg_ops_tbls.bz_google_analytics_txn (
    trans_id character varying(12) ENCODE raw distkey,
    source1 character varying(100) ENCODE lzo,
    medium1 character varying(300) ENCODE lzo,
    campaign character varying(100) ENCODE lzo,
    device character varying(10) ENCODE lzo,
    channel_grp character varying(50) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( trans_id );