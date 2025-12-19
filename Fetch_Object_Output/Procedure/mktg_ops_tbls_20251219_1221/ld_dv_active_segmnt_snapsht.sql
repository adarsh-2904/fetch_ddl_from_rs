CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_dv_active_segmnt_snapsht()
 LANGUAGE plpgsql
AS $$
/*
Created By Michael Andrien
Create Date 8/28/2017
Purpose:  This macro is scheduled to run daily to capture the daily active constituent snapshot metrics to the dv_active_segmnt_snapsht table.  These metrics	
				are used to track and assess our progress in growing our active cnst base by line of business (LOB) and to assess whether we are growing our multi-LOB cnst base.
				The snapshot table allows us to view the historical metrics.

Modified By Michael Andrien
Modified Date 8/31/2017
Purpose:  Added 9 new columns to capture the constituent type and LOB only and and LOB plus other or mult lob counts 
				(cnst_typ_cd, active_all_trans_fr_only_cnt, active_all_trans_fr_othr_cnt, active_all_trans_bio_only_cnt, active_all_trans_bio_othr_cnt, active_phss_rcs_only_cnt,active_phss_rcs_othr_cnt, active_vms_only_cnt, active_vms_othr_cnt)
				Also, added the UNION to include the 'All' count, which provide the active segment count totals for both OR-Orgs and IN-Individual constituent types

Modified By:  Mike Andrien
Modified Date: 03/02/2018
Purpose: Added lapsed and new indicators by LOB

Modified By:  Mike Andrien
Modified Date: 03/07/2018
Purpose:  Added Reactivation count metrics for FR, BIO and PHSS

Modified By:  Mike Andrien
Modified Date: 03/13/2018
Purpose:  Added logic to calculate lapsed, new and reactivated at across all LOBs - add total lapsed, new and reactivated. 

Modified By:  Majeed Mohammad
Modified Date: 03/29/2018
Purpose: Updated the logic in the macro to use the function add_months instead of inteval Months to handle the dates for Feb month

Modified By:  Mike Andrien
Modified Date: 05/28/2018
Purpose:  Added count attributes to distinguish PHSS DemandWare (DMW) count, which include both PHSS Store and Course orders, from the legacy Red Cross Store (RCS)
				orders from the old ValueNet system and SABA course orders (PHSS).  The PHSS_RCS attributes sum the RCS and PHSS counts.  DMW attributes will replace the PHSS and RCS 
				attributes.

Modified By:  Mike Andrien
Modified Date: 07/06/2018
Purpose:  Added logic to capture DemandWare (DMW)  new, lapsed and reactivated metrics.  Also, modify 'total' logic to replace RCS and PHSS with DMW, which covers both Red Cross Store
				and learners.

Modified By:  Mike Andrien
Modified Date: 07/24/2018
Purpose:   Added the Multi-LOB 4,3,and 2 count attributes and the 2-LOB combination counts.

Modified By:  Mike Andrien
Modified Date: 09/19/2022
Purpose: Replace references to arc_fr_smry with gms_arc_fr_smry in the New, Lapsed and Reactivated sections.

Modified By:  Mike Andrien
Modified Date: 03/27/2023
Purpose:  Added the new DemandWare metrics below to segregate course and store order counts.
		active_dmw_course_cnt, active_dmw_course_only_cnt, active_dmw_course_othr_cnt, 
		active_dmw_store_cnt, active_dmw_store_only_cnt, active_dmw_store_othr_cnt, 
		active_dmw_course_nostore_ind, 
		active_dmw_store_nocourse_ind,

Modified By:  Michael Andrien
Modified Date: 07/20/2023
Purpose: Added the active_multi_ever_cnt and renamed multi_lob_all_trans_ind to multi_lob_all_trans_cnt.

Modified By:  Majeed Mohammad
Modified Date: 2/29/2023
Purpose: Replaced the date interval function with add_months function to handle the leap year. 

Modified By:  Michael Andrien
Modified Date: 11/08/2024
Purpose: Updated the logic for calculating the active_multi_ever_cnt.  
--		Sum(active_multi_ever_ind) AS active_multi_ever_cnt,
		Sum(
		CASE WHEN (active_all_trans_fr_ind = 1 
					AND Coalesce(last_donat_dt, first_vol_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
				OR (active_all_trans_bio_ind = 1
					AND Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, first_vol_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
				OR (active_vms_ind = 1
					AND Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, last_donat_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
				OR (active_dmw_ind = 1
					AND (Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, last_donat_dt, first_vol_dt, DATE '1900-01-01') <> DATE '1900-01-01'))
				OR multi_lob_all_trans_ind = 1
			THEN 1 
			ELSE 0
		end ) AS active_multi_ever_cnt,	

Modified By:  Adarsh Ram
Modified Date: 8/27/2025
Purpose: The table arc_store_vws.bz_dim_odr was not found in Redshift. As per Mike’s suggestion, in the meantime we need to create the table arc_store_tbls.dim_odr in the mods_bi database and load the data into that table.
*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_dv_active_segmnt_snapsht', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		truncate table mktg_stage_tbls.dv_active_segmnt_snapsht_stg;
		INSERT INTO mktg_stage_tbls.dv_active_segmnt_snapsht_stg
		SELECT 
			acs.snapsht_dt, 
			acs.cnst_typ_cd, 
			acs.active_all_trans_fr_cnt, 
			acs.active_all_trans_fr_only_cnt, 
			acs.active_all_trans_fr_othr_cnt, 
			lob_lapse.fr_month_lapsed_cnt, 
			lob_new.fr_month_new_active_cnt, 
			lob_react.fr_month_reactivated_cnt,
			acs.active_all_trans_bio_cnt, 
			acs.active_all_trans_bio_only_cnt, 
			acs.active_all_trans_bio_othr_cnt, 
			coalesce(lob_lapse.bio_month_lapsed_cnt,0) AS bio_month_lapsed_cnt, 
			coalesce(lob_new.bio_month_new_active_cnt,0) AS bio_month_new_active_cnt, 
			coalesce(lob_react.bio_month_reactivated_cnt,0) AS bio_month_reactivated_cnt,
			coalesce(acs.active_dmw_cnt,0) AS active_dmw_cnt, 
			coalesce(acs.active_dmw_only_cnt,0) AS active_dmw_only_cnt, 
			coalesce(acs.active_dmw_othr_cnt,0) AS active_dmw_othr_cnt,
			coalesce(acs.active_dmw_course_cnt,0) AS active_dmw_course_cnt, 
			coalesce(acs.active_dmw_course_only_cnt,0) AS active_dmw_course_only_cnt, 
			coalesce(acs.active_dmw_course_othr_cnt,0) AS active_dmw_course_othr_cnt,
			coalesce(acs.active_dmw_store_cnt,0) AS active_dmw_store_cnt, 
			coalesce(acs.active_dmw_store_only_cnt,0) AS active_dmw_store_only_cnt, 
			coalesce(acs.active_dmw_store_othr_cnt,0) AS active_dmw_store_othr_cnt,
			coalesce(acs.active_dmw_course_nostore_ind,0) AS active_dmw_course_nostore_ind, 
			coalesce(acs.active_dmw_store_nocourse_ind,0) AS active_dmw_store_nocourse_ind,
			coalesce(acs.active_rcs_cnt,0) AS active_rcs_cnt, 
			coalesce(acs.active_rcs_only_cnt,0) AS active_rcs_only_cnt, 
			coalesce(acs.active_rcs_othr_cnt,0) AS active_rcs_othr_cnt,
			coalesce(acs.active_phss_cnt,0) AS active_phss_cnt, 
			coalesce(acs.active_phss_only_cnt,0) AS active_phss_only_cnt, 
			coalesce(acs.active_phss_othr_cnt,0) AS active_phss_othr_cnt,
			coalesce(acs.active_phss_rcs_cnt,0) AS active_phss_rcs_cnt, 
			coalesce(acs.active_phss_rcs_only_cnt,0) AS active_phss_rcs_only_cnt, 
			coalesce(acs.active_phss_rcs_othr_cnt,0) AS active_phss_rcs_othr_cnt,
			lob_lapse.rcs_month_lapsed_cnt, 
			lob_new.rcs_month_new_active_cnt, 
			lob_lapse.phss_month_lapsed_cnt, 
			lob_new.phss_month_new_active_cnt, 
			lob_react.phss_month_reactivated_cnt,
			lob_lapse.dmw_month_lapsed_cnt, 
			lob_new.dmw_month_new_active_cnt, 
			lob_react.dmw_month_reactivated_cnt,
			lob_lapse.total_month_lapsed_cnt, 
			lob_new.total_month_new_active_cnt, 
			lob_react.total_month_reactivated_cnt,	
			acs.active_vms_cnt, 
			acs.active_vms_only_cnt, 
			acs.active_vms_othr_cnt, 
			acs.active_cnst_cnt, 
			acs.active_all_trans_cnst_cnt, 
			acs.multi_lob_cnt, 
			acs.multi_lob_all_trans_cnt, 
			acs.active_multi_ever_cnt,
			acs.four_lob_cnt,
			acs.three_lob_cnt,
			acs.two_lob_cnt,
			acs.fr_bio_cnt,
			acs.fr_phss_cnt,
			acs.fr_vms_cnt,
			acs.bio_phss_cnt,
			acs.bio_vms_cnt,
			acs.vol_phss_cnt
		from (
		
			SELECT 
				Current_Date,
				Cast(cnst_typ_cd AS VARCHAR(3)) AS cnst_typ_cd,
				Sum(active_all_trans_fr_ind),
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_all_trans_fr_ind ELSE 0 end) AS active_all_trans_fr_only_ind,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_all_trans_fr_ind ELSE 0 end) AS active_all_trans_fr_othr_ind,
				Sum(active_all_trans_bio_ind),
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_all_trans_bio_ind ELSE 0 end) AS active_all_trans_bio_only_ind,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_all_trans_bio_ind ELSE 0 end) AS active_all_trans_bio_othr_ind,
				Sum(active_dmw_ind) AS active_dmw_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_dmw_ind ELSE 0 end) AS active_dmw_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_dmw_ind ELSE 0 end) AS active_dmw_othr_cnt,		
				Sum(active_dmw_course_ind) AS active_dmw_course_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_dmw_course_ind ELSE 0 end) AS active_dmw_course_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_dmw_course_ind ELSE 0 end) AS active_dmw_course_othr_cnt,
				Sum(active_dmw_store_ind) AS active_dmw_store_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_dmw_store_ind ELSE 0 end) AS active_dmw_store_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_dmw_store_ind ELSE 0 end) AS active_dmw_store_othr_cnt,
				Sum(CASE WHEN active_dmw_course_ind = 1 AND active_dmw_store_ind = 0 THEN active_dmw_course_ind ELSE 0 end) AS active_dmw_course_nostore_ind,
				Sum(CASE WHEN active_dmw_store_ind = 1 AND active_dmw_course_ind = 0 THEN active_dmw_course_ind ELSE 0 end) AS active_dmw_store_nocourse_ind,	
				Sum(active_rcs_ind) AS active_rcs_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_rcs_ind ELSE 0 end) AS active_rcs_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_rcs_ind ELSE 0 end) AS active_rcs_othr_cnt,
				Sum(active_phss_ind) AS active_phss_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_phss_ind ELSE 0 end) AS active_phss_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_phss_ind ELSE 0 end) AS active_phss_othr_cnt,
				Sum(active_phss_rcs_ind) AS active_phss_rcs_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_phss_rcs_ind ELSE 0 end) AS active_phss_rcs_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_phss_rcs_ind ELSE 0 end) AS active_phss_rcs_othr_cnt,
				Sum(rcs_month_lapsed_ind), /* Identifies constituents where their last store purchase was greater the 24 months ago but within 25 monts */
				Sum(rcs_new_cnst_ind),  /* Identifies constituents where their first store purchase was within the last month */
				Sum(phss_month_lapsed_ind), /* Identifies learners where their last course completion date was greater the 24 months ago but within 25 monts */
				Sum(phss_new_cnst_ind), /* Identifies learners where their first course completion date was within the last month */	
				Sum(active_vms_ind),
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_vms_ind ELSE 0 end) AS active_all_trans_vms_only_ind,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_vms_ind ELSE 0 end) AS active_all_trans_vms_othr_ind,
				Sum(active_cnst_ind) AS active_cnst_cnt,
				Sum(active_all_trans_cnst_ind) AS active_all_trans_cnst_cnt,
				Sum(multi_lob_ind) AS multi_lob_cnt,
				Sum(multi_lob_all_trans_ind) AS multi_lob_all_trans_cnt,
		--		Sum(active_multi_ever_ind) AS active_multi_ever_cnt,
				Sum(
				CASE WHEN (active_all_trans_fr_ind = 1 
							AND Coalesce(last_donat_dt, first_vol_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
						OR (active_all_trans_bio_ind = 1
							AND Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, first_vol_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
						OR (active_vms_ind = 1
							AND Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, last_donat_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
						OR (active_dmw_ind = 1
							AND (Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, last_donat_dt, first_vol_dt, DATE '1900-01-01') <> DATE '1900-01-01'))
						OR multi_lob_all_trans_ind = 1
					THEN 1 
					ELSE 0
				end ) AS active_multi_ever_cnt,		
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 4 THEN 1 ELSE 0 end) AS four_lob_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 3 THEN 1 ELSE 0 end) AS three_lob_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 THEN 1 ELSE 0 end) AS two_lob_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_fr_ind = 1 AND active_all_trans_bio_ind = 1 THEN 1 ELSE 0 end) AS fr_bio_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_fr_ind = 1 AND active_dmw_ind = 1 THEN 1 ELSE 0 end) AS fr_phss_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_fr_ind = 1 AND active_vms_ind = 1 THEN 1 ELSE 0 end) AS fr_vms_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_bio_ind = 1 AND active_dmw_ind = 1 THEN 1 ELSE 0 end) AS bio_phss_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_bio_ind = 1 AND active_vms_ind = 1 THEN 1 ELSE 0 end) AS bio_vol_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_vms_ind = 1 AND active_dmw_ind = 1 THEN 1 ELSE 0 end) AS vol_phss_cnt
			FROM  mktg_ops_vws.bzfc_active_cnst_segmnt 
			GROUP BY 1,2
		
		)acs (snapsht_dt, cnst_typ_cd, 
				active_all_trans_fr_cnt, active_all_trans_fr_only_cnt, active_all_trans_fr_othr_cnt, 
				active_all_trans_bio_cnt, active_all_trans_bio_only_cnt, active_all_trans_bio_othr_cnt, 
				active_dmw_cnt, 
				active_dmw_only_cnt, 
				active_dmw_othr_cnt,
				active_dmw_course_cnt, active_dmw_course_only_cnt, active_dmw_course_othr_cnt, 
				active_dmw_store_cnt, active_dmw_store_only_cnt, active_dmw_store_othr_cnt, 
				active_dmw_course_nostore_ind, 
				active_dmw_store_nocourse_ind,
				active_rcs_cnt, active_rcs_only_cnt, active_rcs_othr_cnt,
				active_phss_cnt, active_phss_only_cnt, active_phss_othr_cnt,
				active_phss_rcs_cnt, active_phss_rcs_only_cnt, active_phss_rcs_othr_cnt,
				rcs_month_lapsed_cnt, rcs_month_new_active_cnt, 
				phss_month_lapsed_cnt, phss_month_new_active_cnt, 
				active_vms_cnt, active_vms_only_cnt, active_vms_othr_cnt,
				active_cnst_cnt, active_all_trans_cnst_cnt, multi_lob_cnt, multi_lob_all_trans_cnt,
				active_multi_ever_cnt,
				four_lob_cnt,three_lob_cnt,two_lob_cnt,fr_bio_cnt,fr_phss_cnt,fr_vms_cnt,
			    bio_phss_cnt,bio_vms_cnt,vol_phss_cnt)
		
		LEFT JOIN /*  This section returns the new donor counts by LOB for the prior month  */
		(
		SELECT
				ab.cnst_typ_cd, 
				Sum(CASE WHEN frg.fr_first_dntn_dt >= Add_Months( Current_Date, -1)  AND frg.fr_first_dntn_dt < (Current_Date) THEN 1 ELSE 0 end) AS fr_month_new_active_cnt,
				Sum(CASE WHEN biog.fst_donat_dt >= Add_Months( Current_Date, -1)  AND biog.fst_donat_dt < (Current_Date) THEN 1 ELSE 0 end) AS bio_month_new_active_cnt,
				Sum(CASE WHEN rcsg.first_rcs_order_dt >= Add_Months( Current_Date, -1)  AND rcsg.first_rcs_order_dt < (Current_Date) THEN 1 ELSE 0 end) AS rcs_month_new_active_cnt,
				Sum(CASE WHEN phssg.fst_crs_cmptn_dt >= Add_Months( Current_Date, -1)  AND phssg.fst_crs_cmptn_dt < (Current_Date) THEN 1 ELSE 0 end) AS phss_month_new_active_cnt,
				Sum(CASE WHEN dmwg.first_dmw_order_dt >=  Add_Months( Current_Date, -1)  AND dmwg.first_dmw_order_dt< (Current_Date)  THEN 1 ELSE 0 end) AS dmw_month_new_active_cnt,
				Sum(CASE WHEN (frg.fr_first_dntn_dt >= Add_Months( Current_Date, -1)  AND frg.fr_first_dntn_dt < (Current_Date)) OR 
											(biog.fst_donat_dt >= Add_Months( Current_Date, -1)  AND biog.fst_donat_dt < (Current_Date))  OR
											(dmwg.first_dmw_order_dt >=  Add_Months( Current_Date, -1)  AND dmwg.first_dmw_order_dt< (Current_Date)) 
				/*							(phssg.fst_crs_cmptn_dt >= add_months( current_date, -1)  and phssg.fst_crs_cmptn_dt < (current_date)) or  */
				/*								(rcsg.first_rcs_order_dt >= add_months( current_date, -1)  and rcsg.first_rcs_order_dt < (current_date))   */
											THEN 1 ELSE 0 end) AS total_month_new_active_cnt
			FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
			LEFT JOIN /* FR New Cnsts */
			(
				SELECT
					ab.cnst_mstr_id, 
					fr_first_dntn_dt
				FROM mktg_ops_vws.gms_arc_fr_smry a
				LEFT JOIN eda.arc_mdm_vws.bzfc_arc_best_smry ab ON a.cnst_mstr_id = ab.cnst_mstr_id
				WHERE  fr_first_dntn_dt >= Add_Months( Current_Date, -1)  AND fr_first_dntn_dt < (Current_Date) 
			) frg (cnst_mstr_id, fr_first_dntn_dt) ON ab.cnst_mstr_id = frg.cnst_mstr_id
			LEFT JOIN /* Bio New Cnsts */
			(
				SELECT 
					ab.cnst_mstr_id, 
					fst_donat_dt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
				LEFT JOIN mktg_ops_vws.arc_biomed_smry bs ON ab.cnst_mstr_id = bs.cnst_mstr_id 
				WHERE  fst_donat_dt >= Add_Months( Current_Date, -1)  AND 
								fst_donat_dt < (Current_Date) AND
								(ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_dbl_red_cnt) > 0 
			) biog (cnst_mstr_id, fst_donat_dt) ON ab.cnst_mstr_id = biog.cnst_mstr_id
			LEFT JOIN /* The query below returns the PHSS constituents added within the prior month */	
			(
				SELECT
					ab.cnst_mstr_id, 
					fst_crs_cmptn_dt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab 
				LEFT JOIN mktg_ops_vws.arc_phss_smry ps ON ab.cnst_mstr_id = ps.cnst_mstr_id
				WHERE  fst_crs_cmptn_dt >= Add_Months( Current_Date, -1)  AND fst_crs_cmptn_dt < (Current_Date)
			) phssg (cnst_mstr_id, fst_crs_cmptn_dt) ON  ab.cnst_mstr_id = phssg.cnst_mstr_id			
			LEFT JOIN /* The query below returns the Red Cross Store constituents added within the prior month */	
			(
				SELECT 
					ab.cnst_mstr_id,
					first_rcs_order_dt
			    FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
			    LEFT JOIN 
				(
					SELECT 
						b.cnst_mstr_id,
						Min(Cast(odr_create_ts AS DATE)) AS first_rcs_order_dt
					FROM arc_store_tbls.dim_odr a
					LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge b ON a.billing_prsn_key = b.cnst_mstr_subj_area_id AND b.cnst_mstr_subj_area_cd = 'RCST'
					WHERE Cast(odr_create_ts AS DATE ) BETWEEN Add_Months(Current_Date, -24) AND (Current_Date)
				GROUP BY 1
				) rcs (cnst_mstr_id, first_rcs_order_dt) ON ab.cnst_mstr_id = rcs.cnst_mstr_id
				WHERE  first_rcs_order_dt >= Add_Months( Current_Date, -1)  AND first_rcs_order_dt < (Current_Date)
			) rcsg (cnst_mstr_id, first_rcs_order_dt) ON ab.cnst_mstr_id = rcsg.cnst_mstr_id
			LEFT JOIN /* The query below returns the DemandWare constituents added within the prior month */	
			(
			 /* DemandWare New Constituents */
				SELECT 
					cnst_mstr_id,
					first_dmw_order_dt
				 FROM mktg_ops_vws.bzfc_active_cnst_segmnt 
				 WHERE first_dmw_order_dt >=  Add_Months( Current_Date, -1)  AND first_dmw_order_dt< (Current_Date) 
			) dmwg (cnst_mstr_id, first_dmw_order_dt)  ON ab.cnst_mstr_id = dmwg.cnst_mstr_id
			GROUP BY 1
		
		)lob_new (cnst_typ_cd, fr_month_new_active_cnt, bio_month_new_active_cnt, rcs_month_new_active_cnt, phss_month_new_active_cnt, dmw_month_new_active_cnt, total_month_new_active_cnt)  ON acs.cnst_typ_cd = lob_new.cnst_typ_cd
		
		LEFT JOIN /* This section returns the lapsed constituent counts by LOB for the past month */
		(
			SELECT
				ab.cnst_typ_cd,
				Sum(CASE WHEN ab.lst_fr_dntn_dt < Add_Months( Current_Date, -24)  AND ab.lst_fr_dntn_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS fr_month_lapsed_cnt,
				Sum(CASE WHEN frs.cnst_mstr_id IS NOT NULL AND (coalesce(fr_ry0_dntn_amt,0) + coalesce(fr_ry1_dntn_amt,0)) <= 0 THEN 1 ELSE 0 end) AS active_zero_gift_amt_cnt,
				Sum(CASE WHEN frs.cnst_mstr_id IS NULL THEN 1 ELSE 0 end) AS active_secondary_cnt,
				Sum(CASE WHEN last_donat_dt < Add_Months( Current_Date, -24)  AND last_donat_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS bio_month_lapsed_cnt,
		    	Sum(CASE WHEN last_rcs_order_dt < Add_Months( Current_Date, -24)  AND last_rcs_order_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS rcs_month_lapsed_cnt,
			   	Sum(CASE WHEN last_crs_cmptn_dt < Add_Months( Current_Date, -24)  AND last_crs_cmptn_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS phss_month_lapsed_cnt,
			   	Sum(CASE WHEN last_dmw_order_dt < Add_Months( Current_Date, -24)  AND last_dmw_order_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS dmw_month_lapsed_cnt,
				Sum(CASE WHEN ab.lst_fr_dntn_dt <  Add_Months( Current_Date, -24)  AND ab.lst_fr_dntn_dt >= Add_Months( Current_Date, -25)  OR 
											
		"last_donat_dt"  <  Add_Months( Current_Date, -24)  AND last_donat_dt >= Add_Months( Current_Date, -25)  OR 
											last_dmw_order_dt < Add_Months( Current_Date, -24)  AND last_dmw_order_dt >= Add_Months( Current_Date, -25) 
				/*							last_rcs_order_dt < add_months( current_date, -24)  and last_rcs_order_dt >= add_months( current_date, -25)  or  */
				/*							last_crs_cmptn_dt < add_months( current_date, -24)  and last_crs_cmptn_dt >= add_months( current_date, -25)  */
				THEN 1 ELSE 0 end) AS total_month_lapsed_cnt
			FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
			LEFT JOIN /* FR Lapsed */
				(
					SELECT
						ab.cnst_mstr_id,
						ab.lst_fr_dntn_dt,
						fr_ry0_dntn_amt,
						fr_ry1_dntn_amt
					FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab 
					LEFT JOIN mktg_ops_vws.gms_arc_fr_smry frs  ON ab.cnst_mstr_id = frs.cnst_mstr_id 
					WHERE ab.lst_fr_dntn_dt < Add_Months( Current_Date, -24)  AND ab.lst_fr_dntn_dt >= Add_Months( Current_Date, -25) 
				) frs (cnst_mstr_id,	lst_fr_dntn_dt,	fr_ry0_dntn_amt,	fr_ry1_dntn_amt) ON ab.cnst_mstr_id = frs.cnst_mstr_id
			LEFT JOIN  /* Bio Lapsed */
				(
					SELECT 
						ab.cnst_mstr_id,
						last_donat_dt
					FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
					LEFT JOIN mktg_ops_vws.arc_biomed_smry bs ON ab.cnst_mstr_id = bs.cnst_mstr_id 
					WHERE last_donat_dt < Add_Months( Current_Date, -24)  AND last_donat_dt >= Add_Months( Current_Date, -25)  AND (lftm_prodctv_wb_cnt + lftm_prodctv_pltpheresis_cnt + lftm_prodctv_red_cell_cnt + lftm_prodctv_dbl_red_cnt)  > 0  
				)  bs (cnst_mstr_id, last_donat_dt) ON ab.cnst_mstr_id = bs.cnst_mstr_id 
			
			LEFT JOIN /* The query below returns the Red Cross Store constituents that lapsed within the last month */	
				(
					SELECT 
						ab.cnst_mstr_id,
						last_rcs_order_dt
				    FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
					 LEFT JOIN 
					(
						SELECT 
							b.cnst_mstr_id,
							Min(Cast(odr_create_ts AS DATE)) AS first_rcs_order_dt,
							Max(Cast(odr_create_ts AS DATE)) AS last_rcs_order_dt
						FROM arc_store_tbls.dim_odr a
						LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge b ON a.billing_prsn_key = b.cnst_mstr_subj_area_id AND b.cnst_mstr_subj_area_cd = 'RCST'
						WHERE Cast(odr_create_ts AS DATE) BETWEEN Add_Months(Current_Date, -24) AND (Current_Date)
					GROUP BY 1
					) rcs (cnst_mstr_id, first_rcs_order_dt, last_rcs_order_dt) ON ab.cnst_mstr_id = rcs.cnst_mstr_id
					WHERE  last_rcs_order_dt < Add_Months( Current_Date, -24)  AND last_rcs_order_dt >= Add_Months( Current_Date, -25) 
				) rcsl (cnst_mstr_id, last_rcs_order_dt) ON ab.cnst_mstr_id = rcsl.cnst_mstr_id
			LEFT JOIN /* PHSS Lapsed */
				(
					SELECT
						ab.cnst_mstr_id,
						last_crs_cmptn_dt
					FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab 
					LEFT JOIN mktg_ops_vws.arc_phss_smry ps ON ab.cnst_mstr_id = ps.cnst_mstr_id
					WHERE  last_crs_cmptn_dt < Add_Months( Current_Date, -24)  AND last_crs_cmptn_dt >= Add_Months( Current_Date, -25)  
				) ps (cnst_mstr_id, last_crs_cmptn_dt) ON ab.cnst_mstr_id = ps.cnst_mstr_id 
			LEFT JOIN /* DemandWare Lapsed */
			 /* DemandWare Lapsed Constituents */
			 (
				 SELECT 
				 	cnst_mstr_id,
				 	last_dmw_order_dt
				 FROM 
				(
					SELECT 
						prsn.cnst_mstr_id,
						Min(cal.calendar_dt) AS first_dmw_order_dt,
						Max(cal.calendar_dt) AS last_dmw_order_dt
					 FROM eda.uhss_vws.sfbz_dim_odr odr
					 LEFT JOIN eda.uhss_vws.sfbz_dim_prsn_addr prsn ON odr.billing_prsn_addr_key = prsn.prsn_addr_key
					 LEFT JOIN eda.dw_common_vws.dim_calendar cal ON odr.odr_dt_key = cal.calendar_key
					 LEFT JOIN 
					 	(
					 		SELECT odr_key, 1 AS prod_odr_ind, Count(*) AS odr_line_cnt
					 		FROM eda.uhss_vws.sfbz_fact_product_ln
					 		GROUP BY 1,2
					 	) Prod (odr_key, prod_odr_ind, odr_line_cnt) ON  odr.odr_key = Prod.odr_key
					 LEFT JOIN 
					 	(
					 		SELECT odr_key, 1 AS crs_odr_ind, Count(*) AS odr_line_cnt
					 		FROM eda.uhss_vws.sfbz_fact_course_ln
					 		GROUP BY 1,2
					 	) crs  (odr_key, crs_odr_ind, odr_line_cnt) ON  odr.odr_key = crs.odr_key
					WHERE odr.odr_stat_cd <> 'CANCELLED'
					GROUP BY 1
				) a (cnst_mstr_id, first_dmw_order_dt, last_dmw_order_dt)
				WHERE last_dmw_order_dt <  Add_Months( Current_Date, -24)  AND last_dmw_order_dt >= Add_Months( Current_Date, -25)  
			) dmwl(cnst_mstr_id, last_dmw_order_dt) ON ab.cnst_mstr_id = dmwl.cnst_mstr_id 	
		GROUP BY 1
		
		)lob_lapse (cnst_typ_cd, fr_month_lapsed_cnt, active_zero_gift_amt_cnt, active_secondary_cnt, bio_month_lapsed_cnt, rcs_month_lapsed_cnt, phss_month_lapsed_cnt, dmw_month_lapsed_cnt, total_month_lapsed_cnt) ON acs.cnst_typ_cd = lob_lapse.cnst_typ_cd
		
		LEFT JOIN 	/* Constituent Reactivation Section */
		(
		SELECT
				ab.cnst_typ_cd,
				Sum(CASE WHEN (frr.fr_last_dntn_dt >= Add_Months( Current_Date, -1)  AND frr.fr_last_dntn_dt < (Current_Date)) AND (frr.fr_ry0_dntn_cnt + frr.fr_ry1_dntn_cnt = 1) AND ( frr.fr_lftm_dntn_cnt > 1) THEN 1 ELSE 0 end) AS fr_month_reactivated_cnt,
				Sum(CASE WHEN (last_donat_dt >= Add_Months( Current_Date, -1)  AND last_donat_dt < (Current_Date)) AND 
						(ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_plspheresis_cnt + ry0_prodctv_dbl_red_cnt  + 
						ry1_prodctv_wb_cnt + ry1_prodctv_pltpheresis_cnt + ry1_prodctv_red_cell_cnt + ry1_prodctv_plspheresis_cnt + ry1_prodctv_dbl_red_cnt = 1) AND 
						( lftm_prodctv_wb_cnt + lftm_prodctv_pltpheresis_cnt + lftm_prodctv_red_cell_cnt + lftm_prodctv_plspheresis_cnt + lftm_prodctv_dbl_red_cnt > 1) THEN 1 ELSE 0 end) AS bio_month_reactivated_cnt,
				Sum(CASE WHEN (last_crs_cmptn_dt >= Add_Months( Current_Date, -1)  AND last_crs_cmptn_dt < (Current_Date)) AND (phssr.lapsed_end_dt IS NOT NULL) AND ( lftm_crs_complt_cnt > 1) THEN 1 ELSE 0 end) AS phss_month_reactivated_cnt,
				Sum(CASE WHEN (dmwr.last_dmw_order_dt >= Add_Months( Current_Date, -1)) THEN 1 ELSE 0 end) AS dmw_month_reactivated_cnt,
				Sum(CASE WHEN ((frr.fr_last_dntn_dt >= Add_Months( Current_Date, -1)  AND frr.fr_last_dntn_dt < (Current_Date)) AND (frr.fr_ry0_dntn_cnt + frr.fr_ry1_dntn_cnt = 1) AND ( frr.fr_lftm_dntn_cnt > 1)) OR
											((last_donat_dt >= Add_Months( Current_Date, -1)  AND last_donat_dt < (Current_Date)) AND 
						(ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_plspheresis_cnt + ry0_prodctv_dbl_red_cnt  + 
						ry1_prodctv_wb_cnt + ry1_prodctv_pltpheresis_cnt + ry1_prodctv_red_cell_cnt + ry1_prodctv_plspheresis_cnt + ry1_prodctv_dbl_red_cnt = 1) AND 
						( lftm_prodctv_wb_cnt + lftm_prodctv_pltpheresis_cnt + lftm_prodctv_red_cell_cnt + lftm_prodctv_plspheresis_cnt + lftm_prodctv_dbl_red_cnt > 1)) OR
						dmwr.last_dmw_order_dt IS NOT NULL
					/*	 ((last_crs_cmptn_dt >= add_months( current_date, -1)  and last_crs_cmptn_dt < (current_date)) and (phssr.lapsed_end_dt is not null) and ( lftm_crs_complt_cnt > 1)) */
						THEN 1 ELSE 0 end) AS total_month_reactivated_cnt
			FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
			LEFT JOIN /* The query below returns the FR constituents that re-activated in the prior month */
			(
				SELECT
					ab.cnst_mstr_id,
					fr_last_dntn_dt,
					fr_ry0_dntn_cnt,
					fr_ry1_dntn_cnt,
					fr_lftm_dntn_cnt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
				LEFT JOIN mktg_ops_vws.gms_arc_fr_smry frs ON ab.cnst_mstr_id = frs.cnst_mstr_id
				WHERE (fr_last_dntn_dt >= Add_Months( Current_Date, -1)  AND fr_last_dntn_dt < (Current_Date)) AND (fr_ry0_dntn_cnt + fr_ry1_dntn_cnt = 1) AND ( fr_lftm_dntn_cnt > 1)
			) frr (cnst_mstr_id, fr_last_dntn_dt, fr_ry0_dntn_cnt, fr_ry1_dntn_cnt, 	fr_lftm_dntn_cnt) ON ab.cnst_mstr_id = frr.cnst_mstr_id
			LEFT JOIN /* The query below returns the Bio constituents reactivated within the prior month */	
			(
				SELECT 
					ab.cnst_mstr_id,
					 last_donat_dt, ry0_prodctv_wb_cnt, ry0_prodctv_pltpheresis_cnt, ry0_prodctv_red_cell_cnt, ry0_prodctv_plspheresis_cnt, ry0_prodctv_dbl_red_cnt, 	ry1_prodctv_wb_cnt,
					 ry1_prodctv_pltpheresis_cnt, ry1_prodctv_red_cell_cnt, ry1_prodctv_plspheresis_cnt, ry1_prodctv_dbl_red_cnt, 
					  lftm_prodctv_wb_cnt, lftm_prodctv_pltpheresis_cnt, lftm_prodctv_red_cell_cnt, lftm_prodctv_plspheresis_cnt, lftm_prodctv_dbl_red_cnt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
				LEFT JOIN mktg_ops_vws.arc_biomed_smry bs ON ab.cnst_mstr_id = bs.cnst_mstr_id 
				WHERE  (ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_dbl_red_cnt) > 0 AND
							(last_donat_dt >= Add_Months( Current_Date, -1)  AND last_donat_dt < (Current_Date)) AND 
							(ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_plspheresis_cnt + ry0_prodctv_dbl_red_cnt  + 
							ry1_prodctv_wb_cnt + ry1_prodctv_pltpheresis_cnt + ry1_prodctv_red_cell_cnt + ry1_prodctv_plspheresis_cnt + ry1_prodctv_dbl_red_cnt = 1) AND 
							( lftm_prodctv_wb_cnt + lftm_prodctv_pltpheresis_cnt + lftm_prodctv_red_cell_cnt + lftm_prodctv_plspheresis_cnt + lftm_prodctv_dbl_red_cnt > 1)
			) bior (cnst_mstr_id, last_donat_dt, ry0_prodctv_wb_cnt, ry0_prodctv_pltpheresis_cnt, ry0_prodctv_red_cell_cnt, ry0_prodctv_plspheresis_cnt, ry0_prodctv_dbl_red_cnt, 	ry1_prodctv_wb_cnt,
					 ry1_prodctv_pltpheresis_cnt, ry1_prodctv_red_cell_cnt, ry1_prodctv_plspheresis_cnt, ry1_prodctv_dbl_red_cnt, 
					  lftm_prodctv_wb_cnt, lftm_prodctv_pltpheresis_cnt, lftm_prodctv_red_cell_cnt, lftm_prodctv_plspheresis_cnt, lftm_prodctv_dbl_red_cnt) ON ab.cnst_mstr_id = bior.cnst_mstr_id
			LEFT JOIN /* The query below returns the PHSS constituents reactivated within the prior month */		
			(
				SELECT
					ab.cnst_mstr_id,
					last_crs_cmptn_dt,
					phr.lapsed_end_dt,
					lftm_crs_complt_cnt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab 
				LEFT JOIN mktg_ops_vws.arc_phss_smry ps ON ab.cnst_mstr_id = ps.cnst_mstr_id
				LEFT JOIN 
				(
					SELECT 
						ps.cnst_mstr_id, Max(offer_end_dt)
					FROM mktg_ops_vws.arc_phss_smry ps 
					LEFT JOIN mktg_ops_vws.arc_phss_txn px ON px.cnst_mstr_id = ps.cnst_mstr_id
					WHERE  course_compl_stat = 'COURSE SUCCESS'  AND offer_end_dt < last_crs_cmptn_dt
					GROUP BY 1
					HAVING Max(offer_end_dt) <  Add_Months( Current_Date, -24) 
				) phr (cnst_mstr_id, lapsed_end_dt) ON ab.cnst_mstr_id = phr.cnst_mstr_id
				WHERE (last_crs_cmptn_dt >= Add_Months( Current_Date, -1)  AND last_crs_cmptn_dt < (Current_Date)) AND (phr.lapsed_end_dt IS NOT NULL) AND ( lftm_crs_complt_cnt > 1)
			) phssr (cnst_mstr_id, last_crs_cmptn_dt,lapsed_end_dt,  lftm_crs_complt_cnt) ON  ab.cnst_mstr_id = phssr.cnst_mstr_id		
			LEFT JOIN /* The query below returns the DemandWard constituents reactivated within the prior month */		
			(	
				SELECT 
					a.cnst_mstr_id,
					last_dmw_order_dt,
					prev_dmw_order_dt
				FROM
				(	
						 SELECT 
						 	cnst_mstr_id,
						 	last_dmw_order_dt
						 FROM 
						(
							SELECT 
								prsn.cnst_mstr_id,
								Min(cal.calendar_dt) AS first_dmw_order_dt,
								Max(cal.calendar_dt) AS last_dmw_order_dt
							 FROM eda.uhss_vws.sfbz_dim_odr odr
							 LEFT JOIN eda.uhss_vws.sfbz_dim_prsn_addr prsn ON odr.billing_prsn_addr_key = prsn.prsn_addr_key
							 LEFT JOIN eda.dw_common_vws.dim_calendar cal ON odr.odr_dt_key = cal.calendar_key
							WHERE odr.odr_stat_cd <> 'CANCELLED'
							GROUP BY 1
						) a (cnst_mstr_id, first_dmw_order_dt, last_dmw_order_dt)
						WHERE last_dmw_order_dt <=  Current_Date  AND last_dmw_order_dt > Add_Months( Current_Date, -1)  
				
				) a (cnst_mstr_id, last_dmw_order_dt)
					JOIN
				(
					select cnst_mstr_id,prev_dmw_order_dt
					from (
					
							SELECT 
									prsn.cnst_mstr_id,
									cal.calendar_dt AS prev_dmw_order_dt,
									Row_Number() Over ( PARTITION BY prsn.cnst_mstr_id ORDER BY cal.calendar_dt DESC ) as rn
								 FROM eda.uhss_vws.sfbz_dim_odr odr
								 LEFT JOIN eda.uhss_vws.sfbz_dim_prsn_addr prsn ON odr.billing_prsn_addr_key = prsn.prsn_addr_key
								 LEFT JOIN eda.dw_common_vws.dim_calendar cal ON odr.odr_dt_key = cal.calendar_key
								WHERE odr.odr_stat_cd <> 'CANCELLED'
					      ) as subqry
						where subqry.rn=2
					
				) b (cnst_mstr_id, prev_dmw_order_dt) ON a.cnst_mstr_id = b.cnst_mstr_id
				WHERE b.prev_dmw_order_dt 	<  Add_Months( Current_Date, -24)	
			) dmwr (cnst_mstr_id, last_dmw_order_dt, prev_dmw_order_dt) ON  ab.cnst_mstr_id = dmwr.cnst_mstr_id	
			GROUP BY 1
		
		)lob_react (cnst_typ_cd, fr_month_reactivated_cnt, bio_month_reactivated_cnt, phss_month_reactivated_cnt, dmw_month_reactivated_cnt, total_month_reactivated_cnt) ON acs.cnst_typ_cd = lob_react.cnst_typ_cd
		
		UNION
		
		/* This section was added to include a summary row in the snapshot table to sum the Org and Indiv ('OR, 'IN') records from the query above - so 3 records get written to in the snapshot) */
		
		SELECT 
			acs.snapsht_dt, 
			acs.cnst_typ_cd, 
			acs.active_all_trans_fr_cnt, 
			acs.active_all_trans_fr_only_cnt, 
			acs.active_all_trans_fr_othr_cnt, 
			lob_lapse.fr_month_lapsed_cnt, 
			lob_new.fr_month_new_active_cnt, 
			lob_react.fr_month_reactivated_cnt,
			acs.active_all_trans_bio_cnt, 
			acs.active_all_trans_bio_only_cnt, 
			acs.active_all_trans_bio_othr_cnt, 
			coalesce(lob_lapse.bio_month_lapsed_cnt,0) AS bio_month_lapsed_cnt, 
			coalesce(lob_new.bio_month_new_active_cnt,0) AS bio_month_new_active_cnt, 
			coalesce(lob_react.bio_month_reactivated_cnt,0) AS bio_month_reactivated_cnt,
			coalesce(acs.active_dmw_cnt,0) AS active_dmw_cnt, 
			coalesce(acs.active_dmw_only_cnt,0) AS active_dmw_only_cnt, 
			coalesce(acs.active_dmw_othr_cnt,0) AS active_dmw_othr_cnt,
			coalesce(acs.active_dmw_course_cnt,0) AS active_dmw_course_cnt, 
			coalesce(acs.active_dmw_course_only_cnt,0) AS active_dmw_course_only_cnt, 
			coalesce(acs.active_dmw_course_othr_cnt,0) AS active_dmw_course_othr_cnt,
			coalesce(acs.active_dmw_store_cnt,0) AS active_dmw_store_cnt, 
			coalesce(acs.active_dmw_store_only_cnt,0) AS active_dmw_store_only_cnt, 
			coalesce(acs.active_dmw_store_othr_cnt,0) AS active_dmw_store_othr_cnt,
			coalesce(acs.active_dmw_course_nostore_ind,0) AS active_dmw_course_nostore_ind, 
			coalesce(acs.active_dmw_store_nocourse_ind,0) AS active_dmw_store_nocourse_ind,
			coalesce(acs.active_rcs_cnt,0) AS active_rcs_cnt, 
			coalesce(acs.active_rcs_only_cnt,0) AS active_rcs_only_cnt, 
			coalesce(acs.active_rcs_othr_cnt,0) AS active_rcs_othr_cnt,
			coalesce(acs.active_phss_cnt,0) AS active_phss_cnt, 
			coalesce(acs.active_phss_only_cnt,0) AS active_phss_only_cnt, 
			coalesce(acs.active_phss_othr_cnt,0) AS active_phss_othr_cnt,
			coalesce(acs.active_phss_rcs_cnt,0) AS active_phss_rcs_cnt, 
			coalesce(acs.active_phss_rcs_only_cnt,0) AS active_phss_rcs_only_cnt, 
			coalesce(acs.active_phss_rcs_othr_cnt,0) AS active_phss_rcs_othr_cnt,
			lob_lapse.rcs_month_lapsed_cnt, 
			lob_new.rcs_month_new_active_cnt, 
			lob_lapse.phss_month_lapsed_cnt, 
			lob_new.phss_month_new_active_cnt, 
			lob_react.phss_month_reactivated_cnt,
			lob_lapse.dmw_month_lapsed_cnt, 
			lob_new.dmw_month_new_active_cnt, 
			lob_react.dmw_month_reactivated_cnt,
			lob_lapse.total_month_lapsed_cnt, 
			lob_new.total_month_new_active_cnt, 
			lob_react.total_month_reactivated_cnt,	
			acs.active_vms_cnt, 
			acs.active_vms_only_cnt, 
			acs.active_vms_othr_cnt, 
			acs.active_cnst_cnt, 
			acs.active_all_trans_cnst_cnt, 
			acs.multi_lob_cnt, 
			acs.multi_lob_all_trans_cnt,
			acs.active_multi_ever_cnt,
			acs.four_lob_cnt,
			acs.three_lob_cnt,
			acs.two_lob_cnt,
			acs.fr_bio_cnt,
			acs.fr_phss_cnt,
			acs.fr_vms_cnt,
			acs.bio_phss_cnt,
			acs.bio_vms_cnt,
			acs.vol_phss_cnt
		from
		(
			SELECT 
				Current_Date,
				Cast('ALL' AS VARCHAR(3)) AS cnst_typ_cd,
				Sum(active_all_trans_fr_ind),
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_all_trans_fr_ind ELSE 0 end) AS active_all_trans_fr_only_ind,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_all_trans_fr_ind ELSE 0 end) AS active_all_trans_fr_othr_ind,
				Sum(active_all_trans_bio_ind),
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_all_trans_bio_ind ELSE 0 end) AS active_all_trans_bio_only_ind,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_all_trans_bio_ind ELSE 0 end) AS active_all_trans_bio_othr_ind,
				Sum(active_dmw_ind) AS active_dmw_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_dmw_ind ELSE 0 end) AS active_dmw_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_dmw_ind ELSE 0 end) AS active_dmw_othr_cnt,
				Sum(active_dmw_course_ind) AS active_dmw_course_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_dmw_course_ind ELSE 0 end) AS active_dmw_course_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_dmw_course_ind ELSE 0 end) AS active_dmw_course_othr_cnt,
				Sum(active_dmw_store_ind) AS active_dmw_store_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_dmw_store_ind ELSE 0 end) AS active_dmw_store_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_dmw_store_ind ELSE 0 end) AS active_dmw_store_othr_cnt,
				Sum(CASE WHEN active_dmw_course_ind = 1 AND active_dmw_store_ind = 0 THEN active_dmw_course_ind ELSE 0 end) AS active_dmw_course_nostore_ind,
				Sum(CASE WHEN active_dmw_store_ind = 1 AND active_dmw_course_ind = 0 THEN active_dmw_course_ind ELSE 0 end) AS active_dmw_store_nocourse_ind,	
				Sum(active_rcs_ind) AS active_rcs_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_rcs_ind ELSE 0 end) AS active_rcs_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_rcs_ind ELSE 0 end) AS active_rcs_othr_cnt,
				Sum(active_phss_ind) AS active_phss_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_phss_ind ELSE 0 end) AS active_phss_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_phss_ind ELSE 0 end) AS active_phss_othr_cnt,
				Sum(active_phss_rcs_ind) AS active_phss_rcs_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_phss_rcs_ind ELSE 0 end) AS active_phss_rcs_only_cnt,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_phss_rcs_ind ELSE 0 end) AS active_phss_rcs_othr_cnt,
				Sum(rcs_month_lapsed_ind), /* Identifies constituents where their last store purchase was greater the 24 months ago but within 25 monts */
				Sum(rcs_new_cnst_ind),  /* Identifies constituents where their first store purchase was within the last month */
				Sum(phss_month_lapsed_ind), /* Identifies learners where their last course completion date was greater the 24 months ago but within 25 monts */
				Sum(phss_new_cnst_ind), /* Identifies learners where their first course completion date was within the last month */	
				Sum(active_vms_ind),
				Sum(CASE WHEN multi_lob_all_trans_ind = 0 THEN active_vms_ind ELSE 0 end) AS active_all_trans_vms_only_ind,
				Sum(CASE WHEN multi_lob_all_trans_ind = 1 THEN active_vms_ind ELSE 0 end) AS active_all_trans_vms_othr_ind,
				Sum(active_cnst_ind) AS active_cnst_cnt,
				Sum(active_all_trans_cnst_ind) AS active_all_trans_cnst_cnt,
				Sum(multi_lob_ind) AS multi_lob_cnt,
				Sum(multi_lob_all_trans_ind) AS multi_lob_all_trans_cnt,
				--Sum(active_multi_ever_ind) AS active_multi_ever_cnt,
				Sum(
				CASE WHEN (active_all_trans_fr_ind = 1 
							AND Coalesce(last_donat_dt, first_vol_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
						OR (active_all_trans_bio_ind = 1
							AND Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, first_vol_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
						OR (active_vms_ind = 1
							AND Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, last_donat_dt, last_dmw_order_dt, last_rcs_order_dt, last_crs_cmptn_dt, DATE '1900-01-01') <> DATE '1900-01-01')
						OR (active_dmw_ind = 1
							AND (Coalesce(fr_last_dntn_dt, fr_last_dntn_dt, last_donat_dt, first_vol_dt, DATE '1900-01-01') <> DATE '1900-01-01'))
						OR multi_lob_all_trans_ind = 1
					THEN 1 
					ELSE 0
				end ) AS active_multi_ever_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 4 THEN 1 ELSE 0 end) AS four_lob_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 3 THEN 1 ELSE 0 end) AS three_lob_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 THEN 1 ELSE 0 end) AS two_lob_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_fr_ind = 1 AND active_all_trans_bio_ind = 1 THEN 1 ELSE 0 end) AS fr_bio_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_fr_ind = 1 AND active_dmw_ind = 1 THEN 1 ELSE 0 end) AS fr_phss_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_fr_ind = 1 AND active_vms_ind = 1 THEN 1 ELSE 0 end) AS fr_vms_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_bio_ind = 1 AND active_dmw_ind = 1 THEN 1 ELSE 0 end) AS bio_phss_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_all_trans_bio_ind = 1 AND active_vms_ind = 1 THEN 1 ELSE 0 end) AS bio_vol_cnt,
				Sum(CASE WHEN active_dmw_ind + active_all_trans_bio_ind + active_vms_ind + active_all_trans_fr_ind = 2 AND active_vms_ind = 1 AND active_dmw_ind = 1 THEN 1 ELSE 0 end) AS vol_phss_cnt
			FROM  mktg_ops_vws.bzfc_active_cnst_segmnt 
			GROUP BY 1,2
		
		)acs (snapsht_dt, cnst_typ_cd, 
				active_all_trans_fr_cnt, active_all_trans_fr_only_cnt, active_all_trans_fr_othr_cnt, 
				active_all_trans_bio_cnt, active_all_trans_bio_only_cnt, active_all_trans_bio_othr_cnt, 
				active_dmw_cnt, active_dmw_only_cnt, active_dmw_othr_cnt,
				active_dmw_course_cnt, active_dmw_course_only_cnt, active_dmw_course_othr_cnt, 
				active_dmw_store_cnt, active_dmw_store_only_cnt, active_dmw_store_othr_cnt, 
				active_dmw_course_nostore_ind, 
				active_dmw_store_nocourse_ind,
				active_rcs_cnt, active_rcs_only_cnt, active_rcs_othr_cnt,
				active_phss_cnt, active_phss_only_cnt, active_phss_othr_cnt,
				active_phss_rcs_cnt, active_phss_rcs_only_cnt, active_phss_rcs_othr_cnt,
				rcs_month_lapsed_cnt, rcs_month_new_active_cnt, 
				phss_month_lapsed_cnt, phss_month_new_active_cnt, 
				active_vms_cnt, active_vms_only_cnt, active_vms_othr_cnt,
				active_cnst_cnt, active_all_trans_cnst_cnt, multi_lob_cnt, multi_lob_all_trans_cnt,active_multi_ever_cnt,
				four_lob_cnt,three_lob_cnt,two_lob_cnt,fr_bio_cnt,fr_phss_cnt,fr_vms_cnt,
			    bio_phss_cnt,bio_vms_cnt,vol_phss_cnt)
		LEFT JOIN /*  This section returns the new donor counts by LOB for the prior month  */
		(
		
		
			SELECT
			Cast('ALL' AS VARCHAR(3)) AS cnst_typ_cd,
				Sum(CASE WHEN frg.fr_first_dntn_dt >= Add_Months( Current_Date, -1)  AND frg.fr_first_dntn_dt < (Current_Date) THEN 1 ELSE 0 end) AS fr_month_new_active_cnt,
				Sum(CASE WHEN biog.fst_donat_dt >= Add_Months( Current_Date, -1)  AND biog.fst_donat_dt < (Current_Date) THEN 1 ELSE 0 end) AS bio_month_new_active_cnt,
				Sum(CASE WHEN rcsg.first_rcs_order_dt >= Add_Months( Current_Date, -1)  AND rcsg.first_rcs_order_dt < (Current_Date) THEN 1 ELSE 0 end) AS rcs_month_new_active_cnt,
				Sum(CASE WHEN phssg.fst_crs_cmptn_dt >= Add_Months( Current_Date, -1)  AND phssg.fst_crs_cmptn_dt < (Current_Date) THEN 1 ELSE 0 end) AS phss_month_new_active_cnt,
				Sum(CASE WHEN dmwg.first_dmw_order_dt >=  Add_Months( Current_Date, -1)  AND dmwg.first_dmw_order_dt< (Current_Date)  THEN 1 ELSE 0 end) AS dmw_month_new_active_cnt,
				Sum(CASE WHEN (frg.fr_first_dntn_dt >= Add_Months( Current_Date, -1)  AND frg.fr_first_dntn_dt < (Current_Date)) OR 
											(biog.fst_donat_dt >= Add_Months( Current_Date, -1)  AND biog.fst_donat_dt < (Current_Date))  OR
											(dmwg.first_dmw_order_dt >=  Add_Months( Current_Date, -1)  AND dmwg.first_dmw_order_dt< (Current_Date)) 
				/*							(phssg.fst_crs_cmptn_dt >= add_months( current_date, -1)  and phssg.fst_crs_cmptn_dt < (current_date)) or  */
				/*								(rcsg.first_rcs_order_dt >= add_months( current_date, -1)  and rcsg.first_rcs_order_dt < (current_date))   */
											THEN 1 ELSE 0 end) AS total_month_new_active_cnt
			FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
			LEFT JOIN /* FR New Cnsts */
			(
				SELECT
					ab.cnst_mstr_id, 
					fr_first_dntn_dt
				FROM mktg_ops_vws.gms_arc_fr_smry a
				LEFT JOIN eda.arc_mdm_vws.bzfc_arc_best_smry ab ON a.cnst_mstr_id = ab.cnst_mstr_id
				WHERE  fr_first_dntn_dt >= Add_Months( Current_Date, -1)  AND fr_first_dntn_dt < (Current_Date) 
			) frg (cnst_mstr_id, fr_first_dntn_dt) ON ab.cnst_mstr_id = frg.cnst_mstr_id
			LEFT JOIN /* Bio New Cnsts */
			(
				SELECT 
					ab.cnst_mstr_id, 
					fst_donat_dt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
				LEFT JOIN mktg_ops_vws.arc_biomed_smry bs ON ab.cnst_mstr_id = bs.cnst_mstr_id 
				WHERE  fst_donat_dt >= Add_Months( Current_Date, -1)  AND 
								fst_donat_dt < (Current_Date) AND
								(ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_dbl_red_cnt) > 0 
			) biog (cnst_mstr_id, fst_donat_dt) ON ab.cnst_mstr_id = biog.cnst_mstr_id
			LEFT JOIN /* The query below returns the PHSS constituents added within the prior month */	
			(
				SELECT
					ab.cnst_mstr_id, 
					fst_crs_cmptn_dt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab 
				LEFT JOIN mktg_ops_vws.arc_phss_smry ps ON ab.cnst_mstr_id = ps.cnst_mstr_id
				WHERE  fst_crs_cmptn_dt >= Add_Months( Current_Date, -1)  AND fst_crs_cmptn_dt < (Current_Date)
			) phssg (cnst_mstr_id, fst_crs_cmptn_dt) ON  ab.cnst_mstr_id = phssg.cnst_mstr_id			
			LEFT JOIN /* The query below returns the Red Cross Store constituents added within the prior month */	
			(
				SELECT 
					ab.cnst_mstr_id,
					first_rcs_order_dt
			    FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
			    LEFT JOIN 
				(
					SELECT 
						b.cnst_mstr_id,
						Min(Cast(odr_create_ts AS DATE)) AS first_rcs_order_dt
					FROM arc_store_tbls.dim_odr a
					LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge b ON a.billing_prsn_key = b.cnst_mstr_subj_area_id AND b.cnst_mstr_subj_area_cd = 'RCST'
					WHERE Cast(odr_create_ts AS DATE) BETWEEN Add_Months(Current_Date, -24) AND (Current_Date)
				GROUP BY 1
				) rcs (cnst_mstr_id, first_rcs_order_dt) ON ab.cnst_mstr_id = rcs.cnst_mstr_id
				WHERE  first_rcs_order_dt >= Add_Months( Current_Date, -1)  AND first_rcs_order_dt < (Current_Date)
			) rcsg (cnst_mstr_id, first_rcs_order_dt) ON ab.cnst_mstr_id = rcsg.cnst_mstr_id
			LEFT JOIN /* The query below returns the DemandWare constituents added within the prior month */	
			(
			 /* DemandWare New Constituents */
				SELECT 
					cnst_mstr_id,
					first_dmw_order_dt
				 FROM mktg_ops_vws.bzfc_active_cnst_segmnt 
				 WHERE first_dmw_order_dt >=  Add_Months( Current_Date, -1)  AND first_dmw_order_dt< (Current_Date) 
			) dmwg (cnst_mstr_id, first_dmw_order_dt)  ON ab.cnst_mstr_id = dmwg.cnst_mstr_id	
			GROUP BY 1	
		
		)lob_new (cnst_typ_cd, fr_month_new_active_cnt, bio_month_new_active_cnt, rcs_month_new_active_cnt, phss_month_new_active_cnt, dmw_month_new_active_cnt, total_month_new_active_cnt)  ON acs.cnst_typ_cd = lob_new.cnst_typ_cd
		
		LEFT JOIN /* This section returns the lapsed constituent counts by LOB for the past month */
		(
		SELECT
			Cast('ALL' AS VARCHAR(3)) AS cnst_typ_cd,
				Sum(CASE WHEN ab.lst_fr_dntn_dt < Add_Months( Current_Date, -24)  AND ab.lst_fr_dntn_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS fr_month_lapsed_cnt,
				Sum(CASE WHEN frs.cnst_mstr_id IS NOT NULL AND (coalesce(fr_ry0_dntn_amt,0) + coalesce(fr_ry1_dntn_amt,0)) <= 0 THEN 1 ELSE 0 end) AS active_zero_gift_amt_cnt,
				Sum(CASE WHEN frs.cnst_mstr_id IS NULL THEN 1 ELSE 0 end) AS active_secondary_cnt,
				Sum(CASE WHEN last_donat_dt < Add_Months( Current_Date, -24)  AND last_donat_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS bio_month_lapsed_cnt,
		    	Sum(CASE WHEN last_rcs_order_dt < Add_Months( Current_Date, -24)  AND last_rcs_order_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS rcs_month_lapsed_cnt,
			   	Sum(CASE WHEN last_crs_cmptn_dt < Add_Months( Current_Date, -24)  AND last_crs_cmptn_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS phss_month_lapsed_cnt,
			   	Sum(CASE WHEN last_dmw_order_dt < Add_Months( Current_Date, -24)  AND last_dmw_order_dt >= Add_Months( Current_Date, -25)  THEN 1 ELSE 0 end) AS dmw_month_lapsed_cnt,
				Sum(CASE WHEN ab.lst_fr_dntn_dt <  Add_Months( Current_Date, -24)  AND ab.lst_fr_dntn_dt >= Add_Months( Current_Date, -25)  OR 
											last_donat_dt  <  Add_Months( Current_Date, -24)  AND last_donat_dt >= Add_Months( Current_Date, -25)  OR 
											last_dmw_order_dt < Add_Months( Current_Date, -24)  AND last_dmw_order_dt >= Add_Months( Current_Date, -25) 
				/*							last_rcs_order_dt < add_months( current_date, -24)  and last_rcs_order_dt >= add_months( current_date, -25)  or  */
				/*							last_crs_cmptn_dt < add_months( current_date, -24)  and last_crs_cmptn_dt >= add_months( current_date, -25)  */
				THEN 1 ELSE 0 end) AS total_month_lapsed_cnt
			FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
			LEFT JOIN /* FR Lapsed */
				(
					SELECT
						ab.cnst_mstr_id,
						ab.lst_fr_dntn_dt,
						fr_ry0_dntn_amt,
						fr_ry1_dntn_amt
					FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab 
					LEFT JOIN mktg_ops_vws.gms_arc_fr_smry frs  ON ab.cnst_mstr_id = frs.cnst_mstr_id 
					WHERE ab.lst_fr_dntn_dt < Add_Months( Current_Date, -24)  AND ab.lst_fr_dntn_dt >= Add_Months( Current_Date, -25) 
				) frs (cnst_mstr_id,	lst_fr_dntn_dt,	fr_ry0_dntn_amt,	fr_ry1_dntn_amt) ON ab.cnst_mstr_id = frs.cnst_mstr_id
			LEFT JOIN  /* Bio Lapsed */
				(
					SELECT 
						ab.cnst_mstr_id,
						last_donat_dt
					FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
					LEFT JOIN mktg_ops_vws.arc_biomed_smry bs ON ab.cnst_mstr_id = bs.cnst_mstr_id 
					WHERE last_donat_dt < Add_Months( Current_Date, -24)  AND last_donat_dt >= Add_Months( Current_Date, -25)  AND (lftm_prodctv_wb_cnt + lftm_prodctv_pltpheresis_cnt + lftm_prodctv_red_cell_cnt + lftm_prodctv_dbl_red_cnt)  > 0  
				)  bs (cnst_mstr_id, last_donat_dt) ON ab.cnst_mstr_id = bs.cnst_mstr_id 
			
			LEFT JOIN /* The query below returns the Red Cross Store constituents that lapsed within the last month */	
				(
					SELECT 
						ab.cnst_mstr_id,
						last_rcs_order_dt
				    FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
					 LEFT JOIN 
					(
						SELECT 
							b.cnst_mstr_id,
							Min(Cast(odr_create_ts AS DATE)) AS first_rcs_order_dt,
							Max(Cast(odr_create_ts AS DATE)) AS last_rcs_order_dt
						FROM arc_store_tbls.dim_odr a
						LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge b ON a.billing_prsn_key = b.cnst_mstr_subj_area_id AND b.cnst_mstr_subj_area_cd = 'RCST'
						WHERE Cast(odr_create_ts AS DATE) BETWEEN Add_Months(Current_Date, -24) AND (Current_Date)
					GROUP BY 1
					) rcs (cnst_mstr_id, first_rcs_order_dt, last_rcs_order_dt) ON ab.cnst_mstr_id = rcs.cnst_mstr_id
					WHERE  last_rcs_order_dt < Add_Months( Current_Date, -24)  AND last_rcs_order_dt >= Add_Months( Current_Date, -25) 
				) rcsl (cnst_mstr_id, last_rcs_order_dt) ON ab.cnst_mstr_id = rcsl.cnst_mstr_id
			LEFT JOIN /* PHSS Lapsed */
				(
					SELECT
						ab.cnst_mstr_id,
						last_crs_cmptn_dt
					FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab 
					LEFT JOIN mktg_ops_vws.arc_phss_smry ps ON ab.cnst_mstr_id = ps.cnst_mstr_id
					WHERE  last_crs_cmptn_dt < Add_Months( Current_Date, -24)  AND last_crs_cmptn_dt >= Add_Months( Current_Date, -25)  
				) ps (cnst_mstr_id, last_crs_cmptn_dt) ON ab.cnst_mstr_id = ps.cnst_mstr_id 
			LEFT JOIN /* DemandWare Lapsed */
			 /* DemandWare Lapsed Constituents */
			 (
				 SELECT 
				 	cnst_mstr_id,
				 	last_dmw_order_dt
				 FROM 
				(
					SELECT 
						prsn.cnst_mstr_id,
						Min(cal.calendar_dt) AS first_dmw_order_dt,
						Max(cal.calendar_dt) AS last_dmw_order_dt
					 FROM eda.uhss_vws.sfbz_dim_odr odr
					 LEFT JOIN eda.uhss_vws.sfbz_dim_prsn_addr prsn ON odr.billing_prsn_addr_key = prsn.prsn_addr_key
					 LEFT JOIN eda.dw_common_vws.dim_calendar cal ON odr.odr_dt_key = cal.calendar_key
					 LEFT JOIN 
					 	(
					 		SELECT odr_key, 1 AS prod_odr_ind, Count(*) AS odr_line_cnt
					 		FROM eda.uhss_vws.sfbz_fact_product_ln
					 		GROUP BY 1,2
					 	) Prod (odr_key, prod_odr_ind, odr_line_cnt) ON  odr.odr_key = Prod.odr_key
					 LEFT JOIN 
					 	(
					 		SELECT odr_key, 1 AS crs_odr_ind, Count(*) AS odr_line_cnt
					 		FROM eda.uhss_vws.sfbz_fact_course_ln
					 		GROUP BY 1,2
					 	) crs  (odr_key, crs_odr_ind, odr_line_cnt) ON  odr.odr_key = crs.odr_key
					WHERE odr.odr_stat_cd <> 'CANCELLED'
					GROUP BY 1
				) a (cnst_mstr_id, first_dmw_order_dt, last_dmw_order_dt)
				WHERE last_dmw_order_dt <  Add_Months( Current_Date, -24)  AND last_dmw_order_dt >= Add_Months( Current_Date, -25)  
			) dmwl(cnst_mstr_id, last_dmw_order_dt) ON ab.cnst_mstr_id = dmwl.cnst_mstr_id 
			GROUP BY 1
		
		)lob_lapse (cnst_typ_cd, fr_month_lapsed_cnt, active_zero_gift_amt_cnt, active_secondary_cnt, bio_month_lapsed_cnt, rcs_month_lapsed_cnt, phss_month_lapsed_cnt, dmw_month_lapsed_cnt, total_month_lapsed_cnt) ON acs.cnst_typ_cd = lob_lapse.cnst_typ_cd
		
		LEFT JOIN 	/* Constituent Reactivation Section */
		(
		SELECT
			Cast('ALL' AS VARCHAR(3)) AS cnst_typ_cd,
				Sum(CASE WHEN (frr.fr_last_dntn_dt >= Add_Months( Current_Date, -1)  AND frr.fr_last_dntn_dt < (Current_Date)) AND (frr.fr_ry0_dntn_cnt + frr.fr_ry1_dntn_cnt = 1) AND ( frr.fr_lftm_dntn_cnt > 1) THEN 1 ELSE 0 end) AS fr_month_reactivated_cnt,
				Sum(CASE WHEN (last_donat_dt >= Add_Months( Current_Date, -1)  AND last_donat_dt < (Current_Date)) AND 
						(ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_plspheresis_cnt + ry0_prodctv_dbl_red_cnt  + 
						ry1_prodctv_wb_cnt + ry1_prodctv_pltpheresis_cnt + ry1_prodctv_red_cell_cnt + ry1_prodctv_plspheresis_cnt + ry1_prodctv_dbl_red_cnt = 1) AND 
						( lftm_prodctv_wb_cnt + lftm_prodctv_pltpheresis_cnt + lftm_prodctv_red_cell_cnt + lftm_prodctv_plspheresis_cnt + lftm_prodctv_dbl_red_cnt > 1) THEN 1 ELSE 0 end) AS bio_month_reactivated_cnt,
				Sum(CASE WHEN (last_crs_cmptn_dt >= Add_Months( Current_Date, -1)  AND last_crs_cmptn_dt < (Current_Date)) AND (phssr.lapsed_end_dt IS NOT NULL) AND ( lftm_crs_complt_cnt > 1) THEN 1 ELSE 0 end) AS phss_month_reactivated_cnt,
				Sum(CASE WHEN (dmwr.last_dmw_order_dt >= Add_Months( Current_Date, -1)) THEN 1 ELSE 0 end) AS dmw_month_reactivated_cnt,
				Sum(CASE WHEN ((frr.fr_last_dntn_dt >= Add_Months( Current_Date, -1)  AND frr.fr_last_dntn_dt < (Current_Date)) AND (frr.fr_ry0_dntn_cnt + frr.fr_ry1_dntn_cnt = 1) AND ( frr.fr_lftm_dntn_cnt > 1)) OR
											((last_donat_dt >= Add_Months( Current_Date, -1)  AND last_donat_dt < (Current_Date)) AND 
						(ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_plspheresis_cnt + ry0_prodctv_dbl_red_cnt  + 
						ry1_prodctv_wb_cnt + ry1_prodctv_pltpheresis_cnt + ry1_prodctv_red_cell_cnt + ry1_prodctv_plspheresis_cnt + ry1_prodctv_dbl_red_cnt = 1) AND 
						( lftm_prodctv_wb_cnt + lftm_prodctv_pltpheresis_cnt + lftm_prodctv_red_cell_cnt + lftm_prodctv_plspheresis_cnt + lftm_prodctv_dbl_red_cnt > 1)) OR
						dmwr.last_dmw_order_dt IS NOT NULL
					/*	 ((last_crs_cmptn_dt >= add_months( current_date, -1)  and last_crs_cmptn_dt < (current_date)) and (phssr.lapsed_end_dt is not null) and ( lftm_crs_complt_cnt > 1)) */
						THEN 1 ELSE 0 end) AS total_month_reactivated_cnt
			FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
			LEFT JOIN /* The query below returns the FR constituents that re-activated in the prior month */
			(
				SELECT
					ab.cnst_mstr_id,
					fr_last_dntn_dt,
					fr_ry0_dntn_cnt,
					fr_ry1_dntn_cnt,
					fr_lftm_dntn_cnt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
				LEFT JOIN mktg_ops_vws.gms_arc_fr_smry frs ON ab.cnst_mstr_id = frs.cnst_mstr_id
				WHERE (fr_last_dntn_dt >= Add_Months( Current_Date, -1)  AND fr_last_dntn_dt < (Current_Date)) AND (fr_ry0_dntn_cnt + fr_ry1_dntn_cnt = 1) AND ( fr_lftm_dntn_cnt > 1)
			) frr (cnst_mstr_id, fr_last_dntn_dt, fr_ry0_dntn_cnt, fr_ry1_dntn_cnt, 	fr_lftm_dntn_cnt) ON ab.cnst_mstr_id = frr.cnst_mstr_id
			LEFT JOIN /* The query below returns the Bio constituents reactivated within the prior month */	
			(
				SELECT 
					ab.cnst_mstr_id,
					 last_donat_dt, ry0_prodctv_wb_cnt, ry0_prodctv_pltpheresis_cnt, ry0_prodctv_red_cell_cnt, ry0_prodctv_plspheresis_cnt, ry0_prodctv_dbl_red_cnt, 	ry1_prodctv_wb_cnt,
					 ry1_prodctv_pltpheresis_cnt, ry1_prodctv_red_cell_cnt, ry1_prodctv_plspheresis_cnt, ry1_prodctv_dbl_red_cnt, 
					  lftm_prodctv_wb_cnt, lftm_prodctv_pltpheresis_cnt, lftm_prodctv_red_cell_cnt, lftm_prodctv_plspheresis_cnt, lftm_prodctv_dbl_red_cnt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab
				LEFT JOIN mktg_ops_vws.arc_biomed_smry bs ON ab.cnst_mstr_id = bs.cnst_mstr_id 
				WHERE  (last_donat_dt >= Add_Months( Current_Date, -1)  AND last_donat_dt < (Current_Date)) AND 
							(ry0_prodctv_wb_cnt + ry0_prodctv_pltpheresis_cnt + ry0_prodctv_red_cell_cnt + ry0_prodctv_plspheresis_cnt + ry0_prodctv_dbl_red_cnt  + 
							ry1_prodctv_wb_cnt + ry1_prodctv_pltpheresis_cnt + ry1_prodctv_red_cell_cnt + ry1_prodctv_plspheresis_cnt + ry1_prodctv_dbl_red_cnt = 1) AND 
							( lftm_prodctv_wb_cnt + lftm_prodctv_pltpheresis_cnt + lftm_prodctv_red_cell_cnt + lftm_prodctv_plspheresis_cnt + lftm_prodctv_dbl_red_cnt > 1)
			) bior (cnst_mstr_id, last_donat_dt, ry0_prodctv_wb_cnt, ry0_prodctv_pltpheresis_cnt, ry0_prodctv_red_cell_cnt, ry0_prodctv_plspheresis_cnt, ry0_prodctv_dbl_red_cnt, 	ry1_prodctv_wb_cnt,
					 ry1_prodctv_pltpheresis_cnt, ry1_prodctv_red_cell_cnt, ry1_prodctv_plspheresis_cnt, ry1_prodctv_dbl_red_cnt, 
					  lftm_prodctv_wb_cnt, lftm_prodctv_pltpheresis_cnt, lftm_prodctv_red_cell_cnt, lftm_prodctv_plspheresis_cnt, lftm_prodctv_dbl_red_cnt) ON ab.cnst_mstr_id = bior.cnst_mstr_id
			LEFT JOIN /* The query below returns the PHSS constituents reactivated within the prior month */		
			(
				SELECT
					ab.cnst_mstr_id,
					last_crs_cmptn_dt,
					phr.lapsed_end_dt,
					lftm_crs_complt_cnt
				FROM eda.arc_mdm_vws.bzfc_arc_best_smry ab 
				LEFT JOIN mktg_ops_vws.arc_phss_smry ps ON ab.cnst_mstr_id = ps.cnst_mstr_id
				LEFT JOIN 
				(
					SELECT 
						ps.cnst_mstr_id, Max(offer_end_dt)
					FROM mktg_ops_vws.arc_phss_smry ps 
					LEFT JOIN mktg_ops_vws.arc_phss_txn px ON px.cnst_mstr_id = ps.cnst_mstr_id
					WHERE  course_compl_stat = 'COURSE SUCCESS'  AND offer_end_dt < last_crs_cmptn_dt
					GROUP BY 1
					HAVING Max(offer_end_dt) <  Add_Months( Current_Date, -24) 
				) phr (cnst_mstr_id, lapsed_end_dt) ON ab.cnst_mstr_id = phr.cnst_mstr_id
				WHERE (last_crs_cmptn_dt >= Add_Months( Current_Date, -1)  AND last_crs_cmptn_dt < (Current_Date)) AND (phr.lapsed_end_dt IS NOT NULL) AND ( lftm_crs_complt_cnt > 1)
			) phssr (cnst_mstr_id, last_crs_cmptn_dt,lapsed_end_dt,  lftm_crs_complt_cnt) ON  ab.cnst_mstr_id = phssr.cnst_mstr_id	
			LEFT JOIN /* The query below returns the DemandWard constituents reactivated within the prior month */		
			(	
				SELECT 
					a.cnst_mstr_id,
					last_dmw_order_dt,
					prev_dmw_order_dt
				FROM
				(	
						 SELECT 
						 	cnst_mstr_id,
						 	last_dmw_order_dt
						 FROM 
						(
							SELECT 
								prsn.cnst_mstr_id,
								Min(cal.calendar_dt) AS first_dmw_order_dt,
								Max(cal.calendar_dt) AS last_dmw_order_dt
							 FROM eda.uhss_vws.sfbz_dim_odr odr
							 LEFT JOIN eda.uhss_vws.sfbz_dim_prsn_addr prsn ON odr.billing_prsn_addr_key = prsn.prsn_addr_key
							 LEFT JOIN eda.dw_common_vws.dim_calendar cal ON odr.odr_dt_key = cal.calendar_key
							WHERE odr.odr_stat_cd <> 'CANCELLED'
							GROUP BY 1
						) a (cnst_mstr_id, first_dmw_order_dt, last_dmw_order_dt)
						WHERE last_dmw_order_dt <=  Current_Date  AND last_dmw_order_dt > Add_Months( Current_Date, -1)  
				
				) a (cnst_mstr_id, last_dmw_order_dt)
					JOIN
				(
						SELECT 
							prsn.cnst_mstr_id,
							cal.calendar_dt AS prev_dmw_order_dt
						 FROM eda.uhss_vws.sfbz_dim_odr odr
						 LEFT JOIN eda.uhss_vws.sfbz_dim_prsn_addr prsn ON odr.billing_prsn_addr_key = prsn.prsn_addr_key
						 LEFT JOIN eda.dw_common_vws.dim_calendar cal ON odr.odr_dt_key = cal.calendar_key
						WHERE odr.odr_stat_cd <> 'CANCELLED'
					QUALIFY Row_Number() Over ( PARTITION BY prsn.cnst_mstr_id ORDER BY cal.calendar_dt DESC ) = 2
				) b (cnst_mstr_id, prev_dmw_order_dt) ON a.cnst_mstr_id = b.cnst_mstr_id
				WHERE b.prev_dmw_order_dt 	<  Add_Months( Current_Date, -24)	
			) dmwr (cnst_mstr_id, last_dmw_order_dt, prev_dmw_order_dt) ON  ab.cnst_mstr_id = dmwr.cnst_mstr_id	
			GROUP BY 1
		
		)lob_react (cnst_typ_cd, fr_month_reactivated_cnt, bio_month_reactivated_cnt, phss_month_reactivated_cnt, dmw_month_reactivated_cnt, total_month_reactivated_cnt) ON acs.cnst_typ_cd = lob_react.cnst_typ_cd;


		truncate table mktg_ops_tbls.dv_active_segmnt_snapsht;
		insert into mktg_ops_tbls.dv_active_segmnt_snapsht select * from mktg_stage_tbls.dv_active_segmnt_snapsht_stg;

		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.dv_active_segmnt_snapsht) as INTEGER)
			WHERE proc_name = 'ld_dv_active_segmnt_snapsht' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_dv_active_segmnt_snapsht', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
