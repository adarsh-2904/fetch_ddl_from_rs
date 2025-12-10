CREATE TABLE mktg_ops_tbls.pbi_entrprs_campgn_results (
    result_type character(45) ENCODE lzo distkey,
    subsrc_cd character varying(256) ENCODE lzo,
    campaign_result bigint ENCODE az64,
    src_system character(45) ENCODE lzo,
    load_date date ENCODE az64
)
DISTSTYLE KEY;