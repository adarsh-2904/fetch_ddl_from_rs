CREATE OR REPLACE VIEW mktg_ops_vws.bzf_cem_cnst_msg_pref AS
SELECT
    cnst_mstr_id AS "Constituent Master Identifier",
    cnst_typ_cd AS "Constituent Type Code",
    bzd_all_phone_all_no_ind AS "All LOS - Phone - All Preference Type - No Indicator",
    bzd_fr_all_ackn_no_ind AS "FR - All Channel - Ackn - No Indicator",
    bzd_fr_all_ackncustom_yes_ind AS "FR - All Channels - AcknCustom - Yes Indicator",
    bzd_fr_all_acknsumm_yes_ind AS "FR - All Channels - AcknSumm - Yes Indicator",
    bzd_fr_all_appeal_no_ind AS "FR - All Channels - Appeal - No Indicator",
    bzd_fr_all_disaster_yes_ind AS "FR - All Channels - Disaster - Yes Indicator",
    bzd_fr_all_newsletter_no_ind AS "FR - All Channels - Newsletter - No Indicator",
    bzd_fr_all_newsletter_yes_ind AS "FR - All Channels - Newsletter - Yes Indicator",
    bzd_fr_email_all_no_ind AS "FR - Email - All Preference Type - No Indicator",
    bzd_fr_mail_all_no_ind AS "FR - Mail - All Preference Type - No Indicator",
    bzd_fr_mail_appeal_no_ind AS "FR - Mail - Appeal - No Indicator",
    bzd_fr_mail_appeal1_yes_ind AS "FR - Mail - Appeal 1 - Yes Indicator",
    bzd_fr_mail_appeal2_yes_ind AS "FR - Mail - Appeal 2 - Yes Indicator",
    bzd_fr_mail_appeal4_yes_ind AS "FR - Mail - Appeal 4 - Yes Indicator",
    bzd_fr_mail_premium_no_ind AS "FR - Mail - Premium - No Indicator",
    bzd_fr_phone_all_no_ind AS "FR - Phone - All Preference Type - No Indicator",
    bzd_frgp_all_all_no_ind AS "FRGP - All Channels - All Preference Type - No Indicator",
    bzd_frgp_all_appeal_yes_ind AS "FRGP - All Channels - Appeal - Yes Indicator",
    bzd_frgp_all_cgarenewal_no_ind AS "FRGP - All Channels - GCA Renewal - No Indicator",
    bzd_frgp_all_steward_yes_ind AS "FRGP - All Channels - Steward - Yes Indicator",
    bzd_frgp_all_survey_no_ind AS "FRGP - All Channels - Survey - No Indicator"
FROM eda.arc_cmm_vws.bzf_cnst_msg_pref
WHERE row_stat_cd <> 'L' with no schema binding;