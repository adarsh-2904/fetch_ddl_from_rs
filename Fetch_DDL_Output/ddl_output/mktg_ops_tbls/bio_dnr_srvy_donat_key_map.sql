CREATE TABLE mktg_ops_tbls.bio_dnr_srvy_donat_key_map (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    new_donat_key bigint ENCODE az64,
    old_donat_key bigint ENCODE az64,
    nk_donat_num character varying(18) ENCODE lzo,
    nk_donat_dt date ENCODE az64,
    nk_supplier character varying(4) ENCODE lzo
)
DISTSTYLE AUTO;