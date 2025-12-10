CREATE OR REPLACE VIEW mktg_ops_vws.bzf_cem_cnst_opt_outs 
 AS
/*  
Create Date: 04/13/2017
Created By: Michael Andrien
Purpose: Created to establish a simple view for defining and tracking the 'Do Not Contact' indicators in the Mktg LOB preferred profiles. This view will be exposed to 
the Adobe schema and is referenced by 3 of the 4 LOB preferred profile views to set the do not contact by channel indicators. The view references the new
CEM (Constituent Engagement Management) constituent message preference and constituent DNC views delivered in Stuart Release 17 and made available in the arc_cmm_vws database.
This view is also referenced in the LOB email profile views in which the 'Ok to Email Flag' is managed to simplify email communications/suppressions through our 
Marketing Automation tool (Adobe Campaign at the time this view was created)
Modified By: Michael Andrien
Modified Date: 8/23/2017
Purpose: Added VMS attributes
Modified By: Michael Andrien
Modified Date: 09/01/2024
Purpose: Changed the join to a FULL OUTER JOIN because we discovered master id rows in the DNC view that were not in the Pref view. Also added the COALESCE on the master id
to ensure the view contains a valid master id for all rows.
*/

SELECT 
    COALESCE(a.cnst_mstr_id, b.cnst_mstr_id) AS cnst_mstr_id,
    -- Set FR Do Not Contact Indicators
    COALESCE(CASE WHEN a.bzd_fr_all_appeal_no_ind = 1 OR a.bzd_fr_mail_appeal_no_ind = 1 OR a.bzd_fr_mail_all_no_ind = 1 OR 
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_mail_ind = 1 OR b.bzd_dnc_fr_all_ind = 1 OR b.bzd_dnc_fr_mail_ind = 1 THEN 1 ELSE 0 END, 0) AS fr_do_not_mail_ind,
    COALESCE(CASE WHEN a.bzd_fr_all_appeal_no_ind = 1 OR a.bzd_fr_email_all_no_ind = 1 OR 
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_email_ind = 1 OR b.bzd_dnc_fr_all_ind = 1 OR b.bzd_dnc_fr_email_ind = 1 THEN 1 ELSE 0 END, 0) AS fr_do_not_email_ind,
    COALESCE(CASE WHEN a.bzd_fr_all_appeal_no_ind = 1 OR a.bzd_all_phone_all_no_ind = 1 OR a.bzd_fr_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_fr_all_ind = 1 OR b.bzd_dnc_fr_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS fr_do_not_call_hm_phn_ind,
    COALESCE(CASE WHEN a.bzd_fr_all_appeal_no_ind = 1 OR a.bzd_all_phone_all_no_ind = 1 OR a.bzd_fr_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_fr_all_ind = 1 OR b.bzd_dnc_fr_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS fr_do_not_call_mbl_phn_ind,
    COALESCE(CASE WHEN a.bzd_fr_all_appeal_no_ind = 1 OR a.bzd_all_phone_all_no_ind = 1 OR a.bzd_fr_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_fr_all_ind = 1 OR b.bzd_dnc_fr_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS fr_do_not_call_work_phn_ind,
    COALESCE(CASE WHEN a.bzd_fr_all_appeal_no_ind = 1 OR 
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_text_ind = 1 OR b.bzd_dnc_fr_all_ind = 1 OR b.bzd_dnc_fr_text_ind = 1 THEN 1 ELSE 0 END, 0) AS fr_do_not_txt_ind,
    -- Set Bio Do Not Contact Indicators
    COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_mail_ind = 1 OR b.bzd_dnc_bio_all_ind = 1 OR b.bzd_dnc_bio_mail_ind = 1 THEN 1 ELSE 0 END, 0) AS bio_do_not_mail_ind,
    COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_email_ind = 1 OR b.bzd_dnc_bio_all_ind = 1 OR b.bzd_dnc_bio_email_ind = 1 THEN 1 ELSE 0 END, 0) AS bio_do_not_email_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_bio_all_ind = 1 OR b.bzd_dnc_bio_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS bio_do_not_call_hm_phn_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_bio_all_ind = 1 OR b.bzd_dnc_bio_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS bio_do_not_call_mbl_phn_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_bio_all_ind = 1 OR b.bzd_dnc_bio_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS bio_do_not_call_work_phn_ind,
    COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_text_ind = 1 OR b.bzd_dnc_bio_all_ind = 1 OR b.bzd_dnc_bio_text_ind = 1 THEN 1 ELSE 0 END, 0) AS bio_do_not_txt_ind,
    -- Set PHSS Do Not Contact Indicators
    COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_mail_ind = 1 OR b.bzd_dnc_phss_all_ind = 1 OR b.bzd_dnc_phss_mail_ind = 1 THEN 1 ELSE 0 END, 0) AS phss_do_not_mail_ind,
    COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_email_ind = 1 OR b.bzd_dnc_phss_all_ind = 1 OR b.bzd_dnc_phss_email_ind = 1 THEN 1 ELSE 0 END, 0) AS phss_do_not_email_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_phss_all_ind = 1 OR b.bzd_dnc_phss_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS phss_do_not_call_hm_phn_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_phss_all_ind = 1 OR b.bzd_dnc_phss_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS phss_do_not_call_mbl_phn_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR
                        b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 OR b.bzd_dnc_phss_all_ind = 1 OR b.bzd_dnc_phss_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS phss_do_not_call_work_phn_ind,
    COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_text_ind = 1 OR b.bzd_dnc_phss_all_ind = 1 OR b.bzd_dnc_phss_text_ind = 1 THEN 1 ELSE 0 END, 0) AS phss_do_not_txt_ind,
    -- Set VMS Do Not Contact Indicators
	COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_mail_ind = 1 THEN 1 ELSE 0 END, 0) AS vms_do_not_mail_ind,
    COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_email_ind = 1 THEN 1 ELSE 0 END, 0) AS vms_do_not_email_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS vms_do_not_call_hm_phn_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS vms_do_not_call_mbl_phn_ind,
    COALESCE(CASE WHEN a.bzd_all_phone_all_no_ind = 1 OR b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_phone_ind = 1 THEN 1 ELSE 0 END, 0) AS vms_do_not_call_work_phn_ind,
    COALESCE(CASE WHEN b.bzd_dnc_all_all_ind = 1 OR b.bzd_dnc_all_text_ind = 1 THEN 1 ELSE 0 END, 0) AS vms_do_not_txt_ind
FROM eda.arc_cmm_vws.bzf_cnst_msg_pref a
FULL OUTER JOIN eda.arc_cmm_vws.bzf_cnst_dnc b ON a.cnst_mstr_id = b.cnst_mstr_id
WITH NO SCHEMA BINDING;