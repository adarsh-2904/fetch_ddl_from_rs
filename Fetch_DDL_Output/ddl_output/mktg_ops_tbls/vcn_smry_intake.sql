CREATE TABLE mktg_ops_tbls.vcn_smry_intake (
    path_accnt_id integer NOT NULL ENCODE az64 distkey,
    accnt_id integer ENCODE az64,
    hierarchy_id integer ENCODE az64,
    application_ts timestamp without time zone ENCODE az64,
    path_id integer ENCODE az64,
    path_nm character varying(255) ENCODE lzo,
    entry_point_id integer ENCODE az64,
    point_of_entry character varying(255) ENCODE lzo,
    intake_outcome character varying(24) ENCODE lzo,
    outcome_ts timestamp without time zone ENCODE az64,
    contact_status character varying(50) ENCODE lzo,
    contact_completed_dt timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE KEY;