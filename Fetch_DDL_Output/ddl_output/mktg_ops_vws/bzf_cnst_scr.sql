CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.bzf_cnst_scr 
AS
SELECT
orig_cnst_mstr_id AS orig_cnst_mstr_id,  
cnst_mstr_id AS cnst_mstr_id,  
pgcga_scrid,  
CAST(TRIM(pgcga_scrval) AS DECIMAL(7,3)) AS pgcga_scrval,  
pgcga_scrts,  
pgwg_scrid,
CAST(TRIM(pgwg_scrval) AS DECIMAL(7,3)) AS pgwg_scrval,
pgwg_scrts, 
maj1k_scrid, 
TRIM(maj1k_scrval) AS maj1k_scrval,  
maj1k_scrts,  
pgbeq_scrid,  
CAST(TRIM(pgbeq_scrval) AS DECIMAL(7,3)) AS pgbeq_scrval,  
pgbeq_scrts, 
dis1k_scrid,  
dis1k_scrval,  
dis1k_scrts,  
arc_loyalty_insight1_scrid, 
arc_loyalty_insight1_scrval,  
arc_loyalty_insight1_scrts,  
arc_loyalty_insight2_scrid, 
arc_loyalty_insight2_scrval,  
arc_loyalty_insight2_scrts,  
arc_conv_tag1_scrid, 
arc_conv_tag1_scrval,  
arc_conv_tag1_scrts,  
arc_conv_tag2_scrid, 
arc_conv_tag2_scrval,  
arc_conv_tag2_scrts,  
arc_lapsed_tag1_scrid, 
arc_lapsed_tag1_scrval,  
arc_lapsed_tag1_scrts,  
arc_lapsed_tag2_scrid, 
arc_lapsed_tag2_scrval,  
arc_lapsed_tag2_scrts,  
latest_scrid, 
latest_scrval,  
latest_scrts,  
latest_scr_cd,  
nhq_conv_tag1_scrid, 
nhq_conv_tag1_scrval,  
nhq_conv_tag1_scrts,  
nhq_conv_tag2_scrid, 
nhq_conv_tag2_scrval,  
nhq_conv_tag2_scrts,  
nhq_conv_tag3_scrid, 
nhq_conv_tag3_scrval,  
nhq_conv_tag3_scrts,  
nhq_conv_tag4_scrid, 
nhq_conv_tag4_scrval,  
nhq_conv_tag4_scrts,  
chpt_conv_tag1_scrid, 
chpt_conv_tag1_scrval,  
chpt_conv_tag1_scrts,  
chpt_conv_tag2_scrid, 
chpt_conv_tag2_scrval,  
chpt_conv_tag2_scrts,  
chpt_conv_tag3_scrid, 
chpt_conv_tag3_scrval,  
chpt_conv_tag3_scrts,  
chpt_conv_tag4_scrid, 
chpt_conv_tag4_scrval,  
chpt_conv_tag4_scrts,  
nhq_lapsed_tag1_scrid, 
nhq_lapsed_tag1_scrval,  
nhq_lapsed_tag1_scrts,  
nhq_lapsed_tag2_scrid, 
nhq_lapsed_tag2_scrval,  
nhq_lapsed_tag2_scrts,  
chpt_lapsed_tag1_scrid, 
chpt_lapsed_tag1_scrval,  
chpt_lapsed_tag1_scrts,  
chpt_lapsed_tag2_scrid, 
chpt_lapsed_tag2_scrval,  
chpt_lapsed_tag2_scrts,
tatm_scrid,
tatm_scrval,
tatm_scrts,
tasustnr_scrid,
tasustnr_scrval,
tasustnr_scrts,
am_tm_ind_scrid,
am_tm_ind_scrval,
am_tm_ind_scrts,
am_sust_ind_scrid,
am_sust_ind_scrval,
am_sust_ind_scrts,
am_insights_scrid,
am_insights_scrval,
am_insights_scrts,
lm_tm_ind_scrid,
lm_tm_ind_scrval,
lm_tm_ind_scrts,
lm_sust_ind_scrid,
lm_sust_ind_scrval,
lm_sust_ind_scrts,
lm_lapsed_tag_scrid,
lm_lapsed_tag_scrval,
lm_lapsed_tag_scrts,
im_lapsed_tag_scrid,
im_lapsed_tag_scrval,
im_lapsed_tag_scrts,
ad_tm_ind_scrid,
ad_tm_ind_scrval,
ad_tm_ind_scrts,
ad_conv_tag_scrid,
ad_conv_tag_scrval,
ad_conv_tag_scrts,
ad_insights_scrid,
ad_insights_scrval,
ad_insights_scrts,
ld_tm_ind_scrid,
ld_tm_ind_scrval,
ld_tm_ind_scrts,
ld_conv_tag_scrid,
ld_conv_tag_scrval,
ld_conv_tag_scrts,
id_conv_tag_scrid,
id_conv_tag_scrval,
id_conv_tag_scrts, 
am_web_ind_scrid, 
am_web_ind_scrval, 
am_web_ind_scrts, 
lm_web_ind_scrid, 
lm_web_ind_scrval, 
lm_web_ind_scrts, 
lm_lapsed_insights_scrid, 
lm_lapsed_insights_scrval, 
lm_lapsed_insights_scrts, 
im_lapsed_insights_scrid, 
im_lapsed_insights_scrval, 
im_lapsed_insights_scrts, 
ad_web_ind_scrid, 
ad_web_ind_scrval, 
ad_web_ind_scrts, 
ad_sus_ind_scrid, 
ad_sus_ind_scrval, 
ad_sus_ind_scrts, 
ld_web_ind_scrid, 
ld_web_ind_scrval, 
ld_web_ind_scrts, 
ld_sus_ind_scrid, 
ld_sus_ind_scrval, 
ld_sus_ind_scrts, 
ld_lapsed_insights_scrid, 
ld_lapsed_insights_scrval, 
ld_lapsed_insights_scrts, 
id_lapsed_insights_scrid, 
id_lapsed_insights_scrval, 
id_lapsed_insights_scrts, 
un_conv_tag_scrid, 
un_conv_tag_scrval, 
un_conv_tag_scrts, 
biomed_xpromo_scrid,
biomed_xpromo_scrval,
biomed_xpromo_scrts,
biomed_x_lob_conv_scrid,
biomed_x_lob_conv_scrval,
biomed_x_lob_conv_scrts,
bio2fr_conv_scrid, 
bio2fr_conv_scrval, 
bio2fr_conv_scrts, 
cap2500_non_fr_scrid, 
cap2500_non_fr_scrval, 
cap2500_non_fr_scrts, 
mods_bio2fr_lookalike_scrid, 
mods_bio2fr_lookalike_scrval, 
mods_bio2fr_lookalike_scrts, 
mods_phss2fr_lookalike_scrid, 
mods_phss2fr_lookalike_scrval, 
mods_phss2fr_lookalike_scrts, 
mods_vms2fr_lookalike_scrid, 
mods_vms2fr_lookalike_scrval, 
mods_vms2fr_lookalike_scrts,    
mods_conv_fr_dm_scrid,
mods_conv_fr_dm_scrval,
mods_conv_fr_dm_scrts,
mods_conv_fr_dm_ry_scrid,
mods_conv_fr_dm_ry_scrval,
mods_conv_fr_dm_ry_scrts,
mods_fr_em_scrid,
mods_fr_em_scrval,
mods_fr_em_scrts,
mods_conv_fr_em_scrid,
mods_conv_fr_em_scrval,
mods_conv_fr_em_scrts,      
mods_fr_lapsed_scrid,
mods_fr_lapsed_scrval,
mods_fr_lapsed_scrts,
mods_fr_dod_scrid,
mods_fr_dod_scrval,
mods_fr_dod_scrts,
dm_direct_mail_scrid, 
dm_direct_mail_scrval, 
dm_direct_mail_scrts, 
dm_donor_persona_scrid, 
dm_donor_persona_scrval, 
dm_donor_persona_scrts, 
dm_eoy_scrid, 
dm_eoy_scrval, 
dm_eoy_scrts, 
dm_gt_scrid, 
dm_gt_scrval, 
dm_gt_scrts, 
dm_phil_insights_scrid, 
dm_phil_insights_scrval, 
dm_phil_insights_scrts, 
dm_sustainer_scrid, 
dm_sustainer_scrval, 
dm_sustainer_scrts, 
dm_telemarketing_scrid, 
dm_telemarketing_scrval, 
dm_telemarketing_scrts, 
dm_web_scrid, 
dm_web_scrval, 
dm_web_scrts, 
dm_gift_array_scrid, 
dm_gift_array_scrval, 
dm_gift_array_scrts, 
mods_fr_cultiv_scrid, 
mods_fr_cultiv_scrval, 
mods_fr_cultiv_scrts, 
major_gift_capacity_scrid, 
major_gift_capacity_scrval, 
major_gift_capacity_scrts, 
p2p_diy_scrid, 
p2p_diy_scrval, 
p2p_diy_scrts, 
p2p_org_event_scrid, 
p2p_org_event_scrval, 
p2p_org_event_scrts, 
p2p_persona_scrid, 
p2p_persona_scrval, 
p2p_persona_scrts, 
bb_agecode_scrid,
bb_agecode_scrval,
bb_agecode_scrts, 
propnsty_1k_cumu_missn_scrid, 
propnsty_1k_cumu_missn_scrval, 
propnsty_1k_cumu_missn_scrts, 
propnsty_1k_cumu_distr_scrid, 
propnsty_1k_cumu_distr_scrval, 
propnsty_1k_cumu_distr_scrts, 
propnsty_distr_dntn_12mnths_scrid, 
propnsty_distr_dntn_12mnths_scrval, 
propnsty_distr_dntn_12mnths_scrts, 
propnsty_distr_dnr_to_missn_dnr_scrid, 
propnsty_distr_dnr_to_missn_dnr_scrval, 
propnsty_distr_dnr_to_missn_dnr_scrts,                
sustainer_acquisition_scrid, 
sustainer_acquisition_scrval, 
sustainer_acquisition_scrts, 
sustainer_lapsed_scrid, 
sustainer_lapsed_scrval, 
sustainer_lapsed_scrts, 
propnsty_75_999_scrid,
propnsty_75_999_scrval,
propnsty_75_999_scrts,
grey_to_blue_sky_conv_scrid,
grey_to_blue_sky_conv_scrval,
grey_to_blue_sky_conv_scrts,
sustnr_churn_propnsty_nxt_3_mnths_scrid,
sustnr_churn_propnsty_nxt_3_mnths_scrval,
sustnr_churn_propnsty_nxt_3_mnths_scrts,
bsd_cd, 
tm_scrval, 
sus_scrval, 
insights_scrval, 
web_scrval, 
conv_tag_scrval      
FROM mods_bi.mktg_data_tbls.bzf_cnst_scr
with no schema binding;