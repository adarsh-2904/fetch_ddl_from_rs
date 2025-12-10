CREATE OR REPLACE VIEW mktg_ops_vws.gms_frfbz_dim_tag
/*
Created BY: Michael Andrien
Created Date: 09/20/2022
Purpose: This view contains Tags data of Salesforce Contacts
*/
AS
SELECT 
    frf_tag_key,
    b.cnst_mstr_id,
    a.frf_cnst_key,
    tag_nm,
    strt_dt,
    end_dt,
    comments,
    grp,
    nk_sf_acct_guid,
    nk_sf_cntct_guid,
    nk_sf_tag_guid,
    nk_sf_tag_label_guid,
    CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
    CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
    load_id,
    appl_src_cd
FROM eda.ufds_vws.frfbz_dim_tag a
LEFT JOIN (
    SELECT cnst_mstr_id, unf_fr_cnst_key
    FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst
) b ON a.frf_cnst_key = b.unf_fr_cnst_key with no schema binding;