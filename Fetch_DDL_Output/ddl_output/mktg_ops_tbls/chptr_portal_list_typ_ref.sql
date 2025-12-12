CREATE TABLE mktg_ops_tbls.chptr_portal_list_typ_ref (
    list_typ_key integer NOT NULL ENCODE az64 distkey,
    list_typ_cd character varying(10) NOT NULL ENCODE lzo,
    list_typ_dsc character varying(100) NOT NULL ENCODE lzo,
    list_cat_cd character varying(10) ENCODE lzo,
    list_cat_dsc character varying(100) ENCODE lzo,
    list_sub_cat_cd character varying(10) ENCODE lzo,
    list_sub_cat_dsc character varying(100) ENCODE lzo,
    dw_trans_ts timestamp without time zone NOT NULL ENCODE az64,
    active_flg character varying(2) ENCODE lzo
)
DISTSTYLE KEY;