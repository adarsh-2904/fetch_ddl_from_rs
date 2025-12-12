CREATE TABLE mktg_ops_tbls._zeroetl_watermark (
    obj_name character varying(256) NOT NULL ENCODE lzo distkey,
    last_txn_id bigint NOT NULL DEFAULT 0 ENCODE az64,
    last_txn_seq bigint NOT NULL DEFAULT 0 ENCODE az64,
    last_dw_trans_ts timestamp without time zone ENCODE az64,
    updated_at timestamp without time zone NOT NULL DEFAULT getdate() ENCODE az64,
    PRIMARY KEY (obj_name)
)
DISTSTYLE AUTO
SORTKEY ( obj_name );