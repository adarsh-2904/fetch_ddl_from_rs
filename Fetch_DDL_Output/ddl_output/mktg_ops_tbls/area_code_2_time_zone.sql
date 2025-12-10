CREATE TABLE mktg_ops_tbls.area_code_2_time_zone (
    area_cd_num smallint NOT NULL ENCODE az64,
    time_zone_dsc character varying(20) ENCODE lzo,
    PRIMARY KEY (area_cd_num)
)
DISTSTYLE AUTO;