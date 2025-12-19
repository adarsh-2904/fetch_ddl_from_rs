CREATE OR REPLACE VIEW mktg_ops_vws.gms_cnst_cdi_smry_fr_pa_dm 
AS
WITH dedup_locator_addr AS (
    SELECT
        regexp_replace(COALESCE(LA.line1_addr, ''), '[^\x00-\x7F]', '') AS line1_addr,
        regexp_replace(COALESCE(LA.line2_addr, ''), '[^\x00-\x7F]', '') AS line2_addr,
        regexp_replace(COALESCE(LA.city, ''), '[^\x00-\x7F]', '') AS city,
        regexp_replace(COALESCE(LA.state, ''), '[^\x00-\x7F]', '') AS state,
        regexp_replace(COALESCE(LA.zip_5, ''), '[^\x00-\x7F]', '') AS zip_5,
        LA.locator_addr_strt_ts,
        LA.locator_addr_key,
        LA.assessmnt_key,
        ROW_NUMBER() OVER (
            PARTITION BY 
                regexp_replace(COALESCE(LA.line1_addr, ''), '[^\x00-\x7F]', ''),
                regexp_replace(COALESCE(LA.line2_addr, ''), '[^\x00-\x7F]', ''),
                regexp_replace(COALESCE(LA.city, ''), '[^\x00-\x7F]', ''),
                regexp_replace(COALESCE(LA.state, ''), '[^\x00-\x7F]', ''),
                regexp_replace(COALESCE(LA.zip_5, ''), '[^\x00-\x7F]', '')
            ORDER BY LA.locator_addr_strt_ts DESC, LA.locator_addr_key DESC
        ) AS rn
    FROM eda.arc_mdm_vws.bz_locator_addr LA
)
SELECT 
    PRFR.cnst_mstr_id, 
    COALESCE(DU.unit_key, UCP.rev_credit_key) AS pa_unit_key,
    regexp_replace(PRFR.dm_cnst_line_1_addr, '[^\x00-\x7F]', '') AS dm_cnst_line_1_addr,
    regexp_replace(PRFR.dm_cnst_line_2_addr, '[^\x00-\x7F]', '') AS dm_cnst_line_2_addr,
    regexp_replace(PRFR.dm_cnst_city_nm, '[^\x00-\x7F]', '') AS dm_cnst_city_nm,
    regexp_replace(PRFR.dm_cnst_st_cd, '[^\x00-\x7F]', '') AS dm_cnst_st_cd,
    regexp_replace(PRFR.dm_cnst_zip_5_cd, '[^\x00-\x7F]', '') AS dm_cnst_zip_5_cd,
    regexp_replace(PRFR.dm_cnst_zip_4_cd, '[^\x00-\x7F]', '') AS dm_cnst_zip_4_cd,
    regexp_replace(PRFR.dm_cnst_addr_county_nm, '[^\x00-\x7F]', '') AS dm_cnst_addr_county_nm, 
    PRFR.affl_lock_ind, 
    regexp_replace(DM.cnst_line_1_addr, '[^\x00-\x7F]', '') AS cnst_line_1_addr, 
    regexp_replace(DM.cnst_line_2_addr, '[^\x00-\x7F]', '') AS cnst_line_2_addr,
    regexp_replace(DM.cnst_city_nm, '[^\x00-\x7F]', '') AS cnst_city_nm,
    regexp_replace(DM.cnst_st_cd, '[^\x00-\x7F]', '') AS cnst_st_cd,
    regexp_replace(DM.cnst_zip_5_cd, '[^\x00-\x7F]', '') AS cnst_zip_5_cd,
    regexp_replace(DM.cnst_zip_4_cd, '[^\x00-\x7F]', '') AS cnst_zip_4_cd,
    regexp_replace(DM.cnst_addr_county_nm, '[^\x00-\x7F]', '') AS cnst_addr_county_nm, 
    LA.locator_addr_key AS pa_locator_addr_key,
    DM.locator_addr_key AS dm_locator_addr_key, 
    regexp_replace(BA.assessmnt_ctg, '[^\x00-\x7F]', '') AS pa_addr_assessmnt_ctg, 
    regexp_replace(DM.cnst_addr_assessmnt_ctg, '[^\x00-\x7F]', '') AS dm_addr_assessmnt_ctg, 
    COALESCE(DU2.unit_key, UNIT.unit_key) AS dm_unit_key
FROM mktg_ops_tbls.gms_cnst_cdi_smry_fr_prfr_stg PRFR
LEFT JOIN eda.ufds_vws.bzfc_cnst_fr_prfl UCP 
    ON PRFR.cnst_mstr_id = UCP.cnst_mstr_id
LEFT JOIN dedup_locator_addr LA
    ON LA.rn = 1
    AND LA.line1_addr = regexp_replace(COALESCE(PRFR.dm_cnst_line_1_addr, ''), '[^\x00-\x7F]', '')
    AND LA.line2_addr = regexp_replace(COALESCE(PRFR.dm_cnst_line_2_addr, ''), '[^\x00-\x7F]', '')
    AND LA.city = regexp_replace(COALESCE(PRFR.dm_cnst_city_nm, ''), '[^\x00-\x7F]', '')
    AND LA.state = regexp_replace(COALESCE(PRFR.dm_cnst_st_cd, ''), '[^\x00-\x7F]', '')
    AND LA.zip_5 = regexp_replace(COALESCE(PRFR.dm_cnst_zip_5_cd, ''), '[^\x00-\x7F]', '')
LEFT JOIN eda.arc_mdm_vws.bz_assessmnt BA 
    ON BA.assessmnt_key = LA.assessmnt_key
LEFT JOIN mktg_ops_tbls.cnst_cdi_s_f_p_fr_dmail DM 
    ON PRFR.cnst_mstr_id = DM.cnst_mstr_id
LEFT JOIN eda.dw_common_vws.geo_zip_code_to_chapter GEOZIP 
    ON GEOZIP.zip = PRFR.dm_cnst_zip_5_cd
LEFT JOIN eda.dw_common_vws.dim_unit UNIT 
    ON UNIT.nk_ecode = GEOZIP.ECODE AND UNIT.branch_cd = '000'
LEFT JOIN eda.dw_common_vws.dim_unit_merged DU2 
    ON UNIT.unit_key = DU2.orig_unit_key
LEFT JOIN eda.dw_common_vws.dim_unit_merged DU 
    ON UCP.rev_credit_key = DU.orig_unit_key
WHERE COALESCE(DU2.unit_key, UNIT.unit_key, 0) <> COALESCE(DU.unit_key, UCP.rev_credit_key, 0)
WITH NO SCHEMA BINDING
;