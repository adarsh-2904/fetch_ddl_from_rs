CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_arcpg_amt_typ AS
SELECT
    amt_typ_key,
    amt_typ_cd,
    amt_typ_dsc,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    row_status_cd,
    appl_src_cd,
    load_id,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts
FROM eda.ufds_vws.gmpbz_dim_arcpg_amt_typ
with no schema binding
;