CREATE TABLE mktg_ops_tbls.dim_online_channel (
    online_channel_key integer ENCODE az64 distkey,
    online_channel_cd character varying(30) ENCODE lzo COLLATE case_sensitive,
    online_channel_desc character varying(50) ENCODE lzo COLLATE case_sensitive,
    aem_channel_key integer ENCODE az64,
    aem_channel_cd character varying(30) ENCODE lzo COLLATE case_sensitive,
    aem_channel_desc character varying(50) ENCODE lzo COLLATE case_sensitive,
    atg_channel_key integer ENCODE az64,
    atg_channel_cd character varying(30) ENCODE lzo COLLATE case_sensitive,
    atg_channel_desc character varying(50) ENCODE lzo COLLATE case_sensitive,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( online_channel_key );