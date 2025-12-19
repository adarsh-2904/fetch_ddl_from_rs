CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_sms_fr_prfl()
 LANGUAGE plpgsql
AS $$

/* 
Created By: Michael Andrien 
Create Date: 09/17/2024 
Purpose: This view links the mobile phone numbers from the SMS Profile view (bzfc_sms_profile) to the CDI phone locator view (arc_mdm_vws.bzfc_cnst_phn) to match the mobile phone numbers to the CDI master ids associated with the numbers.  Note, this is a loose match in that we are linking incoming SMS texts responses, which  are anonymous texts with CDI phone numbers from known Red Cross source systems.  After pairing the SMS numbers to the 'Usable' CDI phone numbers, the view joins the CDI master id to the Mktg FR preferred profile on the master id.  An SMS number may be associated with more than one CDI master id and a master id may be associated with more than one number.  The grain of the view is CDI master (cnst_mstr_id) and SMS mobile number.  Lastly, this view is limited to master ids in the Mktg FR preferred profile.  


Modified By: Michael Andrien 
Modified Date: 10/22/2024 
Purpose: Replace the a to b join logic below with Substr(RegExp_Replace(a.locator_phn_num,'[^0-9]', ''),1,10) = b.mobile_num.  This strips non-numeric characters from the profile phone number rather than adding the non-numeric characters to the SMS profile number.  This is a cleaner method for the join. ON a.locator_phn_num = CASE WHEN Length(b.mobile_num) = 10 THEN '(' || Substr(b.mobile_num, 1,3) ||') ' || Substr(b.mobile_num, 4,3) || '-' || Substr(b.mobile_num, 7,4)                    ELSE b.mobile_num                  END  


Modified By:   Greg Seaberg 
Implemented By:  Michael Andrien 
Modified Date:  1/3/2024 Purpose:     Updated join logic between bzfc_sms_profile and the union of bzfc_cnst_phn and bzfc_phone_append.                    Old logic:          Substr(RegExp_Replace(a.locator_phn_num,'[^0-9]', ''),1,10) = b.mobile_num                    New logic:          OTRANSLATE(a.locator_phn_num, OTRANSLATE(a.locator_phn_num, '0123456789',''), '') = b.mobile_num                  Also, changed the bzfc_phone_append UNION to a UNION ALL and added correlated subquery logic to avoid duplicating interaction rows.  Lastly, we removed the         SELECT DISTINCTS and updated the QUALIFY statements to include cnst_mstr_id.  

Modified By: Michael Andrien 
Modified Date: 04/03/2025 

Purpose: Added time_zone_dsc to the view   

Modified By: Michael Andrien 
Modified Date: 08/13/2025 P
urpose: Modified the select and join logic to strip non-numeric values from the phone number before joining.  This fixed the issue with most  records not having CDI master id matches.  Also, added the following attributes to the view for RCO opt-ins and Major Donor Suppression first_rco_phn_opt_in_ts, first_rco_phn_opt_in_dt, last_rco_phn_opt_in_ts, last_rco_phn_opt_in_dt, rco_opt_in_cnt, rco_opt_in_ind, major_donor_suprsn_ind and sf_green_mangd_acct_ind 
*/


DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_sms_fr_prfl', 'Stored Procedure', 'Inprogress', v_start_time);


begin

-- Step 1: Delete existing data
truncate table mktg_ops_tbls.bzfc_sms_fr_prfl;

-- Step 2: Insert new data
INSERT INTO mktg_ops_tbls.bzfc_sms_fr_prfl
SELECT
    --c.
	cnst_mstr_id,
    --b.
	src_mobile_num,
    --b.
	mobile_num,
    --b.
	time_zone_dsc,
    COALESCE(ok_to_text_flg, 'N') AS ok_to_text_flg,
    active_carrier_nm,
    active_create_ts,
    active_status,
    active_source_typ,
    active_source_nm,
    active_status_dsc,
    active_opt_out_dt,
    active_opt_out_source,
    COALESCE(active_subscrbr_ind, 0) AS active_subscrbr_ind,
    unsbscrb_carrier_nm,
    unsbscrb_created_ts,
    unsbscrb_status,
    unsbscrb_source_typ,
    unsbscrb_source_nm,
    unsbscrb_status_dsc,
    unsbscrb_opt_out_dt,
    unsbscrb_opt_out_source,
    COALESCE(unsbscrb_ind, 0) AS unsbscrb_ind,
    adobe_first_unsbscrb_ts,
    adobe_first_unsbscrb_dt,
    adobe_last_unsbscrb_ts,
    adobe_last_unsbscrb_dt,
    adobe_opt_out_ind,
    first_adobe_opt_in_ts,
    first_adobe_opt_in_dt,
    last_adobe_opt_in_ts,
    last_adobe_opt_in_dt,
    COALESCE(adobe_opt_in_ind, 0) AS adobe_opt_in_ind,
    first_mc_opt_in_ts,
    last_mc_opt_in_ts,
    first_mc_opt_out_ts,
    last_mc_opt_out_ts,
    COALESCE(mc_opt_out_cnt, 0) AS mc_opt_out_cnt,
    first_rco_phn_opt_in_ts,
    first_rco_phn_opt_in_dt,
    last_rco_phn_opt_in_ts,
    last_rco_phn_opt_in_dt,
    rco_opt_in_cnt,
    rco_opt_in_ind,
    major_donor_suprsn_ind,
    sf_green_mangd_acct_ind
FROM (
    -- CTE for arc_mdm_vws.bzfc_cnst_phn
    WITH phn_cte AS (
        SELECT
            cnst_mstr_id,
            REGEXP_REPLACE(a.locator_phn_num, '[^0-9]', '') AS locator_phn_num,
            ROW_NUMBER() OVER (
                PARTITION BY a.locator_phn_num
                ORDER BY
                    CASE
                        WHEN b.line_of_service_cd IN ('FR', 'ATG', 'MDON', 'MKTG', 'RCO') THEN 1
                        WHEN b.line_of_service_cd = 'BIO' THEN 2
                        WHEN b.line_of_service_cd = 'VMS' THEN 3
                        WHEN b.line_of_service_cd = 'PHSS' THEN 4
                        ELSE 5
                    END,
                    a.cnst_phn_strt_ts DESC,
                    a.cnst_mstr_id ASC
            ) AS rn
        FROM eda.arc_mdm_vws.bzfc_cnst_phn a
        LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys b
            ON a.arc_srcsys_cd = b.arc_srcsys_cd
        WHERE a.assessmnt_ctg IN ('Usable', 'Use With Caution')
    ),
    append_cte AS (
        SELECT
            cnst_mstr_id,
            REGEXP_REPLACE(a.append_phone_num, '[^0-9]', '') AS locator_phn_num,
            ROW_NUMBER() OVER (
                PARTITION BY a.append_phone_num
                ORDER BY a.list_upload_ts DESC, a.cnst_mstr_id ASC
            ) AS rn
        FROM mktg_ops_vws.bzfc_phone_append a
        WHERE a.line_typ = 'Cell'
        AND NOT EXISTS (
            SELECT 1
            FROM eda.arc_mdm_vws.bzfc_cnst_phn b  --select * from eda.arc_mdm_vws.bzfc_cnst_phn limit 5
            WHERE b.assessmnt_ctg IN ('Usable', 'Use With Caution')
              AND a.append_phone_num::bigint = b.locator_phn_num::bigint
        )
    ),
    combined AS (
        SELECT cnst_mstr_id::bigint, locator_phn_num::bigint FROM phn_cte WHERE rn = 1
        UNION ALL
        SELECT cnst_mstr_id::bigint, locator_phn_num::bigint FROM append_cte WHERE rn = 1
    )
    SELECT *
    FROM combined a
    INNER JOIN mktg_ops_vws.bzfc_sms_profile b
        ON a.locator_phn_num::bigint = b.mobile_num::bigint
) c;

--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.arc_biomed_txn) as nvarchar)+ ' Records inserted.';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_bzfc_sms_fr_prfl' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bzfc_sms_fr_prfl', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;


$$
