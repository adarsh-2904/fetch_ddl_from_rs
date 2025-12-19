CREATE OR REPLACE VIEW mktg_ops_vws.bzf_cem_cnst_msg_pref
/* ---------------------------------------------------------------------------------------------------------------------------
Created By: Michael Andrien
Created On: 04/13/2017
Purpose:This view selects all the columns from bzf_cnst_msg_pref table  NOTE: This view is a copy of
				the cmm_vws view definition.  The MODS team is creating these views in mktg_ops_vws to expose the views to the Adobe schema.
Filters: row_stat_cd <> 'L'
------------------------------------------------------------------------------------------------------------------------------------ */

AS
SELECT
    cnst_mstr_id,
    cnst_typ_cd,
    bzd_all_phone_all_no_ind,
    bzd_fr_all_ackn_no_ind,
    bzd_fr_all_ackncustom_yes_ind,
    bzd_fr_all_acknsumm_yes_ind,
    bzd_fr_all_appeal_no_ind,
    bzd_fr_all_disaster_yes_ind,
    bzd_fr_all_newsletter_no_ind,
    bzd_fr_all_newsletter_yes_ind,
    bzd_fr_email_all_no_ind,
    bzd_fr_mail_all_no_ind,
    bzd_fr_mail_appeal_no_ind,
    bzd_fr_mail_appeal1_yes_ind,
    bzd_fr_mail_appeal2_yes_ind,
    bzd_fr_mail_appeal4_yes_ind ,
    bzd_fr_mail_premium_no_ind,
    bzd_fr_phone_all_no_ind,
    bzd_frgp_all_all_no_ind,
    bzd_frgp_all_appeal_yes_ind,
    bzd_frgp_all_cgarenewal_no_ind,
    bzd_frgp_all_steward_yes_ind,
    bzd_frgp_all_survey_no_ind
FROM eda.arc_cmm_vws.bzf_cnst_msg_pref
with no schema binding;