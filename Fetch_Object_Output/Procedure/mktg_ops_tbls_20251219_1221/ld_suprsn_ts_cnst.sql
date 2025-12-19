CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_suprsn_ts_cnst()
 LANGUAGE plpgsql
AS $$	
/*

Modified By: Michael Andrien
Modified Date: 04/09/2025
Purpose:        Created the a macro (ld_mktg_ops_tbls.suprsn_ts_cnst) to load the mktg_ops_tbls.mktg_ops_tbls.suprsn_ts_cnst table then updated the view 
to select the data from the table.  I transferred the original view SQL to the macro.  We did this to address an issue we had with the view returning lower 
counts when run from Adobe Campaign.  Below are the original comment from the view header regarding the purpose:
Purpose: This view serves as a suppression view for MODS Ops team to use within the Adobe Campaign tool to suppress Training Services constituent from 
cross-promotion campaigns.  The view matches our preferred email and mailing addresses against the CDI email and mailing address views to match the locators 
to other cnst_mstr_id records within the household.  The match logic is intentionally broad to ensure we can apply a very broad suppression when necessary. The 
ts_cnst_match_ind identifies direct matches against our PHSS/TS Preferred profile while the ts_email_match_ind and ts_add_match_ind indicator attributes
identify all constituents from CDI that match on that locator keys.
*/	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_suprsn_ts_cnst', 'Stored Procedure', 'Inprogress', v_start_time);


begin
	
DELETE From mktg_ops_tbls.suprsn_ts_cnst;
--create table mktg_ops_tbls.suprsn_ts_cnst as 
INSERT INTO mktg_ops_tbls.suprsn_ts_cnst
SELECT 
 mstr.cnst_mstr_id, -- CDI Master ID
 CASE WHEN ts_prfr.cnst_mstr_id IS NOT NULL THEN 1 ELSE 0 END AS ts_cnst_match_ind, -- TS Cnst Match Indicator
 CASE WHEN ts_prfr.cnst_mstr_id IS NULL AND ts_email.cnst_mstr_id IS NOT NULL THEN 1 ELSE 0 END AS ts_email_match_ind, -- TS Email Match Indicator
 CASE WHEN ts_prfr.cnst_mstr_id IS NULL AND ts_addr.cnst_mstr_id IS NOT NULL THEN 1 ELSE 0 END AS ts_addr_match_ind -- TS Address Match Indicator

-- Start with the CDI Master table as our base - this table contains all CDI master ids
FROM eda.arc_mdm_vws.bz_cnst_mstr mstr
/* 
The ts_email join does an inner join starting with the distinct list of master ids and email locator keys from CDI .  The CDI master email key list is joined to the TS email key list  on the email key
Note, I limit this to email addresses in the PHSS Preferred with an email assessment category of Validated or Use with Caution.  This returns all CDI master ids associated with Validate email addresses from the preferred profile.
*/
LEFT JOIN 
(
		SELECT DISTINCT
			a.cnst_mstr_id
		FROM 
		(
			SELECT DISTINCT cnst_mstr_id, email_key
			FROM eda.arc_mdm_vws.bzfc_cnst_email
			WHERE assessmnt_ctg IN ('Validated', 'Use with Caution')
		) a (cnst_mstr_id, email_key)
		INNER JOIN 
		(
			SELECT DISTINCT b.email_key
			FROM mktg_ops_vws.cnst_cdi_phss_preferred_email a
			INNER JOIN eda.arc_mdm_vws.bzfc_cnst_email b ON a.cnst_mstr_id = b.cnst_mstr_id
			WHERE b.assessmnt_ctg IN ('Validated', 'Use with Caution')
		) b (email_key) ON a.email_key = b.email_key
) ts_email (cnst_mstr_id)  ON mstr.cnst_mstr_id = ts_email.cnst_mstr_id
/* 
The ts_addr join does an inner join starting with the distinct list of master ids and address locator keys from CDI .  The CDI master address key list is joined to the TS address locator key list  on the address locator key
Note, I limit this to mailing addresses in the PHSS Preferred with an email assessment category of Deliverable and a DPV code of 'Y'.  This returns all CDI master ids associated with Deliverable addresses from the preferred profile.
*/
LEFT JOIN 
(
	SELECT DISTINCT
		a.cnst_mstr_id
	FROM 
	(
		SELECT DISTINCT cnst_mstr_id, locator_addr_key
		FROM eda.arc_mdm_vws.bzfc_cnst_addr
		WHERE assessmnt_ctg = 'Deliverable' AND dpv_cd = 'Y'
	) a (cnst_mstr_id, locator_addr_key)
	INNER JOIN 
	(
		SELECT DISTINCT b.locator_addr_key
		FROM mktg_ops_vws.cnst_cdi_phss_preferred_dmail a
		INNER JOIN eda.arc_mdm_vws.bzfc_cnst_addr b ON a.cnst_mstr_id = b.cnst_mstr_id
		WHERE b.assessmnt_ctg = 'Deliverable' AND b.dpv_cd = 'Y'
	) b (locator_addr_key) ON a.locator_addr_key = b.locator_addr_key
) ts_addr (cnst_mstr_id) ON mstr.cnst_mstr_id = ts_addr.cnst_mstr_id
/* The ts_prfr join returns master id list from the PHSS preferred profile */
LEFT JOIN 
(
	SELECT cnst_mstr_id 
	FROM mktg_ops_vws.cnst_cdi_smry_phss_prfr
) ts_prfr (cnst_mstr_id) ON mstr.cnst_mstr_id = ts_prfr.cnst_mstr_id
/* The where clause below limits the list to master id in the PHSS preferred profile or master ids that match on address or email address */
WHERE 
	ts_prfr.cnst_mstr_id IS NOT NULL
	OR ts_email.cnst_mstr_id IS NOT NULL
	OR ts_addr.cnst_mstr_id IS NOT NULL;
--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.suprsn_ts_cnst) as integer)
        WHERE proc_name = 'ld_suprsn_ts_cnst' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_suprsn_ts_cnst', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;


$$
