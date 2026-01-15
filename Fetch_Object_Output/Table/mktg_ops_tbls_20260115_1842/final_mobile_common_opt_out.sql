CREATE TABLE mktg_ops_tbls.final_mobile_common_opt_out (
    phone bigint ENCODE az64,
    campaign_num integer ENCODE az64,
    opt_in_ts timestamp without time zone ENCODE az64,
    campgn_cd character varying(14) ENCODE lzo COLLATE case_sensitive,
    keyword character varying(8) ENCODE lzo COLLATE case_sensitive,
    short_cd integer ENCODE az64,
    opt_out_ts timestamp without time zone ENCODE az64
)
DISTSTYLE ALL;