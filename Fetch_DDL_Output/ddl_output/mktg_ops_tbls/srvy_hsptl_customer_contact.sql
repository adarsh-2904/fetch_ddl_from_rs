CREATE TABLE mktg_ops_tbls.srvy_hsptl_customer_contact (
    srvy_id smallint ENCODE az64,
    account_nm character varying(100) ENCODE lzo,
    first_nm character varying(50) ENCODE lzo,
    last_nm character varying(50) ENCODE lzo,
    contact_title character varying(128) ENCODE lzo,
    contact_category character varying(30) ENCODE lzo,
    email_addr character varying(100) ENCODE lzo,
    customer_id character varying(20) ENCODE lzo,
    sf_contact_id character varying(30) ENCODE lzo,
    account_id character varying(30) ENCODE lzo,
    survey character varying(40) ENCODE lzo,
    srvy_first_nm character varying(50) ENCODE lzo,
    srvy_last_nm character varying(50) ENCODE lzo,
    srvy_title character varying(128) ENCODE lzo,
    srvy_email_addr character varying(100) ENCODE lzo,
    status character varying(30) ENCODE lzo
)
DISTSTYLE AUTO;