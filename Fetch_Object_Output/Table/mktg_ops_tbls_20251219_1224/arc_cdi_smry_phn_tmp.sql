CREATE TABLE mktg_ops_tbls.arc_cdi_smry_phn_tmp (
    hh_la_id character varying(30) ENCODE lzo COLLATE case_insensitive,
    dw_srcsys_trans_ts timestamp without time zone ENCODE az64,
    arc_srcsys_cd character varying(10) ENCODE lzo COLLATE case_insensitive,
    cnst_phn_num character varying(15) ENCODE lzo COLLATE case_insensitive,
    load_id integer ENCODE az64
)
DISTSTYLE ALL;