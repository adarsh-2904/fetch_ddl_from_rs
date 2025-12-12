CREATE TABLE mktg_ops_tbls.dim_online_channel (
    online_channel_key integer ENCODE az64 distkey,
    online_channel_cd character varying(30) ENCODE lzo,
    online_channel_desc character varying(50) ENCODE lzo,
    aem_channel_key integer ENCODE az64,
    aem_channel_cd character varying(30) ENCODE lzo,
    aem_channel_desc character varying(50) ENCODE lzo,
    atg_channel_key integer ENCODE az64,
    atg_channel_cd character varying(30) ENCODE lzo,
    atg_channel_desc character varying(50) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( online_channel_key );