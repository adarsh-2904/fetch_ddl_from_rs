CREATE TABLE mktg_ops_tbls.fix_site_vol_recruit (
    spon_ext_id character varying(9) ENCODE lzo,
    site_ext_id character varying(9) ENCODE lzo distkey,
    site_nm character varying(200) ENCODE lzo,
    site_addr character varying(250) ENCODE lzo,
    site_city character varying(50) ENCODE lzo,
    site_state character varying(30) ENCODE lzo,
    site_zip character varying(9) ENCODE lzo,
    phase character varying(16) ENCODE lzo,
    start_dt date ENCODE az64,
    end_dt date ENCODE az64,
    spanish_matrl_flg character(1) ENCODE lzo
)
DISTSTYLE KEY;