CREATE TABLE mktg_ops_tbls.dim_bio_donat_freq (
    donat_freq_key integer NOT NULL ENCODE az64,
    donat_freq_dsc character varying(20) ENCODE lzo,
    plasma_freq_band_dsc character varying(5) ENCODE lzo,
    apheresis_freq_band_dsc character varying(5) ENCODE lzo,
    redcell_freq_band_dsc character varying(5) ENCODE lzo,
    active_flg character varying(1) ENCODE lzo,
    dw_create_ts timestamp with time zone ENCODE az64,
    dw_updt_ts timestamp with time zone ENCODE az64,
    row_stat_cd character(1) ENCODE lzo,
    appl_src_cd character varying(4) ENCODE lzo,
    load_id integer ENCODE az64,
    PRIMARY KEY (donat_freq_key)
)
DISTSTYLE AUTO;