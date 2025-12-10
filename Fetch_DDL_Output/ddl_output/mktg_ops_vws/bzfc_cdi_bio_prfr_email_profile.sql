create or replace view mktg_ops_vws.bzfc_cdi_bio_prfr_email_profile as 

with bzl_dim_cntct_email as (
SELECT 
eml.cntct_email_key,
eml.contact_key,
eml.enroll_pref_loc_key,
category,
src_field_desc,
eplref.epl_field_name ,
cntct_email_strt_dt,

cntct_email_end_dt,
eml.created_ts,
eml.created_by,
eml.modified_ts,
eml.modified_by,
cntct_email_addr,
COALESCE(MIN( cntct_email_addr  ) OVER(PARTITION BY nk_contact_id, eml.enroll_pref_loc_key   ORDER BY  cntct_email_strt_dt                  
ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING),'na' ) AS bza_old_cntct_email_addr ,
cntct_email_inv_flg   ,
MIN(  cntct_email_inv_flg ) OVER(PARTITION BY nk_contact_id, eml.enroll_pref_loc_key   ORDER BY  cntct_email_strt_dt        
ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)  AS bza_old_cntct_email_inv_flg,

CASE WHEN 
(bza_old_cntct_email_inv_flg = 'N' AND cntct_email_inv_flg = 'Y') THEN 1
WHEN (bza_old_cntct_email_inv_flg IS NULL AND cntct_email_inv_flg = 'Y') THEN 1
ELSE 0
END  AS bzd_invalid_flag_applied,

CASE WHEN 
(bza_old_cntct_email_inv_flg = 'Y' AND cntct_email_inv_flg = 'N') THEN 1
WHEN (bza_old_cntct_email_inv_flg IS NULL AND cntct_email_inv_flg = 'N') THEN 1
ELSE 0
END  AS bzd_invalid_flag_removed,

/*CASE WHEN 
(bza_old_cntct_email_inv_flg IS NULL AND cntct_email_inv_flg = 'Y') THEN 1
WHEN (bza_old_cntct_email_inv_flg IS NULL AND cntct_email_inv_flg = 'N') THEN 1
ELSE 0
END (TITLE 'No Longer Null') AS bzd_no_longer_null, */

eml.nk_contact_id     ,
bzd_curr_ind       ,
l_cntct_ind ,
latest_w_cntct_id ,

eml.dw_trans_ts ,
eml.row_stat_cd,
eml.appl_src_cd,
eml.load_id 

FROM eda.drms_vws.bza_dim_cntct_email eml
JOIN eda.drms_vws.bz_dim_enrol_pref_loc_ref eplref
ON eplref.enroll_pref_loc_key = eml.enroll_pref_loc_key
)

select 
	prfr.email_addr, 
	case when (bncd_baddom_cnt) > 0 or
			 			 (bncd_hard_cnt) > 0 or
						 (bncd_notfnd_cnt) > 0 or
						 (tot_bncd_soft_cnt) > 3  or
						 (drms_em_opt_out_ind) = 1
			then 'N' else 'Y'
	end as ok_to_email_flg,
	bncd_baddom_cnt,
	bncd_hard_cnt,
	bncd_notfnd_cnt,
	bncd_soft_cnt,
	bncd_mbfull_cnt,
	COALESCE(drms_em_opt_out_ind,0) as drms_em_opt_out_ind
from 
(select distinct em_cnst_email
from mktg_ops_vws.cnst_cdi_smry_bio_prfr)  prfr(email_addr)
left join 
/* Get the Aprimo email bounced details and creates one record per email address */
                ( select b.cntct_email_addr, bncd_baddom_dt, bncd_hard_dt,bncd_soft_dt,bncd_mbfull_dt,bncd_notfnd_dt,
                			   bncd_baddom_cnt, bncd_hard_cnt, bncd_soft_cnt, bncd_mbfull_cnt, bncd_notfnd_cnt, bncd_soft_cnt +  bncd_mbfull_cnt as tot_bncd_soft_cnt,
                			   bncd_baddom_ind, bncd_hard_ind, bncd_soft_ind, bncd_mbfull_ind, bncd_notfnd_ind, bncd_any_ind
				from  eda.bio_campaign_vws.bz_fact_email_e2e a
				left join bzl_dim_cntct_email b on a.cntct_key = b.contact_key 
					and a.launch_dt between b.cntct_email_strt_dt and b.cntct_email_end_dt
					and b.epl_field_name = 'EMAIL_ADDR') bnc (email_addr, bncd_baddom_dt, bncd_hard_dt,bncd_soft_dt,bncd_mbfull_dt,bncd_notfnd_dt,
                			   bncd_baddom_cnt, bncd_hard_cnt, bncd_soft_cnt, bncd_mbfull_cnt, bncd_notfnd_cnt, tot_bncd_soft_cnt,
                			   bncd_baddom_ind, bncd_hard_ind, bncd_soft_ind, bncd_mbfull_ind, bncd_notfnd_ind, bncd_any_ind) on prfr.email_addr = bnc.email_addr
left join  
	(
	select  
	 b.cntct_email_addr,
	max(case when  (DN_CONTACT_IND = 1 or DN_EMAIL_IND = 1 or DN_RECRUIT_IND = 1 ) then 1 else 0 end) as drms_em_opt_out_ind
	from eda.bio_appointment_vws.bzf_dim_cntct_pref a
	left join bzl_dim_cntct_email b on a.contact_key = b.contact_key
	where  b.epl_field_name = 'EMAIL_ADDR' and bzd_curr_ind = 1
	group by 1
	) drms_opt_out (email_addr, drms_em_opt_out_ind) on drms_opt_out.email_addr = bnc.email_addr 
	

	with no schema binding;