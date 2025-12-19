CREATE TABLE mktg_ops_tbls.dim_unit_military_station_zips (
    zip_cd character varying(5) NOT NULL ENCODE raw COLLATE case_sensitive distkey,
    cs_region_cd character varying(5) ENCODE lzo COLLATE case_sensitive,
    cs_region_nm character varying(250) ENCODE lzo COLLATE case_sensitive,
    nk_ecode character(5) NOT NULL ENCODE raw COLLATE case_sensitive,
    unit_nm character varying(100) ENCODE lzo COLLATE case_sensitive,
    PRIMARY KEY (zip_cd, nk_ecode)
)
DISTSTYLE KEY
SORTKEY ( zip_cd, nk_ecode );