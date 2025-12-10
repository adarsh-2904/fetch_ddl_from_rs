CREATE OR REPLACE VIEW mktg_ops_vws.arc_entrprs_smry (cnst_mstr_id, fr_first_dntn_dt, fr_last_dntn_dt, fr_lftm_dntn_cnt, fst_donat_dt, last_donat_dt, lftm_donat_cnt, fst_vol_dt, last_vol_dt, lftm_vol_cnt, first_ts_crs_dt, last_ts_crs_dt, lftm_ts_crs_cnt, first_engagmnt_dt, first_engagmnt_lob_key, last_engagmnt_dt, last_engagmnt_lob_key, lftm_engagmnt_cnt) AS

/*
Created by: Majeed Mohammad
Created on: 11/03/2022
Purpose: View requested by Greg to get the summary counts & last active dates across all LOBs for FR constituents

Modifed by: Majeed Mohammad
Modifed on: 11/08/2022
Purpose:  Renamed the view from  mktg_ops_vws.fr_orc_engagmnt_smry  to mktg_ops_vws.arc_entrprs_smry.
					Driving table is now arc_mdm_vws.bz_cnst_mstr (no longer limited to FR master IDs)
					Added initial engagement / transaction dates for each LOB + first engagement LOB
					Changed LOB text values to key values from mktg_ops_vws.dim_lob
*/
/* summary counts & first & last active dates across all LOBs for all constituent master IDs */
SELECT /* identify lifetime engagement count across all LOBs */
    cnst.cnst_mstr_id, frs.fr_first_dntn_dt, /* first & last FR donation date & lifetime count from fr_smry */ frs.fr_last_dntn_dt, frs.fr_lftm_dntn_cnt, bss.fst_donat_dt, /* first & last Biomed donation date & lifetime count from biomed_smry */ bss.last_donat_dt, bss.lftm_donat_cnt, NULLIF(TO_DATE(LEAST(CAST (TO_CHAR(COALESCE(vss.first_vol_dt, DATE '9999-12-31'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(vss.initial_vol_dt, DATE '9999-12-31'), 'YYYYMMDD') AS INTEGER)) /* identify first Volunteer date, returning null for unmatched records */, 'YYYYMMDD'), DATE '9999-12-31') AS fst_vol_dt, vss.last_vol_dt, /* last Volunteer date & lifetime count from vms_smry */ vss.lftm_vol_cnt, tss1.first_ts_crs_dt, /* first & last TS course completion or purchase (for SABA & DemandWare, respectively) & lifetime count from phss_smry */ tss1.last_ts_crs_dt, tss1.lftm_ts_crs_cnt, NULLIF(TO_DATE(LEAST(CAST (TO_CHAR(COALESCE(frs.fr_first_dntn_dt, DATE '9999-12-31'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(bss.fst_donat_dt, DATE '9999-12-31'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(fst_vol_dt, DATE '9999-12-31'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(tss1.first_ts_crs_dt, DATE '9999-12-31'), 'YYYYMMDD') AS INTEGER)) /* identify earliest transaction date, returning null for unmatched records */, 'YYYYMMDD'), DATE '9999-12-31') AS first_engagmnt_dt,
    CASE
        WHEN first_engagmnt_dt = frs.fr_first_dntn_dt THEN 2 /* identify LOB for earliest transaction date above */
        WHEN first_engagmnt_dt = bss.fst_donat_dt THEN 1
        WHEN first_engagmnt_dt = fst_vol_dt THEN 4
        WHEN first_engagmnt_dt = tss1.first_ts_crs_dt THEN 3
    END AS first_engagmnt_lob_key, NULLIF(TO_DATE(GREATEST(CAST (TO_CHAR(COALESCE(frs.fr_last_dntn_dt, DATE '1900-01-01'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(bss.last_donat_dt, DATE '1900-01-01'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(vss.last_vol_dt, DATE '1900-01-01'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(tss1.last_ts_crs_dt, DATE '1900-01-01'), 'YYYYMMDD') AS INTEGER)) /* identify most recent transaction date, returning null for unmatched records */, 'YYYYMMDD'), DATE '1900-01-01') AS last_engagmnt_dt,
    CASE
        WHEN last_engagmnt_dt = frs.fr_last_dntn_dt THEN 2 /* identify LOB for most recent transaction date above */
        WHEN last_engagmnt_dt = bss.last_donat_dt THEN 1
        WHEN last_engagmnt_dt = vss.last_vol_dt THEN 4
        WHEN last_engagmnt_dt = tss1.last_ts_crs_dt THEN 3
    END AS last_engagmnt_lob_key, NVL(frs.fr_lftm_dntn_cnt, '0') + NVL(bss.lftm_donat_cnt, '0') + NVL(vss.lftm_vol_cnt, '0') + NVL(tss1.lftm_ts_crs_cnt, '0') AS lftm_engagmnt_cnt
    FROM eda.arc_mdm_vws.bz_cnst_mstr AS cnst
    LEFT OUTER JOIN mktg_ops_vws.gms_arc_fr_smry AS frs
        ON cnst.cnst_mstr_id = frs.cnst_mstr_id
    LEFT OUTER JOIN mktg_ops_vws.arc_biomed_smry AS bss
        ON cnst.cnst_mstr_id = bss.cnst_mstr_id
    LEFT OUTER JOIN mktg_ops_vws.arc_vms_smry AS vss
        ON cnst.cnst_mstr_id = vss.cnst_mstr_id
    LEFT OUTER JOIN
    /* derived table combining arc_phss_smry with DemandWare order counts */
    (SELECT /* aggregate count of SABA courses completed + DMW courses purchased */
        tss.cnst_mstr_id, NULLIF(TO_DATE(LEAST(CAST (TO_CHAR(COALESCE(tss.fst_crs_cmptn_dt, DATE '9999-12-31'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(tss.first_dmw_course_dt, DATE '9999-12-31'), 'YYYYMMDD') AS INTEGER)) /* identify most recent course completion / purchase */, 'YYYYMMDD'), DATE '9999-12-31') AS first_ts_crs_dt, NULLIF(TO_DATE(GREATEST(CAST (TO_CHAR(COALESCE(tss.last_crs_cmptn_dt, DATE '1900-01-01'), 'YYYYMMDD') AS INTEGER), CAST (TO_CHAR(COALESCE(tss.last_dmw_course_dt, DATE '1900-01-01'), 'YYYYMMDD') AS INTEGER)) /* identify most recent course completion / purchase */, 'YYYYMMDD'), DATE '1900-01-01') AS last_ts_crs_dt, MAX(tss.lftm_crs_complt_cnt) + COUNT(dodr.odr_key) AS lftm_ts_crs_cnt
        FROM mktg_ops_vws.arc_phss_smry AS tss
        LEFT OUTER JOIN eda.uhss_vws.sfbz_dim_prsn_addr AS dpa
            ON tss.cnst_mstr_id = dpa.cnst_mstr_id
        LEFT OUTER JOIN eda.uhss_vws.sfbz_dim_odr AS dodr
            ON dpa.prsn_addr_key = dodr.billing_prsn_addr_key AND dodr.odr_stat_cd IN ('NEW', 'OPEN')
        WHERE last_ts_crs_dt > DATE '1900-01-01'
        GROUP BY 1, 2, 3
        HAVING lftm_ts_crs_cnt > 0) AS tss1 (cnst_mstr_id, first_ts_crs_dt, last_ts_crs_dt, lftm_ts_crs_cnt)
        ON cnst.cnst_mstr_id = tss1.cnst_mstr_id
    WHERE
    CASE
        WHEN last_engagmnt_dt > DATE '1900-01-01' AND last_engagmnt_dt <= CAST (getdate() AS DATE) THEN 1
        WHEN lftm_engagmnt_cnt > 0 THEN 1
        ELSE 0
    END = 1
WITH NO SCHEMA BINDING;