CREATE TABLE mktg_ops_tbls.pbi_entrprs_campgn_ts_sends (
    email_launch_dt date ENCODE az64,
    src_cd character varying(66) ENCODE lzo,
    sub_src character varying(66) ENCODE lzo,
    channel character varying(5) ENCODE lzo,
    sendcount integer ENCODE az64,
    opens integer ENCODE az64,
    clicks smallint ENCODE az64,
    bounces smallint ENCODE az64,
    unsub smallint ENCODE az64,
    total_conversions smallint ENCODE az64,
    load_dt date ENCODE az64,
    xpromo_ind smallint ENCODE az64
)
DISTSTYLE EVEN;