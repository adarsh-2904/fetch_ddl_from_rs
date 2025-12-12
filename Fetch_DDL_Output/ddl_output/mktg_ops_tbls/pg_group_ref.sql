CREATE TABLE mktg_ops_tbls.pg_group_ref (
    pg_group_key integer NOT NULL ENCODE raw distkey,
    pg_group_cd character varying(10) NOT NULL ENCODE lzo,
    pg_group_nm character varying(50) NOT NULL ENCODE lzo,
    pg_group_dsc character varying(500) ENCODE lzo,
    pg_group_typ character varying(20) ENCODE lzo,
    active_flg character varying(1) ENCODE lzo,
    active_start_dt date ENCODE az64,
    active_end_dt date ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( pg_group_key );