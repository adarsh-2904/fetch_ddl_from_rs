CREATE TABLE mktg_ops_tbls.pbi_entrprs_campgn_smry (
    launch_dt date ENCODE raw distkey,
    channel character varying(20) ENCODE raw,
    lob character varying(128) ENCODE raw,
    target_audience character varying(25) ENCODE raw,
    delivery_label character varying(128) ENCODE raw,
    yrqtr character varying(6) ENCODE lzo,
    src_cd character varying(70) ENCODE raw,
    subsrc_cd character varying(70) ENCODE raw,
    campgn_program_nm character varying(128) ENCODE raw,
    xpromo_ind smallint ENCODE az64,
    is_trigg_msg_ind smallint ENCODE az64,
    sent_cnt integer ENCODE az64,
    open_cnt integer ENCODE az64,
    click_cnt integer ENCODE az64,
    bounce_cnt integer ENCODE az64,
    unsub_cnt integer ENCODE az64,
    appt_cnt integer ENCODE az64,
    src_system character varying(25) ENCODE lzo,
    load_dt date ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( launch_dt, channel, lob, target_audience, delivery_label, src_cd, subsrc_cd, campgn_program_nm );