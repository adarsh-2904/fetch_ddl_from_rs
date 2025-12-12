CREATE TABLE mktg_ops_tbls.arc_crm_ent_infrd_prfl (
    cnst_mstr_id bigint NOT NULL ENCODE az64,
    cnst_hsld_id character(18) NOT NULL ENCODE lzo,
    fr_distr_only_dnr_ind smallint ENCODE az64,
    fr_stdy_st_dnr_ind smallint ENCODE az64,
    fr_hldy_dnr_ind smallint ENCODE az64,
    fr_yr_end_dnr_ind smallint ENCODE az64,
    fr_mjr_dnr_prspct_scr numeric(9,0) ENCODE az64
)
DISTSTYLE ALL;