CREATE TABLE mktg_ops_tbls.srvy_hsptl_sf_contact (
    email character varying(49) ENCODE lzo,
    customer_id character varying(10) ENCODE lzo,
    sf_contact_id character varying(15) ENCODE lzo,
    survey_id smallint ENCODE az64
)
DISTSTYLE AUTO;