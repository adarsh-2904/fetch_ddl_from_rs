CREATE TABLE mktg_ops_tbls.pbi_bzl_fact_show_prodctv_ind (
    contact_key integer NOT NULL ENCODE az64 distkey,
    donor_key integer ENCODE az64,
    nk_key_donor character(7) ENCODE lzo COLLATE case_sensitive,
    nk_donat_dt date ENCODE az64,
    nk_contact_id character varying(20) ENCODE lzo COLLATE case_sensitive,
    apptmt_created_by_key integer ENCODE az64,
    apptmt_created_dt_key integer ENCODE az64,
    prodctv_proc_ind smallint ENCODE az64,
    donat_dt_key integer ENCODE az64,
    PRIMARY KEY (contact_key)
)
DISTSTYLE KEY;