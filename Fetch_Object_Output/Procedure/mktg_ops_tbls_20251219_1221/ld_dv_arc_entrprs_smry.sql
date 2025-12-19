CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dv_arc_entrprs_smry()
 LANGUAGE plpgsql
AS $$

/* ---------------------------------------------------------------------------------------------------------------------------

Created by: Majeed Mohammad
Created date: 04/26/2016
Purpose: This macro loads data into the data visuation enterprise summary table. This macro should be run after all the SMRY tables are loaded. 

Modified by: Majeed Mohammad
Modified date: 06/09/2016
Purpose: Corrected the insert statement for mktg_ops_tbls.dv_arc_fr_smry. Previously, the columns dntn_cnt, dstr_dntn_cnt, dntn_amt were incorrectly mapped. 

Modified by: Majeed Mohammad
Modified date: 07/07/2016
Purpose: Temporarily updated the dates filters to include FY15,FY16 & FY17. 

Modified by: Majeed Mohammad
Modified date: 12/06/2016
Purpose: Updated the join cast(mktg_ops_vws.arc_fr_txn.fr_affl_cd as integer) =dw_common_vws.dim_unit_merged.orig_unit_key to use the column fr_affl_unit_key. 
The view does the explicit cast to integer for this column

Modified by: Majeed Mohammad
Modified on: 04/24/2020
Purpose:  Added the filter to run this macro only on Saturdays 

Modified By:  Mike Andrien
Modified Date: 04/28/2020
Purpose: Converted the FR query the reference the GMS ARC FR TXN view.   Also, replaced bz_cnst_birth_pg with bz_cnst_birth_best
---------------------------------------------------------------------------------------------------------------------------- */
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dv_arc_entrprs_smry', 'Stored Procedure', 'Inprogress', v_start_time);


begin
-- Check if today is Saturday (dow = 6)
        IF EXTRACT(DOW FROM CURRENT_DATE) = 6 THEN
				delete from  mktg_ops_tbls.dv_arc_bio_smry ; 


				insert into mktg_ops_tbls.dv_arc_bio_smry (chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk, distnct_dntn_cnt, walkin_cnt, first_dntn_cnt, phleb_cnt,		doubl_rbc_cnt) 
						SELECT
				  GEO.ECODE as chap_cd ,
				  BIRTH.generation_segmnt_cd as gen_sgmnt_cd,
				  BIRTH.generation_segmnt_dsc as gen_sgmnt_dsc,
				  extract( year from TXN.nk_donat_dt) as engmnt_yr,
				  extract( Month from TXN.nk_donat_dt) as engmnt_mnth,
				  EXTRACT(week FROM TXN.nk_donat_dt) AS engmnt_wk,
				  count(distinct(TXN.donat_key)) as distnct_dntn_cnt,
				  sum(TXN.walk_in_ind) as walkin_cnt,
				  sum(TXN.first_donat_ind) as first_dntn_cnt,
				  sum(TXN.phleb_ind) as phleb_cnt,
				  sum(TXN.dbl_rbc_ind) as doubl_rbc_cnt
				FROM
				  mktg_ops_vws.bz_cnst_birth_best BIRTH RIGHT JOIN mktg_ops_vws.arc_biomed_txn TXN ON TXN.cnst_mstr_id=BIRTH.cnst_mstr_id
					 LEFT JOIN eda.bio_donation_vws.bz_dim_drive_site SITE ON TXN.drive_site_key=SITE.mstr_drive_site_key
					 LEFT JOIN eda.dw_common_vws.geo_zip_code_to_chapter GEO ON SITE.zip=GEO.ZIP
				WHERE TXN.nk_donat_dt  between cast('2014-01-07' as date) and current_date 
				/* Commented out for the demo on 7/7/2016. Added the clause for FY15, FY16 & FY17  */
				  /* 
				  TXN.nk_donat_dt  between cast((case when extract(month from date)<7 then (extract(year from date)-1) else extract(year from date) end)||'-07-01' as date)   AND  date
				  */
				GROUP BY
				  1, 
				  2, 
				  3, 
				  4, 
				  5, 
				  6;


				delete from  mktg_ops_tbls.dv_arc_fr_smry ; 

				insert into mktg_ops_tbls.dv_arc_fr_smry (chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk, dntn_cnt, dstr_dntn_cnt, dntn_amt) 
				SELECT
				  c.nk_ecode as chap_cd,
				  b.generation_segmnt_cd as gen_sgmnt_cd,
				  b.generation_segmnt_dsc as gen_sgmnt_dsc,
				  extract( year from a.dntn_gift_dt) as engmnt_yr,
				  extract( month from a.dntn_gift_dt) as engmnt_mnth,
				   EXTRACT(week FROM a.dntn_gift_dt) AS engmnt_wk,
				  count(distinct(a.giftran_key)) as dntn_cnt,
				  sum(a.fr_distr_dntn_ind) as dstr_dntn_cnt, 
				  sum(a.fr_pmt_amt) as dntn_amt
				FROM 
				(
					  select 
						cnst_mstr_id,
						giftran_key,
						dntn_gift_dt,
						fr_affl_unit_key,
						fr_distr_dntn_ind,
						fr_pmt_amt
					  from mktg_ops_vws.gms_arc_fr_txn a
					  where a.dntn_gift_dt between cast('2014-01-07' as date) and current_date 
				  ) a (cnst_mstr_id, giftran_key, dntn_gift_dt, fr_affl_unit_key, fr_distr_dntn_ind,	fr_pmt_amt)
				LEFT JOIN mktg_ops_vws.bz_cnst_birth_best b ON a.cnst_mstr_id = b.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_unit_merged c ON  a.fr_affl_unit_key =c.orig_unit_key
				WHERE a.dntn_gift_dt between cast('2014-01-07' as date) and current_date 
				/* Commented out for the demo on 7/7/2016. Added the clause for FY15, FY16 & FY17  */
				  /* 
				  mktg_ops_vws.arc_fr_txn.dntn_gift_dt  BETWEEN  cast((case when extract(month from date)<7 then (extract(year from date)-1) else extract(year from date) end)||'-07-01' as date)   AND  date
				  */
				GROUP BY
				  1, 
				  2, 
				  3, 
				  4, 
				  5, 
				  6;

				delete from  mktg_ops_tbls.dv_arc_phss_smry; 


				insert into mktg_ops_tbls.dv_arc_phss_smry	(chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk, course_attnd_cnt, tot_paymnt_amt)
				select
				eda.dw_common_vws.dim_unit_merged.nk_ecode as chap_cd,
				  mktg_ops_vws.bz_cnst_birth_best.generation_segmnt_cd as gen_sgmnt_cd,
				  mktg_ops_vws.bz_cnst_birth_best.generation_segmnt_dsc as gen_sgmnt_dsc,
				  extract(year from  mktg_ops_vws.arc_phss_txn.offer_end_dt) as engmnt_yr,
				  extract( Month from mktg_ops_vws.arc_phss_txn.offer_end_dt) as engmnt_mnth,
				  extract (week from mktg_ops_vws.arc_phss_txn.offer_end_dt) as engmnt_wk,
				  sum(mktg_ops_vws.arc_phss_txn.Course_attd_cnt) as course_attnd_cnt,
				  sum(mktg_ops_vws.arc_phss_txn.Tot_payment_amt) as tot_paymnt_amt
				FROM
				  mktg_ops_vws.bz_cnst_birth_best RIGHT JOIN mktg_ops_vws.arc_phss_txn ON mktg_ops_vws.arc_phss_txn.cnst_mstr_id=mktg_ops_vws.bz_cnst_birth_best.cnst_mstr_id
					 LEFT JOIN eda.dw_common_vws.dim_unit_merged ON mktg_ops_vws.arc_phss_txn.unit_key=eda.dw_common_vws.dim_unit_merged.orig_unit_key
				WHERE mktg_ops_vws.arc_phss_txn.offer_end_dt between cast('2014-01-07' as date) and current_date 
				/* Commented out for the demo on 7/7/2016. Added the clause for FY15, FY16 & FY17  */
				  /* 
				  mktg_ops_vws.arc_phss_txn.offer_end_dt  BETWEEN  cast((case when extract(month from date)<7 then (extract(year from date)-1) else extract(year from date) end)||'-07-01' as date)  AND  date
				  */
				GROUP BY
				  1, 
				  2, 
				  3, 
				  4, 
				  5, 
				  6; 


				delete from  mktg_ops_tbls.dv_arc_vms_smry; 


				insert into mktg_ops_tbls.dv_arc_vms_smry (chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk, hrs_wrkd_cnt)
				SELECT
				  eda.dw_common_vws.dim_unit_merged.nk_ecode as chap_cd,
				  mktg_ops_vws.bz_cnst_birth_best.generation_segmnt_cd as gen_sgmnt_cd,
				  mktg_ops_vws.bz_cnst_birth_best.generation_segmnt_dsc as gen_sgmnt_dsc,
				  extract( year from mktg_ops_vws.arc_vms_txn.hrs_wrkd_dt) as engmnt_yr,
				  extract( Month from mktg_ops_vws.arc_vms_txn.hrs_wrkd_dt) as engmnt_mnth,
				   extract(week from mktg_ops_vws.arc_vms_txn.hrs_wrkd_dt) as engmnt_wk,
				  sum(mktg_ops_vws.arc_vms_txn.tot_hrs_cnt) as hrs_wrkd_cnt
				FROM
				  mktg_ops_vws.bz_cnst_birth_best RIGHT JOIN mktg_ops_vws.arc_vms_txn ON mktg_ops_vws.arc_vms_txn.cnst_mstr_id=mktg_ops_vws.bz_cnst_birth_best.cnst_mstr_id
					 LEFT JOIN eda.dw_common_vws.dim_unit_merged ON mktg_ops_vws.arc_vms_txn.unit_key=eda.dw_common_vws.dim_unit_merged.orig_unit_key
				WHERE mktg_ops_vws.arc_vms_txn.hrs_wrkd_dt  between cast('2014-01-07' as date) and current_date 
				/* Commented out for the demo on 7/7/2016. Added the clause for FY15, FY16 & FY17  */
				  /* 
				  mktg_ops_vws.arc_vms_txn.hrs_wrkd_dt  BETWEEN  cast((case when extract(month from date)<7 then (extract(year from date)-1) else extract(year from date) end)||'-07-01' as date)  AND  date
				  */
				GROUP BY
				  1, 
				  2, 
				  3, 
				  4, 
				  5, 
				  6;


				delete from  mktg_ops_tbls.dv_arc_entrprs_smry; 
				 

				insert into  mktg_ops_tbls.dv_arc_entrprs_smry
				  (	chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk, distnct_dntn_cnt, walkin_cnt, first_dntn_cnt, phleb_cnt,
						doubl_rbc_cnt, dntn_cnt, dstr_dntn_cnt, dntn_amt, course_attnd_cnt,
						tot_paymnt_amt, hrs_wrkd_cnt  )
				select chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk, sum(distnct_dntn_cnt) as distnct_dntn_cnt, sum(walkin_cnt) as walkin_cnt, sum( first_dntn_cnt) as first_dntn_cnt, sum( phleb_cnt) as phleb_cnt, sum( doubl_rbc_cnt) as doubl_rbc_cnt, sum( dntn_cnt) as dntn_cnt, sum(dstr_dntn_cnt) as dstr_dntn_cnt, sum( dntn_amt) as dntn_amt, sum( 
				course_attnd_cnt) as course_attnd_cnt, sum( tot_paymnt_amt) as tot_paymnt_amt, sum( hrs_wrkd_cnt) as hrs_wrkd_cnt
				 from 
				(SELECT	chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk, cast(distnct_dntn_cnt as integer) distnct_dntn_cnt, cast(walkin_cnt as integer) walkin_cnt, cast( first_dntn_cnt as integer) first_dntn_cnt, cast( phleb_cnt as integer) 
				phleb_cnt, cast( doubl_rbc_cnt as integer) doubl_rbc_cnt, cast(0 as integer) dntn_cnt,  cast(0 as integer)  dstr_dntn_cnt,  cast(0 as DECIMAL(13,2)) dntn_amt,   cast(0 as integer)  
				course_attnd_cnt,  cast(0 as DECIMAL(13,2)) tot_paymnt_amt,  cast(0 as integer)  hrs_wrkd_cnt
				FROM	mktg_ops_tbls.dv_arc_bio_smry
				 union 
				SELECT	chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk,  0 distnct_dntn_cnt,  0 walkin_cnt, 0  first_dntn_cnt,  0 phleb_cnt,  0 doubl_rbc_cnt, dntn_cnt, dstr_dntn_cnt, dntn_amt,   0 course_attnd_cnt,  0 tot_paymnt_amt,  0 
				hrs_wrkd_cnt
				FROM	mktg_ops_tbls.dv_arc_fr_smry
				 union 
				SELECT	chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk,0 distnct_dntn_cnt,  0 walkin_cnt, 0  first_dntn_cnt,  0 phleb_cnt,  0 doubl_rbc_cnt,  0 dntn_cnt,  0 dstr_dntn_cnt,  0 dntn_amt,  course_attnd_cnt,   tot_paymnt_amt,  0 
				hrs_wrkd_cnt
				FROM	mktg_ops_tbls.dv_arc_phss_smry
				 union 
				SELECT	chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk, 0 distnct_dntn_cnt,  0 walkin_cnt, 0  first_dntn_cnt,  0 phleb_cnt,  0 doubl_rbc_cnt,  0 dntn_cnt,  0 dstr_dntn_cnt,  0 dntn_amt,   0 course_attnd_cnt,  0 tot_paymnt_amt, 
				   hrs_wrkd_cnt
				FROM	mktg_ops_tbls.dv_arc_vms_smry) SMRY 
				group by chap_cd, gen_sgmnt_cd, gen_sgmnt_dsc, engmnt_yr, engmnt_mnth,
						engmnt_wk	;

					--audit update	
					 v_end_time := GETDATE();
					 v_ok_message = 'Records inserted.';
		        
					UPDATE mods_bi.etl_config.audit_log
					SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.dv_arc_entrprs_smry) as INTEGER)
					WHERE proc_name = 'ld_dv_arc_entrprs_smry' 
					AND task_name = 'Stored Procedure' 
					AND start_time = v_start_time;
		ELSE
            v_end_time := GETDATE();
			v_ok_message = 'Procedure skipped: Today is not Saturday.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.dv_arc_entrprs_smry) as INTEGER)
			WHERE proc_name = 'ld_dv_arc_entrprs_smry' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
        END IF;
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_dv_arc_entrprs_smry', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
