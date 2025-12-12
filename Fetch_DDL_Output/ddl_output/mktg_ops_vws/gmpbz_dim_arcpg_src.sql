CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_arcpg_src AS
SELECT
    src_key AS comnictn_src_key,
    src_cd AS nk_comnictn_src_cd,
    src_dsc AS comnictn_src_dsc,
    activity_cd,
    activity_dsc,
    prog_cd AS campgn_typ_cd,
    prog_dsc AS campgn_typ_dsc,
    initiative_cd,
    initiative_dsc,
    effort AS effort_num,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    active_ind,
    row_status_cd,
    appl_src_cd,
    load_id,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
FROM eda.ufds_vws.gmpbz_dim_arcpg_src
with no schema binding
;