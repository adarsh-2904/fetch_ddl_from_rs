CREATE TABLE mktg_ops_tbls.srvy_hsptl_customer_contact (
    srvy_id smallint ENCODE az64,
    account_nm character varying(100) ENCODE lzo COLLATE case_insensitive,
    first_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    last_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    contact_title character varying(128) ENCODE lzo COLLATE case_insensitive,
    contact_category character varying(30) ENCODE lzo COLLATE case_insensitive,
    email_addr character varying(100) ENCODE lzo COLLATE case_insensitive,
    customer_id character varying(20) ENCODE lzo COLLATE case_insensitive,
    sf_contact_id character varying(30) ENCODE lzo COLLATE case_insensitive,
    account_id character varying(30) ENCODE lzo COLLATE case_insensitive,
    survey character varying(40) ENCODE lzo COLLATE case_insensitive,
    srvy_first_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    srvy_last_nm character varying(50) ENCODE lzo COLLATE case_insensitive,
    srvy_title character varying(128) ENCODE lzo COLLATE case_insensitive,
    srvy_email_addr character varying(100) ENCODE lzo COLLATE case_insensitive,
    status character varying(30) ENCODE lzo COLLATE case_insensitive
)
DISTSTYLE AUTO;