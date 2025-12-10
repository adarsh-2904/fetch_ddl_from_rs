CREATE OR REPLACE VIEW mktg_ops_vws.dim_isp_labor
AS
/*
Modified By: Michael Andrien
Modified Date: 10/24/25
Purpose: Created the dim_isp_labor view to simplify the method for combining ISP labor data with dim_operator data from our blood banking system.  The base query was
provided to the MODS team by ABI team.  This view will be joined to the eda.bio_shipment_vws.bzl_dim_operator to create the mktg_ops_vws.bz_dim_operator table, which is reference in biomed survey model and various Power BI reporting models.
*/
 SELECT
    labor_unf.labor_key,
    labor_unf.empl_id,
    zip.region_code AS nk_region_id,
    labor_unf.job_title AS labor_job_title,
    labor_unf.first_nm,
    labor_unf.last_nm,
    labor_unf.middle_nm,
    (labor_unf.prefd_last_nm || ', ' || labor_unf.prefd_first_nm) AS staff_nm,
    labor_unf.prefd_first_nm AS staff_prefd_first_nm,
    labor_unf.prefd_last_nm AS staff_prefd_last_nm,
    labor_unf.buss_phn,
    labor_unf.login_user_nm,
    labor_unf.departure_dt,
    labor_unf.em_addr AS staff_email_addr,
    labor_unf.mgr_labor_key,
    CASE WHEN sfRes.union_affiliation  IS NOT NULL THEN 'Y' ELSE 'N' END AS union_flg,
    sfRes.weekly_hours  AS standard_hrs,
    loc.addr_ln1 AS staff_addr_line1,
    loc.addr_ln2 AS staff_addr_line2,
    loc.city AS staff_city,
    loc.st_cd AS staff_st_cd,
    LEFT(loc.cln_zip_cd, 5) as staff_zip,
    fcc.nk_fcc_cd,
    fcc.fcc_desc,
    CASE
        WHEN fcc.nk_fcc_cd = '83140' THEN 'Mobile'
        WHEN fcc.nk_fcc_cd = '83340' THEN 'APH/IFS'
        ELSE 'Other'
    END AS aphrss_wb_dsc,
	labor_unf_supv.prefd_last_nm || ', ' || labor_unf_supv.prefd_first_nm AS supervisor_nm,	
	sl_labor_unf_supv.prefd_last_nm || ', ' || sl_labor_unf_supv.prefd_first_nm AS sl_supervisor_nm,
    sfRes.union_affiliation  AS union_cd,
    sfRes.union_description  AS union_dsc,
    CASE WHEN r2_tags.cnt > 0 THEN 'Y' ELSE 'N' END AS staff_role,
    labor_unf_supv.em_addr AS suprvsr_email_addr,
    CASE WHEN labor_unf.departure_dt IS NULL THEN 'Y' ELSE 'N' END AS active_flg,
    CASE
        WHEN sfRes.hire_date IS NULL THEN iam.empl_hire_dt
        ELSE sfRes.hire_date
    END AS hire_dt,
    sfRes.hire_date AS rehire_dt,
    CASE
        WHEN labor_unf.departure_dt IS NULL THEN
            ((EXTRACT(YEAR FROM CURRENT_DATE) * 10000 + EXTRACT(MONTH FROM CURRENT_DATE) * 100 + EXTRACT(DAY FROM CURRENT_DATE)) -
             (EXTRACT(YEAR FROM COALESCE(sfRes.hire_date, iam.empl_hire_dt)) * 10000 + EXTRACT(MONTH FROM COALESCE(sfRes.hire_date, iam.empl_hire_dt)) * 100 + EXTRACT(DAY FROM COALESCE(sfRes.hire_date, iam.empl_hire_dt)))) / 10000
        ELSE
            ((EXTRACT(YEAR FROM labor_unf.departure_dt) * 10000 + EXTRACT(MONTH FROM labor_unf.departure_dt) * 100 + EXTRACT(DAY FROM labor_unf.departure_dt)) -
             (EXTRACT(YEAR FROM COALESCE(sfRes.hire_date, iam.empl_hire_dt)) * 10000 + EXTRACT(MONTH FROM COALESCE(sfRes.hire_date, iam.empl_hire_dt)) * 100 + EXTRACT(DAY FROM COALESCE(sfRes.hire_date, iam.empl_hire_dt)))) / 10000
    END AS tenure_yrs,
    CASE
        WHEN labor_unf.departure_dt IS NULL THEN 'Yes'
        WHEN labor_unf.departure_dt IS NOT NULL AND
            ROUND(
                (DATE_PART('year', CURRENT_DATE) - DATE_PART('year', labor_unf.departure_dt)) * 12 +
                (DATE_PART('month', CURRENT_DATE) - DATE_PART('month', labor_unf.departure_dt)), 0
            ) <= 13 THEN 'Yes'
        ELSE 'No'
    END AS isp_active_flg,
    --ebdr_ids.second_latest_ebdrid AS "eBDR ID" --**original field not yet available**: ubds_vws.bzl_dim_staff_ebdr_ids.latest_used_staff_id
    ebdr_ids.most_used_ebdrid
FROM eda.ulds_vws.bz_dim_labor_unf labor_unf
LEFT JOIN eda.ulds_vws.bz_dim_loctn_unf loc ON labor_unf.loctn_key = loc.loctn_key
LEFT JOIN eda.ulds_vws.bz_dim_fcc_unf fcc ON labor_unf.fcc_key = fcc.fcc_key
LEFT JOIN eda.bio_drive_planning_vws.bz_dim_drive_staff_mstr sfRes ON labor_unf.empl_id = sfRes.employee_id
LEFT JOIN eda.ulds_vws.bz_dim_labor_unf labor_unf_supv ON labor_unf.mgr_labor_key = labor_unf_supv.labor_key
LEFT JOIN eda.ulds_vws.bz_dim_labor_unf sl_labor_unf_supv ON labor_unf_supv.mgr_labor_key = sl_labor_unf_supv.labor_key
LEFT JOIN eda.iam_vws.bzfc_iam_acct_all iam ON labor_unf.empl_id = iam.nk_empl_id
LEFT JOIN eda.bio_donation_vws.bz_dim_staff_ebdr_ids ebdr_ids ON labor_unf.em_addr = ebdr_ids.new_email
LEFT JOIN eda.dw_common_vws.dim_zipcodes zip ON Left(loc.cln_zip_cd, 5) = zip.zip
LEFT JOIN (
    SELECT
        rs.employee_id,
        COUNT(*) AS cnt
    FROM eda.bio_drive_planning_vws.bz_dim_tag AS tag_dim
    INNER JOIN eda.bio_drive_planning_vws.bz_dim_resource_tag rs_tg ON tag_dim.nk_tag_guid = rs_tg.nk_tag_guid
    INNER JOIN eda.hmsp_vws.hmbz_dim_staff rs ON rs_tg.nk_resource_guid = rs.nk_staff_id
    WHERE tag_dim.tag_name ILIKE '%2rbc%'
        AND tag_dim."type" = 'Role'
        AND rs_tg.resource_tag_start_date <= CURRENT_DATE
        AND (rs_tg.resource_tag_expiry_date IS NULL OR rs_tg.resource_tag_expiry_date > CURRENT_DATE)
    GROUP BY rs.employee_id
) r2_tags ON r2_tags.employee_id = labor_unf.empl_id
WHERE
    labor_unf.labor_typ = 'employee'
    AND labor_unf.empl_id IS NOT NULL
    AND LENGTH(labor_unf.empl_id) > 0
WITH NO SCHEMA BINDING
;