CREATE TABLE mktg_ops_tbls.pg_calc_stuart_upld_lkp (
    clnsd_first_nm character varying(20) ENCODE lzo,
    middle_nm character varying(40) ENCODE lzo,
    clnsd_last_nm character varying(80) ENCODE lzo,
    clnsd_email_addr character varying(100) ENCODE lzo distkey,
    addr_ln1 character varying(100) ENCODE lzo,
    addr_ln2 character varying(100) ENCODE lzo,
    addr_ln3 character varying(100) ENCODE lzo,
    city character varying(25) ENCODE lzo,
    state character varying(2) ENCODE lzo,
    zip_cd character varying(10) ENCODE lzo,
    phone_num character varying(20) ENCODE lzo,
    lkp_insert_ts timestamp without time zone ENCODE az64,
    stuart_upld_ts timestamp without time zone ENCODE az64,
    grp_cd character varying(20) NOT NULL ENCODE lzo,
    grp_nm character varying(255) NOT NULL ENCODE lzo,
    upld_typ_key integer ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY;