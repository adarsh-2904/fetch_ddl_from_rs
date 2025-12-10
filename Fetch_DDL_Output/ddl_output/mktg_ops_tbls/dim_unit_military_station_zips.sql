CREATE TABLE mktg_ops_tbls.dim_unit_military_station_zips (
    zip_cd character varying(5) NOT NULL ENCODE raw distkey,
    cs_region_cd character varying(5) ENCODE lzo,
    cs_region_nm character varying(250) ENCODE lzo,
    nk_ecode character(5) NOT NULL ENCODE raw,
    unit_nm character varying(100) ENCODE lzo,
    PRIMARY KEY (zip_cd, nk_ecode)
)
DISTSTYLE KEY
SORTKEY ( zip_cd, nk_ecode );