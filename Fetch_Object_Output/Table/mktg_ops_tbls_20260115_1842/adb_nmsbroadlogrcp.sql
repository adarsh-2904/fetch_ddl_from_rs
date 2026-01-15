CREATE TABLE mktg_ops_tbls.adb_nmsbroadlogrcp (
    ibroadlogid integer NOT NULL ENCODE raw distkey,
    ideliveryid integer NOT NULL ENCODE az64,
    iflags smallint NOT NULL ENCODE az64,
    imsgid integer NOT NULL ENCODE az64,
    irecipientid integer NOT NULL ENCODE az64,
    iserviceid integer NOT NULL ENCODE az64,
    istatus smallint NOT NULL ENCODE az64,
    saddress character varying(512) ENCODE lzo COLLATE case_sensitive,
    tsevent timestamp without time zone ENCODE az64,
    tslastmodified timestamp without time zone ENCODE az64,
    bidmlocatoraddrkey bigint ENCODE az64,
    ireportcellcodeid integer ENCODE az64,
    itreatmentcodeid integer ENCODE az64,
    sbusinessunit character varying(5) ENCODE lzo COLLATE case_sensitive,
    ssegmentcode character varying(50) ENCODE lzo COLLATE case_sensitive,
    saudiencetype character varying(255) ENCODE lzo COLLATE case_sensitive,
    biememailkey bigint ENCODE az64,
    imarketingunitkey integer ENCODE az64,
    iunitkey integer ENCODE az64,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    row_stat_cd character(1) NOT NULL ENCODE lzo COLLATE case_sensitive,
    appl_src_cd character varying(4) NOT NULL ENCODE lzo COLLATE case_sensitive,
    load_id integer NOT NULL ENCODE az64,
    PRIMARY KEY (ibroadlogid)
)
DISTSTYLE KEY
SORTKEY ( ibroadlogid );