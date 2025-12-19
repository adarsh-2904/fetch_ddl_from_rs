CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dv_channel_accessibility()
 LANGUAGE plpgsql
AS $$
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_dv_channel_accessibility', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN
		-- Check if today is Saturday (dow = 6)
        IF EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN
			
			DELETE FROM  mktg_ops_tbls.dv_channel_accessibility_stg;
			insert into  mktg_ops_tbls.dv_channel_accessibility_stg
				select
						a.cnst_mstr_id,
						case when fr.do_not_phone_ind+ bio.do_not_phone_ind+ phss.do_not_phone_ind+ vms.do_not_phone_ind >= 1 then 1 else 0 end as do_not_phone_ind,
						case when fr.do_not_email_ind+ bio.do_not_email_ind+ phss.do_not_email_ind+ vms.do_not_email_ind >= 1 then 1 else 0 end as do_not_email_ind,
						case when fr.do_not_mail_ind+ bio.do_not_mail_ind+ phss.do_not_mail_ind+ vms.do_not_mail_ind >= 1 then 1 else 0 end as do_not_mail_ind,
						case when fr.do_not_txt_ind+ bio.do_not_txt_ind+ phss.do_not_txt_ind+ vms.do_not_txt_ind >= 1 then 1 else 0 end as do_not_txt_ind,
						case when frem.ok_to_email_flg = 'N' or  frem.ok_to_email_flg is null then 'N'
									when frem.ok_to_email_flg = 'Y' then 'Y' 
									else 'N' end as fr_ok_to_email_flg, 
						case when phssem.ok_to_email_flg = 'N' or phssem.ok_to_email_flg is null then 'N'
									when phssem.ok_to_email_flg = 'Y' then 'Y' 
									else 'N' end as phss_ok_to_email_flg 
					from 
					(
						select 
							cnst_mstr_id
						from eda.arc_mdm_vws.bzfc_arc_best_smry
					) a (cnst_mstr_id)
					left join /* Get FR channel DNCs */
					(
						select 
							cnst_mstr_id,
							case when do_not_call_hm_phn_ind+ do_not_call_mbl_phn_ind+do_not_call_work_phn_ind >= 1 then 1 else 0 end as do_not_phone_ind,
							do_not_email_ind, 
							do_not_mail_ind, 
							do_not_txt_ind
						from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr  
					) fr (cnst_mstr_id, do_not_phone_ind,do_not_email_ind, do_not_mail_ind, do_not_txt_ind)  on a.cnst_mstr_id = fr.cnst_mstr_id
					left join /* Get BIO channel DNCs */
					(
						select 
							cnst_mstr_id,
							case when do_not_call_hm_phn_ind+ do_not_call_mbl_phn_ind+do_not_call_work_phn_ind >= 1 then 1 else 0 end as do_not_phone_ind,
							do_not_email_ind, 
							do_not_mail_ind, 
							do_not_txt_ind
						from mktg_ops_tbls.cnst_cdi_smry_bio_prfr
					) bio (cnst_mstr_id, do_not_phone_ind,do_not_email_ind, do_not_mail_ind, do_not_txt_ind)  on a.cnst_mstr_id = bio.cnst_mstr_id
					
					left join  /* Get PHSS channel DNCs */
					(
						select 
							cnst_mstr_id,
							case when phss_do_not_call_hm_phn_ind+ phss_do_not_call_mbl_phn_ind+phss_do_not_call_work_phn_ind >= 1 then 1 else 0 end as do_not_phone_ind,
							phss_do_not_email_ind, 
							phss_do_not_mail_ind, 
							phss_do_not_txt_ind
						from mktg_ops_vws.cnst_cdi_smry_phss_prfr
					) phss (cnst_mstr_id, do_not_phone_ind,do_not_email_ind, do_not_mail_ind, do_not_txt_ind)  on a.cnst_mstr_id = phss.cnst_mstr_id
				
					left join  /* Get VMS channel DNCs */ 
					(
						select 
							cnst_mstr_id,
							case when do_not_call_hm_phn_ind+ do_not_call_mbl_phn_ind+do_not_call_work_phn_ind >= 1 then 1 else 0 end as do_not_phone_ind,
							do_not_email_ind, 
							do_not_mail_ind, 
							do_not_txt_ind
						from mktg_ops_vws.cnst_cdi_smry_vms_prfr
					) vms (cnst_mstr_id, do_not_phone_ind,do_not_email_ind, do_not_mail_ind, do_not_txt_ind)  on a.cnst_mstr_id =  vms.cnst_mstr_id
					left join /* Get FR ok_to_email_flg */
					(
						select 
							cnst_mstr_id,
							email_addr,
							ok_to_email_flg
						from mktg_ops_vws.gms_bzfc_cnst_cdi_fr_prfr_em_prfl
					) frem (cnst_mstr_id,email_addr, ok_to_email_flg) on a.cnst_mstr_id = frem.cnst_mstr_id
						
					left join /* Get PHSS ok_to_email_flg */
					(
						select 
							cnst_mstr_id,
							email_addr,
							ok_to_email_flg
						from mktg_ops_vws.bzfc_cnst_cdi_phss_email_prfl
					) phssem (cnst_mstr_id, email_addr, ok_to_email_flg) on a.cnst_mstr_id = phssem.cnst_mstr_id;


				DELETE FROM mktg_ops_tbls.dv_channel_accessibility;
				INSERT INTO mktg_ops_tbls.dv_channel_accessibility
				with bzl_dim_cnst_unf as 
				(
				select ct.cnst_mstr_id as bz_cnst_mstr_id, ct.contact_key as dr_contact_key from eda.bio_donation_vws.bz_dim_donor  dn
				inner join eda.bio_appointment_vws.bzl_dim_contact ct on dn.donor_external_id = ct.nk_key_donor
				),
				
				bzfc_cnst_email as (
				select distinct cnst_mstr_id, assessmnt_ctg,cnst_email_addr,arc_srcsys_cd from eda.arc_mdm_vws.bzfc_cnst_email
				)
				
				
				select 
					case when f.state_dsc is null then 'Unknown State'
							  else f.state_dsc
					end as cnst_arc_best_state,
					case when a.cnst_gender = 'M' then 'Male'
							  when a.cnst_gender = 'F' then 'Female'
							  else 'Unknown Gender'
					end as cnst_arc_best_gender,
					case when b.bzd_derived_age between 18 and 25 then '18-25'
							  when  b.bzd_derived_age between 26 and 35 then '26-35'
							  when  b.bzd_derived_age between 36 and 45 then '36-45'
							  when  b.bzd_derived_age between 46 and 55 then '46-55'
							  when  b.bzd_derived_age > 55 then '>55'
							  else 'Unknown Age'
					end as cnst_age_band,
					 COALESCE(c.assessmnt_ctg, 'Unknown email') AS email_assessmnt_ctg, 
					COALESCE(d.assessmnt_ctg, 'Unknown Address') AS addr_assessmnt_ctg, 
					COALESCE(e.assessmnt_ctg, 'Unknown Phone') AS phone_assessmnt_ctg, 
					COALESCE(a.lst_arc_patrng_los, 'Unknown Patronage') AS last_patrng_los,
					COALESCE(extract (year from a.lst_arc_patrng_dt),0) as last_arc_patrng_yr,
					COALESCE(extract (year from a.lst_bio_dntn_dt),0) as last_bio_patrng_yr,
					COALESCE(extract (year from a.lst_fr_dntn_dt),0) as last_fr_patrng_yr,
					COALESCE(extract (year from a.lst_phss_cours_cmpltn_dt),0) as last_phss_patrng_yr,
					COALESCE(extract (year from a.lst_volntrng_dt),0) as last_volntr_patrng_yr,
				
				/* 01/18/2017: Majeed: Added the patronage life stage for the different LOBs */	
					case
				when a.lst_arc_patrng_dt is null then 'No Patronage'
				when a.lst_arc_patrng_dt <= '01/01/1900' then 'Invalid Patronage'
				when a.lst_arc_patrng_dt between CURRENT_DATE -  interval '2' year  and CURRENT_DATE then 'Active'
				when a.lst_arc_patrng_dt between CURRENT_DATE -  interval '4' year  and CURRENT_DATE - interval '2' year  then 'Inactive'
				when a.lst_arc_patrng_dt between CURRENT_DATE -  interval '10' year  and  CURRENT_DATE - interval '4' year  then 'Lapsed'
				when a.lst_arc_patrng_dt <= CURRENT_DATE - interval '10' year  then 'Super Lapsed'
				else 'Invalid Patronage'
				end as arc_patrng_life_stg , 
					case
				when a.lst_bio_dntn_dt is null then 'No Patronage'
				when a.lst_bio_dntn_dt <= '01/01/1900' then 'Invalid Patronage'
				when a.lst_bio_dntn_dt between CURRENT_DATE -  interval '2' year  and CURRENT_DATE then 'Active'
				when a.lst_bio_dntn_dt between CURRENT_DATE -  interval '4' year  and CURRENT_DATE - interval '2' year  then 'Inactive'
				when a.lst_bio_dntn_dt between CURRENT_DATE -  interval '10' year  and  CURRENT_DATE - interval '4' year  then 'Lapsed'
				when a.lst_bio_dntn_dt <= CURRENT_DATE - interval '10' year  then 'Super Lapsed'
				else 'Invalid Patronage'
				end as bio_patrng_life_stg , 
					case
				when a.lst_fr_dntn_dt is null then 'No Patronage'
				when a.lst_fr_dntn_dt <= '01/01/1900' then 'Invalid Patronage'
				when a.lst_fr_dntn_dt between CURRENT_DATE -  interval '2' year  and CURRENT_DATE then 'Active'
				when a.lst_fr_dntn_dt between CURRENT_DATE -  interval '4' year  and CURRENT_DATE - interval '2' year  then 'Inactive'
				when a.lst_fr_dntn_dt between CURRENT_DATE -  interval '10' year  and  CURRENT_DATE - interval '4' year  then 'Lapsed'
				when a.lst_fr_dntn_dt <= CURRENT_DATE - interval '10' year  then 'Super Lapsed'
				else 'Invalid Patronage'
				end as fr_patrng_life_stg , 
					case
				when a.lst_phss_cours_cmpltn_dt is null then 'No Patronage'
				when a.lst_phss_cours_cmpltn_dt <= '01/01/1900' then 'Invalid Patronage'
				when a.lst_phss_cours_cmpltn_dt between CURRENT_DATE -  interval '2' year  and CURRENT_DATE then 'Active'
				when a.lst_phss_cours_cmpltn_dt between CURRENT_DATE -  interval '4' year  and CURRENT_DATE - interval '2' year  then 'Inactive'
				when a.lst_phss_cours_cmpltn_dt between CURRENT_DATE -  interval '10' year  and  CURRENT_DATE - interval '4' year  then 'Lapsed'
				when a.lst_phss_cours_cmpltn_dt <= CURRENT_DATE - interval '10' year  then 'Super Lapsed'
				else 'Invalid Patronage'
				end as phss_patrng_life_stg , 
					case
				when a.lst_volntrng_dt is null then 'No Patronage'
				when a.lst_volntrng_dt <= '01/01/1900' then 'Invalid Patronage'
				when a.lst_volntrng_dt between CURRENT_DATE -  interval '2' year  and CURRENT_DATE then 'Active'
				when a.lst_volntrng_dt between CURRENT_DATE -  interval '4' year  and CURRENT_DATE - interval '2' year  then 'Inactive'
				when a.lst_volntrng_dt between CURRENT_DATE -  interval '10' year  and  CURRENT_DATE - interval '4' year  then 'Lapsed'
				when a.lst_volntrng_dt <= CURRENT_DATE - interval '10' year  then 'Super Lapsed'
				else 'Invalid Patronage'
				end as vol_patrng_life_stg , 
				
					case when lst_bio_dntn_dt is not null then 1 else 0 end as bio_patrng_ind,
					case when lst_fr_dntn_dt is not null then 1 else 0 end as fr_patrng_ind,
					case when lst_phss_cours_cmpltn_dt is not null then 1 else 0 end as phss_patrng_ind,
					case when lst_volntrng_dt is not null then 1 else 0 end as volntr_patrng_ind,	
					case when lst_bio_dntn_dt is null and lst_fr_dntn_dt is null and lst_phss_cours_cmpltn_dt is null and lst_volntrng_dt is  null
							  then 1 else 0
					end as no_patrng_ind,
					case when ( CURRENT_DATE - interval '2' year ) <= lst_bio_dntn_dt then 1 else 0 end as active_bio_patrng_ind,
					case when (CURRENT_DATE - interval '2' year) <= lst_fr_dntn_dt then 1 else 0 end as active_fr_patrng_ind,
					case when (CURRENT_DATE - interval '2' year) <= lst_phss_cours_cmpltn_dt then 1 else 0 end as active_phss_patrng_ind,
					case when (CURRENT_DATE - interval '2' year) <= lst_volntrng_dt then 1 else 0 end as active_volntr_patrng_ind,
					( (case when lst_bio_dntn_dt is not null then 1 else 0 end) +
					  (case when lst_fr_dntn_dt is not null then 1 else 0 end) +
					  (case when lst_phss_cours_cmpltn_dt is not null then 1 else 0 end) +
					  (case when lst_volntrng_dt is not null then 1 else 0 end)
					) as patrng_cnt,
					(
						(case when (CURRENT_DATE - interval '2' year) <= lst_bio_dntn_dt then 1 else 0 end) +
						(case when (CURRENT_DATE - interval '2' year) <= lst_fr_dntn_dt then 1 else 0 end) +
						(case when (CURRENT_DATE - interval '2' year) <= lst_phss_cours_cmpltn_dt then 1 else 0 end) + 
						(case when (CURRENT_DATE - interval '2' year) <= lst_volntrng_dt then 1 else 0 end) 
					) as active_patrng_cnt,
				--	income.var_val_dsc as income_val_dsc, 
				--	cast(income.var_val_cd as integer) as income_val_cd, 
					case when cnst_dsp_id is not null then 1 else 0 end as ln_verfd_ind,
					coalesce(app_flg.bz_app_chan_accessible_flg, 'N') as bz_app_chan_accessible_flg, 
					COALESCE(app_flg.bz_app_chan_accessible_ind,0) as bz_app_chan_accessible_ind,  
				--	case when ema.assessmnt_email_ext_strt_ts is not null then 'Y' else 'N' end as ext_email_valid_flg,
					'Y' as ext_email_valid_flg,
				--	case when ema.assessmnt_email_ext_strt_ts between (current_date - interval '1' year) and current_date  then 'Y' else 'N' end as  ext_email_last_yr_valid_flg,
					'Y' as ext_email_last_yr_valid_flg,
					case when COALESCE(i.region_key,0) = 0 then 'N' else 'Y' end as in_blood_region_flg,
					dnc.do_not_phone_ind,
					dnc.do_not_email_ind,
					dnc.do_not_mail_ind,
					dnc.do_not_txt_ind,
					dnc.fr_ok_to_email_flg,
					dnc.phss_ok_to_email_flg,
					a.cnst_mstr_id
				from eda.arc_mdm_vws.bzfc_arc_best_smry a
				left join mktg_ops_tbls.bz_cnst_birth_best b on a.cnst_mstr_id = b.cnst_mstr_id
				left join bzfc_cnst_email c  on  a.cnst_mstr_id = c.cnst_mstr_id and a.cnst_email_addr = c.cnst_email_addr and a.email_arc_srcsys_cd = c.arc_srcsys_cd
				left join 
							(select distinct cnst_mstr_id, assessmnt_ctg,locator_addr_key,arc_srcsys_cd from eda.arc_mdm_vws.bzfc_cnst_addr) 
					d (cnst_mstr_id, assessmnt_ctg,locator_addr_key,arc_srcsys_cd) on  a.cnst_mstr_id = d.cnst_mstr_id and a.locator_addr_key = d.locator_addr_key and a.addr_arc_srcsys_cd = d.arc_srcsys_cd
				left join 
							(select distinct cnst_mstr_id, assessmnt_ctg,locator_phn_key,arc_srcsys_cd from eda.arc_mdm_vws.bzfc_cnst_phn) 
					e (cnst_mstr_id, assessmnt_ctg,locator_phn_key,arc_srcsys_cd) on  a.cnst_mstr_id = e.cnst_mstr_id and a.locator_phn_key = e.locator_phn_key and a.addr_arc_srcsys_cd = e.arc_srcsys_cd
				left join eda.dw_common_vws.dim_state f on a.cnst_addr_state = f.state_cd
				left join eda.arc_mdm_vws.bzf_cnst_chrctrstc g on g.cnst_mstr_id = a.cnst_mstr_id
				--left join (select distinct var_val_dsc, var_val_cd
				--from mktg_ops_vws.arc_glossary 
				--where var_nm = 'bzd_income') income on income.var_val_cd = g.bzd_income
				left outer join (select a.cnst_mstr_id, 'Y' as bz_app_chan_accessible_flg,  1   as bz_app_chan_accessible_ind
				 										from eda.arc_mdm_vws.bzfc_arc_best_smry a 
				 										inner  join bzl_dim_cnst_unf b on 
				 										a.cnst_mstr_id=b.bz_cnst_mstr_id 
				 										inner join eda.drms_vws.bz_dim_donor_mktg c on b.dr_contact_key = c.contact_key 
				 										where attribute_1_flg='Y' /* 09/21/2017: Majeed: Added this filter to minimize the records returned by this subquery. The filter limits the records to about 700k. Without this filter, about 270Millions records were being returned */
				 										group by 1  /* 09/21/2017: Majeed: Added the group by to return one record per cnst_mstr_id. Group by works faster than distinct */
				 										)  app_flg on a.cnst_mstr_id = app_flg.cnst_mstr_id
				
				/* The Next join pulls in the email assessment details to determine whether the consituent email has been validated by StrikeIron and when */
				--left join eda.arc_mdm_vws.bz_assessmnt_email_ext ema on  a.locator_email_key = ema.email_key
				left join eda.dw_common_vws.dim_zipcodes h on a.cnst_addr_zip_5 = h.ZIP
				left join eda.dw_common_vws.dim_region i on h.Region_Code = i. nk_region_id
				left join mktg_ops_tbls.dv_channel_accessibility_stg dnc on a.cnst_mstr_id = dnc.cnst_mstr_id
				 
				where (cnst_deceased_cd <> 'D' or cnst_deceased_cd is null)   ;

				 v_end_time := GETDATE();
				v_ok_message = 'Records inserted.';
		        
		        UPDATE mods_bi.mktg_ops_tbls.audit_log
		        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.dv_channel_accessibility) as INTEGER)
		        WHERE proc_name = 'ld_dv_channel_accessibility' 
		        AND task_name = 'Stored Procedure' 
		        AND start_time = v_start_time;

     
     ELSE 
        v_end_time := GETDATE();
		v_ok_message = 'Procedure skipped: Today is not Saturday.';
        
        UPDATE mods_bi.mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.dv_channel_accessibility) as INTEGER)
        WHERE proc_name = 'ld_dv_channel_accessibility' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;
	
	END IF;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_dv_channel_accessibility: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO mods_bi.mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_dv_channel_accessibility', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
