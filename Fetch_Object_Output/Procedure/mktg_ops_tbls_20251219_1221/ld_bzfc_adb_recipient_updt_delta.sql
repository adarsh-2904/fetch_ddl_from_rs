CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_adb_recipient_updt_delta()
 LANGUAGE plpgsql
AS $$
	/*
Created By: Michael Andrien
Create Date: 	11/29/2021
Purpose: Converted the mktg_ops_vws.bzfc_adb_recipient_updt_delta details into a macro, which loads a physical table and
redesigned the view to reference the table.  This was done for performance reasons.  The original view was running too long and 
encountering spool issues when referenced by the Adobe Campaign workflow to update the Adobe Recipient data.
The revised view logic was redesigned on 11/24/2021 by removing the UNIONs and replacing them with joins
that rebuild the recipient record based on the current values in the LOB preferred profiles.  The new values 
are compared to the existing recipient values and the records that don't match are returned in the view.
Documented in MODS Teamwork task # 8078664.

Modified By: Michael Andrien
Modified Date: 05/10/2022
Purpose:	Updated the Where clause to include recipients in the view when the recipient attribute value is null and the preferred profile attribute is not null.  Teamwork ticket #8674526 - https://arcmarketingcommunications.teamwork.com/desk/tickets/8674526

Modified By: Michael Andrien
Modified Date: 11/19/2022
Purpose:	Renamec cnst_cdi_phss_smry_prfr to cnst_cdi_smry_phss_prfr
*/
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_adb_recipient_updt_delta', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
			truncate table mktg_stage_tbls.bzfc_adb_recipient_updt_delta_stg;
			
			insert into mktg_stage_tbls.bzfc_adb_recipient_updt_delta_stg
			(
			igender,
			irecipientid,
			saddress1,
			saddress2,
			scity,
			semail,
			sfirstname,
			slastname,
			smiddlename,
			smobilephone,
			sorigin,
			sphone,
			ssalutation,
			sstatecode,
			szipcode,
			tsbirth,
			tslastmodified,
			tscreated,
			bicnst_mstr_id,
			birecipientid,
			dlastdonationamt,
			ifr_field_unit_dimension_id,
			fr_field_chapter_cd,
			fr_field_region_cd,
			ifr_mkt_field_unit_dimension_id,
			fr_mkt_chapter_cd,
			fr_mkt_region_cd,
			iisbio,
			iisfr,
			iisphss,
			iisvms,
			saddress1_bio,
			saddress1_fr,
			saddress1_phss,
			saddress1_vms,
			saddress2_bio,
			saddress2_fr,
			saddress2_phss,
			saddress2_vms,
			sbio_em_email,
			scity_bio,
			scity_fr,
			scity_phss,
			scity_vms,
			sfraddrquality,
			sfr_em_email,
			sbioaddrquality,
			scompany,
			smobilephone_bio,
			smobilephone_fr,
			smobilephone_phss,
			smobilephone_vms,
			sphone_bio,
			sphone_fr,
			sphone_phss,
			sphone_vms,
			sphssaddrquality,
			sphss_em_email,
			sstatecode_bio,
			sstatecode_fr,
			sstatecode_phss,
			sstatecode_vms,
			svmsaddrquality,
			svms_em_email,
			szipcode_bio,
			szipcode_fr,
			szipcode_phss,
			szipcode_vms,
			bidm_namelocatorkey,
			biem_namelocatorkey,
			biemaillocatorkey,
			biaddrlocatorkey,
			biprimphonelocatorkey,
			bimblphonelocatorkey,
			sdm_firstname_fr,
			sdm_middlename_fr,
			sdm_lastname_fr,
			sdm_firstname_bio,
			sdm_middlename_bio,
			sdm_lastname_bio,
			sdm_firstname_phss,
			sdm_middlename_phss,
			sdm_lastname_phss,
			sdm_firstname_vms,
			sdm_middlename_vms,
			sdm_lastname_vms,
			sem_firstname_fr,
			sem_middlename_fr,
			sem_lastname_fr,
			sem_firstname_bio,
			sem_middlename_bio,
			sem_lastname_bio,
			sem_firstname_phss,
			sem_middlename_phss,
			sem_lastname_phss,
			sem_firstname_vms,
			sem_middlename_vms,
			sem_lastname_vms,
			semailquality_fr,
			semailquality_bio,
			semailquality_phss,
			semailquality_vms,
			saddress4_fr,
			saddress4_bio,
			saddress4_phss,
			saddress4_vms,
			tslastdonation,
			sfr_ok_to_email_flg,
			dw_trans_ts,
			row_stat_cd,
			appl_src_cd
			)
			
			with cte as(
			
						SELECT 	
				 igender, 
				r.irecipientid, 
				CASE WHEN collate(rfr.cnst_mstr_id::text,'CS') IS NOT NULL THEN collate(rfr.dm_cnst_line_1_addr::text,'CS')
							WHEN collate(rbio.cnst_mstr_id::text,'CS') IS NOT NULL THEN collate(rbio.dm_cnst_line_1_addr::text,'CS')
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.dm_cnst_line_1_addr
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.dm_cnst_line_1_addr
							ELSE NULL
				end AS saddress1, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(rfr.dm_cnst_line_2_addr::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.dm_cnst_line_2_addr
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.dm_cnst_line_2_addr
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.dm_cnst_line_2_addr
							ELSE NULL
				end AS saddress2, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(rfr.dm_cnst_city_nm::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.dm_cnst_city_nm
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.dm_cnst_city_nm
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.dm_cnst_city_nm
							ELSE NULL
				end AS scity, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(rfr.em_cnst_email::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.em_cnst_email
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.em_cnst_email
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.em_cnst_email
							ELSE NULL
				end AS semail, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN Coalesce(collate(rfr.em_cnst_prsn_f_nm::text,'CS'), collate(rfr.dm_cnst_prsn_f_nm::text,'CS'), NULL)
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN Coalesce(rbio.em_cnst_prsn_f_nm, rbio.dm_cnst_prsn_f_nm, NULL)
							WHEN rts.cnst_mstr_id IS NOT NULL THEN Coalesce(rts.em_cnst_prsn_f_nm, rts.dm_cnst_prsn_f_nm, NULL)
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN Coalesce(rvol.em_cnst_prsn_f_nm, rvol.dm_cnst_prsn_f_nm, NULL)
							ELSE NULL
				end AS sfirstname, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN Coalesce(collate(rfr.em_cnst_prsn_l_nm::text,'CS'), collate(rfr.dm_cnst_prsn_l_nm::text,'CS'), NULL)
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN Coalesce(rbio.em_cnst_prsn_l_nm, rbio.dm_cnst_prsn_l_nm, NULL)
							WHEN rts.cnst_mstr_id IS NOT NULL THEN Coalesce(rts.em_cnst_prsn_l_nm, rts.dm_cnst_prsn_l_nm, NULL)
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN Coalesce(rvol.em_cnst_prsn_l_nm, rvol.dm_cnst_prsn_l_nm, NULL)
							ELSE NULL
				end AS slastname, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN Coalesce(collate(rfr.em_cnst_prsn_m_nm::text,'CS'), collate(rfr.dm_cnst_prsn_m_nm::text,'CS'), NULL)
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN Coalesce(collate(rbio.em_cnst_prsn_m_nm::text,'CS'),  collate(rfr.dm_cnst_prsn_m_nm::text,'CS'), NULL)
							WHEN rts.cnst_mstr_id IS NOT NULL THEN Coalesce(rts.em_cnst_prsn_m_nm, rts.dm_cnst_prsn_m_nm, NULL)
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN Coalesce(rvol.em_cnst_prsn_m_nm, rvol.dm_cnst_prsn_m_nm, NULL)
							ELSE NULL
				end AS smiddlename, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(rfr.cnst_mbl_phn::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.cnst_mbl_phn
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.cnst_mbl_phn
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.cnst_mbl_phn
							ELSE NULL
				end AS smobilephone ,
				
				sorigin,
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(rfr.prim_cnst_phn::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.prim_cnst_phn
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.prim_cnst_phn
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.prim_cnst_phn
							ELSE NULL
				end AS sphone, 
			ssalutation, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(rfr.dm_cnst_st_cd::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.dm_cnst_st_cd
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.dm_cnst_st_cd
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.dm_cnst_st_cd
							ELSE NULL
				end AS sstatecode, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(rfr.dm_cnst_zip_5_cd::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.dm_cnst_zip_5_cd
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.dm_cnst_zip_5_cd
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.dm_cnst_zip_5_cd
							ELSE NULL
				end AS szipcode,
				tsbirth, 
				Current_Timestamp(0) AS  tslastmodified, 
				tscreated, 
				bicnst_mstr_id, 
				birecipientid, 
				Coalesce(frs.fr_last_dntn_amt, NULL) AS dlastdonationamt, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN fru.unit_key
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN biou.unit_key
							WHEN rts.cnst_mstr_id IS NOT NULL THEN tsu.unit_key
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN volu.unit_key
							ELSE NULL
				end AS ifr_field_unit_dimension_id,
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(fru.nk_ecode::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN biou.nk_ecode
							WHEN rts.cnst_mstr_id IS NOT NULL THEN tsu.nk_ecode
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN volu.nk_ecode
							ELSE NULL
				end AS fr_field_chapter_cd, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN collate(fru.cs_region_cd::text,'CS')
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN biou.cs_region_cd
							WHEN rts.cnst_mstr_id IS NOT NULL THEN tsu.cs_region_cd
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN volu.cs_region_cd
							ELSE NULL
				end AS fr_field_region_cd, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN frmu.unit_key
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN biomu.unit_key
							WHEN rts.cnst_mstr_id IS NOT NULL THEN tsmu.unit_key
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN volmu.unit_key
							ELSE NULL
				end AS ifr_mkt_field_unit_dimension_id,
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN frmu.nk_ecode
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN biomu.nk_ecode
							WHEN rts.cnst_mstr_id IS NOT NULL THEN tsmu.nk_ecode
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN volmu.nk_ecode
							ELSE NULL
				end AS fr_mkt_chapter_cd, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN frmu.cs_region_cd
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN biomu.cs_region_cd
							WHEN rts.cnst_mstr_id IS NOT NULL THEN tsmu.cs_region_cd
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN volmu.cs_region_cd
							ELSE NULL
				end AS fr_mkt_region_cd, 
				CASE WHEN rbio.cnst_mstr_id IS NOT NULL THEN 1 ELSE 0 end AS iisbio, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN 1 ELSE 0 end AS iisfr, 
				CASE WHEN rts.cnst_mstr_id IS NOT NULL THEN 1 ELSE 0 end AS iisphss,
				CASE WHEN rvol.cnst_mstr_id IS NOT NULL THEN 1 ELSE 0 end AS iisvms, 
				rbio.dm_cnst_line_1_addr AS saddress1_bio, 
				rfr.dm_cnst_line_1_addr AS saddress1_fr, 
				rts.dm_cnst_line_1_addr AS saddress1_phss, 
				rvol.dm_cnst_line_1_addr AS saddress1_vms,
				rbio.dm_cnst_line_2_addr AS saddress2_bio, 
				rfr.dm_cnst_line_2_addr AS saddress2_fr, 
				rts.dm_cnst_line_2_addr AS saddress2_phss, 
				rvol.dm_cnst_line_2_addr AS saddress2_vms, 
				rbio.em_cnst_email AS sbio_em_email,
				rbio.dm_cnst_city_nm AS scity_bio, 
				rfr.dm_cnst_city_nm AS scity_fr, 
				rts.dm_cnst_city_nm AS scity_phss, 
				rvol.dm_cnst_city_nm AS scity_vms, 
				rfr.dm_cnst_addr_assessmnt_ctg AS sfraddrquality, 
				rfr.em_cnst_email AS sfr_em_email,
				rbio.dm_cnst_addr_assessmnt_ctg AS sbioaddrquality, 
				scompany, 
				rbio.cnst_mbl_phn AS smobilephone_bio, 
				rfr.cnst_mbl_phn AS smobilephone_fr,
				rts.cnst_mbl_phn AS smobilephone_phss, 
				rvol.cnst_mbl_phn AS smobilephone_vms, 
				rbio.prim_cnst_phn AS sphone_bio, 
				rfr.prim_cnst_phn AS sphone_fr, 
				rts.prim_cnst_phn AS sphone_phss,
				rvol.prim_cnst_phn AS sphone_vms, 
				rts.dm_cnst_addr_assessmnt_ctg AS sphssaddrquality, 
				rts.em_cnst_email AS sphss_em_email,
			  	rbio.dm_cnst_st_cd AS sstatecode_bio,
				rfr.dm_cnst_st_cd AS sstatecode_fr, 
				rts.dm_cnst_st_cd AS sstatecode_phss, 
				rvol.dm_cnst_st_cd AS sstatecode_vms, 
				rvol.dm_cnst_addr_assessmnt_ctg AS svmsaddrquality,
				rvol.em_cnst_email AS svms_em_email, 
				rbio.dm_cnst_zip_5_cd AS szipcode_bio, 
				rfr.dm_cnst_zip_5_cd AS szipcode_fr, 
				rts.dm_cnst_zip_5_cd AS szipcode_phss, 
				rvol.dm_cnst_zip_5_cd AS szipcode_vms,
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN rfr.dm_locator_prsn_nm_key
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN 0
							WHEN rts.cnst_mstr_id IS NOT NULL THEN 0
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN 0
							ELSE NULL	
				end AS bidm_namelocatorkey,
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN rfr.em_locator_prsn_nm_key
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN 0
							WHEN rts.cnst_mstr_id IS NOT NULL THEN 0
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN 0
							ELSE NULL	
				end AS biem_namelocatorkey, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN rfr.em_email_key
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.em_email_key
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.em_cnst_email_key
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.em_cnst_email_key
							ELSE NULL	
				end AS biemaillocatorkey,
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN rfr.dm_locator_addr_key
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN rbio.dm_locator_addr_key
							WHEN rts.cnst_mstr_id IS NOT NULL THEN rts.dm_locator_addr_key
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN rvol.dm_locator_addr_key
							ELSE NULL	
				end AS biaddrlocatorkey, 
				Cast(0 AS BIGINT) AS biprimphonelocatorkey, 
				Cast(0 AS BIGINT) AS bimblphonelocatorkey,
				rfr.dm_cnst_prsn_f_nm AS sdm_firstname_fr, 
				rfr.dm_cnst_prsn_m_nm AS sdm_middlename_fr, 
				rfr.dm_cnst_prsn_l_nm AS sdm_lastname_fr, 
				rbio.dm_cnst_prsn_f_nm AS sdm_firstname_bio,
				rbio.dm_cnst_prsn_m_nm AS sdm_middlename_bio, 
				rbio.dm_cnst_prsn_l_nm AS sdm_lastname_bio, 
				rts.dm_cnst_prsn_f_nm AS sdm_firstname_phss, 
				rts.dm_cnst_prsn_m_nm AS sdm_middlename_phss,
				rts.dm_cnst_prsn_l_nm AS sdm_lastname_phss, 
				rvol.dm_cnst_prsn_f_nm AS sdm_firstname_vms, 
				rvol.dm_cnst_prsn_m_nm AS sdm_middlename_vms, 
				rvol.dm_cnst_prsn_l_nm AS sdm_lastname_vms,
				 rfr.em_cnst_prsn_f_nm AS sem_firstname_fr, 
				rfr.em_cnst_prsn_m_nm AS sem_middlename_fr, 
				 rfr.em_cnst_prsn_l_nm AS sem_lastname_fr, 
				rbio.em_cnst_prsn_f_nm AS sem_firstname_bio,
				rbio.em_cnst_prsn_m_nm AS sem_middlename_bio, 
				rbio.em_cnst_prsn_l_nm AS sem_lastname_bio, 
				rts.em_cnst_prsn_f_nm AS sem_firstname_phss, 
				rts.em_cnst_prsn_m_nm AS sem_middlename_phss,
				rts.em_cnst_prsn_l_nm AS sem_lastname_phss, 
				rvol.em_cnst_prsn_f_nm AS sem_firstname_vms, 
				rvol.em_cnst_prsn_m_nm AS sem_middlename_vms, 
				rvol.em_cnst_prsn_l_nm AS sem_lastname_vms,
				rfr.em_cnst_email_assessmnt_ctg AS semailquality_fr, 
				rbio.em_cnst_email_assessmnt_ctg AS semailquality_bio, 
				rts.em_cnst_email_assessmnt_ctg AS semailquality_phss, 
				rvol.em_cnst_email_assessmnt_ctg AS semailquality_vms,
				rfr.dm_cnst_addr_county_nm AS saddress4_fr, 
				rbio.dm_cnst_addr_county_nm AS saddress4_bio, 
				Cast(NULL AS VARCHAR(100)) AS saddress4_phss, 
				rvol.dm_cnst_addr_county_nm AS  saddress4_vms, 
				frs.fr_last_dntn_dt AS tslastdonation, 
				CASE WHEN semail IS NULL THEN 'N' ELSE b.ok_to_email_flg end AS sfr_ok_to_email_flg,
				Current_Timestamp(0) AS dw_trans_ts, 
				'C'::varchar AS row_stat_cd, 
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN 'FR'
							WHEN rbio.cnst_mstr_id IS NOT NULL THEN 'BIO'
							WHEN rts.cnst_mstr_id IS NOT NULL THEN 'TS'
							WHEN rvol.cnst_mstr_id IS NOT NULL THEN 'VOL'
							ELSE NULL
				end AS appl_src_cd,
				-------------------------------------------------------------
				CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN Coalesce(collate(rfr.em_cnst_prsn_f_nm::text,'CS'), collate(rfr.dm_cnst_prsn_f_nm::text,'CS'))
																WHEN rbio.cnst_mstr_id IS NOT NULL THEN Coalesce(rbio.em_cnst_prsn_f_nm, rbio.dm_cnst_prsn_f_nm, NULL)
																WHEN rts.cnst_mstr_id IS NOT NULL THEN Coalesce(rts.em_cnst_prsn_f_nm, rts.dm_cnst_prsn_f_nm, NULL)
																WHEN rvol.cnst_mstr_id IS NOT NULL THEN Coalesce(rvol.em_cnst_prsn_f_nm, rvol.dm_cnst_prsn_f_nm, NULL)
																ELSE NULL
													end as em_frst_nm,
			CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN Coalesce(collate(rfr.em_cnst_prsn_l_nm::text,'CS'), collate(rfr.dm_cnst_prsn_l_nm::text,'CS'))
																WHEN rbio.cnst_mstr_id IS NOT NULL THEN Coalesce(rbio.em_cnst_prsn_l_nm, rbio.dm_cnst_prsn_l_nm, NULL)
																WHEN rts.cnst_mstr_id IS NOT NULL THEN Coalesce(rts.em_cnst_prsn_l_nm, rts.dm_cnst_prsn_l_nm, NULL)
																WHEN rvol.cnst_mstr_id IS NOT NULL THEN Coalesce(rvol.em_cnst_prsn_l_nm, rvol.dm_cnst_prsn_l_nm, NULL)
																ELSE NULL
													end as em_lst_nm,
			CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN fru.unit_key
						WHEN rbio.cnst_mstr_id IS NOT NULL THEN biou.unit_key
						WHEN rts.cnst_mstr_id IS NOT NULL THEN tsu.unit_key
						WHEN rvol.cnst_mstr_id IS NOT NULL THEN volu.unit_key
						ELSE NULL
				end as unit_ky,
				
			CASE WHEN rfr.cnst_mstr_id IS NOT NULL THEN frmu.unit_key
						WHEN rbio.cnst_mstr_id IS NOT NULL THEN biomu.unit_key
						WHEN rts.cnst_mstr_id IS NOT NULL THEN tsmu.unit_key
						WHEN rvol.cnst_mstr_id IS NOT NULL THEN volmu.unit_key
						ELSE NULL
			   end as mkt_unit_ky
				
			FROM 
			/*
			The recipient table forms the base of the query. This is joined to each LOB preferred profile to reflect recipient current attribute values.  These values
			are compared against the existing recipient values to identify which recipient records require updates.  Note, the view is limited to recipient records that reference
			a bicnst_mstr_id value that is present in one of our LOB preferred profile tables.  It excludes recipient records that reference non-active or orphaned cnst_mstr_id values.
			The where qualifier in the view definition enforces the rule.
			*/
			(
				SELECT 
					irecipientid, 
					bicnst_mstr_id,
					birecipientid,
					igender,
					sorigin,
					scompany,
					tsbirth,
					tscreated,
					ssalutation,
					semail,
					sfr_em_email,
					sbio_em_email,
					sphss_em_email,
					svms_em_email,
					sfirstname,
					slastname,
					ifr_field_unit_dimension_id,
					ifr_mkt_field_unit_dimension_id
			FROM mktg_ops_vws.bz_adb_nmsrecipient
			) r  
			
			LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr rfr ON r.bicnst_mstr_id = rfr.cnst_mstr_id
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr rbio ON r.bicnst_mstr_id = rbio.cnst_mstr_id
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr rts ON r.bicnst_mstr_id = rts.cnst_mstr_id
			LEFT JOIN mktg_ops_vws.cnst_cdi_smry_vms_prfr rvol ON r.bicnst_mstr_id = rvol.cnst_mstr_id
			LEFT JOIN
			(
				SELECT 
					cnst_mstr_id,fr_last_dntn_amt, fr_last_dntn_dt
				FROM mktg_ops_vws.gms_arc_fr_smry 
			) frs ON rfr.cnst_mstr_id = frs.cnst_mstr_id
			LEFT JOIN 
			(
				SELECT
					unit_key,
					nk_ecode,
					cs_region_cd
				FROM mktg_ops_vws.bz_dim_unit 
			) fru (unit_key, nk_ecode, cs_region_cd) ON fru.unit_key = rfr.unit_key 
			LEFT JOIN 
			(
				SELECT
					unit_key,
					nk_ecode,
					cs_region_cd
				FROM mktg_ops_vws.bz_dim_unit 
			) frmu (unit_key, nk_ecode, cs_region_cd) ON frmu.unit_key = rfr.mktg_unit_key 
			LEFT JOIN 
			(
				SELECT
					unit_key,
					nk_ecode,
					cs_region_cd
				FROM mktg_ops_vws.bz_dim_unit 
			) biou (unit_key, nk_ecode, cs_region_cd) ON  biou.unit_key = rbio.unit_key 
			LEFT JOIN 
			(
				SELECT
					unit_key,
					nk_ecode,
					cs_region_cd
				FROM mktg_ops_vws.bz_dim_unit 
			) biomu (unit_key, nk_ecode, cs_region_cd) ON biomu.unit_key = rbio.mktg_unit_key 
			LEFT JOIN 
			(
				SELECT
					unit_key,
					nk_ecode,
					cs_region_cd
				FROM mktg_ops_vws.bz_dim_unit 
			) tsu (unit_key, nk_ecode, cs_region_cd) ON  tsu.unit_key = rts.unit_key 
			LEFT JOIN 
			(
				SELECT
					unit_key,
					nk_ecode,
					cs_region_cd
				FROM mktg_ops_vws.bz_dim_unit 
			) tsmu (unit_key, nk_ecode, cs_region_cd) ON tsmu.unit_key = rts.mktg_unit_key 
			LEFT JOIN 
			(
				SELECT
					unit_key,
					nk_ecode,
					cs_region_cd
				FROM mktg_ops_vws.bz_dim_unit 
			) volu (unit_key, nk_ecode, cs_region_cd) ON  volu.unit_key = rvol.unit_key 
			LEFT JOIN 
			(
				SELECT
					unit_key,
					nk_ecode,
					cs_region_cd
				FROM mktg_ops_vws.bz_dim_unit 
			) volmu (unit_key, nk_ecode, cs_region_cd) ON volmu.unit_key = rvol.mktg_unit_key 
			LEFT JOIN mktg_ops_vws.gms_bzfc_cnst_cdi_fr_prfr_em_prfl b ON b.cnst_mstr_id = r.bicnst_mstr_id AND b.email_addr = r.semail
			where
			(rfr.cnst_mstr_id IS NOT NULL OR rbio.cnst_mstr_id IS NOT NULL OR rts.cnst_mstr_id IS NOT NULL OR rvol.cnst_mstr_id IS NOT NULL) /*Isolate the changes to recipient record that reference and active LOB profile master id. */
				AND 
				/*
				Now limit the returned rows to records where the current recipient attribute value doesn't match the current LOB profile value.  Limit the comparison
				to the LOB email, first & last name and the unit and mktg unit key value.
				*/
				(
					(collate(r.sfr_em_email::text,'CS') <> collate(rfr.em_cnst_email::text,'CS') OR collate(r.sfr_em_email::text,'CS') IS NULL AND  collate(rfr.em_cnst_email::text,'CS') IS NOT NULL)
					OR (r.sbio_em_email <> rbio.em_cnst_email OR (r.sbio_em_email IS NULL AND  rbio.em_cnst_email IS NOT null))
					OR (r.sphss_em_email <> rts.em_cnst_email OR (r.sphss_em_email IS NULL AND  rts.em_cnst_email IS NOT null))
					OR (r.svms_em_email <> rvol.em_cnst_email OR (r.svms_em_email IS NULL AND rvol.em_cnst_email IS NOT null))
					OR (r.sfirstname <> em_frst_nm OR (r.sfirstname IS NULL AND em_frst_nm IS NOT null))
					OR (r.slastname <> em_lst_nm OR (r.slastname IS NULL AND em_lst_nm IS NOT null))
					OR (r.ifr_field_unit_dimension_id <> unit_ky OR (r.ifr_field_unit_dimension_id IS NULL AND unit_ky IS NOT null))
					OR (r.ifr_mkt_field_unit_dimension_id <> mkt_unit_ky OR (r.ifr_mkt_field_unit_dimension_id IS NULL AND mkt_unit_ky IS NOT null))
				)
			
			
			
			)
			
			select
			igender,
			irecipientid,
			saddress1,
			saddress2,
			scity,
			semail,
			sfirstname,
			slastname,
			smiddlename,
			smobilephone,
			sorigin,
			sphone,
			ssalutation,
			sstatecode,
			szipcode,
			tsbirth,
			tslastmodified,
			tscreated,
			bicnst_mstr_id,
			birecipientid,
			dlastdonationamt,
			ifr_field_unit_dimension_id,
			fr_field_chapter_cd,
			fr_field_region_cd,
			ifr_mkt_field_unit_dimension_id,
			fr_mkt_chapter_cd,
			fr_mkt_region_cd,
			iisbio,
			iisfr,
			iisphss,
			iisvms,
			saddress1_bio,
			saddress1_fr,
			saddress1_phss,
			saddress1_vms,
			saddress2_bio,
			saddress2_fr,
			saddress2_phss,
			saddress2_vms,
			sbio_em_email,
			scity_bio,
			scity_fr,
			scity_phss,
			scity_vms,
			sfraddrquality,
			sfr_em_email,
			sbioaddrquality,
			scompany,
			smobilephone_bio,
			smobilephone_fr,
			smobilephone_phss,
			smobilephone_vms,
			sphone_bio,
			sphone_fr,
			sphone_phss,
			sphone_vms,
			sphssaddrquality,
			sphss_em_email,
			sstatecode_bio,
			sstatecode_fr,
			sstatecode_phss,
			sstatecode_vms,
			svmsaddrquality,
			svms_em_email,
			szipcode_bio,
			szipcode_fr,
			szipcode_phss,
			szipcode_vms,
			bidm_namelocatorkey,
			biem_namelocatorkey,
			biemaillocatorkey,
			biaddrlocatorkey,
			biprimphonelocatorkey,
			bimblphonelocatorkey,
			sdm_firstname_fr,
			sdm_middlename_fr,
			sdm_lastname_fr,
			sdm_firstname_bio,
			sdm_middlename_bio,
			sdm_lastname_bio,
			sdm_firstname_phss,
			sdm_middlename_phss,
			sdm_lastname_phss,
			sdm_firstname_vms,
			sdm_middlename_vms,
			sdm_lastname_vms,
			sem_firstname_fr,
			sem_middlename_fr,
			sem_lastname_fr,
			sem_firstname_bio,
			sem_middlename_bio,
			sem_lastname_bio,
			sem_firstname_phss,
			sem_middlename_phss,
			sem_lastname_phss,
			sem_firstname_vms,
			sem_middlename_vms,
			sem_lastname_vms,
			semailquality_fr,
			semailquality_bio,
			semailquality_phss,
			semailquality_vms,
			saddress4_fr,
			saddress4_bio,
			saddress4_phss,
			saddress4_vms,
			tslastdonation,
			sfr_ok_to_email_flg,
			dw_trans_ts,
			row_stat_cd,
			appl_src_cd
			
			from cte;
			
			truncate table  mktg_ops_tbls.bzfc_adb_recipient_updt_delta;
			
			insert into mktg_ops_tbls.bzfc_adb_recipient_updt_delta select * from  mktg_stage_tbls.bzfc_adb_recipient_updt_delta_stg;
		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bzfc_adb_recipient_updt_delta) as INTEGER)
			WHERE proc_name = 'ld_bzfc_adb_recipient_updt_delta' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bzfc_adb_recipient_updt_delta', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
