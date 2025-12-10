CREATE TABLE mktg_ops_tbls.pbi_model_perf_dashbrd (
    cnst_mstr_id bigint ENCODE raw distkey,
    src_key integer ENCODE az64,
    dm_file character varying(3) ENCODE lzo,
    lol_sel_key integer ENCODE az64,
    mail_cnt integer ENCODE az64,
    superdupe_ind smallint ENCODE az64,
    vigintile character varying(2) ENCODE lzo,
    mods_fr_scr numeric(13,4) ENCODE az64,
    dir_dntn_cnt integer ENCODE az64,
    dir_dntn_amt numeric(15,2) ENCODE az64,
    ind_dntn_cnt integer ENCODE az64,
    ind_dntn_amt numeric(15,2) ENCODE az64,
    cnst_typ_cd smallint ENCODE az64,
    lst_dntn_amt numeric(15,2) ENCODE az64,
    blackjack integer ENCODE az64,
    expected_val numeric(13,4) ENCODE az64,
    age integer ENCODE az64,
    recency numeric(4,1) ENCODE az64,
    sm_custom_scr smallint ENCODE az64,
    sm_children_scr smallint ENCODE az64,
    vig_cutoff smallint ENCODE az64,
    wfall_key smallint ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cnst_mstr_id );