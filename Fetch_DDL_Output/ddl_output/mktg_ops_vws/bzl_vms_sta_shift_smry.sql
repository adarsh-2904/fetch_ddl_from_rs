CREATE OR REPLACE VIEW mktg_ops_vws.bzl_vms_sta_shift_smry
/*
Created By: Michael Andrien
Create Date: 03/29/2019
Purpose: This view was created to support the Sound The Alarm campaign. The view summarizes volunteer shift and team affiliation data into 
one record per CDI master id. The view references the mktg_ops_vws.vms_sta_indivs and mktg_ops_vws.vms_sta_orgs views, which were
loaded from the Volunteer Connection (VCN) system. These views contain the detail shifts by volunteer and the teams affiliated with each shift.
The views referenced by this view are loaded on an ad hoc basis. The MODS team will consider automating the daily or weekly VCN data pulls once 
the MODS Ops team determines whether the campaign emails need to be sent on a recurring basis.
*/
AS
SELECT 
    cnst_mstr_id,
    CASE WHEN registered_cnt > 0 THEN 'Y' ELSE 'N' END AS active_registration_flg,
    CASE WHEN fire_dept_agency_cnt > 0 THEN 'Y' ELSE 'N' END AS fire_dept_agency_flg,
    CASE WHEN corp_business_cnt > 0 THEN 'Y' ELSE 'N' END AS corp_business_flg,
    latest_regis_start_ts,
    registered_cnt,
    attended_cnt,
    cancelled_cnt,
    fire_dept_agency_cnt,
    corp_business_cnt,
    community_org_cnt,
    family_cnt,
    other_cnt
FROM (
    SELECT 
        c.cnst_mstr_id, 
        MAX(a.registration_start_datetime) AS latest_regis_start_ts,
        SUM(CASE WHEN a.registration_status_lookup = 'Registered' THEN 1 ELSE 0 END) AS registered_cnt,
        SUM(CASE WHEN a.registration_status_lookup = 'Attended' THEN 1 ELSE 0 END) AS attended_cnt,        
        SUM(CASE WHEN a.registration_status_lookup = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_cnt,
        SUM(CASE WHEN d.team_type = 'Fire Department/Agency' THEN 1 ELSE 0 END) AS fire_dept_agency_cnt,
        SUM(CASE WHEN d.team_type = 'Business or Corporation' THEN 1 ELSE 0 END) AS corp_business_cnt,
        SUM(CASE WHEN d.team_type IN ('Community Organization', 'Community Organization (School, Religious Organization, etc.)') THEN 1 ELSE 0 END) AS community_org_cnt,
        SUM(CASE WHEN d.team_type = 'Family' THEN 1 ELSE 0 END) AS family_cnt,
        SUM(CASE WHEN d.team_type = 'Other' THEN 1 ELSE 0 END) AS other_cnt
    FROM mktg_ops_vws.vms_sta_indivs a
    LEFT JOIN eda.vms_vws.dim_volunteer b 
        ON b.nk_account_id = a.account_id
    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge c 
        ON b.vol_key = c.cnst_mstr_subj_area_id 
        AND cnst_mstr_subj_area_cd = 'VMS'
    LEFT JOIN mktg_ops_vws.vms_sta_orgs d 
        ON a.team_id = d.team_id
    GROUP BY c.cnst_mstr_id
) AS a with no schema binding;