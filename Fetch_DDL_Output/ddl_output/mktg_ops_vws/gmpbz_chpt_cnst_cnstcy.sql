CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_chpt_cnst_cnstcy AS
-- Created By: Michael Andrien
-- Create Date: 03/07/2020
-- Purpose: Replicated from ufds_vws to support Adobe Campaign. Contains normalized chapter constituency records with effective dates.

SELECT
    a.cnst_mstr_id,
    b.chpt_cnstcy_affn_key,
    b.gmp_cnst_key,
    b.cnstcy_typ_cd,
    b.cnstcy_typ_dsc,
    CAST(b.strt_dt AS DATE) AS strt_dt,
    CAST(b.end_dt AS DATE) AS end_dt,
    b.active_ind,
    CASE 
        WHEN b.end_dt < CURRENT_DATE THEN 'Former'
        WHEN b.end_dt >= CURRENT_DATE THEN 'Current'
    END AS cnstcy_status,
    CAST(b.srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(b.srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    b.srcsys_created_by,
    b.srcsys_modified_by,
    b.row_status_cd,
    CAST(b.dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    b.load_id,
    b.appl_src_cd
FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst a
LEFT JOIN eda.ufds_vws.gmpbz_chpt_cnst_cnstcy b
    ON a.unf_fr_cnst_key = b.gmp_cnst_key
WHERE 
    a.cnst_typ_cd IN ('AG', 'IN', 'OR')
    AND b.chpt_cnstcy_affn_key IS NOT NULL
    AND a.cnst_mstr_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY a.cnst_mstr_id, b.chpt_cnstcy_affn_key
    ORDER BY b.strt_dt DESC, b.end_dt DESC, b.active_ind DESC
) = 1
with no schema binding 
;