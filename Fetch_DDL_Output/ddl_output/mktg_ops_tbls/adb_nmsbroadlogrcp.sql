CREATE TABLE mktg_ops_tbls.adb_nmsbroadlogrcp (
    ibroadlogid integer NOT NULL ENCODE raw distkey,
    ideliveryid integer NOT NULL ENCODE az64,
    iflags smallint NOT NULL ENCODE az64,
    imsgid integer NOT NULL ENCODE az64,
    irecipientid integer NOT NULL ENCODE az64,
    iserviceid integer NOT NULL ENCODE az64,
    istatus smallint NOT NULL ENCODE az64,
    saddress character varying(512) ENCODE lzo,
    tsevent timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    bidmlocatoraddrkey bigint ENCODE az64,
    ireportcellcodeid integer ENCODE az64,
    itreatmentcodeid integer ENCODE az64,
    sbusinessunit character varying(5) ENCODE lzo,
    ssegmentcode character varying(50) ENCODE lzo,
    saudiencetype character varying(255) ENCODE lzo,
    biememailkey bigint ENCODE az64,
    imarketingunitkey integer ENCODE az64,
    iunitkey integer ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo,
    load_id integer NOT NULL ENCODE az64,
    PRIMARY KEY (ibroadlogid)
)
DISTSTYLE KEY
SORTKEY ( ibroadlogid );