CREATE TABLE mktg_ops_tbls.adb_nmstrackinglogrcp (
    ibroadlogid integer NOT NULL ENCODE az64,
    ideliveryid integer NOT NULL ENCODE az64,
    irecipientid integer NOT NULL ENCODE az64,
    itrackinglogid integer NOT NULL ENCODE az64,
    iurlid integer NOT NULL ENCODE az64,
    iuseragent integer NOT NULL ENCODE az64,
    sexternalid character varying(48) ENCODE lzo,
    ssourceid character varying(48) ENCODE lzo,
    ssourcetype character varying(16) ENCODE lzo,
    tslog timestamp without time zone ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64
)
DISTSTYLE ALL;