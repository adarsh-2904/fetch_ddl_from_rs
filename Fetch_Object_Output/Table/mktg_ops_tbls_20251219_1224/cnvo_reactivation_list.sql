CREATE TABLE mktg_ops_tbls.cnvo_reactivation_list (
    cnst_nm character varying(50) ENCODE lzo COLLATE case_sensitive,
    email character varying(50) ENCODE lzo COLLATE case_sensitive,
    contct_id integer NOT NULL ENCODE raw distkey,
    addr_line1 character varying(50) ENCODE lzo COLLATE case_sensitive,
    addr_line2 character varying(50) ENCODE lzo COLLATE case_sensitive,
    addr_line3 character varying(50) ENCODE lzo COLLATE case_sensitive,
    city character varying(30) ENCODE lzo COLLATE case_sensitive,
    state_cd character varying(2) ENCODE lzo COLLATE case_sensitive,
    zip character varying(10) ENCODE lzo COLLATE case_sensitive,
    home_ph character varying(20) ENCODE lzo COLLATE case_sensitive,
    reactvtn_start_dt date ENCODE az64,
    reactvtn_end_dt date ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64,
    PRIMARY KEY (contct_id)
)
DISTSTYLE KEY
SORTKEY ( contct_id );