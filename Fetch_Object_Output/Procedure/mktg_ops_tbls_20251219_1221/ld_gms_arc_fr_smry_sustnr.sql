CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_arc_fr_smry_sustnr()
 LANGUAGE plpgsql
AS $$
/* The below comments refer to the _src view, which has now been incorporated into this stored procedure instead of being maintained as a separate view. */
/*
---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 04/22/2018
Purpose: This view returns one summary row for sustaining donor and provides summary metrics by calendar year for 
        both online and offline gifts. The view includes the first and last sustaining donation for the current calendar year
        and 2 prior year for both online and offline sustaining gifts as well as the gift count and total amount by year. I've 
        included indicators for each year and online/offline/other channel to help aggregate sustainer count metrics and flags for each
        year and channel to aide report and dashboard filters.

Modified By; Michael Andrien
Modified Date: 5/4/2018
Purpose:  Changed 'Other' logic to use fund group type and to include fund code = 4900-dm.

Modified By; Michael Andrien
Modified Date: 5/14/2018
Purpose:  Added the current sustainer indicator attribute (current_sustnr_ind) - Defined as any constituent who's last online or offline sustaining gift is within 2 months of the current date.

Modified by: Michael Andrien
Modified Date: 07/03/2018
Purpose:  Added 'Phone' sustainer transaction logic and attributes

Modified by: Michael Andrien
Modified Date: 07/18/2018
Purpose:  Modified the initial txn query to which all the left joins are based to resolve an issue with some cnst_mstr_ids having more than one summary row.

Modified by: Michael Andrien
Modified Date: 07/19/2018
Purpose: Added cy0_last_othr_sustnr_gift_dt and cy0_last_phone_sustnr_gift_dt to the current sustainer indicator logic.

Modified by: Michael Andrien
Modified Date: 07/31/2018
Purpose:   Added the Face-2-Face Channel summary metric

Modified by: Michael Andrien
Modified Date: 01/04/2019
Purpose: Altered the current_sustnr_ind logic to evaluate both CY0 and CY1 dates.  The current_sustnr_ind counts drop when we rolled over to the new year
      because we only compared CY0 dates to the 3 month giving criteria.

Modified by: Michael Andrien
Modified Date: 05/06/2019
Purpose:  Added logic for the Last Sustainer Date (txn.last_sustnr_dt).  This date reflects the most recent sustainer transaction date without regard for channel or year.  
This enhancement was requested by Jack Schwaner from the MODS team.

Modified by: Michael Andrien
Modified Date: 05/20/2019
Purpose:  Modified logic for the Last Sustainer Date (txn.last_sustnr_dt).  This date reflects the most recent sustainer transaction date without regard for channel or year.  
This enhancement was requested by Jack Schwaner from the MODS team.

Modified by: Michael Andrien
Modified Date: 05/21/2019
Purpose:  Removed the 'othr' subquery in the txn join.  The query was duplicating sustainer donations from other groups and adding rows to the view that should not be included in the view.

Modified by: Michael Andrien
Modified Date: 01/16/2020
Purpose:  Added the first sustainer date (txn.first_sustnr_dt) to output.

Modified by: Michael Andrien
Modified Date: 02/10/2020
Purpose:  Created the GMS version to read from gms_arc_fr_txn

Modified by: Michael Andrien
Modified Date: 05/11/2020
Purpose:  Modified the gmpbzal_dim_fund joins to include a qualify statement to aviod a 1:M join on the fund_cd.

Modified by: Michael Andrien
Modified Date: 08/16/2020
Purpose: Added 2 constraints to the drive gms_arc_fr_txn (txn) query on primary_gift_ind = 1 and fr_pmt_amt > 0.  Also, added an additional constraint to the online sustainer CY0, CY1 and CY2 queries to limit the results to online_channel_cd = 'OD'.

Modified by: Michael Andrien
Modified Date: 09/03/2020
Purpose: Removed primary_gift_ind=1 and online_channel_cd = 'OD' from the 8/16/2020 update.  These were incorrectly limiting the transactions required to produce accurate sustainer summary counts.  Added the 'or txn.sustnr_typ_key <> 0' logic to the first and last sustnr_dt attributes below.
    min(case when recurring_ind = 1 or   txn.gift_src_cd =  'RQZ00000M000' or sustnr.phone_sustnr_gift_ind = 1 or f2f_sustnr_gift_ind = 1 or txn.sustnr_typ_key <> 0 then txn.dntn_gift_dt else null end) as first_sustnr_dt,
    max(case when recurring_ind = 1 or   txn.gift_src_cd =  'RQZ00000M000' or sustnr.phone_sustnr_gift_ind = 1 or f2f_sustnr_gift_ind = 1 or txn.sustnr_typ_key <> 0 then txn.dntn_gift_dt else null end) as last_sustnr_dt

Modified by: Greg Seaberg - Deployed by Michael Andrien
Modified Date: 04/25/2022
Purpose: Added RCO sustainer lightbox conversions, which are online sustaining donations created when a donor makes a one-time donation on RCO and subsequently agrees to start a new sustaining donation with the first gift 30 days out from the one-time donation that was just completed.
    These conversions generate a new row in rco_vws.bz_dim_subscription with a rcrng_start_ts 30 days out from the one-time donation date and with null values for both first_rco_dntn_id and last_rco_dntn_id
    cnst_mstr_id values are derived by joining to rco_tbls.dim_CDI_1C_trans_bridge on the trans_billng_key and subsequently to arc_mdm_vws.bz_cnst_mstr_bridge on the acct_prsn_key

Modified by: Michael Andrien
Modified Date: 07/14/2022
Purpose: Added logic to the first_sustnr_dt to reference the first_online_sustnr_gift_ind attribute in th gms_arc_fr_txn_sustnr view to set the min gift date in cases where the initial OD online sustainer gift is not present.
*/

/* The Below comments are for the original teradata macro */
/*
Modified by: Michael Andrien
Modified Date: 07/31/2018
Purpose:  This macro was created to instantiate the FR summary sustainer data view.  The macro is run daily and reads the data in bz_arc_fr_smry_sustnr_src view
					to load the arc_fr_smry_sustnr table.  The physical table is required to improve reporting from the CE universe.

Modified by: Michael Andrien
Modified Date: 05/06/2019
Purpose:	Added logic for the Last Sustainer Date (txn.last_sustnr_dt).  This date reflects the most recent sustainer transaction date without regard for channel or year.  
This enhancement was requested by Jack Schwaner from the MODS team.

Modified by: Michael Andrien
Modified Date: 05/20/2019
Purpose:	Modified logic for the Last Sustainer Date (txn.last_sustnr_dt).  This date reflects the most recent sustainer transaction date without regard for channel or year.  
This enhancement was requested by Jack Schwaner from the MODS team.			

Modified by: Michael Andrien
Modified Date: 01/16/2020
Purpose:	Added the first sustainer date and amount (first_sustnr_dt, first_sustnr_gift_amt) and last sustainer gift amount (last_sustnr_gift_amt) to output.

Modified by: Michael Andrien
Modified Date: 02/10/2020
Purpose:	Created the GMS version to read from gms_arc_fr_txn.  NOTE:  Replaced trans_id with giftran_key, reading gms_arc_fr_txn rather than arc_fr_txn and changed ddcoe_vws.fcc to mktg_ops_vws.gmpbz_dim_gl_fcc
*/
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
BEGIN
	v_start_time := GETDATE();
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
	VALUES ('ld_gms_arc_fr_smry_sustnr', 'Stored Procedure', 'Inprogress', v_start_time);

	-- Start transaction block
	BEGIN
		-- Truncate the staging table before loading new data
		TRUNCATE TABLE mods_bi.mktg_stage_tbls.gms_arc_fr_smry_sustnr_stg;
		-- Load data into staging table
		INSERT INTO mktg_stage_tbls.gms_arc_fr_smry_sustnr_stg
		
		WITH fund_ranking AS (
			SELECT 
				fund_key, 
				fund_cd, 
				gl_company_fund_cd,
				ROW_NUMBER() OVER (PARTITION BY fund_cd ORDER BY active_ind DESC, fund_key DESC) AS rn
			FROM mktg_ops_vws.gmpbzal_dim_fund
		),
		gms_arc_fr_smry_sustnr_src AS (
			SELECT 
			  txn.cnst_mstr_id,
			  EXTRACT(YEAR FROM CURRENT_DATE) AS cy0_year_dsc,
			  CASE WHEN cy0_sustnr.first_offline_sustnr_gift_dt IS NULL THEN NULL ELSE cy0_sustnr.first_offline_sustnr_gift_dt END AS cy0_first_offline_sustnr_gift_dt,
			  CASE WHEN cy0_sustnr.last_offline_sustnr_gift_dt IS NULL THEN NULL ELSE cy0_sustnr.last_offline_sustnr_gift_dt END AS cy0_last_offline_sustnr_gift_dt,
			  COALESCE(cy0_sustnr.offline_sustnr_gift_cnt, 0) AS cy0_offline_sustnr_gift_cnt,
			  COALESCE(cy0_sustnr.offline_sustnr_gift_amt, 0) AS cy0_offline_sustnr_gift_amt,
			  EXTRACT(YEAR FROM CURRENT_DATE) - 1 AS cy1_year_dsc,
			  cy1_sustnr.first_offline_sustnr_gift_dt AS cy1_first_offline_sustnr_gift_dt,
			  cy1_sustnr.last_offline_sustnr_gift_dt AS cy1_last_offline_sustnr_gift_dt,
			  COALESCE(cy1_sustnr.offline_sustnr_gift_cnt, 0) AS cy1_offline_sustnr_gift_cnt,
			  COALESCE(cy1_sustnr.offline_sustnr_gift_amt, 0) AS cy1_offline_sustnr_gift_amt,
			  EXTRACT(YEAR FROM CURRENT_DATE) - 2 AS cy2_year_dsc,
			  cy2_sustnr.first_offline_sustnr_gift_dt AS cy2_first_offline_sustnr_gift_dt,
			  cy2_sustnr.last_offline_sustnr_gift_dt AS cy2_last_offline_sustnr_gift_dt,
			  COALESCE(cy2_sustnr.offline_sustnr_gift_cnt, 0) AS cy2_offline_sustnr_gift_cnt,
			  COALESCE(cy2_sustnr.offline_sustnr_gift_amt, 0) AS cy2_offline_sustnr_gift_amt,
			  cy0_onl_sustnr.first_online_sustnr_gift_dt AS cy0_first_online_sustnr_gift_dt,
			  cy0_onl_sustnr.last_online_sustnr_gift_dt AS cy0_last_online_sustnr_gift_dt,
			  COALESCE(cy0_onl_sustnr.online_sustnr_gift_cnt, 0) AS cy0_online_sustnr_gift_cnt,
			  COALESCE(cy0_onl_sustnr.online_sustnr_gift_amt, 0) AS cy0_online_sustnr_gift_amt,
			  cy1_onl_sustnr.first_online_sustnr_gift_dt AS cy1_first_online_sustnr_gift_dt,
			  cy1_onl_sustnr.last_online_sustnr_gift_dt AS cy1_last_online_sustnr_gift_dt,
			  COALESCE(cy1_onl_sustnr.online_sustnr_gift_cnt, 0) AS cy1_online_sustnr_gift_cnt,
			  COALESCE(cy1_onl_sustnr.online_sustnr_gift_amt, 0) AS cy1_online_sustnr_gift_amt,
			  cy2_onl_sustnr.first_online_sustnr_gift_dt AS cy2_first_online_sustnr_gift_dt,
			  cy2_onl_sustnr.last_online_sustnr_gift_dt AS cy2_last_online_sustnr_gift_dt,
			  COALESCE(cy2_onl_sustnr.online_sustnr_gift_cnt, 0) AS cy2_online_sustnr_gift_cnt,
			  COALESCE(cy2_onl_sustnr.online_sustnr_gift_amt, 0) AS cy2_online_sustnr_gift_amt,
			  cy0_phn_sustnr.first_phone_sustnr_gift_dt AS cy0_first_phone_sustnr_gift_dt,
			  cy0_phn_sustnr.last_phone_sustnr_gift_dt AS cy0_last_phone_sustnr_gift_dt,
			  COALESCE(cy0_phn_sustnr.phone_sustnr_gift_cnt, 0) AS cy0_phone_sustnr_gift_cnt,
			  COALESCE(cy0_phn_sustnr.phone_sustnr_gift_amt, 0) AS cy0_phone_sustnr_gift_amt,
			  cy1_phn_sustnr.first_phone_sustnr_gift_dt AS cy1_first_phone_sustnr_gift_dt,
			  cy1_phn_sustnr.last_phone_sustnr_gift_dt AS cy1_last_phone_sustnr_gift_dt,
			  COALESCE(cy1_phn_sustnr.phone_sustnr_gift_cnt, 0) AS cy1_phone_sustnr_gift_cnt,
			  COALESCE(cy1_phn_sustnr.phone_sustnr_gift_amt, 0) AS cy1_phone_sustnr_gift_amt,
			  cy2_phn_sustnr.first_phone_sustnr_gift_dt AS cy2_first_phone_sustnr_gift_dt,
			  cy2_phn_sustnr.last_phone_sustnr_gift_dt AS cy2_last_phone_sustnr_gift_dt,
			  COALESCE(cy2_phn_sustnr.phone_sustnr_gift_cnt, 0) AS cy2_phone_sustnr_gift_cnt,
			  COALESCE(cy2_phn_sustnr.phone_sustnr_gift_amt, 0) AS cy2_phone_sustnr_gift_amt,  
			  cy0_othr_sustnr.first_othr_sustnr_gift_dt AS cy0_first_othr_sustnr_gift_dt,
			  cy0_othr_sustnr.last_othr_sustnr_gift_dt AS cy0_last_othr_sustnr_gift_dt,
			  COALESCE(cy0_othr_sustnr.othr_sustnr_gift_cnt, 0) AS cy0_othr_sustnr_gift_cnt,
			  COALESCE(cy0_othr_sustnr.othr_sustnr_gift_amt, 0) AS cy0_othr_sustnr_gift_amt,
			  cy1_othr_sustnr.first_othr_sustnr_gift_dt AS cy1_first_othr_sustnr_gift_dt,
			  cy1_othr_sustnr.last_othr_sustnr_gift_dt AS cy1_last_othr_sustnr_gift_dt,
			  COALESCE(cy1_othr_sustnr.othr_sustnr_gift_cnt, 0) AS cy1_othr_sustnr_gift_cnt,
			  COALESCE(cy1_othr_sustnr.othr_sustnr_gift_amt, 0) AS cy1_othr_sustnr_gift_amt,
			  cy2_othr_sustnr.first_othr_sustnr_gift_dt AS cy2_first_othr_sustnr_gift_dt,
			  cy2_othr_sustnr.last_othr_sustnr_gift_dt AS cy2_last_othr_sustnr_gift_dt,
			  COALESCE(cy2_othr_sustnr.othr_sustnr_gift_cnt, 0) AS cy2_othr_sustnr_gift_cnt,
			  COALESCE(cy2_othr_sustnr.othr_sustnr_gift_amt, 0) AS cy2_othr_sustnr_gift_amt,
			  cy0_f2f_sustnr.first_f2f_sustnr_gift_dt AS cy0_first_f2f_sustnr_gift_dt,
			  cy0_f2f_sustnr.last_f2f_sustnr_gift_dt AS cy0_last_f2f_sustnr_gift_dt,
			  COALESCE(cy0_f2f_sustnr.f2f_sustnr_gift_cnt, 0) AS cy0_f2f_sustnr_gift_cnt,
			  COALESCE(cy0_f2f_sustnr.f2f_sustnr_gift_amt, 0) AS cy0_f2f_sustnr_gift_amt,
			  cy1_f2f_sustnr.first_f2f_sustnr_gift_dt AS cy1_first_f2f_sustnr_gift_dt,
			  cy1_f2f_sustnr.last_f2f_sustnr_gift_dt AS cy1_last_f2f_sustnr_gift_dt,
			  COALESCE(cy1_f2f_sustnr.f2f_sustnr_gift_cnt, 0) AS cy1_f2f_sustnr_gift_cnt,
			  COALESCE(cy1_f2f_sustnr.f2f_sustnr_gift_amt, 0) AS cy1_f2f_sustnr_gift_amt,
			  cy2_f2f_sustnr.first_f2f_sustnr_gift_dt AS cy2_first_f2f_sustnr_gift_dt,
			  cy2_f2f_sustnr.last_f2f_sustnr_gift_dt AS cy2_last_f2f_sustnr_gift_dt,
			  COALESCE(cy2_f2f_sustnr.f2f_sustnr_gift_cnt, 0) AS cy2_f2f_sustnr_gift_cnt,
			  COALESCE(cy2_f2f_sustnr.f2f_sustnr_gift_amt, 0) AS cy2_f2f_sustnr_gift_amt,
			  CASE WHEN cy0_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy0_offline_sustainer_ind,
			  CASE WHEN cy0_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy0_offline_sustainer_flg,
			  CASE WHEN cy1_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy1_offline_sustainer_ind,
			  CASE WHEN cy1_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy1_offline_sustainer_flg,
			  CASE WHEN cy2_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy2_offline_sustainer_ind,
			  CASE WHEN cy2_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy2_offline_sustainer_flg,
			  CASE WHEN cy0_onl_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy0_online_sustainer_ind,
			  CASE WHEN cy0_onl_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy0_online_sustainer_flg,
			  CASE WHEN cy1_onl_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy1_online_sustainer_ind,
			  CASE WHEN cy1_onl_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy1_online_sustainer_flg,
			  CASE WHEN cy2_onl_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy2_online_sustainer_ind,
			  CASE WHEN cy2_onl_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy2_online_sustainer_flg,
			  CASE WHEN cy0_phn_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy0_phone_sustainer_ind,
			  CASE WHEN cy0_phn_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy0_phone_sustainer_flg,
			  CASE WHEN cy1_phn_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy1_phone_sustainer_ind,
			  CASE WHEN cy1_phn_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy1_phone_sustainer_flg,
			  CASE WHEN cy2_phn_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy2_phone_sustainer_ind,
			  CASE WHEN cy2_phn_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy2_phone_sustainer_flg,
			  CASE WHEN cy0_othr_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy0_othr_sustainer_ind,
			  CASE WHEN cy0_othr_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy0_othr_sustainer_flg,
			  CASE WHEN cy1_othr_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy1_othr_sustainer_ind,
			  CASE WHEN cy1_othr_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy1_othr_sustainer_flg,
			  CASE WHEN cy2_othr_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy2_othr_sustainer_ind,
			  CASE WHEN cy2_othr_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy2_othr_sustainer_flg,
			  CASE WHEN cy0_f2f_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy0_f2f_sustainer_ind,
			  CASE WHEN cy0_f2f_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy0_f2f_sustainer_flg,
			  CASE WHEN cy1_f2f_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy1_f2f_sustainer_ind,
			  CASE WHEN cy1_f2f_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy1_f2f_sustainer_flg,
			  CASE WHEN cy2_f2f_sustnr.calendar_yr IS NULL THEN 0 ELSE 1 END AS cy2_f2f_sustainer_ind,
			  CASE WHEN cy2_f2f_sustnr.calendar_yr IS NULL THEN 'N' ELSE 'Y' END AS cy2_f2f_sustainer_flg,
			  CASE WHEN cy0_last_phone_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR cy0_last_offline_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR 
					  cy0_last_online_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR cy0_last_othr_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR cy0_last_f2f_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR
					   cy1_last_phone_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR cy1_last_offline_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR 
					  cy1_last_online_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR cy1_last_othr_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE) OR cy1_last_f2f_sustnr_gift_dt >= DATEADD(month, -2, CURRENT_DATE)
					THEN 1 ELSE 0 END AS current_sustnr_ind,
			  CASE WHEN cy0_offline_sustainer_ind = 1 OR cy0_online_sustainer_ind = 1 OR cy0_phone_sustainer_ind = 1 OR cy0_othr_sustainer_ind = 1 OR cy0_f2f_sustainer_ind = 1 THEN 1 ELSE 0 END AS cy0_sustainer_ind,
			  CASE WHEN cy1_offline_sustainer_ind = 1 OR cy1_online_sustainer_ind = 1 OR cy1_phone_sustainer_ind = 1 OR cy1_othr_sustainer_ind = 1 OR cy1_f2f_sustainer_ind = 1 THEN 1 ELSE 0 END AS cy1_sustainer_ind,
			  CASE WHEN cy2_offline_sustainer_ind = 1 OR cy2_online_sustainer_ind = 1 OR cy2_phone_sustainer_ind = 1 OR cy2_othr_sustainer_ind = 1 OR cy2_f2f_sustainer_ind = 1 THEN 1 ELSE 0 END AS cy2_sustainer_ind,     
			  txn.first_sustnr_dt,
			  txn.last_sustnr_dt
			FROM 
			(
				SELECT
					cnst_mstr_id,
					MAX(sustnr_lightbox_ind) sustnr_lightbox_ind,
					SUM(COALESCE(online_sustnr_cnt, 0)) online_sustnr_cnt,
					SUM(COALESCE(offline_sustnr_cnt, 0)) offline_sustnr_cnt,
					SUM(COALESCE(phone_sustnr_cnt, 0)) phone_sustnr_cnt,
					SUM(COALESCE(f2f_sustnr_cnt, 0)) f2f_sustnr_cnt,
					MIN(first_sustnr_gift_dt) first_sustnr_dt,
					MAX(last_sustnr_gift_dt) last_sustnr_dt
				FROM 
				(
					SELECT 
						txn.cnst_mstr_id, 
						0 AS sustnr_lightbox_ind,
						SUM(CASE WHEN recurring_ind = 1 THEN 1 ELSE 0 END) AS online_sustnr_cnt, -- 'Online' 
						SUM(CASE WHEN txn.gift_src_cd = 'RQZ00000M000' OR txn.sustnr_typ_key > 0 THEN 1 ELSE 0 END) AS offline_sustnr_cnt, -- txn.gift_src_cd
						SUM(CASE WHEN sustnr.phone_sustnr_gift_ind = 1 THEN 1 ELSE 0 END) AS phone_sustnr_cnt, -- 'Phone'
						SUM(CASE WHEN sustnr.f2f_sustnr_gift_ind = 1 THEN 1 ELSE 0 END) AS f2f_sustnr_cnt, -- 'Phone'
						MIN(CASE WHEN (recurring_ind = 1 AND txn.dntn_gift_dt <= DATE '2020-04-17') OR (recurring_ind = 1 AND txn.dntn_gift_dt > DATE '2020-04-17' AND txn.online_channel_cd = 'OD') OR sustnr.first_online_sustnr_gift_ind = 1 OR txn.gift_src_cd = 'RQZ00000M000' OR sustnr.phone_sustnr_gift_ind = 1 OR f2f_sustnr_gift_ind = 1 OR txn.sustnr_typ_key = 2 THEN txn.dntn_gift_dt ELSE NULL END) AS first_sustnr_gift_dt,
						MAX(CASE WHEN recurring_ind = 1 OR txn.gift_src_cd = 'RQZ00000M000' OR sustnr.phone_sustnr_gift_ind = 1 OR f2f_sustnr_gift_ind = 1 OR txn.sustnr_typ_key <> 0 THEN txn.dntn_gift_dt ELSE NULL END) AS last_sustnr_gift_dt
					FROM mktg_ops_vws.gms_arc_fr_txn txn
					LEFT JOIN mktg_ops_vws.gms_arc_fr_txn_sustnr sustnr ON txn.giftran_key = sustnr.giftran_key AND txn.cnst_mstr_id = sustnr.cnst_mstr_id
					WHERE txn.fr_pmt_amt > 0 
					AND txn.primary_gift_ind = 1
					GROUP BY 1,2
				
					UNION ALL
				
					SELECT 
						brg.cnst_mstr_id,
						1 AS sustnr_lightbox_ind,
						0 AS online_sustnr_cnt,
						0 AS offline_sustnr_cnt,
						0 AS phone_sustnr_cnt,
						0 AS f2f_sustnr_cnt,
						MIN(CAST(sub.created_ts AS DATE)) AS first_sustnr_gift_dt,
						MAX(CAST(sub.created_ts AS DATE)) AS last_sustnr_gift_dt
					FROM eda.rco_vws.bz_dim_trans_billng bil
					INNER JOIN eda.rco_vws.bz_dim_subscription sub ON bil.acct_key = sub.acct_key
					INNER JOIN eda.rco_vws.bz_fact_dnr_trans fdt ON bil.trans_billng_key = fdt.trans_billng_key AND CAST(sub.created_ts AS DATE) = CAST(fdt.dntn_regis_ts AS DATE) AND sub.created_ts >= fdt.dntn_regis_ts
					INNER JOIN eda.rco_vws.bz_dim_CDI_1C_trans_bridge cdi1c ON bil.trans_billng_key = cdi1c.trans_billng_key 
					INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge brg ON cdi1c.acct_prsn_key = brg.cnst_mstr_subj_area_id AND brg.cnst_mstr_subj_area_cd = 'RCO'
					WHERE sub.created_ts >= DATE '2022-04-20'
						AND sub.rcrng_start_ts >= sub.created_ts + INTERVAL '15' DAY
						AND sub.rcrng_start_ts > CURRENT_DATE
						AND sub.first_rco_dntn_id IS NULL 
					GROUP BY 1,2,3,4,5,6
				) txn
				GROUP BY 1
				HAVING SUM(COALESCE(online_sustnr_cnt, 0) + COALESCE(offline_sustnr_cnt, 0) + COALESCE(phone_sustnr_cnt, 0) + COALESCE(f2f_sustnr_cnt, 0)) > 0  
					OR MAX(sustnr_lightbox_ind) = 1 
			) txn

			LEFT JOIN
			(
				SELECT 
					cnst_mstr_id,
					calendar_yr,
					MIN(dntn_gift_dt) AS first_offline_sustnr_gift_dt,
					MAX(dntn_gift_dt) AS last_offline_sustnr_gift_dt,
					COUNT(*) AS offline_sustnr_gift_cnt,
					SUM(fr_pmt_amt) AS offline_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE (gift_src_cd = 'RQZ00000M000' OR sustnr_typ_key > 0) AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE)
				GROUP BY 1,2
			) cy0_sustnr ON txn.cnst_mstr_id = cy0_sustnr.cnst_mstr_id

			LEFT JOIN
			(
				SELECT 
					cnst_mstr_id,
					calendar_yr,
					MIN(dntn_gift_dt) AS first_offline_sustnr_gift_dt,
					MAX(dntn_gift_dt) AS last_offline_sustnr_gift_dt,
					COUNT(*) AS offline_sustnr_gift_cnt,
					SUM(fr_pmt_amt) AS offline_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE (gift_src_cd = 'RQZ00000M000' OR sustnr_typ_key > 0) AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 1
				GROUP BY 1,2
			) cy1_sustnr ON txn.cnst_mstr_id = cy1_sustnr.cnst_mstr_id

			LEFT JOIN
			(
				SELECT 
					cnst_mstr_id,
					calendar_yr,
					MIN(dntn_gift_dt) AS first_offline_sustnr_gift_dt,
					MAX(dntn_gift_dt) AS last_offline_sustnr_gift_dt,
					COUNT(*) AS offline_sustnr_gift_cnt,
					SUM(fr_pmt_amt) AS offline_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE (gift_src_cd = 'RQZ00000M000' OR sustnr_typ_key > 0) AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 2
				GROUP BY 1,2
			) cy2_sustnr ON txn.cnst_mstr_id = cy2_sustnr.cnst_mstr_id

			LEFT JOIN 
			(
				SELECT 
					cnst_mstr_id,
					calendar_yr,
					MIN(dntn_gift_dt) AS first_online_sustnr_gift_dt,
					MAX(dntn_gift_dt) AS last_online_sustnr_gift_dt,
					COUNT(*) AS online_sustnr_gift_cnt,
					SUM(fr_pmt_amt) AS online_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE 
					recurring_ind = 1 
					AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE)
					AND fr_pmt_amt > 0
				GROUP BY 1,2
			  
				UNION ALL 
				
				SELECT 
					brg.cnst_mstr_id,
					EXTRACT(YEAR FROM sub.created_ts) calendar_yr,
					MIN(CAST(sub.created_ts AS DATE)) AS first_online_sustnr_gift_dt,
					MAX(CAST(sub.created_ts AS DATE)) AS last_online_sustnr_gift_dt,
					CAST(0 AS DECIMAL(15,0)) AS online_sustnr_gift_cnt,
					MAX(CAST(sub.amt AS DECIMAL(18,2))) AS online_sustnr_gift_amt
				FROM eda.rco_vws.bz_dim_trans_billng bil
				INNER JOIN eda.rco_vws.bz_dim_subscription sub ON bil.acct_key = sub.acct_key
				INNER JOIN eda.rco_vws.bz_fact_dnr_trans fdt ON bil.trans_billng_key = fdt.trans_billng_key AND CAST(sub.created_ts AS DATE) = CAST(fdt.dntn_regis_ts AS DATE) AND sub.created_ts >= fdt.dntn_regis_ts
				INNER JOIN eda.rco_vws.bz_dim_CDI_1C_trans_bridge cdi1c ON bil.trans_billng_key = cdi1c.trans_billng_key 
				INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge brg ON cdi1c.acct_prsn_key = brg.cnst_mstr_subj_area_id AND brg.cnst_mstr_subj_area_cd = 'RCO'
				WHERE sub.created_ts >= DATE '2022-04-20'
					AND sub.rcrng_start_ts >= sub.created_ts + INTERVAL '15' DAY
					AND sub.rcrng_start_ts > CURRENT_DATE
					AND sub.first_rco_dntn_id IS NULL
					AND EXTRACT(YEAR FROM sub.created_ts) = EXTRACT(YEAR FROM CURRENT_DATE)
					AND brg.cnst_mstr_id NOT IN (SELECT cnst_mstr_id FROM mktg_ops_vws.gms_arc_fr_txn a
						LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
						WHERE recurring_ind = 1 AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) AND fr_pmt_amt > 0 GROUP BY 1)
				GROUP BY 1,2,5
			) cy0_onl_sustnr ON txn.cnst_mstr_id = cy0_onl_sustnr.cnst_mstr_id

			LEFT JOIN 
			(
				SELECT 
					cnst_mstr_id,
					calendar_yr,
					MIN(dntn_gift_dt) AS first_online_sustnr_gift_dt,
					MAX(dntn_gift_dt) AS last_online_sustnr_gift_dt,
					COUNT(*) AS online_sustnr_gift_cnt,
					SUM(fr_pmt_amt) AS online_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE 
					recurring_ind = 1 
					AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 1
					AND fr_pmt_amt > 0
				GROUP BY 1,2
			  
				UNION ALL 
				
				SELECT 
					brg.cnst_mstr_id,
					EXTRACT(YEAR FROM sub.created_ts) calendar_yr,
					MIN(CAST(sub.created_ts AS DATE)) AS first_online_sustnr_gift_dt,
					MAX(CAST(sub.created_ts AS DATE)) AS last_online_sustnr_gift_dt,
					CAST(0 AS DECIMAL(15,0)) AS online_sustnr_gift_cnt,
					MAX(CAST(sub.amt AS DECIMAL(18,2))) AS online_sustnr_gift_amt
				FROM eda.rco_vws.bz_dim_trans_billng bil
				INNER JOIN eda.rco_vws.bz_dim_subscription sub ON bil.acct_key = sub.acct_key
				INNER JOIN eda.rco_vws.bz_fact_dnr_trans fdt ON bil.trans_billng_key = fdt.trans_billng_key AND CAST(sub.created_ts AS DATE) = CAST(fdt.dntn_regis_ts AS DATE) AND sub.created_ts >= fdt.dntn_regis_ts
				INNER JOIN eda.rco_vws.bz_dim_CDI_1C_trans_bridge cdi1c ON bil.trans_billng_key = cdi1c.trans_billng_key 
				INNER JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge brg ON cdi1c.acct_prsn_key = brg.cnst_mstr_subj_area_id AND brg.cnst_mstr_subj_area_cd = 'RCO'
				WHERE sub.created_ts >= DATE '2022-04-20'
					AND sub.rcrng_start_ts >= sub.created_ts + INTERVAL '15' DAY
					AND sub.rcrng_start_ts > CURRENT_DATE
					AND sub.first_rco_dntn_id IS NULL
					AND EXTRACT(YEAR FROM sub.created_ts) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
					AND brg.cnst_mstr_id NOT IN (SELECT cnst_mstr_id FROM mktg_ops_vws.gms_arc_fr_txn a
						LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
						WHERE recurring_ind = 1 AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 1 AND fr_pmt_amt > 0 GROUP BY 1)
				GROUP BY 1,2,5
			) cy1_onl_sustnr ON txn.cnst_mstr_id = cy1_onl_sustnr.cnst_mstr_id

			LEFT JOIN 
			(
				SELECT 
					cnst_mstr_id,
					calendar_yr,
					MIN(dntn_gift_dt) AS first_online_sustnr_gift_dt,
					MAX(dntn_gift_dt) AS last_online_sustnr_gift_dt,
					COUNT(*) AS online_sustnr_gift_cnt,
					SUM(fr_pmt_amt) AS online_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE 
					recurring_ind = 1 
					AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 2
					AND fr_pmt_amt > 0
				GROUP BY 1,2
			) cy2_onl_sustnr ON txn.cnst_mstr_id = cy2_onl_sustnr.cnst_mstr_id

			LEFT JOIN
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_phone_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_phone_sustnr_gift_dt,
					COUNT(*) AS phone_sustnr_gift_cnt,
					SUM(txn.fr_pmt_amt) AS phone_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn_sustnr a
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn txn ON a.giftran_key = txn.giftran_key AND a.cnst_mstr_id = txn.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE phone_sustnr_gift_ind = 1 AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE)
				GROUP BY 1,2
			) cy0_phn_sustnr ON txn.cnst_mstr_id = cy0_phn_sustnr.cnst_mstr_id

			LEFT JOIN
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_phone_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_phone_sustnr_gift_dt,
					COUNT(*) AS phone_sustnr_gift_cnt,
					SUM(txn.fr_pmt_amt) AS phone_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn_sustnr a
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn txn ON a.giftran_key = txn.giftran_key AND a.cnst_mstr_id = txn.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE phone_sustnr_gift_ind = 1 AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 1
				GROUP BY 1,2
			) cy1_phn_sustnr ON txn.cnst_mstr_id = cy1_phn_sustnr.cnst_mstr_id

			LEFT JOIN 
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_phone_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_phone_sustnr_gift_dt,
					COUNT(*) AS phone_sustnr_gift_cnt,
					SUM(txn.fr_pmt_amt) AS phone_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn_sustnr a
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn txn ON a.giftran_key = txn.giftran_key AND a.cnst_mstr_id = txn.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE phone_sustnr_gift_ind = 1 AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 2
				GROUP BY 1,2
			) cy2_phn_sustnr ON txn.cnst_mstr_id = cy2_phn_sustnr.cnst_mstr_id

			LEFT JOIN
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_othr_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_othr_sustnr_gift_dt,
					COUNT(*) AS othr_sustnr_gift_cnt,
					SUM(a.fr_pmt_amt) AS othr_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn_sustnr phn ON a.giftran_key = phn.giftran_key AND a.cnst_mstr_id = phn.cnst_mstr_id
				LEFT JOIN fund_ranking c ON a.trans_fund_cd = c.fund_cd AND c.rn = 1
				WHERE phone_sustnr_gift_ind = 0 AND recurring_ind = 0 AND f2f_sustnr_gift_ind = 0 AND
						a.gift_src_cd <> 'RQZ00000M000' AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) AND 
						((c.gl_company_fund_cd NOT IN ('051', '052', '062') AND trans_fund_cd <> '4900--dm') OR trans_fund_cd = '4900-dm')
				GROUP BY 1,2
				HAVING COUNT(*) >= 4
			) cy0_othr_sustnr ON txn.cnst_mstr_id = cy0_othr_sustnr.cnst_mstr_id

			LEFT JOIN 
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_othr_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_othr_sustnr_gift_dt,
					COUNT(*) AS othr_sustnr_gift_cnt,
					SUM(a.fr_pmt_amt) AS othr_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn_sustnr phn ON a.giftran_key = phn.giftran_key AND a.cnst_mstr_id = phn.cnst_mstr_id
				LEFT JOIN fund_ranking c ON a.trans_fund_cd = c.fund_cd AND c.rn = 1
				WHERE phone_sustnr_gift_ind = 0 AND recurring_ind = 0 AND f2f_sustnr_gift_ind = 0 AND
						a.gift_src_cd <> 'RQZ00000M000' AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 1 AND 
						((c.gl_company_fund_cd NOT IN ('051', '052', '062') AND trans_fund_cd <> '4900--dm') OR trans_fund_cd = '4900-dm')
				GROUP BY 1,2
				HAVING COUNT(*) >= 4
			) cy1_othr_sustnr ON txn.cnst_mstr_id = cy1_othr_sustnr.cnst_mstr_id

			LEFT JOIN 
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_othr_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_othr_sustnr_gift_dt,
					COUNT(*) AS othr_sustnr_gift_cnt,
					SUM(a.fr_pmt_amt) AS othr_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn a
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn_sustnr phn ON a.giftran_key = phn.giftran_key AND a.cnst_mstr_id = phn.cnst_mstr_id
				LEFT JOIN fund_ranking c ON a.trans_fund_cd = c.fund_cd AND c.rn = 1
				WHERE phone_sustnr_gift_ind = 0 AND recurring_ind = 0 AND f2f_sustnr_gift_ind = 0 AND
						a.gift_src_cd <> 'RQZ00000M000' AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 2 AND 
						((c.gl_company_fund_cd NOT IN ('051', '052', '062') AND trans_fund_cd <> '4900--dm') OR trans_fund_cd = '4900-dm')
				GROUP BY 1,2
				HAVING COUNT(*) >= 4
			) cy2_othr_sustnr ON txn.cnst_mstr_id = cy2_othr_sustnr.cnst_mstr_id

			LEFT JOIN 
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_f2f_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_f2f_sustnr_gift_dt,
					COUNT(*) AS f2f_sustnr_gift_cnt,
					SUM(txn.fr_pmt_amt) AS f2f_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn_sustnr a
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn txn ON a.giftran_key = txn.giftran_key AND a.cnst_mstr_id = txn.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE f2f_sustnr_gift_ind = 1 AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE)
				GROUP BY 1,2
			) cy0_f2f_sustnr ON txn.cnst_mstr_id = cy0_f2f_sustnr.cnst_mstr_id

			LEFT JOIN
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_f2f_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_f2f_sustnr_gift_dt,
					COUNT(*) AS f2f_sustnr_gift_cnt,
					SUM(txn.fr_pmt_amt) AS f2f_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn_sustnr a
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn txn ON a.giftran_key = txn.giftran_key AND a.cnst_mstr_id = txn.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE f2f_sustnr_gift_ind = 1 AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 1
				GROUP BY 1,2
			) cy1_f2f_sustnr ON txn.cnst_mstr_id = cy1_f2f_sustnr.cnst_mstr_id

			LEFT JOIN
			(
				SELECT 
					a.cnst_mstr_id,
					calendar_yr,
					MIN(a.dntn_gift_dt) AS first_f2f_sustnr_gift_dt,
					MAX(a.dntn_gift_dt) AS last_f2f_sustnr_gift_dt,
					COUNT(*) AS f2f_sustnr_gift_cnt,
					SUM(txn.fr_pmt_amt) AS f2f_sustnr_gift_amt
				FROM mktg_ops_vws.gms_arc_fr_txn_sustnr a
				LEFT JOIN mktg_ops_vws.gms_arc_fr_txn txn ON a.giftran_key = txn.giftran_key AND a.cnst_mstr_id = txn.cnst_mstr_id
				LEFT JOIN eda.dw_common_vws.dim_calendar b ON a.dntn_gift_dt = b.calendar_dt
				WHERE f2f_sustnr_gift_ind = 1 AND calendar_yr = EXTRACT(YEAR FROM CURRENT_DATE) - 2
				GROUP BY 1,2
			) cy2_f2f_sustnr ON txn.cnst_mstr_id = cy2_f2f_sustnr.cnst_mstr_id
)
		SELECT  cnst_mstr_id, cy0_year_dsc, cy0_first_offline_sustnr_gift_dt,
				cy0_last_offline_sustnr_gift_dt, cy0_offline_sustnr_gift_cnt,
				cy0_offline_sustnr_gift_amt, cy1_year_dsc, cy1_first_offline_sustnr_gift_dt,
				cy1_last_offline_sustnr_gift_dt, cy1_offline_sustnr_gift_cnt,
				cy1_offline_sustnr_gift_amt, cy2_year_dsc, cy2_first_offline_sustnr_gift_dt,
				cy2_last_offline_sustnr_gift_dt, cy2_offline_sustnr_gift_cnt,
				cy2_offline_sustnr_gift_amt, cy0_first_online_sustnr_gift_dt,
				cy0_last_online_sustnr_gift_dt, cy0_online_sustnr_gift_cnt, cy0_online_sustnr_gift_amt,
				cy1_first_online_sustnr_gift_dt, cy1_last_online_sustnr_gift_dt,
				cy1_online_sustnr_gift_cnt, cy1_online_sustnr_gift_amt, cy2_first_online_sustnr_gift_dt,
				cy2_last_online_sustnr_gift_dt, cy2_online_sustnr_gift_cnt, cy2_online_sustnr_gift_amt,
				cy0_first_phone_sustnr_gift_dt, cy0_last_phone_sustnr_gift_dt,
				cy0_phone_sustnr_gift_cnt, cy0_phone_sustnr_gift_amt, cy1_first_phone_sustnr_gift_dt,
				cy1_last_phone_sustnr_gift_dt, cy1_phone_sustnr_gift_cnt, cy1_phone_sustnr_gift_amt,
				cy2_first_phone_sustnr_gift_dt, cy2_last_phone_sustnr_gift_dt,
				cy2_phone_sustnr_gift_cnt, cy2_phone_sustnr_gift_amt, cy0_first_othr_sustnr_gift_dt,
				cy0_last_othr_sustnr_gift_dt, cy0_othr_sustnr_gift_cnt, cy0_othr_sustnr_gift_amt,
				cy1_first_othr_sustnr_gift_dt, cy1_last_othr_sustnr_gift_dt,
				cy1_othr_sustnr_gift_cnt, cy1_othr_sustnr_gift_amt, cy2_first_othr_sustnr_gift_dt,
				cy2_last_othr_sustnr_gift_dt, cy2_othr_sustnr_gift_cnt, cy2_othr_sustnr_gift_amt,
				cy0_first_f2f_sustnr_gift_dt, cy0_last_f2f_sustnr_gift_dt, cy0_f2f_sustnr_gift_cnt,
				cy0_f2f_sustnr_gift_amt, cy1_first_f2f_sustnr_gift_dt, cy1_last_f2f_sustnr_gift_dt,
				cy1_f2f_sustnr_gift_cnt, cy1_f2f_sustnr_gift_amt, cy2_first_f2f_sustnr_gift_dt,
				cy2_last_f2f_sustnr_gift_dt, cy2_f2f_sustnr_gift_cnt, cy2_f2f_sustnr_gift_amt,
				cy0_offline_sustainer_ind, cy0_offline_sustainer_flg, cy1_offline_sustainer_ind,
				cy1_offline_sustainer_flg, cy2_offline_sustainer_ind, cy2_offline_sustainer_flg,
				cy0_online_sustainer_ind, cy0_online_sustainer_flg, cy1_online_sustainer_ind,
				cy1_online_sustainer_flg, cy2_online_sustainer_ind, cy2_online_sustainer_flg,
				cy0_phone_sustainer_ind, cy0_phone_sustainer_flg, cy1_phone_sustainer_ind,
				cy1_phone_sustainer_flg, cy2_phone_sustainer_ind, cy2_phone_sustainer_flg,
				cy0_othr_sustainer_ind, cy0_othr_sustainer_flg, cy1_othr_sustainer_ind,
				cy1_othr_sustainer_flg, cy2_othr_sustainer_ind, cy2_othr_sustainer_flg,
				cy0_f2f_sustainer_ind, cy0_f2f_sustainer_flg, cy1_f2f_sustainer_ind,
				cy1_f2f_sustainer_flg, cy2_f2f_sustainer_ind, cy2_f2f_sustainer_flg,
				current_sustnr_ind,
				cy0_sustainer_ind, cy1_sustainer_ind, cy2_sustainer_ind,
				first_sustnr_dt, 
				last_sustnr_dt
		FROM gms_arc_fr_smry_sustnr_src;
		
		-- Only proceed to target table if staging was successful
        TRUNCATE TABLE mktg_ops_tbls.gms_arc_fr_smry_sustnr;

		INSERT INTO mktg_ops_tbls.gms_arc_fr_smry_sustnr
		SELECT  a.cnst_mstr_id, cy0_year_dsc, cy0_first_offline_sustnr_gift_dt,
				cy0_last_offline_sustnr_gift_dt, cy0_offline_sustnr_gift_cnt,
				cy0_offline_sustnr_gift_amt, cy1_year_dsc, cy1_first_offline_sustnr_gift_dt,
				cy1_last_offline_sustnr_gift_dt, cy1_offline_sustnr_gift_cnt,
				cy1_offline_sustnr_gift_amt, cy2_year_dsc, cy2_first_offline_sustnr_gift_dt,
				cy2_last_offline_sustnr_gift_dt, cy2_offline_sustnr_gift_cnt,
				cy2_offline_sustnr_gift_amt, cy0_first_online_sustnr_gift_dt,
				cy0_last_online_sustnr_gift_dt, cy0_online_sustnr_gift_cnt, cy0_online_sustnr_gift_amt,
				cy1_first_online_sustnr_gift_dt, cy1_last_online_sustnr_gift_dt,
				cy1_online_sustnr_gift_cnt, cy1_online_sustnr_gift_amt, cy2_first_online_sustnr_gift_dt,
				cy2_last_online_sustnr_gift_dt, cy2_online_sustnr_gift_cnt, cy2_online_sustnr_gift_amt,
				cy0_first_phone_sustnr_gift_dt, cy0_last_phone_sustnr_gift_dt,
				cy0_phone_sustnr_gift_cnt, cy0_phone_sustnr_gift_amt, cy1_first_phone_sustnr_gift_dt,
				cy1_last_phone_sustnr_gift_dt, cy1_phone_sustnr_gift_cnt, cy1_phone_sustnr_gift_amt,
				cy2_first_phone_sustnr_gift_dt, cy2_last_phone_sustnr_gift_dt,
				cy2_phone_sustnr_gift_cnt, cy2_phone_sustnr_gift_amt, cy0_first_othr_sustnr_gift_dt,
				cy0_last_othr_sustnr_gift_dt, cy0_othr_sustnr_gift_cnt, cy0_othr_sustnr_gift_amt,
				cy1_first_othr_sustnr_gift_dt, cy1_last_othr_sustnr_gift_dt,
				cy1_othr_sustnr_gift_cnt, cy1_othr_sustnr_gift_amt, cy2_first_othr_sustnr_gift_dt,
				cy2_last_othr_sustnr_gift_dt, cy2_othr_sustnr_gift_cnt, cy2_othr_sustnr_gift_amt,
				cy0_first_f2f_sustnr_gift_dt, cy0_last_f2f_sustnr_gift_dt, cy0_f2f_sustnr_gift_cnt,
				cy0_f2f_sustnr_gift_amt, cy1_first_f2f_sustnr_gift_dt, cy1_last_f2f_sustnr_gift_dt,
				cy1_f2f_sustnr_gift_cnt, cy1_f2f_sustnr_gift_amt, cy2_first_f2f_sustnr_gift_dt,
				cy2_last_f2f_sustnr_gift_dt, cy2_f2f_sustnr_gift_cnt, cy2_f2f_sustnr_gift_amt,
				cy0_offline_sustainer_ind, cy0_offline_sustainer_flg, cy1_offline_sustainer_ind,
				cy1_offline_sustainer_flg, cy2_offline_sustainer_ind, cy2_offline_sustainer_flg,
				cy0_online_sustainer_ind, cy0_online_sustainer_flg, cy1_online_sustainer_ind,
				cy1_online_sustainer_flg, cy2_online_sustainer_ind, cy2_online_sustainer_flg,
				cy0_phone_sustainer_ind, cy0_phone_sustainer_flg, cy1_phone_sustainer_ind,
				cy1_phone_sustainer_flg, cy2_phone_sustainer_ind, cy2_phone_sustainer_flg,
				cy0_othr_sustainer_ind, cy0_othr_sustainer_flg, cy1_othr_sustainer_ind,
				cy1_othr_sustainer_flg, cy2_othr_sustainer_ind, cy2_othr_sustainer_flg,
				cy0_f2f_sustainer_ind, cy0_f2f_sustainer_flg, cy1_f2f_sustainer_ind,
				cy1_f2f_sustainer_flg, cy2_f2f_sustainer_ind, cy2_f2f_sustainer_flg,
				current_sustnr_ind,
				cy0_sustainer_ind, cy1_sustainer_ind, cy2_sustainer_ind,
				first_sustnr_dt, 
				COALESCE(b.fr_pmt_amt, 0) as first_sustnr_gift_amt,
				last_sustnr_dt,
				COALESCE(c.fr_pmt_amt, 0) as last_sustnr_gift_amt        
		FROM mktg_stage_tbls.gms_arc_fr_smry_sustnr_stg a
		LEFT JOIN 
		(
			select 
				cnst_mstr_id,
				dntn_gift_dt,
				sum(fr_pmt_amt) as fr_pmt_amt
			from mktg_ops_vws.gms_arc_fr_txn
			group by 1,2
		) b on a.cnst_mstr_id = b.cnst_mstr_id and a.first_sustnr_dt = b.dntn_gift_dt
		LEFT JOIN 
		(
			select 
				cnst_mstr_id,
				dntn_gift_dt,
				sum(fr_pmt_amt) as fr_pmt_amt
			from mktg_ops_vws.gms_arc_fr_txn
			group by 1,2
		) c on a.cnst_mstr_id = c.cnst_mstr_id and a.last_sustnr_dt = c.dntn_gift_dt;

		v_end_time := GETDATE();
		v_ok_message = cast((select count(*) from mods_bi.mktg_ops_tbls.gms_arc_fr_smry_sustnr) as nvarchar)+ ' Records inserted.';
        
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message
        WHERE proc_name = 'ld_gms_arc_fr_smry_sustnr' 
        AND task_name = 'Stored Procedure' 
        AND start_time = v_start_time;

    EXCEPTION
		WHEN OTHERS THEN
			v_end_time := GETDATE(); 
			v_error_message := 'Error in ld_gms_arc_fr_smry_sustnr: ' || SQLERRM;
        
			-- Log the error before raising the exception
			INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time, end_time, TaskMessage)
			VALUES ('ld_gms_arc_fr_smry_sustnr', 'Stored Procedure', 'ERROR', v_start_time, v_end_time, v_error_message);

			-- Now raise the exception
			RAISE EXCEPTION 'An error occurred: %', SQLERRM;
	END;
END;
$$
