CREATE TABLE mktg_ops_tbls.cnst_addr_ncoa_log (
    old_cnst_mstr_id bigint NOT NULL ENCODE zstd distkey,
    old_locator_addr_key bigint ENCODE zstd,
    cnst_addr_old_addr1 character varying(255) ENCODE zstd,
    cnst_addr_old_addr2 character varying(255) ENCODE zstd,
    cnst_addr_old_city_nm character varying(255) ENCODE zstd,
    cnst_addr_old_state_cd character(12) ENCODE zstd,
    cnst_addr_old_zip_5_cd character(15) ENCODE zstd,
    new_cnst_mstr_id bigint ENCODE zstd,
    new_locator_addr_key bigint ENCODE zstd,
    cnst_addr_new_addr1 character varying(255) ENCODE zstd,
    cnst_addr_new_addr2 character varying(255) ENCODE zstd,
    cnst_addr_new_city_nm character varying(255) ENCODE zstd,
    cnst_addr_new_state_cd character(12) ENCODE zstd,
    cnst_addr_new_zip_5_cd character(15) ENCODE zstd,
    cnst_addr_new_zip_4_cd character(14) ENCODE zstd,
    file_nm character varying(512) NOT NULL ENCODE zstd,
    load_id integer NOT NULL ENCODE zstd,
    appl_src_cd character varying(512) NOT NULL ENCODE zstd,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE zstd,
    PRIMARY KEY (old_cnst_mstr_id, file_nm, load_id)
)
DISTSTYLE KEY
SORTKEY ( old_cnst_mstr_id );