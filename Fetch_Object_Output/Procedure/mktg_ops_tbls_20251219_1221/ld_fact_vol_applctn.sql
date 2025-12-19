CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_fact_vol_applctn()
 LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_fact_vol_applctn', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN

	TRUNCATE TABLE mktg_stage_tbls.fact_vol_applctn_stg;

---------------------------------------
 /*1st insert statement*/ 
 --------------------------------------
 
drop table if exists temp_vol_app;
create temp table temp_vol_app as /*Create temp table to bypass error:failed to find conversion function from "unknown" to character varying*/
WITH ranked_email AS (
    SELECT  
      email.cnst_mstr_id, 
        email.orig_cnst_mstr_id, 
        'Direct' AS attrib_typ, 
        email.src_cd, 
        email.subsrc_cd, 
        email.email_addr, 

        -- Campaign Details
        campgn.campgn_key, 

        -- Delivery Details
        deliv.delivery_key,  

        -- Intake Info
        intake.accnt_id,  
        intake.application_ts, 
        intake.path_id,  
        intake.path_nm, 
        intake.entry_point_id, 
        intake.point_of_entry, 
        intake.intake_outcome, 
        intake.outcome_ts, 
        intake.contact_status, 
        intake.contact_completed_dt, 

        CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS dw_trans_ts, 
        'I' AS row_stat_cd, 
        'MKTG' AS appl_src_cd, 
        100 AS load_id,

        ROW_NUMBER() OVER (
            PARTITION BY intake.accnt_id, intake.application_ts 
            ORDER BY email.intrctn_dt, email.srcsys_trans_ts
        ) AS rn
    FROM mktg_ops_vws.bzfc_fact_email_interaction email

    LEFT JOIN (
        SELECT campgn_key, campgn_lob_nm, campgn_nm, campgn_program_nm, campgn_channel_nm 
        FROM mktg_ops_vws.bz_dim_campgn
        WHERE campgn_channel_nm IN ('direct mail','email') 
          AND (campgn_lob_nm IN ('cross promotion','volunteer') OR campgn_lob_nm ILIKE '%consumer%fund%')
    ) campgn ON coalesce(campgn.campgn_key,0)::int8 = coalesce(email.campaign_key,0)::int8

    LEFT JOIN (
        SELECT delivery_key, xpromo_ind, delivery_start_dt 
        FROM mktg_ops_vws.bz_dim_delivery--Hitansu: is dim_delivery same as bz_dim_delivery
    ) deliv ON coalesce(deliv.delivery_key,0)::int8 = coalesce(email.delivery_key,0)::int8

    LEFT JOIN (
        SELECT cnst_mstr_id 
        FROM mktg_ops_vws.cnst_cdi_smry_vms_prfr
    ) vms ON coalesce(vms.cnst_mstr_id,0)::int8 = coalesce(email.cnst_mstr_id,0)::int8

   LEFT JOIN (
        SELECT cnst_mstr_id, cnst_mstr_subj_area_cd, cnst_mstr_subj_area_id 
        FROM eda.arc_mdm_vws.bz_cnst_mstr_bridge
    ) bridge ON coalesce(bridge.cnst_mstr_id,0)::int8 = coalesce(vms.cnst_mstr_id,0)::int8 
             AND bridge.cnst_mstr_subj_area_cd = 'VMS' 

    LEFT JOIN (
        SELECT vol_key, nk_account_id 
        FROM eda.vms_vws.dim_volunteer
    ) vol ON coalesce(bridge.cnst_mstr_subj_area_id,0)::int8  = coalesce(vol.vol_key,0)::int8 

    INNER JOIN mktg_ops_tbls.vcn_smry_intake intake 
        ON coalesce(intake.accnt_id,0)::int8 = coalesce(vol.nk_account_id,0)::int8

    WHERE 
        LOWER(campgn.campgn_nm) NOT LIKE '%survey%' AND (
            (LOWER(campgn.campgn_lob_nm) = 'cross promotion' AND LOWER(campgn.campgn_program_nm) = 'volunteer') OR
            (LOWER(campgn.campgn_lob_nm) = 'volunteer' AND LOWER(campgn.campgn_program_nm) LIKE '%volunteer%react%') OR
            (LOWER(campgn.campgn_lob_nm) = 'volunteer' AND LOWER(campgn.campgn_channel_nm) = 'direct mail' AND LOWER(campgn.campgn_program_nm) = 'direct mail') OR
            (LOWER(campgn.campgn_lob_nm) = 'volunteer' AND LOWER(campgn.campgn_channel_nm) = 'email' AND LOWER(campgn.campgn_program_nm) LIKE '%vol%auto%serie%') OR
            (LOWER(campgn.campgn_lob_nm) LIKE '%consumer%fund%' AND LOWER(campgn.campgn_channel_nm) = 'email' AND LOWER(campgn.campgn_program_nm) = 'crossnotes') OR
            (LOWER(campgn.campgn_lob_nm) LIKE '%consumer%fund%' AND LOWER(campgn.campgn_channel_nm) = 'email' AND LOWER(campgn.campgn_program_nm) LIKE '%trigg%serie%' AND LOWER(campgn.campgn_nm) LIKE '%new%donor%welc%') OR
            (LOWER(campgn.campgn_program_nm) LIKE 'egram%' AND deliv.xpromo_ind = 1::char(2))
        )
        AND application_ts::date BETWEEN deliv.delivery_start_dt::date AND (deliv.delivery_start_dt + INTERVAL '37 days')
)

select * from  ranked_email
WHERE rn = 1;

insert into mktg_stage_tbls.fact_vol_applctn_stg
(
cnst_mstr_id,orig_cnst_mstr_id,attrib_typ, src_cd, subsrc_cd, email_addr,
		campgn_key, delivery_key,  accnt_id, application_ts,
		path_id, path_nm, entry_point_id, point_of_entry, intake_outcome,
		outcome_ts, contact_status, contact_completed_dt, dw_trans_ts, row_stat_cd, appl_src_cd, load_id


)
SELECT 
    COALESCE(cnst_mstr_id, 0)::INT8,
    COALESCE(orig_cnst_mstr_id, 0)::INT8,
    attrib_typ::VARCHAR(20),
    src_cd::VARCHAR(20),
    subsrc_cd::VARCHAR(40),
    email_addr::VARCHAR(128),
    COALESCE(campgn_key, 0)::INT4,
    COALESCE(delivery_key, 0)::INT4,
    COALESCE(accnt_id, 0)::INT4,
    application_ts::TIMESTAMP,
    COALESCE(path_id, 0)::INT4,
    path_nm::VARCHAR(255),
    COALESCE(entry_point_id, 0)::INT4,
    point_of_entry::VARCHAR(255),
    intake_outcome::VARCHAR(24),
    outcome_ts::TIMESTAMP,
    contact_status::VARCHAR(50),
    contact_completed_dt::TIMESTAMP,
    dw_trans_ts::TIMESTAMP,
    row_stat_cd::CHAR(1),
    appl_src_cd::VARCHAR(4),
    COALESCE(load_id, 0)::INT4 from temp_vol_app;
	drop table if exists temp_vol_app;
---------------------------------------
 /*2nd insert statement*/ 
 --------------------------------------
drop table if exists temp_vol_app2;
create temp table temp_vol_app2 as /*Create temp table to bypass error:failed to find conversion function from "unknown" to character varying*/
WITH ranked_dmail AS (
    SELECT  
        dmail.cnst_mstr_id, 
        dmail.orig_cnst_mstr_id,  
        'Direct' AS attrib_typ, 
        dmail.src_cd, 
        dmail.subsrc_cd, 
        NULL AS email_addr,  -- DMAIL has no email address

        -- Campaign Details
        campgn.campgn_key, 

        -- Delivery Details
        deliv.delivery_key,  

        -- Intake Info
        intake.accnt_id,  
        intake.application_ts, 
        intake.path_id,  
        intake.path_nm, 
        intake.entry_point_id, 
        intake.point_of_entry, 
        intake.intake_outcome, 
        intake.outcome_ts, 
        intake.contact_status, 
        intake.contact_completed_dt, 

        CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS dw_trans_ts, 
        'I' AS row_stat_cd, 
        'MKTG' AS appl_src_cd, 
        100 AS load_id,

        ROW_NUMBER() OVER (
            PARTITION BY intake.accnt_id, intake.application_ts 
            ORDER BY dmail.intrctn_dt, dmail.srcsys_trans_ts
        ) AS rn

    FROM mktg_ops_vws.bzfc_fact_dmail_interaction dmail
--select * from mktg_ops_tbls.bzfc_fact_dmail_interaction
    LEFT JOIN mktg_ops_vws.bz_dim_campgn campgn 
        ON coalesce(campgn.campgn_key,0)::bigint = coalesce(dmail.campaign_key,0) ::bigint

    LEFT JOIN mktg_ops_vws.bz_dim_delivery deliv 
        ON coalesce(deliv.delivery_key,0)::bigint = coalesce(dmail.delivery_key,0) ::bigint

    LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr vms 
        ON coalesce(vms.cnst_mstr_id,0)::bigint = coalesce(dmail.cnst_mstr_id,0) ::bigint

    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge bridge 
        ON coalesce(bridge.cnst_mstr_id,0)::bigint = coalesce(vms.cnst_mstr_id,0) ::bigint
        AND bridge.cnst_mstr_subj_area_cd = 'VMS' 

    LEFT JOIN eda.vms_vws.dim_volunteer vol 
        ON coalesce(bridge.cnst_mstr_subj_area_id,0)::bigint = coalesce(vol.vol_key,0) ::bigint

    INNER JOIN mktg_ops_tbls.vcn_smry_intake intake 
        ON coalesce(intake.accnt_id,0)::bigint = coalesce(vol.nk_account_id,0)::bigint

    WHERE 
        LOWER(campgn.campgn_nm) NOT LIKE '%survey%' AND (
            (LOWER(campgn.campgn_lob_nm) = 'cross promotion' AND LOWER(campgn.campgn_program_nm) = 'volunteer') OR
            (LOWER(campgn.campgn_lob_nm) = 'volunteer' AND LOWER(campgn.campgn_program_nm) LIKE '%volunteer%react%') OR
            (LOWER(campgn.campgn_lob_nm) = 'volunteer' AND LOWER(campgn.campgn_channel_nm) = 'direct mail' AND LOWER(campgn.campgn_program_nm) = 'direct mail') OR
            (LOWER(campgn.campgn_lob_nm) = 'consumer fundraising' AND LOWER(campgn.campgn_channel_nm) = 'direct mail' AND LOWER(campgn.campgn_program_nm) = 'fr newsletter')
        )
        AND application_ts BETWEEN COALESCE(deliv.delivery_start_dt, deliv.mail_drop_dt) 
                              AND COALESCE(deliv.delivery_start_dt, deliv.mail_drop_dt) + INTERVAL '60 days'
)


SELECT *
FROM ranked_dmail
WHERE rn = 1;
INSERT INTO mktg_stage_tbls.fact_vol_applctn_stg
(	cnst_mstr_id, orig_cnst_mstr_id, attrib_typ, src_cd, subsrc_cd, email_addr,
		campgn_key, delivery_key,  accnt_id, application_ts,
		path_id, path_nm, entry_point_id, point_of_entry, intake_outcome,
		outcome_ts, contact_status, contact_completed_dt, dw_trans_ts, row_stat_cd, appl_src_cd, load_id ) 
SELECT 
    COALESCE(cnst_mstr_id, 0)::INT8,
    COALESCE(orig_cnst_mstr_id, 0)::INT8,
    attrib_typ::VARCHAR(20),
    src_cd::VARCHAR(20),
    subsrc_cd::VARCHAR(40),
    email_addr::VARCHAR(128),
    COALESCE(campgn_key, 0)::INT4,
    COALESCE(delivery_key, 0)::INT4,
    COALESCE(accnt_id, 0)::INT4,
    application_ts::TIMESTAMP,
    COALESCE(path_id, 0)::INT4,
    path_nm::VARCHAR(255),
    COALESCE(entry_point_id, 0)::INT4,
    point_of_entry::VARCHAR(255),
    intake_outcome::VARCHAR(24),
    outcome_ts::TIMESTAMP,
    contact_status::VARCHAR(50),
    contact_completed_dt::TIMESTAMP,
    dw_trans_ts::TIMESTAMP,
    row_stat_cd::CHAR(1),
    appl_src_cd::VARCHAR(4),
    COALESCE(load_id, 0)::INT4
    from temp_vol_app2;
	drop table if exists temp_vol_app2;
---------------------------------------
 /*3rd insert statement*/ 
 --------------------------------------
insert into mktg_stage_tbls.fact_vol_applctn_stg 
(cnst_mstr_id, orig_cnst_mstr_id, attrib_typ, campgn_key, delivery_key, spon_ext_id, site_ext_id,
                                site_cd, site_nm, nk_donat_dt, accnt_id, application_ts, path_id,
                                path_nm, entry_point_id, point_of_entry, intake_outcome, outcome_ts,contact_status, contact_completed_dt,
                                dw_trans_ts, row_stat_cd, appl_src_cd, load_id) 

SELECT 
    mb.cnst_mstr_id,
    mb.cnst_mstr_id AS orig_cnst_mstr_id,
    'InDirect' AS attrib_typ,
    0 AS campgn_key,
    0 AS delivery_key,
    a.spon_ext_id,
    a.site_ext_id,
    b.drive_site_cd,
    b.drive_site_nm,
    c.donation_dt as nk_donat_dt,
    h.accnt_id,
    h.application_ts,
    h.path_id,
    h.path_nm,
    h.entry_point_id,
    h.point_of_entry,
    h.intake_outcome,
    h.outcome_ts,
    h.contact_status,
    h.contact_completed_dt,
    CURRENT_TIMESTAMP AS dw_trans_ts,
    'I' AS row_stat_cd,
    'MKTG' AS appl_src_cd,
    100 AS load_id
FROM mktg_ops_tbls.fix_site_vol_recruit a
INNER JOIN eda.bio_appointment_vws.bzl_dim_drive_site b --ubds_vws.drbz_dim_drive_site
    ON b.nk_site_ext_id = LPAD(CAST(a.site_ext_id AS VARCHAR), 9, '0')
INNER JOIN eda.bio_donation_vws.bz_fact_donation c --ubds_vws.ePbz_fact_donation
    ON b.mstr_drive_site_key = c.mstr_drive_site_key
    
--Aug8,2025: new joins added in Redshift migration   
left join eda.arc_mdm_vws.bz_cnst_mstr_external_brid f 
	on f.cnst_srcsys_scndry_id=c.donor_external_id  
left join mktg_ops_vws.cnst_cdi_smry_vms_prfr e 
	on e.cnst_mstr_id = f.cnst_mstr_id 
left join eda.arc_mdm_vws.cnst_mstr_bridge mb
	on mb.cnst_mstr_id= f.cnst_mstr_id and mb.cnst_mstr_subj_area_cd = 'VMS' 
--LEFT JOIN ubds_vws.bz_dim_cnst_unf d 
--    ON c.donor_key = d.ep_donor_key
--LEFT JOIN select cnst_mstr_id from mktg_ops_vws.cnst_cdi_smry_vms_prfr e 
--    ON e.cnst_mstr_id = d.bz_cnst_mstr_id 
--LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge f 
--    ON f.cnst_mstr_id = e.cnst_mstr_id 
--    AND f.cnst_mstr_subj_area_cd = 'VMS' 
LEFT JOIN eda.vms_vws.dim_volunteer g 
    ON mb.cnst_mstr_subj_area_id = g.vol_key 
LEFT JOIN mktg_ops_tbls.vcn_smry_intake h 
    ON h.accnt_id = g.nk_account_id
WHERE a.site_ext_id IS NOT NULL
    AND c.donation_dt >= DATE '2023-07-01'
    AND CAST(h.application_ts AS DATE) BETWEEN c.donation_dt AND (c.donation_dt + INTERVAL '60 day')
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY f.cnst_mstr_id, h.application_ts 
    ORDER BY c.donation_dt
) = 1;
DELETE From mktg_ops_tbls.fact_vol_applctn  WHERE (SELECT Count(*) FROM mktg_ops_tbls.vcn_smry_intake )>0 ;
  insert into mktg_ops_tbls.fact_vol_applctn 
(cnst_mstr_id, orig_cnst_mstr_id, attrib_typ, campgn_key, delivery_key, spon_ext_id, site_ext_id,
                                site_cd, site_nm, nk_donat_dt, accnt_id, application_ts, path_id,
                                path_nm, entry_point_id, point_of_entry, intake_outcome, outcome_ts,contact_status, contact_completed_dt,
                                dw_trans_ts, row_stat_cd, appl_src_cd, load_id) 
					
select
cnst_mstr_id, orig_cnst_mstr_id, attrib_typ, campgn_key, delivery_key, spon_ext_id, site_ext_id,
                                site_cd, site_nm, nk_donat_dt, accnt_id, application_ts, path_id,
                                path_nm, entry_point_id, point_of_entry, intake_outcome, outcome_ts,contact_status, contact_completed_dt,
                                dw_trans_ts, row_stat_cd, appl_src_cd, load_id
								from mktg_stage_tbls.fact_vol_applctn_stg ;


 	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_stage_tbls.fact_vol_applctn_stg) as integer)
        WHERE proc_name = 'ld_fact_vol_applctn' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_fact_vol_applctn', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
