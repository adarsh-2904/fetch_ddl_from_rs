CREATE TABLE mktg_ops_tbls.pbi_model_perf_dim_lol (
    dm_program character varying(100) ENCODE lzo,
    select_grp_dsc character varying(100) ENCODE lzo,
    reclass_multi_ind smallint ENCODE az64,
    hpg_1kplus_ind smallint ENCODE az64,
    lol_sel_key integer ENCODE raw distkey
)
DISTSTYLE KEY
SORTKEY ( lol_sel_key );