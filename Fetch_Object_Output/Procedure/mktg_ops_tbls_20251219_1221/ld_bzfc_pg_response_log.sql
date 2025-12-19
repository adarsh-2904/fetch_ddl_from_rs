CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_pg_response_log()
 LANGUAGE plpgsql
AS $_$
	
/* ---------------------------------------------------------------------------------------------------------------------------

Created by: Majeed Mohammad
Created On: 08/31/2021
Purpose: Macro to instantiate the table mktg_ops_tbls.bzfc_pg_response_log 

Modified By:  Michael Andrien
Modified Date:  09/01/2021
Purpose: Added a qualifier to the mktg_stage_tbls.dm_response_gplg_stg_hist table query to exclude logically deleted (row_stat_cd = 'L') CDS response data.  We
logically deleted 16,565 rows from the history response table to eliminate duplicate response data between the history and glpg stage tables.

Modified By:  Michael Andrien
Modified Date:  09/02/2021
Purpose:  Added the section at the end of the macro to insert new rows into the bzfc_pg_response_log_ref table.  This establishes the pg_response_log_key for the 
respons log rows and preserves the values when the bzfc_pg_response_log table gets truncated and reloaded on a daily basis.  We need to 
preserver the keys in a separate table to ensure the keys do not change because they are referenced in the lead generation PBI interface to allow
gift planning officers (GPO) to add comments to the leads and to assign leads to GPOs.

Modified By:  Michael Andrien
Modified Date:  09/13/2021
Purpose: Apply source code (src_cd) updates to PG Calc (Digital) response rows where the source code is null and the derived campaign is not null)

Modified By:  Michael Andrien
Modified Date:  09/27/2021
Purpose: Corrected a column ordering issue where the age and story attributes were in the wrong order in the CDS section of the queries below.

Modified By:  Michael Andrien
Modified Date:  10/26/2021
Purpose:  Fixed the arc_story and age column order in the PG Calc and Hist queries.  Also, 
  --Added Case statement to Adobe Survey section for marital_status - setting Casado to Married and Vuido to Widowed
  -- means_of_support_volunteering - added case logic to standardize format
  --means_of_support_check_credit_card - added case logic to standardize format
  --arc_programs_important_to_provide_arc_services_in_future - added case logic to standardize format

Modified By:  Michael Andrien
Modified Date:  10/27/2021
Purpose:  Added the UPDATE section to UPDATE the master id and stuart list processing date for the records sent to Stuart.  
These are the records we were not able to match through our standard matching process.

Modified By:  Michael Andrien
Modified Date:  01/27/2022
Purpose:  Added coalesce statements to the phone attribute for the Adobe Survey and Survey History UNION ALL queries.  We originally mapped NULL values to 
the phone attribute.  Now we first take the phone from the survey source, if that is null we take the primary phone from the FR preferred, if that is null we take the phone found in ARC Best.

Modified By:  Michael Andrien
Modified Date:  01/31/2022
Purpose:  Added coalesce statements to the name and address components found in the Adobe Survey Insert section.  
The ranking is 1) survey response value, 2) FR Preferred EM/EM, 3) ARC Best

Modified By:  Michael Andrien
Modified Date:  02/24/2022
Purpose:  Added coalesce statements to email and phone for all UNION ALL queries.

Modified By:  Michael Andrien
Modified Date:  07/22/2022
Purpose:  Added new Freewill attributes to the UNIONed queries.  Also, modified the Stuart list UPDATE section
to include the FRWL source.

Modified By:  Michael Andrien
Modified Date:  07/28/2022
Purpose:  Added the condition below to the WHERE clause for the historic response data (mktg_stage_tbls.dm_response_gplg_stg_hist) load section to include legacy PG Survey response data prior to Jan 1st 2020.
  --or (substr(d.pg_src_cd,8,1) = '4' and response_dt <='01/01/2020')
  
Modified By:  Michael Andrien
Modified Date:  09/27/2022
Purpose:  Added case logic to fix null birth_dt and spouse_birth_dt issue when the birth_dt_src and spouse_birth_dt_src attributes are not null.
  case 
    when birth_dt is null and birth_dt_src is not null and length(birth_dt_src) = 10 and instr(birth_dt_src, '-', 1,1) = 5 then cast(cast(oreplace(birth_dt_src,'-','') as date format 'yyyymmdd') as date format 'mm/dd/yyyy')
    when extract(year from birth_dt) between 0000 and 0099 then add_months(birth_dt,22800) 
    else birth_dt 
  end as birth_dt, 
  case 
    when spouse_birth_dt is null and spouse_birth_dt_src is not null and length(spouse_birth_dt_src) = 10 and instr(spouse_birth_dt_src, '-', 1,1) = 5 then cast(cast(oreplace(spouse_birth_dt_src,'-','') as date  format 'yyyymmdd') as date format 'mm/dd/yyyy')
    when extract(year from spouse_birth_dt) between 0000 and 0099 then add_months(spouse_birth_dt,22800) 
    else spouse_birth_dt 
  end as spouse_birth_dt, 

Modified By:  Michael Andrien
Modified Date:  11/04/2022
Purpose:  Modified the WHERE clause on the UPDATE statement for the SNQH - Stuart updates.  The UPDATE was overriding an non-zero cnst_mstr_id value in the cnst_mstr_id in the bzfc_pg_response_log with a zero value 
in some cases. The revise where clause fixes this issue.
    where --(a.cnst_mstr_id = 0 and 
    (zeroifnull(c.cnst_mstr_id) <> 0 and a.cnst_mstr_id = 0) --or (a.appl_src_cd in ('FRWL', 'PGC') and stuart_list_proc_dt is null and a.cnst_mstr_id = 0)

Modified By:  Michael Andrien
Modified Date:  11/16/2022
Purpose: Added  Freewill unique gift id (frwl_gift_id) to the merge table definition and load.

Modified By:  Michael Andrien
Modified Date:  12/01/2022
Purpose: Added the hist_seqnum, history_record_id attributes to the bzfc_pg_response_log and bzfc_pg_response_log_ref tables.  These are the unique ids for the historical PG and Adobe survey response data sets. Including these ids 
the log tables will improve our match rates and recduce the number of orphaned pg_response_log_key records in the log ref table.

Modified By:  Michael Andrien
Modified Date:  01/04/2023
Purpose: Modified the bzfc_pg_response_log_ref insert from a generic insert that applied to all data sources to separate insert for each data source (FRWL, PGC, HIST, CDS, ADBE).  Each source except the PGC source
joins on a unique id, which should reduce or eliminate orphaned reference records from being created.

Modified By:  Michael Andrien
Modified Date:  01/18/2023
Purpose: Added the means_of_support_beneficiary_designation attribute to each data source insert statement.  The new question was added to the 
FY23 PG Supporter Survey.  We did not ask our data vendors to add this to the standard PG response data format so I've set a NULL value default for all data sources exept our survey response source.

Modified By:  Michael Andrien
Modified Date:  01/30/2023
Purpose:  Added qualify statements to the CDS and Adobe Survey queries to address duplicate response rows and modified the where clause in the Historic data query to exclude survey response data after 2020 - these are covered in the Adobe Survery query section.  Also,
split the Stuart master id UPDATE section into five separate updates by source (PGC, HIST, FRWL, CDS, ADBE)

Modified By:  Michael Andrien
Modified Date:  04/17/2023
Purpose:  Modifier the where clause for historical data load from <= '01/01/202' to '12/31/2020'

Modified By:  Greg Seaberg
Implemented By:   Michael Andrien
Modified Date:  04/17/2023
Purpose:  Modified the where clause for historical data load to a case statement to exclude FY20 supporter survey responses that were submitted via an Adobe web form
    Email responses are identified based on source code APP20064E000
    DM responses (submitted online) are identified based on a combination of source code APP20054M000 and a null value for CDS image ID

Modified By:  Michael Andrien
Modified Date:  07/11/2023
Purpose: Added the 3 new attributes below. and modified the PGCalc bzfc_pg_response_log_ref insert log 
  pgc_response_id
  phone_mobile_ind
  phone_home_ind

Modified By:  Michael Andrien
Modified Date:  11/02/2023
Purpose: Modified references to the FRWL gift_created_dt attribute.  This was changed to gift_created_ts in the source table so we applied the appropriate casts column refs. Also, added
cast timestamp as date logic to the dcmnt_created_ts and chng_made_ts attributes that were changed from dt to ts.


Modified By:  Greg Seaberg
Implemented By:   Majeed Mohammad
Modified Date:  01/23/2024
Purpose:   Added this logic to the first SQL for PG Calc online responses to calculate the derived_campaign
         regexp_substr(site_url, '(?<=tracking\/)(.*?)(?=\.php)',1,1,'i') as derived_campaign

Modified By:  Greg Seaberg
Implemented By:   Majeed Mohammad
Modified Date:  01/25/2024
Purpose:   Removed the cast as smallint for the columns (means_of_support_gift_in_your_will_honoring_a_loved_one & means_of_support_beneficiary_designation) in the second union of INSERT to mktg_ops_tbls.bzfc_pg_response_log . 
          Replaced this with a to_number function that can handle both integer and char values. 

        Updated the derived_campaign column as 
      coalesce(nullif(trim(derived_campaign),''), 
        regexp_substr(site_url, '(?<=tracking\/)(.*?)(?=\.php)',1,1,'i'), 
         regexp_substr(site_url, '(?<=mailers\/)(.*?)(?=\.php)',1,1,'i'), 
          substr(site_url, instr(site_url,'/',1,3) + 1, coalesce(nullifzero(instr(site_url,'?')) - 1,length(site_url)) - instr(site_url,'/',1,3))) derived_campgn,

Modified By:  Greg Seaberg
Implemented By: Michael Hall
Modified Date:  02/15/2024
Purpose: Added phone type decode logic for SQL query that includes the Adobe survey responses:
  cast(CASE WHEN a.phone_typ = 'Mobile' THEN 1 ELSE 0 END AS BYTEINT) as phone_mobile_ind,
  cast(CASE WHEN a.phone_typ = 'Home' THEN 1 ELSE 0 END AS BYTEINT) as phone_home_ind,

Modified By:  	Greg Seaberg
Implemented By: Michael Andrien
Modified Date:  04/26/2024
Purpose: 				Added MDS responses from TM lead generation campaign

Modified By:  	Greg Seaberg
Implemented By: Michael Andrien
Modified Date:  05/07/2024
Purpose: 				Corrected issue with MDS responses that previously included address line 1 from arc_best_smry in the coalesce statement for address line 2
								Added fr_prfr and arc_best_smry to coalesce statement for clnsd_email_addr
								Added eoc.cmnt to wg_fdbck field in MDS section of UNION ALL
Modified By:  	Greg Seaberg
Implemented By: Michael Hall
Modified Date:  05/23/2024
Purpose: 				Increased data length of wg_fdbck column from 50 characters to 256 characters as the user comment field was being truncated.

Modified By:  Michael Andrien
Modified Date:  07/30/2024
Purpose: Added wg_intend_arc_in_will attribute to the table

Modified By:  Michael Andrien
Modified Date:  01/23/2025
Purpose: Added the attributes below to the unioned queries
    cntct_prfrnc
    giving_reason_frnd_fmly_mbr_suprtr
    means_of_support_gift_ira_chrtbl_dstrbtn
Modified By:  Michael Andrien
Modified Date:  01/27/2025
Purpose:  Fixed the 'Intends' and 'Would Consider' response values for the 'Means of Support' questions.  The Intends option was missing for several questions.

Modified by: Michael Andrien
Modified On: 01/30/2025
Purpose:    Added cntct_prfrnc_phone_ind, cntct_prfrnc_email_ind, cntct_prfrnc_text_ind attributes to the macro/table.

Modified By:  Michael Andrien
Modified Date:  02/11/2025
Purpose: Updated the cntct_prfrnc_phone, cntct_prfrnc_text, cntct_prfrnc_email and means_of_support_gift_from_ira_by_qcd 
and means_of_support_gift_in_your_will_honoring_a_loved_one mapping logic for the CDS offline, FRWL and PGCalc insert/selects

Modified By:  Michael Andrien
Modified Date:  04/07/2025
Purpose:    Added 6 new attributes: jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc and gft_cmnts

Modified by: Michael Andrien
Modified date: 04/23/2025
Purpose: Added MDS call recording file name attribute to the table - rcrdg_file_nm.

Modified by: Michael Andrien
Modified date: 08/07/2025
Purpose: Update the mapping logic for all the 'means_of_support...' questions to set resonse values = 3 to 'Would consider' for responses associated with
iwebappid values before 230148501 and to 'Intend' for iwebappid values on or after 230148501
    WHEN iwebappid < 230148501 THEN 'Would consider' 
    WHEN iwebappid >= 230148501 THEN 'Intend' 

Modified by: 	Greg Seaberg
Implemented by: Michael Andrien
Modified date: 	08/11/2025
Purpose: 				Update the logic for MDS TM responses to select active records over logically deleted records
								Exclude mds_rspns_typ = 'NOT CONTACTED' records

Modified by: 	Adarsh
Implemented by: Michael Andrien
Modified date: 	08/13/2025
Purpose: 		Implemented individual insert into instead of union all
*/

	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_pg_response_log', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
	truncate table mktg_ops_tbls.bzfc_pg_response_log;	

INSERT INTO mktg_ops_tbls.bzfc_pg_response_log 
 (
	clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign,
	first_response_dt, response_group_dsc, response_cnt, first_response_ts,
	match_lob_src, match_typ, cds_batch_number, cds_sequence_number,
	response_ts_src, response_ts, response_dt, site_url, lander_type,
	nk_ecode, src_cd_src, scr_cd, cnst_mstr_id_src, 
	cnst_mstr_id,
	orig_cnst_mstr_id, 
	ttl, first_nm, middle_nm, last_nm, sfx, prf_ttl,
	cmpny_nm, 
	birth_dt_src, birth_dt, 
	spouse_birth_dt_src, spouse_birth_dt,     
	addr_ln1, addr_ln2, addr_ln3, city, state, zip_cd, 
	phone_num, phone_mobile_ind, phone_home_ind,
	email_addr, 
    cntct_prfrnc,
    cntct_prfrnc_phone_ind, cntct_prfrnc_text_ind, cntct_prfrnc_email_ind,
    cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
    giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, means_of_support_volunteering,
	means_of_support_gift_in_your_will, means_of_support_gift_in_your_will_honoring_a_loved_one,
	means_of_support_beneficiary_designation,
    means_of_support_gift_ira_chrtbl_dstrbtn,
	means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	gift_typ,
	gift_created_dt_src,
	gift_created_dt,
	dcmnt_created_dt_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	don_ext_id,
	frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	chng_made_dt_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
	jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
    mds_pg_response_typ,
	hist_seqnum, history_record_id,
	pgc_response_id,
	mds_unq_id,
    rcrdg_file_nm,
	curr_prcsd_file_nm, last_match_proc_dt, stuart_list_proc_dt,
	dw_trans_ts, row_stat_cd, appl_src_cd, load_id 
)
SELECT  
/* Set 2 character first names to uppercase to standardize and clean response names.  Otherwise, we format the first name to have first initial uppercase.*/
 CAST( CASE 
    WHEN LENGTH(
      COALESCE(
        collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
        collate(a.first_nm::text, 'CASE_INSENSITIVE')
      )
    ) = 2 
    THEN UPPER(
      COALESCE(
        collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
        collate(a.first_nm::text, 'CASE_INSENSITIVE')
      )
    )
    ELSE INITCAP(
      COALESCE(
        collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
        collate(a.first_nm::text, 'CASE_INSENSITIVE')
      )
   )
  END  as VARCHAR(307)) as clnsd_first_nm,  
/*Standardize last name to have first initial uppercase. */ 
	Cast(InitCap(Coalesce(collate(b.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_last_nm::text,'CASE_INSENSITIVE'), collate(a.last_nm::text,'CASE_INSENSITIVE'))) AS varchar(307)) AS clnsd_last_nm,  
	CAST(clnsd_email_addr AS VARCHAR(307)) AS clnsd_email_addr, 
	cast(COALESCE(
        NULLIF(TRIM(derived_campaign), ''),

        -- tracking/ segment
        CASE 
            WHEN site_url LIKE '%/tracking/%' AND site_url LIKE '%.php%' THEN
                SPLIT_PART(SPLIT_PART(site_url, '/tracking/', 2), '.php', 1)
            ELSE NULL
        END,

        -- mailers/ segment
        CASE 
            WHEN site_url LIKE '%/mailers/%' AND site_url LIKE '%.php%' THEN
                SPLIT_PART(SPLIT_PART(site_url, '/mailers/', 2), '.php', 1)
            ELSE NULL
        END,

        -- Fallback: get the path after domain, before query params
        SPLIT_PART(SPLIT_PART(site_url, '/', 4), '?', 1)
    ) as VARCHAR(307))AS derived_campgn,
	first_response_dt, 
	response_group_dsc, 
	response_cnt, 
	first_response_ts,
	match_lob_src, match_typ, cast(cds_batch_number as VARCHAR(307)) as cds_batch_number, cast(cds_sequence_number as VARCHAR(307)) as cds_sequence_number,
	cast(response_ts_src as VARCHAR(307)) as response_ts_src, 
	response_ts, 
	response_dt, 
	site_url, 
	lander_type,
	nk_ecode, 
	src_cd_src, 
	src_cd, 
	cnst_mstr_id_src, 
	a.cnst_mstr_id,
	a.orig_cnst_mstr_id, 
	cast(ttl as VARCHAR(307)) as ttl, 
	cast(first_nm as VARCHAR(307)) as first_nm, 
	cast(middle_nm as VARCHAR(307)) as middle_nm, 
	cast(last_nm as VARCHAR(307)) as last_nm, 
    cast(sfx as VARCHAR(307)) as sfx, 
    prf_ttl,
	cmpny_nm, 
	birth_dt_src, 
	CASE
    -- Format: YYYY-MM-DD (e.g. 1915-10-17)
    WHEN birth_dt IS NULL 
         AND REGEXP_COUNT(birth_dt_src, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') > 0
      THEN TO_DATE(birth_dt_src, 'YYYY-MM-DD')

    -- Format: MM-DD-YYYY (e.g. 04-01-1952)
    WHEN birth_dt IS NULL 
         AND REGEXP_COUNT(birth_dt_src, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$') > 0
      THEN TO_DATE(SUBSTRING(birth_dt_src, 7, 4) || SUBSTRING(birth_dt_src, 1, 2) || SUBSTRING(birth_dt_src, 4, 2), 'YYYYMMDD')

    -- Format: MM/DD/YYYY (e.g. 10/19/1949)
    WHEN birth_dt IS NULL 
         AND REGEXP_COUNT(birth_dt_src, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$') > 0
      THEN TO_DATE(SUBSTRING(birth_dt_src, 7, 4) || SUBSTRING(birth_dt_src, 1, 2) || SUBSTRING(birth_dt_src, 4, 2), 'YYYYMMDD')

    ELSE birth_dt
  END AS birth_dt, 
	spouse_birth_dt_src, 
 	CASE
    -- Format: YYYY-MM-DD (e.g. 1915-10-17)
    WHEN spouse_birth_dt IS NULL 
         AND REGEXP_COUNT(spouse_birth_dt_src, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') > 0
      THEN TO_DATE(spouse_birth_dt_src, 'YYYY-MM-DD')

    -- Format: MM-DD-YYYY (e.g. 04-01-1952)
    WHEN spouse_birth_dt IS NULL 
         AND REGEXP_COUNT(spouse_birth_dt_src, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$') > 0
      THEN TO_DATE(SUBSTRING(spouse_birth_dt_src, 7, 4) || SUBSTRING(spouse_birth_dt_src, 1, 2) || SUBSTRING(spouse_birth_dt_src, 4, 2), 'YYYYMMDD')

    -- Format: MM/DD/YYYY (e.g. 10/19/1949)
    WHEN spouse_birth_dt IS NULL 
         AND REGEXP_COUNT(spouse_birth_dt_src, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$') > 0
      THEN TO_DATE(SUBSTRING(spouse_birth_dt_src, 7, 4) || SUBSTRING(spouse_birth_dt_src, 1, 2) || SUBSTRING(spouse_birth_dt_src, 4, 2), 'YYYYMMDD')

    ELSE spouse_birth_dt
  END AS spouse_birth_dt, 
	addr_ln1, addr_ln2, addr_ln3, cast(city as VARCHAR(307)) as city, state, zip_cd, 
	phone_num, phone_mobile_ind, phone_home_ind,
	email_addr, 
    Cast(NULL AS VARCHAR(25)) AS cntct_prfrnc, 
    CASE WHEN cntct_prfrnc_phone = 'x' THEN 1 ELSE 0 END AS cntct_prfrnc_phone_ind,
    CASE WHEN cntct_prfrnc_text = 'x' THEN 1 ELSE 0 END AS cntct_prfrnc_text_ind,
    CASE WHEN cntct_prfrnc_email = 'x' THEN 1 ELSE 0 END AS cntct_prfrnc_email_ind,
    cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cast(cga_fdbk as VARCHAR(307)) as cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
    Cast(NULL AS VARCHAR(5)) AS giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, means_of_support_volunteering,
	means_of_support_gift_in_your_will, 
    means_of_support_gift_by_beneficiary_designation AS means_of_support_gift_in_your_will_honoring_a_loved_one,  /* Ask Michael Hall and Greg about this */
	means_of_support_gift_by_beneficiary_designation AS means_of_support_beneficiary_designation,
	means_of_support_gift_from_ira_by_qcd AS means_of_support_gift_ira_chrtbl_dstrbtn,    
	means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	gift_typ,
	cast(gift_created_dt_src as VARCHAR(307)) as gift_created_dt_src,
	gift_created_dt,
	cast(dcmnt_created_dt_src as VARCHAR(307)) as dcmnt_created_dt_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	cast(don_ext_id as VARCHAR(307)) as don_ext_id ,
	cast(frwl_gift_id as VARCHAR(307)) as frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	cast(chng_made_dt_src as VARCHAR(307)) as chng_made_dt_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
    jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
	Cast(NULL AS VARCHAR(30)) AS mds_pg_response_typ,
	Cast(NULL AS BIGINT) AS hist_seqnum, 
	Cast(NULL AS INTEGER)  AS history_record_id,
	pgc_response_id,
	Cast(NULL AS VARCHAR(30)) AS mds_unq_id,
	Cast(NULL AS VARCHAR(25)) AS rcrdg_file_nm,
	cast(curr_prcsd_file_nm as VARCHAR(307)) as curr_prcsd_file_nm,  
	last_match_proc_dt, 
	stuart_list_proc_dt,
	dw_trans_ts, row_stat_cd, appl_src_cd, 
    load_id
FROM mktg_stage_tbls.dm_response_gplg_stg_merge a
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr b ON a.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN mktg_ops_vws.bzfc_arc_best_smry c ON a.cnst_mstr_id = c.cnst_mstr_id;

commit;

INSERT INTO mktg_ops_tbls.bzfc_pg_response_log 
 (
	clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign,
	first_response_dt, response_group_dsc, response_cnt, first_response_ts,
	match_lob_src, match_typ, cds_batch_number, cds_sequence_number,
	response_ts_src, response_ts, response_dt, site_url, lander_type,
	nk_ecode, src_cd_src, scr_cd, cnst_mstr_id_src, 
	cnst_mstr_id,
	orig_cnst_mstr_id, 
	ttl, first_nm, middle_nm, last_nm, sfx, prf_ttl,
	cmpny_nm, 
	birth_dt_src, birth_dt, 
	spouse_birth_dt_src, spouse_birth_dt,     
	addr_ln1, addr_ln2, addr_ln3, city, state, zip_cd, 
	phone_num, phone_mobile_ind, phone_home_ind,
	email_addr, 
    cntct_prfrnc,
    cntct_prfrnc_phone_ind, cntct_prfrnc_text_ind, cntct_prfrnc_email_ind,
    cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
    giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, means_of_support_volunteering,
	means_of_support_gift_in_your_will, means_of_support_gift_in_your_will_honoring_a_loved_one,
	means_of_support_beneficiary_designation,
    means_of_support_gift_ira_chrtbl_dstrbtn,
	means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	gift_typ,
	gift_created_dt_src,
	gift_created_dt,
	dcmnt_created_dt_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	don_ext_id,
	frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	chng_made_dt_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
	jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
    mds_pg_response_typ,
	hist_seqnum, history_record_id,
	pgc_response_id,
	mds_unq_id,
    rcrdg_file_nm,
	curr_prcsd_file_nm, last_match_proc_dt, stuart_list_proc_dt,
	dw_trans_ts, row_stat_cd, appl_src_cd, load_id 
)
SELECT  
/* Set 2 character first names to uppercase to standardize and clean response names.  Otherwise, we format the first name to have first initial uppercase.*/
  cast(clnsd_first_nm as VARCHAR(307)) as clnsd_first_nm,  
/*Standardize last name to have first initial uppercase. */ 
  cast(clnsd_last_nm as VARCHAR(307)) as clnsd_last_nm,  
/* Standardize email address to lowercase and remove spaces*/
	cast(clnsd_email_addr as VARCHAR(307)) as clnsd_email_addr, 
	cast(derived_campaign as VARCHAR(307)) as derived_campaign,
	first_response_dt, 
	response_group_dsc, 
	response_cnt, 
	first_response_ts,
	match_lob_src, 
	match_typ, 
	cast(cds_batch_number as VARCHAR(307)) as cds_batch_number, cast(cds_sequence_number as VARCHAR(307)) as cds_sequence_number,
	cast(response_ts_src as VARCHAR(307)) as response_ts_src, 
	response_ts, 
	response_dt, 
	site_url,
    lander_type,
	nk_ecode, src_cd_src, src_cd, 
	cnst_mstr_id_src, 
	cnst_mstr_id,
	orig_cnst_mstr_id, 
	cast(ttl as VARCHAR(307)) as ttl, 
	cast(first_nm as VARCHAR(307)) as first_nm, 
	cast(middle_nm as VARCHAR(307)) as middle_nm, 
	cast(last_nm as VARCHAR(307)) as last_nm, 
	cast(sfx as VARCHAR(307)) as sfx, 
	prf_ttl,
	cmpny_nm, 
	birth_dt_src, 
	cast(birth_dt as date) as birth_dt, 
	spouse_birth_dt_src, 
	cast(spouse_birth_dt as date) as spouse_birth_dt, 
	addr_ln1, 
	addr_ln2,
	addr_ln3, 
	cast(city as VARCHAR(307)) as city, 
	state, 
	zip_cd, 
	phone_num,
	phone_mobile_ind,
	phone_home_ind,
	email_addr, 
    cntct_prfrnc,        
    cntct_prfrnc_phone_ind,
    cntct_prfrnc_text_ind,
    cntct_prfrnc_email_ind,
	cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cast(cga_fdbk as VARCHAR(307)) as cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
     giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, 
    means_of_support_volunteering,
	means_of_support_gift_in_your_will, 
	means_of_support_gift_in_your_will_honoring_a_loved_one,
	means_of_support_beneficiary_designation,
	
--    Cast(NULL AS VARCHAR(50)) AS means_of_support_gift_ira_chrtbl_dstrbtn,    
    means_of_support_gift_ira_chrtbl_dstrbtn,    
	means_of_support_blood_donation, 
    means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	gift_typ,
	cast(gift_created_ts_src as VARCHAR(307)) as gift_created_ts_src,
	gift_created_dt,
	cast(dcmnt_created_ts_src as VARCHAR(307)) as dcmnt_created_ts_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	cast(don_ext_id as VARCHAR(307)) as don_ext_id,
	cast(frwl_gift_id as VARCHAR(307)) as frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	cast(chng_made_ts_src as VARCHAR(307)) as chng_made_ts_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
    jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
	mds_pg_response_typ,
	hist_seqnum, 
	history_record_id,
	pgc_response_id,
	mds_unq_id,
	rcrdg_file_nm,
	cast(curr_prcsd_file_nm as VARCHAR(307)) as curr_prcsd_file_nm, 
	last_match_proc_dt, 
	stuart_list_proc_dt,  
	dw_trans_ts, row_stat_cd, appl_src_cd, 
load_id
	
	from (
	
			
		/* Query to include the CDS offline responses */
		SELECT  
		/* Set 2 character first names to uppercase to standardize and clean response names.  Otherwise, we format the first name to have first initial uppercase.*/
		  Cast(CASE WHEN Length(Coalesce(collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
		        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
		        collate(a.first_nm::text, 'CASE_INSENSITIVE'))) = 2 THEN Upper(Coalesce(collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
		        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
		        collate(a.first_nm::text, 'CASE_INSENSITIVE'))) ELSE InitCap(Coalesce(collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
		        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
		        collate(a.first_nm::text, 'CASE_INSENSITIVE'))) end AS VARCHAR(20)) AS clnsd_first_nm,  
		/*Standardize last name to have first initial uppercase. */ 
		  Cast(InitCap(Coalesce(collate(b.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_last_nm::text,'CASE_INSENSITIVE'), collate(a.last_nm::text,'CASE_INSENSITIVE'))) AS VARCHAR(80)) AS clnsd_last_nm,  
		/* Standardize email address to lowercase and remove spaces*/
			Replace(Lower(email_addr),Chr(32), '') AS clnsd_email_addr, 
			Cast('CDS Response' AS VARCHAR(50)) AS derived_campaign,
			Cast(response_dt AS DATE) first_response_dt, 
			Cast('NA' AS VARCHAR(10)) AS response_group_dsc, 
			Cast(NULL AS SMALLINT) AS response_cnt, 
			Cast(response_ts AS TIMESTAMP) AS first_response_ts,
			Cast('NA' AS VARCHAR(4)) AS match_lob_src, 
			Cast('NA' AS VARCHAR(50)) AS match_typ, 
			cds_batch_number, cds_sequence_number,
			response_ts_src, 
			response_ts, 
			response_dt, 
			site_url, lander_type,
			nk_ecode, src_cd_src, src_cd, 
			cnst_mstr_id_src, 
			a.cnst_mstr_id,
			a.orig_cnst_mstr_id, 
			Coalesce(collate(b.dm_cnst_prsn_prfx_nm::text,'CASE_INSENSITIVE'), collate(c.prsn_nm_prefix::text,'CASE_INSENSITIVE'), collate(a.ttl::text,'CASE_INSENSITIVE')) AS ttl, 
			Coalesce(collate(b.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'), collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'), collate(a.first_nm::text,'CASE_INSENSITIVE')) AS first_nm, 
			Coalesce(collate(b.dm_cnst_prsn_m_nm::text,'CASE_INSENSITIVE'), collate(c.prsn_middle_nm::text,'CASE_INSENSITIVE'), collate(a.middle_nm::text,'CASE_INSENSITIVE')) AS middle_nm, 
			Coalesce(collate(b.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_last_nm::text,'CASE_INSENSITIVE') ,collate(a.last_nm::text,'CASE_INSENSITIVE')) AS last_nm, 
			Coalesce(collate(b.dm_cnst_prsn_sfx_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_nm_suffix::text,'CASE_INSENSITIVE'), collate(a.sfx::text,'CASE_INSENSITIVE')) AS sfx, 
			prf_ttl,
			cmpny_nm, 
			birth_dt_src, 
			CASE WHEN Extract(YEAR From birth_dt) BETWEEN 0000 AND 0099 THEN Add_Months(birth_dt,22800) ELSE birth_dt end AS birth_dt, 
			spouse_birth_dt_src, 
			CASE WHEN Extract(YEAR From spouse_birth_dt) BETWEEN 0000 AND 0099 THEN Add_Months(spouse_birth_dt,22800) ELSE spouse_birth_dt end AS spouse_birth_dt, 
			Coalesce(collate(dm_cnst_line_1_addr::text,'CASE_INSENSITIVE'),collate(addr_ln1::text,'CASE_INSENSITIVE')) AS addr_ln1, 
			Coalesce(collate(dm_cnst_line_2_addr::text,'CASE_INSENSITIVE'),collate(addr_ln2::text,'CASE_INSENSITIVE')) AS addr_ln2,
			addr_ln3, 
			Coalesce(collate(dm_cnst_city_nm::text,'CASE_INSENSITIVE'),collate(city::text,'CASE_INSENSITIVE')) AS city, 
			Coalesce(collate(dm_cnst_st_cd::text,'CASE_INSENSITIVE'),collate(state::text,'CASE_INSENSITIVE')) AS state, 
			Coalesce(collate(dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE'),collate(zip_cd::text,'CASE_INSENSITIVE')) AS zip_cd, 
			Cast(Coalesce(collate(a.phone_num::text,'CASE_INSENSITIVE'), collate(b.prim_cnst_phn::text,'CASE_INSENSITIVE'), collate(c.cnst_phn_num::text,'CASE_INSENSITIVE')) AS VARCHAR(20)) AS phone_num,
			CASE WHEN a.phone_num IS NOT NULL THEN a.phone_mobile_ind ELSE 0 end AS phone_mobile_ind,
			CASE WHEN a.phone_num IS NOT NULL THEN a.phone_home_ind ELSE 0 end AS phone_home_ind,
			Cast(Coalesce(collate(a.email_addr::text,'CASE_INSENSITIVE'), collate(b.em_cnst_email::text,'CASE_INSENSITIVE'), collate(c.cnst_email_addr::text,'CASE_INSENSITIVE')) AS VARCHAR(100)) AS email_addr, 
		    Cast(NULL AS VARCHAR(25)) AS cntct_prfrnc,        
		    CASE WHEN cntct_prfrnc_phone = 'x' THEN 1 ELSE 0 END AS cntct_prfrnc_phone_ind,
		    CASE WHEN cntct_prfrnc_text = 'x' THEN 1 ELSE 0 END AS cntct_prfrnc_text_ind,
		    CASE WHEN cntct_prfrnc_email = 'x' THEN 1 ELSE 0 END AS cntct_prfrnc_email_ind,
			cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
			cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
			cga_other, cga_fdbk, wg_rqst, 
			wg_arc_in_will, 
			wg_intend_arc_in_will,
			wg_consider_arc_in_will,
			wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
			interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
			interest_in_gift_outside_will, interest_in_life_income_gifts,
			interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
			giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
			giving_reason_respond_to_local_or_national_disasters_or_emergencies,
			giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
		    Cast(NULL AS VARCHAR(5)) AS giving_reason_frnd_fmly_mbr_suprtr,
			influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
			arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
			arc_programs_blood_services, arc_programs_domestic_disaster_relief,
			arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
			means_of_support_check_credit_card, 
		    means_of_support_volunteering,
			means_of_support_gift_in_your_will, 
			CASE WHEN CAST(Substring(src_cd,4,4)as INTEGER) < 2301 AND Substring(src_cd,8,1) = '4' THEN means_of_support_gift_by_beneficiary_designation ELSE NULL end AS means_of_support_gift_in_your_will_honoring_a_loved_one,
			CASE WHEN CAST(Substring(src_cd,4,4) as INTEGER)  >= 2301 AND Substring(src_cd,8,1) = '4'  THEN means_of_support_gift_by_beneficiary_designation ELSE NULL end AS means_of_support_beneficiary_designation,
			
		--    Cast(NULL AS VARCHAR(50)) AS means_of_support_gift_ira_chrtbl_dstrbtn,    
		    means_of_support_gift_from_ira_by_qcd AS means_of_support_gift_ira_chrtbl_dstrbtn,    
			means_of_support_blood_donation, 
		    means_of_support_gifts_that_pay_you_income_for_life,
			means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
			marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
			gift_typ,
			gift_created_ts_src,
			Cast(gift_created_ts AS DATE) AS gift_created_dt,
			dcmnt_created_ts_src,
			Cast(dcmnt_created_ts AS DATE) AS dcmnt_created_dt,
			est_gift_value_amt,
			gift_value_typ,
			plan_typ,
			contigent_lvl,
			message,
			don_ext_id,
			frwl_gift_id,
			asset_type,
			fincl_inst,
			prfrd_nm,
			chng_made_ts_src,
			Cast(chng_made_ts AS DATE) AS chng_made_dt,
			old_gift_value_amt,
			new_gift_value_amt,
		    jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
			Cast(NULL AS VARCHAR(30)) AS mds_pg_response_typ,
			Cast(NULL AS BIGINT) AS hist_seqnum, 
			Cast(NULL AS INTEGER)  AS history_record_id,
			Cast(NULL AS INTEGER)  AS pgc_response_id,
			Cast(NULL AS VARCHAR(30)) AS mds_unq_id,
			Cast(NULL AS VARCHAR(25)) AS rcrdg_file_nm,
			curr_prcsd_file_nm, 
			Current_Date AS last_match_proc_dt, 
			Cast(NULL AS DATE) AS stuart_list_proc_dt,  
			a.dw_trans_ts, a.row_stat_cd, a.appl_src_cd, a.load_id,
		
			Row_Number() Over ( PARTITION BY a.cds_image_id ORDER BY  CASE WHEN appl_src_cd = 'CDS' THEN 1
		              WHEN appl_src_cd = 'HIST' THEN 2
		              end ASC, a.dw_trans_ts ASC) as rn
		     
		FROM mktg_stage_tbls.dm_response_gplg_stg a
		LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr b ON a.cnst_mstr_id = b.cnst_mstr_id
		LEFT JOIN mktg_ops_vws.bzfc_arc_best_smry c ON a.cnst_mstr_id = c.cnst_mstr_id
		--left join mktg_ops_vws.bz_cnst_birth_best c on a.cnst_mstr_id = c.cnst_mstr_id 
		WHERE Trim(cds_batch_number) <> ''  AND row_stat_cd <> 'L' 

	) as subqry
	
	where subqry.rn=1;
	
	
	commit;

 
INSERT INTO mktg_ops_tbls.bzfc_pg_response_log 
 (
	clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign,
	first_response_dt, response_group_dsc, response_cnt, first_response_ts,
	match_lob_src, match_typ, cds_batch_number, cds_sequence_number,
	response_ts_src, response_ts, response_dt, site_url, lander_type,
	nk_ecode, src_cd_src, scr_cd, cnst_mstr_id_src, 
	cnst_mstr_id,
	orig_cnst_mstr_id, 
	ttl, first_nm, middle_nm, last_nm, sfx, prf_ttl,
	cmpny_nm, 
	birth_dt_src, birth_dt, 
	spouse_birth_dt_src, spouse_birth_dt,     
	addr_ln1, addr_ln2, addr_ln3, city, state, zip_cd, 
	phone_num, phone_mobile_ind, phone_home_ind,
	email_addr, 
    cntct_prfrnc,
    cntct_prfrnc_phone_ind, cntct_prfrnc_text_ind, cntct_prfrnc_email_ind,
    cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
    giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, means_of_support_volunteering,
	means_of_support_gift_in_your_will, means_of_support_gift_in_your_will_honoring_a_loved_one,
	means_of_support_beneficiary_designation,
    means_of_support_gift_ira_chrtbl_dstrbtn,
	means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	gift_typ,
	gift_created_dt_src,
	gift_created_dt,
	dcmnt_created_dt_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	don_ext_id,
	frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	chng_made_dt_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
	jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
    mds_pg_response_typ,
	hist_seqnum, history_record_id,
	pgc_response_id,
	mds_unq_id,
    rcrdg_file_nm,
	curr_prcsd_file_nm, last_match_proc_dt, stuart_list_proc_dt,
	dw_trans_ts, row_stat_cd, appl_src_cd, load_id 
) 

SELECT  
/* Set 2 character first names to uppercase to standardize and clean response names.  Otherwise, we format the first name to have first initial uppercase.*/
  clnsd_first_nm,  
/*Standardize last name to have first initial uppercase. */ 
  clnsd_last_nm,  
/* Standardize email address to lowercase and remove spaces*/
	clnsd_email_addr, 
	derived_campaign,
	first_response_dt, 
	response_group_dsc, 
	response_cnt, 
	first_response_ts,
	match_lob_src, 
	match_typ, 
	cds_batch_number, cds_sequence_number,
	response_ts_src, 
	response_ts, 
	response_dt, 
	site_url, lander_type,
	nk_ecode, src_cd_src, scr_cd, 
	cnst_mstr_id_src, 
	cnst_mstr_id,
	orig_cnst_mstr_id, 
	ttl, 
	first_nm, 
	middle_nm, 
	last_nm, 
	sfx, 
	prf_ttl,
	cmpny_nm, 
	birth_dt_src, 
	birth_dt, 
	spouse_birth_dt_src, 
	spouse_birth_dt, 
	addr_ln1, 
	addr_ln2,
	addr_ln3, 
	city, 
	state, 
	zip_cd, 
	phone_num,
	phone_mobile_ind,
	phone_home_ind,
	email_addr, 
    cntct_prfrnc,        
    cntct_prfrnc_phone_ind,
    cntct_prfrnc_text_ind,
    cntct_prfrnc_email_ind,
	cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
     giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, 
    means_of_support_volunteering,
	means_of_support_gift_in_your_will, 
	means_of_support_gift_in_your_will_honoring_a_loved_one,
	means_of_support_beneficiary_designation,
	
--    Cast(NULL AS VARCHAR(50)) AS means_of_support_gift_ira_chrtbl_dstrbtn,    
    means_of_support_gift_ira_chrtbl_dstrbtn,    
	means_of_support_blood_donation, 
    means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	gift_typ,
	gift_created_dt_src,
	gift_created_dt,
	dcmnt_created_dt_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	don_ext_id,
	frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	chng_made_dt_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
    jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
	mds_pg_response_typ,
	hist_seqnum, 
	history_record_id,
	pgc_response_id,
	mds_unq_id,
	rcrdg_file_nm,
	curr_prcsd_file_nm, 
	last_match_proc_dt, 
	stuart_list_proc_dt,  
	dw_trans_ts, row_stat_cd, appl_src_cd, load_id
	
	from(
	
SELECT
 Cast(CASE WHEN Length(Coalesce( collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
        collate(a.first_nm::text, 'CASE_INSENSITIVE'))) = 2 THEN Upper(Coalesce( collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
        collate(a.first_nm::text, 'CASE_INSENSITIVE'))) ELSE InitCap(Coalesce( collate(b.dm_cnst_prsn_f_nm::text, 'CASE_INSENSITIVE'),
        collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),
        collate(a.first_nm::text, 'CASE_INSENSITIVE'))) end AS VARCHAR(20)) AS clnsd_first_nm ,
  Cast(InitCap(Coalesce(collate(b.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_last_nm::text,'CASE_INSENSITIVE'), collate(a.last_nm::text,'CASE_INSENSITIVE'))) AS VARCHAR(80)) AS clnsd_last_nm,  
  Cast(Coalesce(collate(a.email::text,'CASE_INSENSITIVE'), collate(b.em_cnst_email::text,'CASE_INSENSITIVE'), collate(c.cnst_email_addr::text,'CASE_INSENSITIVE')) AS VARCHAR(100)) AS clnsd_email_addr, 
  Cast('Survey' AS VARCHAR(50)) AS derived_campaign,
  Cast(srvy_respns_dt AS DATE)  AS first_response_dt, 
  Cast('NA' AS VARCHAR(10)) AS response_group_dsc, 
  Cast(NULL AS SMALLINT) AS response_cnt,
Cast(Substring(Cast(history_record_ts AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS first_response_ts,
  Cast('NA' AS VARCHAR(4)) AS match_lob_src, 
  Cast('NA' AS VARCHAR(50)) AS match_typ, 
  Cast(NULL AS VARCHAR(256)) AS cds_batch_number, 
  Cast(NULL AS VARCHAR(256)) AS cds_sequence_number,
  Cast(NULL AS VARCHAR(25)) AS  response_ts_src, 
  Cast(Substring(Cast(history_record_ts AS CHAR(26)) FROM 1 FOR 19) AS TIMESTAMP) AS response_ts,
  Cast(srvy_respns_dt  AS DATE) AS response_dt,
  Cast(NULL AS VARCHAR(256)) AS site_url,
  Cast(NULL AS VARCHAR(256)) AS lander_type,
  Cast(a.nk_ecode AS VARCHAR(256)) AS nk_ecode, 
  Cast(NULL AS VARCHAR(256)) AS src_cd_src, 
  Cast(a.src_cd AS VARCHAR(20)) AS scr_cd, 
  Cast(NULL AS VARCHAR(19)) AS cnst_mstr_id_src, 
  Cast(cnst_mstr_id_xlob AS BIGINT) AS cnst_mstr_id,          
  Cast(a.orig_cnst_mstr_id AS BIGINT) AS orig_cnst_mstr_id, 
  Cast(NULL AS VARCHAR(20)) AS ttl,
  Cast(Coalesce(collate(a.first_nm::text,'CASE_INSENSITIVE'), collate(b.em_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'), collate(b.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'), collate(c.prsn_first_nm::text,'CASE_INSENSITIVE')) AS VARCHAR(20)) AS first_nm, 
  Cast(NULL AS VARCHAR(40)) AS middle_nm, 
  Cast(Coalesce(collate(a.last_nm::text,'CASE_INSENSITIVE'), collate(b.em_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'), collate(b.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'), collate(c.prsn_last_nm::text,'CASE_INSENSITIVE')) AS VARCHAR(80)) last_nm, 
  Cast(NULL AS VARCHAR(30)) AS sfx, 
  Cast(NULL AS VARCHAR(200)) AS prf_ttl,
  Cast(c.cnst_org_nm AS VARCHAR(200)) AS cmpny_nm,
  Cast(NULL AS VARCHAR(10)) AS birth_dt_src, 
  Cast(NULL AS DATE) AS birth_dt, 
  Cast(NULL AS VARCHAR(10)) AS spouse_birth_dt_src,
  Cast(NULL AS DATE) AS spouse_birth_dt,
  Cast(Coalesce(collate(a.addr1::text,'CASE_INSENSITIVE'), collate(b.dm_cnst_line_1_addr::text,'CASE_INSENSITIVE'), collate(c. cnst_line1_addr::text,'CASE_INSENSITIVE')) AS VARCHAR(100)) AS addr_ln1, 
  Cast(CASE WHEN a.addr1 IS NULL THEN Coalesce(collate(b.dm_cnst_line_2_addr::text,'CASE_INSENSITIVE'), collate(c.cnst_line2_addr::text,'CASE_INSENSITIVE')) end AS VARCHAR(100)) AS addr_ln2, 
  Cast(NULL AS VARCHAR(100)) AS addr_ln3, 
  Cast(Coalesce(collate(a.city::text,'CASE_INSENSITIVE'), collate(b.dm_cnst_city_nm::text,'CASE_INSENSITIVE'), collate(c.cnst_addr_city::text,'CASE_INSENSITIVE')) AS VARCHAR(25)) AS city, 
  Cast(Coalesce(collate(a.state::text,'CASE_INSENSITIVE'), collate(b.dm_cnst_st_cd::text,'CASE_INSENSITIVE'), collate(c.cnst_addr_state::text,'CASE_INSENSITIVE')) AS VARCHAR(2)) AS state, 
  Cast(Coalesce(collate(a.zip_cd::text,'CASE_INSENSITIVE'), collate(b.dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE'), collate(c.cnst_addr_zip_5::text,'CASE_INSENSITIVE')) AS VARCHAR(10)) AS zip_cd, 
  Cast(Coalesce(collate(a.phone::text,'CASE_INSENSITIVE'), collate(b.prim_cnst_phn::text,'CASE_INSENSITIVE'), collate(c.cnst_phn_num::text,'CASE_INSENSITIVE')) AS VARCHAR(20)) AS phone_num,
  Cast(CASE WHEN a.phone_typ = 'Mobile' THEN 1 ELSE 0 END AS SMALLINT) AS phone_mobile_ind,
  Cast(CASE WHEN a.phone_typ = 'Home' THEN 1 ELSE 0 END AS SMALLINT) AS phone_home_ind,
  Cast(Coalesce(collate(a.email::text,'CASE_INSENSITIVE'), collate(b.em_cnst_email::text,'CASE_INSENSITIVE'), collate(c.cnst_email_addr::text,'CASE_INSENSITIVE')) AS VARCHAR(100)) AS email_addr, 
  Cast(a.cntct_prfrnc AS VARCHAR(100)) AS cntct_prfrnc,
  Cast(g8_cntct_prfrnc_phone_ind AS SMALLINT) AS cntct_prfrnc_phone_ind, 
  Cast(g8_cntct_prfrnc_text_ind AS SMALLINT) AS cntct_prfrnc_text_ind,
  Cast(g8_cntct_prfrnc_email_ind AS SMALLINT) AS cntct_prfrnc_email_ind, 
  Cast(NULL AS VARCHAR(256)) AS cdrp_pg_info_request_pg_information, 
  Cast(NULL AS VARCHAR(256)) AS cdrp_pg_confirm_arc_in_will,
  Cast(NULL AS VARCHAR(256)) AS cga_age_payments_begin, 
  Cast(NULL AS VARCHAR(50)) AS cga_5000, 
  Cast(NULL AS VARCHAR(50)) AS cga_10000, 
  Cast(NULL AS VARCHAR(50)) AS cga_50000, 
  Cast(NULL AS VARCHAR(50)) AS cga_100000,
  Cast(NULL AS VARCHAR(132)) AS cga_other, 
  Cast(NULL AS VARCHAR(50)) AS cga_fdbk, 
  Cast(NULL AS VARCHAR(50)) AS wg_rqst, 
  Cast(NULL AS VARCHAR(50)) AS wg_arc_in_will, 
  Cast(NULL AS VARCHAR(50)) AS wg_intend_arc_in_will,
  Cast(NULL AS VARCHAR(50)) AS wg_consider_arc_in_will,
  Cast(NULL AS VARCHAR(256)) AS wg_fdbk, 
  Cast(NULL AS VARCHAR(256)) AS interest_in_life_income_gift_w_stock, 
  Cast(NULL AS VARCHAR(256)) AS interest_in_life_income_gift_w_real_estate,
  Cast(NULL AS VARCHAR(256)) AS interest_in_life_income_gift_w_ira, 
  Cast(NULL AS VARCHAR(256)) AS interest_in_gift_in_will,
  Cast(NULL AS VARCHAR(256)) AS interest_in_gift_outside_will, 
  Cast(NULL AS VARCHAR(256)) AS interest_in_life_income_gifts,
  Cast(NULL AS VARCHAR(256)) AS interest_in_ira_qcd_gifts, 
  Cast(NULL AS VARCHAR(256)) AS consider_charity_in_will, 
  Cast(NULL AS VARCHAR(256)) AS email_opt_in,
  Cast((CASE WHEN a1_there_for_me_suprt_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256))AS giving_reason_arc_was_there_for_me, 
  Cast((CASE WHEN b1_gen_suprt_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS giving_reason_provide_general_support,
  Cast((CASE WHEN c1_dstr_suprt_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS giving_reason_respond_to_local_or_national_disasters_or_emergencies,
  Cast((CASE WHEN d1_tax_suprt_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS giving_reason_tax_purposes, 
  Cast((CASE WHEN e1_mission_suprt_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS giving_reason_believe_in_arc_mission,
  Cast((CASE WHEN f1_frnd_fmly_mbr_suprtr_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS giving_reason_frnd_fmly_mbr_suprtr,
  Cast((CASE WHEN a2_inflncl_persn_ind = 1 THEN 'Yes' ELSE '' end) AS VARCHAR(256)) AS influential_person_in_your_life, 
  Cast(NULL AS VARCHAR(256)) AS has_the_arc_brought_hope_and_help_to_your_family_or_community,
  Cast((CASE WHEN a3_pgm_safety_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS arc_programs_health_safety_education, 
  Cast((CASE WHEN b3_pgm_afes_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS arc_programs_support_for_armed_forces,
  Cast((CASE WHEN c3_pgm_biomed_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS arc_programs_blood_services, 
  Cast((CASE WHEN d3_pgm_domestic_dstr_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS arc_programs_domestic_disaster_relief,
  Cast((CASE WHEN e3_pgm_intl_dstr_ind = 1 THEN 'x' ELSE '' end) AS VARCHAR(256)) AS arc_programs_international_relief, 
  Cast((CASE WHEN b4_very_imprtnt_ind = 1 THEN 'Very important' 
            WHEN c4_somewhat_imprtnt_ind = 1 THEN 'Somewhat important' 
            WHEN d4_not_imprtnt_ind = 1 THEN 'Not important'
            ELSE '' end) AS VARCHAR(256)) AS arc_programs_important_to_provide_arc_services_in_future,
  Cast((CASE WHEN a5_suprt_cc_ind = 4 THEN 'Have Done' 
             WHEN a5_suprt_cc_ind = 3 AND iwebappid < 230148501 THEN 'Would consider'  
             WHEN a5_suprt_cc_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN a5_suprt_cc_ind = 2 THEN 'Unlikely' 
             WHEN a5_suprt_cc_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_check_credit_card, 
  Cast((CASE WHEN b5_suprt_vlntr_ind = 4 THEN 'Have Done' 
             WHEN b5_suprt_vlntr_ind = 3 AND iwebappid < 230148501 THEN 'Would consider' 
             WHEN b5_suprt_vlntr_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN b5_suprt_vlntr_ind = 2 THEN 'Unlikely' 
             WHEN b5_suprt_vlntr_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_volunteering,
  Cast((CASE WHEN c5_suprt_gift_in_will_ind = 4 THEN 'Have Done' 
             WHEN c5_suprt_gift_in_will_ind = 3 AND iwebappid < 230148501 THEN 'Would consider' 
             WHEN c5_suprt_gift_in_will_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN c5_suprt_gift_in_will_ind = 2 THEN 'Unlikely' 
             WHEN c5_suprt_gift_in_will_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_gift_in_your_will, 
  Cast((CASE WHEN d5_suprt_fmly_mbr_ind = 4 THEN 'Have Done' 
             WHEN d5_suprt_fmly_mbr_ind = 3 AND iwebappid < 230148501 THEN 'Would consider'  
             WHEN d5_suprt_fmly_mbr_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN d5_suprt_fmly_mbr_ind = 2 THEN 'Unlikely' 
             WHEN d5_suprt_fmly_mbr_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_gift_in_your_will_honoring_a_loved_one,
  Cast((CASE WHEN d5_gift_bnfcry_dsgntn_ind = 4 THEN 'Have Done' 
             WHEN d5_gift_bnfcry_dsgntn_ind = 3 AND iwebappid < 230148501 THEN 'Would consider' 
             WHEN d5_gift_bnfcry_dsgntn_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN d5_gift_bnfcry_dsgntn_ind = 2 THEN 'Unlikely' 
             WHEN d5_gift_bnfcry_dsgntn_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_beneficiary_designation,
  Cast((CASE WHEN e5_suprt_bld_dntn_ind = 4 THEN 'Have Done' 
             WHEN e5_suprt_bld_dntn_ind = 3 AND iwebappid < 230148501 THEN 'Would consider' 
             WHEN e5_suprt_bld_dntn_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN e5_suprt_bld_dntn_ind = 2 THEN 'Unlikely' 
             WHEN e5_suprt_bld_dntn_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_blood_donation, 
  Cast((CASE WHEN d5_gift_ira_chrtbl_dstrbtn_ind = 4 THEN 'Have Done' 
             WHEN d5_gift_ira_chrtbl_dstrbtn_ind = 3 AND iwebappid < 230148501 THEN 'Would consider' 
             WHEN d5_gift_ira_chrtbl_dstrbtn_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN d5_gift_ira_chrtbl_dstrbtn_ind = 2 THEN 'Unlikely' 
             WHEN d5_gift_ira_chrtbl_dstrbtn_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_gift_ira_chrtbl_dstrbtn,
 Cast((CASE WHEN f5_suprt_gift_incm_life_ind = 4 THEN 'Have Done' 
             WHEN f5_suprt_gift_incm_life_ind = 3 AND iwebappid < 230148501 THEN 'Would consider' 
             WHEN f5_suprt_gift_incm_life_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN f5_suprt_gift_incm_life_ind = 2 THEN 'Unlikely' 
             WHEN f5_suprt_gift_incm_life_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_gifts_that_pay_you_income_for_life,
  Cast((CASE WHEN g5_suprt_othr_asset_ind = 4 THEN 'Have Done' 
             WHEN g5_suprt_othr_asset_ind = 3 AND iwebappid < 230148501 THEN 'Would consider' 
             WHEN g5_suprt_othr_asset_ind = 3 AND iwebappid >= 230148501 THEN 'Intend' 
             WHEN g5_suprt_othr_asset_ind = 2 THEN 'Unlikely' 
             WHEN g5_suprt_othr_asset_ind = 1 THEN 'Would like more detail' 
            ELSE '' 
      end) AS VARCHAR(256)) AS means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
  Cast((CASE WHEN marital_status = 'Casado' THEN 'Married'
            WHEN marital_status = 'Viudo' THEN 'Widowed'
            ELSE marital_status
      end)AS VARCHAR(78)) AS marital_status, 
  Cast((CASE WHEN b8_children_ind = 1 THEN 'Yes' 
            WHEN b8_children_ind = 0 THEN 'No' 
            ELSE '' 
      end) AS VARCHAR(256)) AS chldrn, 
  Cast((CASE WHEN c8_grand_children_ind = 1 THEN 'Yes' 
            WHEN c8_grand_children_ind = 0 THEN 'No' 
            ELSE '' 
        end) AS VARCHAR(256)) AS grndchldrn, 
  Cast(g8_arc_story AS VARCHAR(4000)) AS arc_story, 
  Cast(age_band AS VARCHAR(66)) AS age, 
  Cast(NULL AS VARCHAR(12)) AS cds_image_id,
  Cast(NULL AS VARCHAR(256)) AS gift_typ,
    Cast(NULL AS VARCHAR(10)) AS gift_created_dt_src,
    Cast(NULL AS DATE) AS gift_created_dt,
    Cast(NULL AS VARCHAR(10)) AS dcmnt_created_dt_src,
    Cast(NULL AS DATE) AS dcmnt_created_dt,
    Cast(NULL AS DECIMAL(15,2))AS est_gift_value_amt,
    Cast(NULL AS VARCHAR(256)) AS gift_value_typ,
    Cast(NULL AS VARCHAR(256)) AS plan_typ,
    Cast(NULL AS VARCHAR(256)) AS contigent_lvl,
    Cast(NULL AS VARCHAR(1500)) AS message,
    Cast(NULL AS VARCHAR(30)) AS don_ext_id,
    Cast(NULL AS VARCHAR(30)) AS frwl_gift_id,
    Cast(NULL AS VARCHAR(256)) AS asset_type,
    Cast(NULL AS VARCHAR(256)) AS fincl_inst,
    Cast(NULL AS VARCHAR(256)) AS prfrd_nm,
    Cast(NULL AS VARCHAR(10)) AS chng_made_dt_src,
    Cast(NULL AS DATE) AS chng_made_dt,
    Cast(NULL AS DECIMAL(15,2))AS old_gift_value_amt,
    Cast(NULL AS DECIMAL(15,2))AS new_gift_value_amt,
  Cast(NULL AS SMALLINT) AS jnt_gft_ind, 
  Cast(NULL AS VARCHAR(50)) AS addtnl_nm, 
  Cast(NULL AS SMALLINT) AS anmty_ind, 
  Cast(NULL AS VARCHAR(50)) AS gft_vhcl_dsc, 
  Cast(NULL AS VARCHAR(30)) AS dsgntn_dsc, 
  Cast(NULL AS VARCHAR(256)) AS gft_cmnts  , 
  Cast(NULL AS VARCHAR(30)) AS mds_pg_response_typ,
  Cast(NULL AS BIGINT) AS hist_seqnum, 
  history_record_id,
  Cast(NULL AS INTEGER)  AS pgc_response_id,
  Cast(NULL AS VARCHAR(30)) AS mds_unq_id,
  Cast(NULL AS VARCHAR(25)) AS rcrdg_file_nm,
  Cast(NULL AS VARCHAR(255)) AS curr_prcsd_file_nm, 
  Current_Date AS last_match_proc_dt, 
  Cast(NULL AS DATE) AS stuart_list_proc_dt,  
  a.dw_updt_ts AS dw_trans_ts, 
  a.row_stat_cd, 
  a.appl_src_cd,  
  a.load_id,
  Row_Number() Over ( PARTITION BY a.history_record_id ORDER BY CASE WHEN d.cnst_mstr_id IS NOT NULL THEN 1 
                                                              WHEN e.cnst_mstr_id IS NOT NULL THEN 2 
                                                              ELSE 3 
                                                        end ASC, a.dw_updt_ts ASC) as rn
FROM mktg_ops_vws.srvy_gplg_rspns_ss a   
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr b ON a.cnst_mstr_id_xlob  = b.cnst_mstr_id    
LEFT JOIN mktg_ops_vws.bzfc_arc_best_smry c ON a.cnst_mstr_id_xlob  = c.cnst_mstr_id           
LEFT JOIN mktg_ops_vws.bzfc_fact_dmail_interaction d ON Coalesce(b.cnst_mstr_id, c.cnst_mstr_id, 0) = d.cnst_mstr_id AND a.src_cd = d.src_cd
LEFT JOIN mktg_ops_vws.bzfc_fact_email_interaction e ON Coalesce(b.cnst_mstr_id, c.cnst_mstr_id, 0) = e.cnst_mstr_id AND a.src_cd = e.src_cd

	
	
	
	
	) as subqry
	where subqry.rn=1;
	
commit;

                                                                                                            
INSERT INTO mktg_ops_tbls.bzfc_pg_response_log 
 (
	clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign,
	first_response_dt, response_group_dsc, response_cnt, first_response_ts,
	match_lob_src, match_typ, cds_batch_number, cds_sequence_number,
	response_ts_src, response_ts, response_dt, site_url, lander_type,
	nk_ecode, src_cd_src, scr_cd, cnst_mstr_id_src, 
	cnst_mstr_id,
	orig_cnst_mstr_id, 
	ttl, first_nm, middle_nm, last_nm, sfx, prf_ttl,
	cmpny_nm, 
	birth_dt_src, birth_dt, 
	spouse_birth_dt_src, spouse_birth_dt,     
	addr_ln1, addr_ln2, addr_ln3, city, state, zip_cd, 
	phone_num, phone_mobile_ind, phone_home_ind,
	email_addr, 
    cntct_prfrnc,
    cntct_prfrnc_phone_ind, cntct_prfrnc_text_ind, cntct_prfrnc_email_ind,
    cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
    giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, means_of_support_volunteering,
	means_of_support_gift_in_your_will, means_of_support_gift_in_your_will_honoring_a_loved_one,
	means_of_support_beneficiary_designation,
    means_of_support_gift_ira_chrtbl_dstrbtn,
	means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	gift_typ,
	gift_created_dt_src,
	gift_created_dt,
	dcmnt_created_dt_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	don_ext_id,
	frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	chng_made_dt_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
	jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
    mds_pg_response_typ,
	hist_seqnum, history_record_id,
	pgc_response_id,
	mds_unq_id,
    rcrdg_file_nm,
	curr_prcsd_file_nm, last_match_proc_dt, stuart_list_proc_dt,
	dw_trans_ts, row_stat_cd, appl_src_cd, load_id 
) 


                                                        
SELECT    
/* Set 2 character first names to uppercase to standardize and clean response names.  Otherwise, we format the first name to have first initial uppercase.*/
    CASE WHEN Length(Coalesce(collate(b.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),collate(a.first_nm::text,'CASE_INSENSITIVE'))) = 2 THEN Upper(Coalesce(collate(b.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),collate(a.first_nm::text,'CASE_INSENSITIVE'))) ELSE InitCap(Coalesce(collate(b.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'),collate(a.first_nm::text,'CASE_INSENSITIVE'))) end AS clnsd_first_nm,  
/*Standardize last name to have first initial uppercase. */    
    InitCap(Coalesce(collate(b.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_last_nm::text,'CASE_INSENSITIVE') ,collate(a.last_nm::text,'CASE_INSENSITIVE'))) AS clnsd_last_nm,
/* Standardize email address to lowercase and remove spaces*/
	REPLACE(LOWER(email_addr), ' ', '') AS clnsd_email_addr, 
	  SPLIT_PART(
    SPLIT_PART(
      REGEXP_SUBSTR(site_url, 'tracking/[^/]+\.php', 1, 1, 'i'),
      '/',
      2
    ),
    '.php',
    1
  ) AS derived_campaign,
	--cast(NULL as VARCHAR(50)) as derived_campaign,
	Cast(response_dt AS DATE ) first_response_dt, 
	Cast('NA' AS VARCHAR(10)) AS response_group_dsc, 
	Cast(NULL AS SMALLINT) AS response_cnt, 
	Cast(response_ts AS TIMESTAMP(0)) AS first_response_ts,
	Cast('NA' AS VARCHAR(4)) AS match_lob_src, 
	Cast('NA' AS VARCHAR(50)) AS match_typ, 
	cds_batch_number, cds_sequence_number,
	response_ts_src, 
	response_ts, 
	response_dt, 
	site_url, lander_type,
	nk_ecode, a.src_cd_src, a.src_cd, 
	cnst_mstr_id_src, 
	a.cnst_mstr_id,
	a.orig_cnst_mstr_id, 
	Coalesce(collate(b.dm_cnst_prsn_prfx_nm::text,'CASE_INSENSITIVE'), collate(c.prsn_nm_prefix::text,'CASE_INSENSITIVE'), collate(a.ttl::text,'CASE_INSENSITIVE')) AS ttl, 
	Coalesce(collate(b.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'), collate(c.prsn_first_nm::text,'CASE_INSENSITIVE'), collate(a.first_nm::text,'CASE_INSENSITIVE')) AS first_nm, 
	Coalesce(collate(b.dm_cnst_prsn_m_nm::text,'CASE_INSENSITIVE'), collate(c.prsn_middle_nm::text,'CASE_INSENSITIVE'), collate(a.middle_nm::text,'CASE_INSENSITIVE')) AS middle_nm, 
	Coalesce(collate(b.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_last_nm::text,'CASE_INSENSITIVE') ,collate(a.last_nm::text,'CASE_INSENSITIVE')) AS last_nm, 
	Coalesce(collate(b.dm_cnst_prsn_sfx_nm::text,'CASE_INSENSITIVE'),collate(c.prsn_nm_suffix::text,'CASE_INSENSITIVE'), collate(a.sfx::text,'CASE_INSENSITIVE')) AS sfx, 
	prf_ttl,
	CASE WHEN a.cmpny_nm IS NULL THEN c.cnst_org_nm end AS cmpny_nm, 
	birth_dt_src, 
	TO_DATE(birth_dt,'YYYYMMDD') as birth_dt, 
	spouse_birth_dt_src, 
	TO_DATE(spouse_birth_dt,'YYYYMMDD') as spouse_birth_dt,
	Coalesce(collate(dm_cnst_line_1_addr::text,'CASE_INSENSITIVE'),collate(addr_ln1::text,'CASE_INSENSITIVE')) AS addr_ln1, 
	Coalesce(collate(dm_cnst_line_2_addr::text,'CASE_INSENSITIVE'),collate(addr_ln2::text,'CASE_INSENSITIVE')) AS addr_ln2, 
	addr_ln3, 
	Coalesce(collate(dm_cnst_city_nm::text,'CASE_INSENSITIVE'),collate(city::text,'CASE_INSENSITIVE')) AS city, 
	Coalesce(collate(dm_cnst_st_cd::text,'CASE_INSENSITIVE'),collate(state::text,'CASE_INSENSITIVE')) AS state, 
	Coalesce(collate(dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE'),collate(zip_cd::text,'CASE_INSENSITIVE')) AS zip_cd, 
	Cast(Coalesce(collate(a.phone_num::text,'CASE_INSENSITIVE'), collate(b.prim_cnst_phn::text,'CASE_INSENSITIVE'), collate(c.cnst_phn_num::text,'CASE_INSENSITIVE')) AS VARCHAR(20)) AS phone_num,
	Cast(0 AS SMALLINT) AS phone_mobile_ind,
	Cast(0 AS SMALLINT) AS phone_home_ind,
	Cast(Coalesce(collate(a.email_addr::text,'CASE_INSENSITIVE'), collate(b.em_cnst_email::text,'CASE_INSENSITIVE'), collate(c.cnst_email_addr::text,'CASE_INSENSITIVE')) AS VARCHAR(100)) AS email_addr, 
	Cast(NULL AS VARCHAR(100)) AS cntct_prfrnc,    
    Cast(NULL AS SMALLINT) AS cntct_prfrnc_phone_ind,
    Cast(NULL AS SMALLINT) AS cntct_prfrnc_text_ind,
    Cast(NULL AS SMALLINT) AS cntct_prfrnc_email_ind,
	cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	Cast(NULL AS VARCHAR(5)) AS wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_disaster_support as giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
    Cast(NULL AS VARCHAR(256)) AS giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, means_of_support_volunteering,
	means_of_support_gift_in_your_will, means_of_support_gift_in_your_will_honoring_a_loved_one,
	Cast(NULL AS VARCHAR(256)) AS means_of_support_beneficiary_designation,
	Cast(NULL AS VARCHAR(256)) AS means_of_support_gift_ira_chrtbl_dstrbtn,
	means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_other_assets as means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	Cast(NULL AS VARCHAR(256)) AS gift_typ,
	Cast(NULL AS VARCHAR(10)) AS gift_created_dt_src,
	Cast(NULL AS DATE) AS gift_created_dt,
	Cast(NULL AS VARCHAR(10)) AS dcmnt_created_dt_src,
	Cast(NULL AS DATE) AS dcmnt_created_dt,
	Cast(NULL AS DECIMAL(15,2))AS est_gift_value_amt,
	Cast(NULL AS VARCHAR(256)) AS gift_value_typ,
	Cast(NULL AS VARCHAR(256)) AS plan_typ,
	Cast(NULL AS VARCHAR(256)) AS contigent_lvl,
	Cast(NULL AS VARCHAR(1500)) AS message,
	Cast(NULL AS VARCHAR(30)) AS don_ext_id,
	Cast(NULL AS VARCHAR(30)) AS frwl_gift_id,
	Cast(NULL AS VARCHAR(256)) AS asset_type,
	Cast(NULL AS VARCHAR(256)) AS fincl_inst,
	Cast(NULL AS VARCHAR(256)) AS prfrd_nm,
	Cast(NULL AS VARCHAR(10)) AS chng_made_dt_src,
	Cast(NULL AS DATE) AS chng_made_dt,
	Cast(NULL AS DECIMAL(15,2))AS old_gift_value_amt,
	Cast(NULL AS DECIMAL(15,2))AS new_gift_value_amt,
    Cast(NULL AS SMALLINT) AS jnt_gft_ind, 
    Cast(NULL AS VARCHAR(50)) AS addtnl_nm, 
    Cast(NULL AS SMALLINT) AS anmty_ind, 
    Cast(NULL AS VARCHAR(50)) AS gft_vhcl_dsc, 
    Cast(NULL AS VARCHAR(30)) AS dsgntn_dsc, 
    Cast(NULL AS VARCHAR(256)) AS gft_cmnts  , 
	Cast(NULL AS VARCHAR(30)) AS mds_pg_response_typ,
	seqnum AS hist_seqnum, 
	Cast(NULL AS INTEGER)  AS history_record_id,
	Cast(NULL AS INTEGER)  AS pgc_response_id,
	Cast(NULL AS VARCHAR(30)) AS mds_unq_id,
	Cast(NULL AS VARCHAR(25)) AS rcrdg_file_nm,
	curr_prcsd_file_nm, 
	Current_Date AS last_match_proc_dt, 
	Cast(NULL AS DATE) AS    stuart_list_proc_dt,    
	a.dw_trans_ts, a.row_stat_cd, a.appl_src_cd, a.load_id

FROM mktg_stage_tbls.dm_response_gplg_stg_hist a
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr b ON a.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN mktg_ops_vws.bzfc_arc_best_smry c ON a.cnst_mstr_id = c.cnst_mstr_id
LEFT JOIN mktg_ops_vws.gmpbzal_dim_src d ON a.src_cd = d.src_cd
/*Exclude Online survey responses from the flattened historical file because we have the online Adobe survey responses covered in the srvy_gplg_rspns_ss view. */
WHERE 
  CASE WHEN Substring(d.pg_src_cd,8,1) <> '4' THEN 1
    WHEN d.src_cd IS NULL THEN 1
    WHEN d.pg_src_cd IN ('APP20054E000', 'APP20064E000') THEN 0     /*Exclude FY20 supporter survey email responses, which come through via an Adobe web form */
    WHEN d.pg_src_cd = 'APP20054M000' AND Coalesce(collate(Trim(a.cds_image_id)::text,'CASE_INSENSITIVE'),'') = '' THEN 0   /*Exclude FY20 supporter survey DM responses that were submitted online, which come through via an Adobe web form */
    WHEN Substring(d.pg_src_cd,8,1) = '4' AND response_dt <= Cast ('12/31/2020' AS DATE) THEN 1
    ELSE 0 end = 1
  AND a.row_stat_cd <> 'L';
         

  commit;
---------------------------------------------------------
INSERT INTO mktg_ops_tbls.bzfc_pg_response_log 
 (
	clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign,
	first_response_dt, response_group_dsc, response_cnt, first_response_ts,
	match_lob_src, match_typ, cds_batch_number, cds_sequence_number,
	response_ts_src, response_ts, response_dt, site_url, lander_type,
	nk_ecode, src_cd_src, scr_cd, cnst_mstr_id_src, 
	cnst_mstr_id,
	orig_cnst_mstr_id, 
	ttl, first_nm, middle_nm, last_nm, sfx, prf_ttl,
	cmpny_nm, 
	birth_dt_src, birth_dt, 
	spouse_birth_dt_src, spouse_birth_dt,     
	addr_ln1, addr_ln2, addr_ln3, city, state, zip_cd, 
	phone_num, phone_mobile_ind, phone_home_ind,
	email_addr, 
    cntct_prfrnc,
    cntct_prfrnc_phone_ind, cntct_prfrnc_text_ind, cntct_prfrnc_email_ind,
    cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, interest_in_life_income_gift_w_stock, interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, interest_in_gift_in_will,
	interest_in_gift_outside_will, interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, consider_charity_in_will, email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, giving_reason_believe_in_arc_mission,
    giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life, has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education, arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card, means_of_support_volunteering,
	means_of_support_gift_in_your_will, means_of_support_gift_in_your_will_honoring_a_loved_one,
	means_of_support_beneficiary_designation,
    means_of_support_gift_ira_chrtbl_dstrbtn,
	means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, grndchldrn, arc_story, age, cds_image_id,
	gift_typ,
	gift_created_dt_src,
	gift_created_dt,
	dcmnt_created_dt_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	don_ext_id,
	frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	chng_made_dt_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
	jnt_gft_ind, addtnl_nm, anmty_ind, gft_vhcl_dsc, dsgntn_dsc, gft_cmnts,
    mds_pg_response_typ,
	hist_seqnum, history_record_id,
	pgc_response_id,
	mds_unq_id,
    rcrdg_file_nm,
	curr_prcsd_file_nm, last_match_proc_dt, stuart_list_proc_dt,
	dw_trans_ts, row_stat_cd, appl_src_cd, load_id 
)

 SELECT  
/* Set 2 character first names to uppercase to standardize and clean response names.  Otherwise, we format the first name to have first initial uppercase.*/
   clnsd_first_nm,  
/*Standardize last name to have first initial uppercase.  */
  clnsd_last_nm,  
/* Standardize email address to lowercase and remove spaces	*/
	clnsd_email_addr, 
	derived_campaign,
	first_response_dt, 
	response_group_dsc,
	response_cnt, 
	first_response_ts,
	match_lob_src, 
	match_typ, 
	cds_batch_number,
	cds_sequence_number,
	call_ts_src, 
	call_ts, 
	call_dt, 
	site_url, lander_type,
	nk_ecode, src_cd_src, src_cd, 
	cnst_mstr_id_src, 
	cnst_mstr_id,
	orig_cnst_mstr_id, 
	ttl, 
	first_nm, 
	middle_nm, 
	last_nm, 
	sfx, 
	prf_ttl,
	cmpny_nm, 
	birth_dt_src, 
	birth_dt, 
	spouse_birth_dt_src, 
	/*case when extract(year from spouse_birth_dt) between 0000 and 0099 then add_months(spouse_birth_dt,22800) else spouse_birth_dt end*/
	spouse_birth_dt, 
	addr_ln1, 
	addr_ln2, 
	addr_ln3, 
	city, 
	state, 
	zip_cd, 
	phone_num,
	phone_mobile_ind,
	phone_home_ind,
	email_addr, 
    cntct_prfrnc,    
    cntct_prfrnc_phone_ind,
    cntct_prfrnc_text_ind,
    cntct_prfrnc_email_ind,
	cdrp_pg_info_request_pg_information, cdrp_pg_confirm_arc_in_will,
	cga_age_payments_begin, cga_5000, cga_10000, cga_50000, cga_100000,
	cga_other, cga_fdbk, wg_rqst, 
	wg_arc_in_will, 
	wg_intend_arc_in_will,
	wg_consider_arc_in_will,
	wg_fdbk, 
	interest_in_life_income_gift_w_stock, 
	interest_in_life_income_gift_w_real_estate,
	interest_in_life_income_gift_w_ira, 
	interest_in_gift_in_will,
	interest_in_gift_outside_will, 
	interest_in_life_income_gifts,
	interest_in_ira_qcd_gifts, 
	consider_charity_in_will, 
	email_opt_in,
	giving_reason_arc_was_there_for_me, giving_reason_provide_general_support,
	giving_reason_respond_to_local_or_national_disasters_or_emergencies,
	giving_reason_tax_purposes, 
    giving_reason_believe_in_arc_mission,
    giving_reason_frnd_fmly_mbr_suprtr,
	influential_person_in_your_life,  has_the_arc_brought_hope_and_help_to_your_family_or_community,
	arc_programs_health_safety_education,  arc_programs_support_for_armed_forces,
	arc_programs_blood_services, arc_programs_domestic_disaster_relief,
	arc_programs_international_relief, arc_programs_important_to_provide_arc_services_in_future,
	means_of_support_check_credit_card,  means_of_support_volunteering,
	means_of_support_gift_in_your_will, 
	means_of_support_gift_in_your_will_honoring_a_loved_one,
	 means_of_support_beneficiary_designation,
	means_of_support_gift_ira_chrtbl_dstrbtn,    
	means_of_support_blood_donation, means_of_support_gifts_that_pay_you_income_for_life,
	means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
	marital_status, chldrn, 
	grndchldrn, arc_story, 
	age, 
	cds_image_id,
	gift_typ,
	gift_created_dt_src,
	gift_created_dt,
	dcmnt_created_dt_src,
	dcmnt_created_dt,
	est_gift_value_amt,
	gift_value_typ,
	plan_typ,
	contigent_lvl,
	message,
	don_ext_id,
	frwl_gift_id,
	asset_type,
	fincl_inst,
	prfrd_nm,
	chng_made_ts_src,
	chng_made_dt,
	old_gift_value_amt,
	new_gift_value_amt,
    jnt_gft_ind, 
    addtnl_nm, 
    anmty_ind, 
    gft_vhcl_dsc, 
    dsgntn_dsc, 
    gft_cmnts  , 
	mds_pg_response_typ,
	hist_seqnum, 
	history_record_id,
	pgc_response_id,
	mds_unq_id,
    rcrdg_file_nm,
    curr_prcsd_file_nm, 
	last_match_proc_dt, 
	stuart_list_proc_dt,  
	dw_trans_ts, row_stat_cd, appl_src_cd, load_id
	
	from(		
			  SELECT  
			/* Set 2 character first names to uppercase to standardize and clean response names.  Otherwise, we format the first name to have first initial uppercase.*/
			  Cast(CASE WHEN Length(Coalesce(collate(frp.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'),collate(ab.prsn_first_nm::text,'CASE_INSENSITIVE'),collate(eoc.first_nm::text,'CASE_INSENSITIVE'))) = 2 THEN Upper(Coalesce(collate(frp.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'),collate(ab.prsn_first_nm::text,'CASE_INSENSITIVE'),collate(eoc.first_nm::text,'CASE_INSENSITIVE'))) ELSE InitCap(Coalesce(collate(frp.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'),collate(ab.prsn_first_nm::text,'CASE_INSENSITIVE'),collate(eoc.first_nm::text,'CASE_INSENSITIVE'))) end AS VARCHAR(20)) AS clnsd_first_nm,  
			/*Standardize last name to have first initial uppercase.  */
			  Cast(InitCap(Coalesce(collate(frp.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'),collate(ab.prsn_last_nm::text,'CASE_INSENSITIVE'), collate(eoc.last_nm::text,'CASE_INSENSITIVE'))) AS VARCHAR(80)) AS clnsd_last_nm,  
			/* Standardize email address to lowercase and remove spaces	*/
				Replace(Lower(Coalesce(collate(eoc.email_addr_updt::text,'CASE_INSENSITIVE'),collate(eoc.email_addr::text,'CASE_INSENSITIVE'),collate(frp.em_cnst_email::text,'CASE_INSENSITIVE'),collate(ab.cnst_email_addr::text,'CASE_INSENSITIVE'))),Chr(32), '') AS clnsd_email_addr, 
				Cast('MDS '||eoc.cmpgn_cd AS VARCHAR(50)) AS derived_campaign,
				Cast(call_dt AS DATE) first_response_dt, 
				Cast('NA' AS VARCHAR(10)) AS response_group_dsc,
				Cast(NULL AS SMALLINT) AS response_cnt, 
				Cast(call_ts AS TIMESTAMP) AS first_response_ts,
				Cast('NA' AS VARCHAR(4)) AS match_lob_src, 
				Cast('NA' AS VARCHAR(50)) AS match_typ, 
				Cast(NULL AS VARCHAR(100)) AS cds_batch_number, Cast(NULL AS VARCHAR(50)) AS cds_sequence_number,
				call_ts_src, 
				call_ts, 
				call_dt, 
				Cast(NULL AS VARCHAR(256)) AS site_url, Cast(NULL AS VARCHAR(100)) AS lander_type,
				Coalesce(frp.mktg_unit_cd,ztc.ecode) AS nk_ecode, eoc.src_cd AS src_cd_src, src_cd, 
				Cast(eoc.cnst_mstr_id AS VARCHAR(19)) AS cnst_mstr_id_src, 
				eoc.cnst_mstr_id,
				eoc.orig_cnst_mstr_id, 
				Coalesce(collate(frp.dm_cnst_prsn_prfx_nm::text,'CASE_INSENSITIVE'), collate(ab.prsn_nm_prefix::text,'CASE_INSENSITIVE'), collate(eoc.ttl::text,'CASE_INSENSITIVE')) AS ttl, 
				Coalesce(collate(frp.dm_cnst_prsn_f_nm::text,'CASE_INSENSITIVE'), collate(ab.prsn_first_nm::text,'CASE_INSENSITIVE'), collate(eoc.first_nm::text,'CASE_INSENSITIVE')) AS first_nm, 
				Coalesce(collate(frp.dm_cnst_prsn_m_nm::text,'CASE_INSENSITIVE'), collate(ab.prsn_middle_nm::text,'CASE_INSENSITIVE'), collate(eoc.middle_nm::text,'CASE_INSENSITIVE')) AS middle_nm, 
				Coalesce(collate(frp.dm_cnst_prsn_l_nm::text,'CASE_INSENSITIVE'),collate(ab.prsn_last_nm::text,'CASE_INSENSITIVE'),collate(eoc.last_nm::text,'CASE_INSENSITIVE')) AS last_nm, 
				Coalesce(collate(frp.dm_cnst_prsn_sfx_nm::text,'CASE_INSENSITIVE'),collate(ab.prsn_nm_suffix::text,'CASE_INSENSITIVE'), collate(eoc.sfx::text,'CASE_INSENSITIVE')) AS sfx, 
				Cast(NULL AS VARCHAR(200)) AS prf_ttl,
				ab.cnst_org_nm AS cmpny_nm, 
				eoc.birth_dt_src, 
				CASE WHEN Extract(YEAR From birth_dt) BETWEEN 0000 AND 0099 THEN Add_Months(birth_dt,22800) ELSE birth_dt end AS birth_dt, 
				Cast(NULL AS VARCHAR(10)) AS spouse_birth_dt_src, 
				/*case when extract(year from spouse_birth_dt) between 0000 and 0099 then add_months(spouse_birth_dt,22800) else spouse_birth_dt end*/
				Cast(NULL AS DATE) AS spouse_birth_dt, 
				Coalesce(collate(eoc.addr_line1_updt::text,'CASE_INSENSITIVE'),collate(eoc.addr_line1::text,'CASE_INSENSITIVE'),collate(frp.dm_cnst_line_1_addr::text,'CASE_INSENSITIVE'),collate(ab.cnst_line1_addr::text,'CASE_INSENSITIVE')) AS addr_ln1, 
				Coalesce(collate(eoc.addr_line2_updt::text,'CASE_INSENSITIVE'),collate(eoc.addr_line2::text,'CASE_INSENSITIVE'),collate(frp.dm_cnst_line_2_addr::text,'CASE_INSENSITIVE'),collate(ab.cnst_line2_addr::text,'CASE_INSENSITIVE')) AS addr_ln2, 
				Coalesce(collate(eoc.addr_line3_updt::text,'CASE_INSENSITIVE'),collate(eoc.addr_line3::text,'CASE_INSENSITIVE')) AS addr_ln3, 
				Coalesce(collate(eoc.city_updt::text,'CASE_INSENSITIVE'),collate(eoc.city::text,'CASE_INSENSITIVE'),collate(frp.dm_cnst_city_nm::text,'CASE_INSENSITIVE'),collate(ab.cnst_addr_city::text,'CASE_INSENSITIVE')) AS city, 
				Coalesce(collate(eoc.state_updt::text,'CASE_INSENSITIVE'),collate(eoc.state::text,'CASE_INSENSITIVE'),collate(frp.dm_cnst_st_cd::text,'CASE_INSENSITIVE'),collate(ab.cnst_addr_state::text,'CASE_INSENSITIVE')) AS state, 
				Coalesce(collate(eoc.zip_cd_updt::text,'CASE_INSENSITIVE'),collate(eoc.zip_cd::text,'CASE_INSENSITIVE'),collate(dm_cnst_zip_5_cd::text,'CASE_INSENSITIVE'),collate(ab.cnst_addr_zip_5::text,'CASE_INSENSITIVE')) AS zip_cd, 
				Cast(Coalesce(collate(eoc.phn_num_updt_cln::text,'CASE_INSENSITIVE'), collate(eoc.phn_num_src::text,'CASE_INSENSITIVE'), collate(frp.prim_cnst_phn::text,'CASE_INSENSITIVE'), collate(ab.cnst_phn_num::text,'CASE_INSENSITIVE')) AS VARCHAR(20)) AS phone_num,
				CASE WHEN NullIf(Trim(Coalesce(collate(eoc.phn_num_updt_cln::text,'CASE_INSENSITIVE'),collate(eoc.phn_num_src::text,'CASE_INSENSITIVE'))),'') IS NOT NULL THEN eoc.phone_mobile_ind ELSE 0 end AS phone_mobile_ind,
				CASE WHEN NullIf(Trim(Coalesce(collate(eoc.phn_num_updt_cln::text,'CASE_INSENSITIVE'),collate(eoc.phn_num_src::text,'CASE_INSENSITIVE'))),'') IS NOT NULL THEN eoc.phone_home_ind ELSE 0 end AS phone_home_ind,
				Cast(Coalesce(collate(eoc.email_addr_updt::text,'CASE_INSENSITIVE'), collate(eoc.email_addr::text,'CASE_INSENSITIVE'), collate(frp.em_cnst_email::text,'CASE_INSENSITIVE'), collate(ab.cnst_email_addr::text,'CASE_INSENSITIVE')) AS VARCHAR(100)) AS email_addr, 
			    Cast(NULL AS VARCHAR(100)) AS cntct_prfrnc,    
			    Cast(NULL AS SMALLINT) AS cntct_prfrnc_phone_ind,
			    Cast(NULL AS SMALLINT) AS cntct_prfrnc_text_ind,
			    Cast(NULL AS SMALLINT) AS cntct_prfrnc_email_ind,
				Cast(NULL AS VARCHAR(5)) AS cdrp_pg_info_request_pg_information, Cast(NULL AS VARCHAR(5)) AS cdrp_pg_confirm_arc_in_will,
				Cast(NULL AS VARCHAR(100)) AS cga_age_payments_begin, Cast(NULL AS VARCHAR(5)) AS cga_5000, Cast(NULL AS VARCHAR(5)) AS cga_10000, Cast(NULL AS VARCHAR(5)) AS cga_50000, Cast(NULL AS VARCHAR(5)) AS cga_100000,
				Cast(NULL AS VARCHAR(132)) AS cga_other, Cast(NULL AS VARCHAR(256)) AS cga_fdbk, Cast(NULL AS VARCHAR(5)) AS wg_rqst, 
				Cast(NULL AS VARCHAR(5)) AS wg_arc_in_will, 
				Cast(NULL AS VARCHAR(5)) AS wg_intend_arc_in_will,
				Cast(NULL AS VARCHAR(5)) AS wg_consider_arc_in_will,
				Cast(eoc.cmnt AS VARCHAR(256)) AS wg_fdbk, 
				Cast(NULL AS VARCHAR(5)) AS interest_in_life_income_gift_w_stock, 
				Cast(NULL AS VARCHAR(5)) AS interest_in_life_income_gift_w_real_estate,
				Cast(NULL AS VARCHAR(5)) AS interest_in_life_income_gift_w_ira, 
				Cast(NULL AS VARCHAR(5)) AS interest_in_gift_in_will,
				Cast(NULL AS VARCHAR(5)) AS interest_in_gift_outside_will, 
				Cast(NULL AS VARCHAR(5)) AS interest_in_life_income_gifts,
				Cast(NULL AS VARCHAR(5)) AS interest_in_ira_qcd_gifts, 
				Cast(NULL AS VARCHAR(5)) AS consider_charity_in_will, 
				Cast(NULL AS VARCHAR(5)) AS email_opt_in,
				Cast(NULL AS VARCHAR(5)) AS giving_reason_arc_was_there_for_me, Cast(NULL AS VARCHAR(5)) AS giving_reason_provide_general_support,
				Cast(NULL AS VARCHAR(5)) AS giving_reason_respond_to_local_or_national_disasters_or_emergencies,
				Cast(NULL AS VARCHAR(5)) AS giving_reason_tax_purposes, 
			    Cast(NULL AS VARCHAR(5)) AS giving_reason_believe_in_arc_mission,
			    Cast(NULL AS VARCHAR(5)) AS giving_reason_frnd_fmly_mbr_suprtr,
				Cast(NULL AS VARCHAR(5)) AS influential_person_in_your_life, Cast(NULL AS VARCHAR(5)) AS has_the_arc_brought_hope_and_help_to_your_family_or_community,
				Cast(NULL AS VARCHAR(5)) AS arc_programs_health_safety_education, Cast(NULL AS VARCHAR(5)) AS arc_programs_support_for_armed_forces,
				Cast(NULL AS VARCHAR(5)) AS arc_programs_blood_services, Cast(NULL AS VARCHAR(5)) AS arc_programs_domestic_disaster_relief,
				Cast(NULL AS VARCHAR(5)) AS arc_programs_international_relief, Cast(NULL AS VARCHAR(50)) AS arc_programs_important_to_provide_arc_services_in_future,
				Cast(NULL AS VARCHAR(50)) AS means_of_support_check_credit_card, Cast(NULL AS VARCHAR(50)) AS means_of_support_volunteering,
				Cast(NULL AS VARCHAR(50)) AS means_of_support_gift_in_your_will, 
				Cast(NULL AS VARCHAR(50)) AS means_of_support_gift_in_your_will_honoring_a_loved_one,
				Cast(NULL AS VARCHAR(50)) AS means_of_support_beneficiary_designation,
				Cast(NULL AS VARCHAR(50)) AS means_of_support_gift_ira_chrtbl_dstrbtn,    
				Cast(NULL AS VARCHAR(50)) AS means_of_support_blood_donation, Cast(NULL AS VARCHAR(50)) AS means_of_support_gifts_that_pay_you_income_for_life,
				Cast(NULL AS VARCHAR(50)) AS means_of_support_gifts_of_other_assets_stock_real_estate_bank_acct,
				Cast(NULL AS VARCHAR(50)) AS marital_status, Cast(NULL AS VARCHAR(5)) AS chldrn, 
				Cast(NULL AS VARCHAR(5)) AS grndchldrn, Cast(NULL AS VARCHAR(4000)) AS arc_story, 
				Cast(eoc.drvd_age AS VARCHAR(20)) AS age, 
				Cast(NULL AS VARCHAR(50)) AS cds_image_id,
				Cast(NULL AS VARCHAR(50)) AS  gift_typ,
				Cast(NULL AS VARCHAR(10)) AS gift_created_dt_src,
				Cast(NULL AS DATE) AS gift_created_dt,
				Cast(NULL AS VARCHAR(10)) AS dcmnt_created_dt_src,
				Cast(NULL AS DATE) AS dcmnt_created_dt,
				Cast(NULL AS DECIMAL(15,2)) AS est_gift_value_amt,
				Cast(NULL AS VARCHAR(5)) AS gift_value_typ,
				Cast(NULL AS VARCHAR(20)) AS plan_typ,
				Cast(NULL AS VARCHAR(5)) AS contigent_lvl,
				Cast(NULL AS VARCHAR(1500)) AS message,
				Cast(NULL AS VARCHAR(30)) AS don_ext_id,
				Cast(NULL AS VARCHAR(30)) AS frwl_gift_id,
				Cast(NULL AS VARCHAR(100)) AS asset_type,
				Cast(NULL AS VARCHAR(100)) AS fincl_inst,
				Cast(NULL AS VARCHAR(100)) AS prfrd_nm,
				Cast(NULL AS VARCHAR(10)) AS chng_made_ts_src,
				Cast(NULL AS DATE) AS chng_made_dt,
				Cast(NULL AS DECIMAL(15,2)) AS old_gift_value_amt,
				Cast(NULL AS DECIMAL(15,2)) AS new_gift_value_amt,
			    Cast(NULL AS SMALLINT) AS jnt_gft_ind, 
			    Cast(NULL AS VARCHAR(50)) AS addtnl_nm, 
			    Cast(NULL AS SMALLINT) AS anmty_ind, 
			    Cast(NULL AS VARCHAR(50)) AS gft_vhcl_dsc, 
			    Cast(NULL AS VARCHAR(30)) AS dsgntn_dsc, 
			    Cast(NULL AS VARCHAR(256)) AS gft_cmnts  , 
				eoc.pg_rspns_typ AS mds_pg_response_typ,
				Cast(NULL AS BIGINT) AS hist_seqnum, 
				Cast(NULL AS INTEGER)  AS history_record_id,
				Cast(NULL AS INTEGER)  AS pgc_response_id,
				eoc.unq_id AS mds_unq_id,
			    eoc.rcrdg_file_nm,
			    curr_prcsd_file_nm, 
				Current_Date AS last_match_proc_dt, 
				Cast(NULL AS DATE) AS stuart_list_proc_dt,  
				eoc.dw_trans_ts, eoc.row_stat_cd, eoc.appl_src_cd, eoc.load_id,
			Row_Number() Over(PARTITION BY eoc.unq_id ORDER BY CASE WHEN eoc.row_stat_cd IN ('L','D') THEN 1 ELSE 0 END ASC,
					eoc.rcrdg_file_nm DESC NULLS LAST, eoc.load_id DESC, eoc.dw_trans_ts DESC) as rn
			FROM mktg_ops_tbls.phone_interaction_pg_eoc eoc
			LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr frp ON eoc.cnst_mstr_id = frp.cnst_mstr_id
			LEFT JOIN mktg_ops_vws.bzfc_arc_best_smry ab ON eoc.cnst_mstr_id = ab.cnst_mstr_id
			--left join mktg_ops_vws.bz_cnst_birth_best c on eoc.cnst_mstr_id = ab.cnst_mstr_id 
			LEFT JOIN eda.dw_common_vws.geo_zip_code_to_chapter ztc ON Left(Trim(Coalesce(eoc.zip_cd_updt,eoc.zip_cd,ab.cnst_addr_zip_5)),5) = ztc.zip
			WHERE CASE WHEN eoc.pg_rspns_typ = 'NOT CONTACTED' THEN 1 ELSE 0 END = 0 

) as subqry
where subqry.rn=1;

 
  
--------------------------------------------------------------------------------------------------------------------------------------------------------
  commit;
  
 
  
  UPDATE mktg_ops_tbls.bzfc_pg_response_log
SET
scr_cd = CASE WHEN scr_cd IS NOT NULL AND Length(Trim(scr_cd)) > 0 THEN scr_cd
            WHEN Trim(derived_campaign) = 'estateguide' AND response_dt BETWEEN DATE '2017-09-11' AND DATE '2018-09-08' THEN 'APP17092M000'
            WHEN Trim(derived_campaign) = 'estateplanning' AND response_dt BETWEEN DATE '2017-09-11' AND DATE '2018-09-08' THEN 'APP17092M000'
            WHEN Trim(derived_campaign) = 'requestTTF' AND response_dt BETWEEN DATE '2017-09-11' AND DATE '2018-09-08' THEN 'APP17092M000'
            WHEN Trim(derived_campaign) = 'freerequest' AND response_dt BETWEEN DATE '2017-09-19' AND DATE '2018-09-17' THEN 'APP17092E000'
            WHEN Trim(derived_campaign) = 'freeworkbook' AND response_dt BETWEEN DATE '2017-09-19' AND DATE '2018-09-17' THEN 'APP17092E000'
            WHEN Trim(derived_campaign) = 'planningoffer' AND response_dt BETWEEN DATE '2018-01-17' AND DATE '2019-01-18' THEN 'APP18012M000'
            WHEN Trim(derived_campaign) = 'willsoffer' AND response_dt BETWEEN DATE '2018-01-17' AND DATE '2019-01-18' THEN 'APP18012M000'
            WHEN Trim(derived_campaign) = 'booklet' AND response_dt BETWEEN DATE '2018-02-01' AND DATE '2019-01-28' THEN 'APP18012E000'
            WHEN Trim(derived_campaign) = 'giftsummary' AND response_dt BETWEEN DATE '2018-08-02' AND DATE '2019-03-16' THEN 'APP18071M000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt BETWEEN DATE '2018-10-31' AND DATE '2019-03-29' THEN 'APP18101E000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt BETWEEN DATE '2019-03-30' AND DATE '2019-07-11' THEN 'APP19031E000'
            WHEN Trim(derived_campaign) = 'giftsummary' AND response_dt BETWEEN DATE '2019-03-17' AND DATE '2019-09-12' THEN 'APP19031M000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt BETWEEN DATE '2019-07-12' AND DATE '2019-09-23' THEN 'APP19071E000'
            WHEN Trim(derived_campaign) = 'ARC-Life-Income-Gifts-Lander' AND response_dt BETWEEN DATE '2018-10-23' AND DATE '2019-10-23' THEN 'APP18090E000'
            WHEN Trim(derived_campaign) = 'planningoffer' AND response_dt BETWEEN DATE '2019-01-19' AND DATE '2020-01-16' THEN 'APP19012M000'
            WHEN Trim(derived_campaign) = 'willsoffer' AND response_dt BETWEEN DATE '2019-01-19' AND DATE '2020-01-16' THEN 'APP19012M000'
            WHEN Trim(derived_campaign) = 'booklet' AND response_dt BETWEEN DATE '2019-01-29' AND DATE '2020-01-30' THEN 'APP19012E000'
            WHEN Trim(derived_campaign) = 'giftsummary' AND response_dt BETWEEN DATE '2019-09-13' AND DATE '2020-03-19' THEN 'APP19091M000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt BETWEEN DATE '2019-09-24' AND DATE '2020-04-13' THEN 'APP19091E000'
            WHEN Trim(derived_campaign) = 'booklet' AND response_dt BETWEEN DATE '2020-01-31' AND DATE '2020-07-31' THEN 'APP20012E000'
            WHEN Trim(derived_campaign) = 'bookletrequest' AND response_dt BETWEEN DATE '2020-01-31' AND DATE '2020-07-31' THEN 'APP20012E000'
            WHEN Trim(derived_campaign) = 'planningoffer' AND response_dt BETWEEN DATE '2020-01-17' AND DATE '2020-07-31' THEN 'APP20012M000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt BETWEEN DATE '2020-04-14' AND DATE '2020-09-14' THEN 'APP20031E000'
            WHEN Trim(derived_campaign) = 'giftsummary' AND response_dt BETWEEN DATE '2020-03-20' AND DATE '2020-09-14' THEN 'APP20031M000'
            WHEN Trim(derived_campaign) = 'ARC-Life-Income-Gifts-Lander' AND response_dt BETWEEN DATE '2019-10-24' AND DATE '2020-10-23' THEN 'APP19107E000'
            WHEN Trim(derived_campaign) = 'bookletoffer' AND response_dt BETWEEN DATE '2018-01-17' AND DATE '2020-12-31' THEN 'APP18012M000'
            WHEN Trim(derived_campaign) = 'guideoffer' AND response_dt BETWEEN DATE '2018-01-17' AND DATE '2020-12-31' THEN 'APP18012M000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt BETWEEN DATE '2020-09-15' AND DATE '2021-03-31' THEN 'APP20091E000'
            WHEN Trim(derived_campaign) = 'giftsummary' AND response_dt BETWEEN DATE '2020-09-15' AND DATE '2021-03-31' THEN 'APP20091M000'
            WHEN Trim(derived_campaign) = 'willsguide' AND response_dt BETWEEN DATE '2018-09-09' AND DATE '2021-07-31' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'booklet' AND response_dt BETWEEN DATE '2020-08-01' AND DATE '2021-08-09' THEN 'APP20082E000'
            WHEN Trim(derived_campaign) = 'bookletrequest' AND response_dt BETWEEN DATE '2020-08-01' AND DATE '2021-08-09' THEN 'APP20082E000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt BETWEEN DATE '2021-04-01' AND DATE '2021-09-14' THEN 'APP21041E000'
            WHEN Trim(derived_campaign) = 'giftsummary' AND response_dt BETWEEN DATE '2021-04-01' AND DATE '2021-09-14' THEN 'APP21041M000'
            WHEN Trim(derived_campaign) = 'estateguide' AND response_dt BETWEEN DATE '2018-09-09' AND DATE '2021-12-31' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt BETWEEN DATE '2021-09-15' AND DATE '2022-03-31' THEN 'APP21091E000'
            WHEN Trim(derived_campaign) = 'giftsummary' AND response_dt BETWEEN DATE '2021-09-15' AND DATE '2022-03-31' THEN 'APP21091M000'
            WHEN Trim(derived_campaign) = 'ARC-Life-Income-Gifts-Lander' AND response_dt >= DATE '2020-10-24' THEN 'APP20107E000'
            WHEN Trim(derived_campaign) = 'booklet' AND response_dt >= DATE '2021-08-10' THEN 'APP21082E000'
            WHEN Trim(derived_campaign) = 'bookletrequest' AND response_dt >= DATE '2021-08-10' THEN 'APP21082E000'
            WHEN Trim(derived_campaign) = 'cga' AND response_dt >= DATE '2015-01-01' THEN 'APP00001D000'
            WHEN Trim(derived_campaign) = 'cgaillustration' AND response_dt >= DATE '2022-04-01' THEN 'APP22041E000'
            WHEN Trim(derived_campaign) = 'cgarequest' AND response_dt >= DATE '2019-07-12' THEN 'APP19071E000'
            WHEN Trim(derived_campaign) = 'charitable-gift-annuity' AND response_dt >= DATE '2015-01-01' THEN 'APP00001D000'
            WHEN Trim(derived_campaign) = 'estatebooklet' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'estateplanning' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'freebooklet' AND response_dt >= DATE '2017-09-19' THEN 'APP17092E000'
            WHEN Trim(derived_campaign) = 'freerequest' AND response_dt >= DATE '2018-09-18' THEN 'APP18092E000'
            WHEN Trim(derived_campaign) = 'freeTTF' AND response_dt >= DATE '2017-09-19' THEN 'APP17092E000'
            WHEN Trim(derived_campaign) = 'freeTTFguide' AND response_dt >= DATE '2017-09-19' THEN 'APP17092E000'
            WHEN Trim(derived_campaign) = 'freewillsoffer' AND response_dt >= DATE '2018-09-18' THEN 'APP18092E000'
            WHEN Trim(derived_campaign) = 'freeworkbook' AND response_dt >= DATE '2018-09-18' THEN 'APP18092E000'
            WHEN Trim(derived_campaign) = 'giftbenefits' AND response_dt >= DATE '2019-09-13' THEN 'APP19091M000'
            WHEN Trim(derived_campaign) = 'giftsummary' AND response_dt >= DATE '2022-04-01' THEN 'APP22041M000'
            WHEN Trim(derived_campaign) = 'guide' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'guiderequest' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'legacy-planned-giving' AND response_dt >= DATE '2015-01-01' THEN 'APP00003D000'
            WHEN Trim(derived_campaign) = 'planningbook' AND response_dt >= DATE '2015-01-01' THEN 'APC00002E000'
            WHEN Trim(derived_campaign) = 'planningguide' AND response_dt >= DATE '2017-08-02' THEN 'APP17082E000'
            WHEN Trim(derived_campaign) = 'planningoffer' AND response_dt >= DATE '2020-08-01' THEN 'APP20082M000'
            WHEN Trim(derived_campaign) = 'requestbook' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'requestTTF' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'TTFbooklet' AND response_dt >= DATE '2017-09-11' THEN 'APP17092M000'
            WHEN Trim(derived_campaign) = 'TTFoffer' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'will-estate-planning' AND response_dt >= DATE '2015-01-01' THEN 'APP00002D000'
            WHEN Trim(derived_campaign) = 'willsbook' AND response_dt >= DATE '2017-01-15' THEN 'APP17012M000'
            WHEN Trim(derived_campaign) = 'willsguide' AND response_dt >= DATE '2021-08-01' THEN 'APP21082M000'
            WHEN Trim(derived_campaign) = 'willsoffer' AND response_dt >= DATE '2020-01-17' THEN 'APP20012M000'
            WHEN Trim(derived_campaign) = 'willsplanning' AND response_dt >= DATE '2017-09-11' THEN 'APP17092M000'
            WHEN Trim(derived_campaign) = 'yourbooklet' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'yourfreebook' AND response_dt >= DATE '2017-09-19' THEN 'APP17092E000'
            WHEN Trim(derived_campaign) = 'yourfreeguide' AND response_dt >= DATE '2016-09-20' THEN 'APP16092E000'
            WHEN Trim(derived_campaign) = 'yourplanningbook' AND response_dt >= DATE '2015-01-01' THEN 'APC00002E000'
            WHEN Trim(derived_campaign) = 'yourrequest' AND response_dt >= DATE '2016-09-12' THEN 'APP16092M000'
            WHEN Trim(derived_campaign) = 'yourttf' AND response_dt >= DATE '2018-09-09' THEN 'APP18092M000'
            WHEN Trim(derived_campaign) = 'freeguide' AND response_dt >= DATE '2015-01-01' THEN 'APP00002D000'
            WHEN Trim(derived_campaign) = 'arc-wills-guide-offer-donor-mailing-lander' AND response_dt >= DATE '2021-07-01' THEN 'APP21082M000'
            WHEN Trim(derived_campaign) = 'arc-wills-guide-digital-campaign-lander' AND response_dt >= DATE '2021-07-01' THEN 'APP00002D000'
            end
WHERE (mktg_ops_tbls.bzfc_pg_response_log.scr_cd IS NULL OR Length(Trim(scr_cd)) = 0)
   AND mktg_ops_tbls.bzfc_pg_response_log.derived_campaign IS NOT NULL
    AND Length(Trim(mktg_ops_tbls.bzfc_pg_response_log.derived_campaign)) > 0
    AND (mktg_ops_tbls.bzfc_pg_response_log.cds_image_id IS NULL OR Length(Trim(mktg_ops_tbls.bzfc_pg_response_log.cds_image_id)) = 0);


  
 
  UPDATE mktg_ops_tbls.bzfc_pg_response_log
 SET 
  cnst_mstr_id = a.cnst_mstr_id,
  stuart_list_proc_dt = a.stuart_list_proc_dt,
  cnst_mstr_id_src = 'SNHQ'
FROM
(	

	SELECT 
    cnst_mstr_id,
    log_cnst_mstr_id,
    pg_response_log_key, 
    clnsd_first_nm,
    clnsd_last_nm,
    cmpny_nm,
    clnsd_email_addr, 
    derived_campaign,
    response_group_dsc,
    cds_image_id,
    frwl_gift_id,
    hist_seqnum,
    history_record_id,
    pgc_response_id,
    first_response_dt,
    stuart_list_proc_dt,
    appl_src_cd
    
    from (
    			SELECT 
    coalesce(c.cnst_mstr_id,0) as cnst_mstr_id,
    a.cnst_mstr_id AS log_cnst_mstr_id,
    a.pg_response_log_key, 
    a.clnsd_first_nm,
    a.clnsd_last_nm,
    a.cmpny_nm,
    a.clnsd_email_addr, 
    a.derived_campaign,
    a.response_group_dsc,
    a.cds_image_id,
    a.frwl_gift_id,
    a.hist_seqnum,
    a.history_record_id,
    a.pgc_response_id,
    a.first_response_dt,
    Cast(b.stuart_upld_ts AS DATE) AS stuart_list_proc_dt,
    a.appl_src_cd,
    Row_Number() Over (PARTITION BY a.pgc_response_id, a.clnsd_email_addr, a.clnsd_last_nm, a.clnsd_first_nm, cmpny_nm, derived_campaign, response_group_dsc
                             ORDER BY stuart_list_proc_dt ASC) as rn
  FROM mktg_ops_vws.bzfc_pg_response_log a
  INNER JOIN mktg_ops_tbls.pg_calc_stuart_upld_lkp b  
      ON
      (a.clnsd_first_nm = b.clnsd_first_nm OR (a.clnsd_first_nm IS NULL AND b.clnsd_first_nm IS NULL))
      AND (a.clnsd_last_nm = b.clnsd_last_nm OR (a.clnsd_last_nm IS NULL AND  b.clnsd_last_nm IS NULL)) 
      AND (a.clnsd_email_addr = b.clnsd_email_addr OR (a.clnsd_email_addr IS NULL AND  b.clnsd_email_addr IS NULL)) 
      AND (a.addr_ln1 = b.addr_ln1 OR (a.addr_ln1 IS NULL AND  b.addr_ln1 IS NULL)) 
      AND (a.city = b.city OR (a.city IS NULL AND  b.city IS NULL)) 
      AND (a.state = b.state OR (a.state IS NULL AND  b.state IS NULL)) 
      AND (a.zip_cd = b.zip_cd OR (a.zip_cd IS NULL AND  b.zip_cd IS NULL))
  LEFT JOIN 
    (
    	SELECT cnst_mstr_id, cnst_email_addr
    	from (
    	
			    	SELECT cnst_mstr_id, cnst_email_addr,Row_Number()  Over (PARTITION BY  cnst_email_addr ORDER BY dw_srcsys_trans_ts DESC) as rn
			      FROM eda.arc_mdm_vws.bz_cnst_email 
			      WHERE arc_srcsys_cd = 'SNHQ'
    	
    	) as subqry 
    	
    	where rn=1
      
      
    ) c (cnst_mstr_id, cnst_email_addr) ON a.clnsd_email_addr = c.cnst_email_addr 
  WHERE --(a.cnst_mstr_id = 0 and 
    (coalesce(c.cnst_mstr_id,0) <> 0 AND a.cnst_mstr_id = 0) --or (a.appl_src_cd in ('FRWL', 'PGC') and stuart_list_proc_dt is null and a.cnst_mstr_id = 0)
    AND a.appl_src_cd = 'PGC'

    
    ) as sqry
    
     where sqry.rn =1
  	
) a (cnst_mstr_id, log_cnst_mstr_id, pg_response_log_key, clnsd_first_nm,clnsd_last_nm, cmpny_nm, clnsd_email_addr, derived_campaign, response_group_dsc,cds_image_id, frwl_gift_id, hist_seqnum, history_record_id, pgc_response_id, first_response_dt, stuart_list_proc_dt, appl_src_cd)

 WHERE 
  ((mktg_ops_tbls.bzfc_pg_response_log.cnst_mstr_id = 0) OR (mktg_ops_tbls.bzfc_pg_response_log.appl_src_cd IN 
      ('PGC') AND mktg_ops_tbls.bzfc_pg_response_log.stuart_list_proc_dt IS NULL))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_first_nm, 'NULL') = Coalesce(a.clnsd_first_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_last_nm, 'NULL') = Coalesce(a.clnsd_last_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cmpny_nm, 'NULL') = Coalesce(a.cmpny_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_email_addr, 'NULL') = Coalesce(a.clnsd_email_addr, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.derived_campaign, 'NULL') = Coalesce(a.derived_campaign, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.response_group_dsc, 'NULL') = Coalesce(a.response_group_dsc, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cds_image_id, 'NULL') = Coalesce(a.cds_image_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.first_response_dt, Cast('01/01/1900' AS DATE)) = 
      Coalesce(a.first_response_dt,  Cast('01/01/1900' AS DATE))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.frwl_gift_id, 'NULL') = Coalesce(a.frwl_gift_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.hist_seqnum, -1) = Coalesce(a.hist_seqnum, -1)
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.history_record_id, -1) = Coalesce(a.history_record_id, -1)
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.pgc_response_id, -1) = Coalesce(a.pgc_response_id, -1);

 
 
 
 UPDATE mktg_ops_tbls.bzfc_pg_response_log
 SET 
  cnst_mstr_id = a.cnst_mstr_id,
  stuart_list_proc_dt = a.stuart_list_proc_dt,
  cnst_mstr_id_src = 'SNHQ'
FROM
(
   SELECT 
    cnst_mstr_id,
    log_cnst_mstr_id,
    pg_response_log_key, 
    clnsd_first_nm,
    clnsd_last_nm,
    cmpny_nm,
    clnsd_email_addr, 
    derived_campaign,
    response_group_dsc,
    cds_image_id,
    frwl_gift_id,
    hist_seqnum,
    history_record_id,
    first_response_dt,
    stuart_list_proc_dt,
    appl_src_cd
    
    from (
    
    		 SELECT 
    coalesce(c.cnst_mstr_id,0) as cnst_mstr_id,
    a.cnst_mstr_id AS log_cnst_mstr_id,
    a.pg_response_log_key, 
    a.clnsd_first_nm,
    a.clnsd_last_nm,
    a.cmpny_nm,
    a.clnsd_email_addr, 
    a.derived_campaign,
    a.response_group_dsc,
    a.cds_image_id,
    a.frwl_gift_id,
    a.hist_seqnum,
    a.history_record_id,
    a.first_response_dt,
    Cast(b.stuart_upld_ts AS DATE) AS stuart_list_proc_dt,
    a.appl_src_cd,
    Row_Number() Over (PARTITION BY hist_seqnum
                              ORDER BY stuart_list_proc_dt ASC) as rn
  FROM mktg_ops_vws.bzfc_pg_response_log a
  INNER JOIN mktg_ops_tbls.pg_calc_stuart_upld_lkp b  
      ON
      (a.clnsd_first_nm = b.clnsd_first_nm OR (a.clnsd_first_nm IS NULL AND b.clnsd_first_nm IS NULL))
      AND (a.clnsd_last_nm = b.clnsd_last_nm OR (a.clnsd_last_nm IS NULL AND  b.clnsd_last_nm IS NULL)) 
      AND (a.clnsd_email_addr = b.clnsd_email_addr OR (a.clnsd_email_addr IS NULL AND  b.clnsd_email_addr IS NULL)) 
      AND (a.addr_ln1 = b.addr_ln1 OR (a.addr_ln1 IS NULL AND  b.addr_ln1 IS NULL)) 
      AND (a.city = b.city OR (a.city IS NULL AND  b.city IS NULL)) 
      AND (a.state = b.state OR (a.state IS NULL AND  b.state IS NULL)) 
      AND (a.zip_cd = b.zip_cd OR (a.zip_cd IS NULL AND  b.zip_cd IS NULL))
  LEFT JOIN 
    (
      SELECT cnst_mstr_id, cnst_email_addr
      from(
      		SELECT cnst_mstr_id, cnst_email_addr, Row_Number()  Over (PARTITION BY  cnst_email_addr ORDER BY dw_srcsys_trans_ts DESC) as rn
      		FROM eda.arc_mdm_vws.bz_cnst_email 
      		WHERE arc_srcsys_cd = 'SNHQ'
      
      ) as subqry
      
      where subqry.rn =1
      
    ) c (cnst_mstr_id, cnst_email_addr) ON a.clnsd_email_addr = c.cnst_email_addr 
  WHERE --(a.cnst_mstr_id = 0 and 
    (coalesce(c.cnst_mstr_id,0) <> 0 AND a.cnst_mstr_id = 0) --or (a.appl_src_cd in ('FRWL', 'PGC') and stuart_list_proc_dt is null and a.cnst_mstr_id = 0)
    AND a.appl_src_cd = 'HIST'
   
    ) as sqry
    
    where sqry.rn=1

) a (cnst_mstr_id, log_cnst_mstr_id, pg_response_log_key, clnsd_first_nm,clnsd_last_nm, cmpny_nm, clnsd_email_addr, derived_campaign, response_group_dsc,cds_image_id, frwl_gift_id, hist_seqnum, history_record_id, first_response_dt, stuart_list_proc_dt, appl_src_cd)

WHERE 
  ((mktg_ops_tbls.bzfc_pg_response_log.cnst_mstr_id = 0) OR (mktg_ops_tbls.bzfc_pg_response_log.appl_src_cd IN 
      ('HIST') AND mktg_ops_tbls.bzfc_pg_response_log.stuart_list_proc_dt IS NULL))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_first_nm, 'NULL') = Coalesce(a.clnsd_first_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_last_nm, 'NULL') = Coalesce(a.clnsd_last_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cmpny_nm, 'NULL') = Coalesce(a.cmpny_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_email_addr, 'NULL') = Coalesce(a.clnsd_email_addr, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.derived_campaign, 'NULL') = Coalesce(a.derived_campaign, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.response_group_dsc, 'NULL') = Coalesce(a.response_group_dsc, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cds_image_id, 'NULL') = Coalesce(a.cds_image_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.first_response_dt, Cast('01/01/1900' AS DATE)) = 
      Coalesce(a.first_response_dt,  Cast('01/01/1900' AS DATE))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.frwl_gift_id, 'NULL') = Coalesce(a.frwl_gift_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.hist_seqnum, -1) = Coalesce(a.hist_seqnum, -1)
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.history_record_id, -1) = Coalesce(a.history_record_id, -1);


UPDATE mktg_ops_tbls.bzfc_pg_response_log

SET
  cnst_mstr_id = a.cnst_mstr_id,
  stuart_list_proc_dt = a.stuart_list_proc_dt,
  cnst_mstr_id_src = 'SNHQ'
  
FROM
(

	SELECT 
    cnst_mstr_id,
    log_cnst_mstr_id,
    pg_response_log_key, 
    clnsd_first_nm,
    clnsd_last_nm,
    cmpny_nm,
    clnsd_email_addr, 
    derived_campaign,
    response_group_dsc,
    cds_image_id,
    frwl_gift_id,
    hist_seqnum,
    history_record_id,
    first_response_dt,
    stuart_list_proc_dt,
    appl_src_cd
    from (
    		SELECT 
    coalesce(c.cnst_mstr_id,0) as cnst_mstr_id,
    a.cnst_mstr_id AS log_cnst_mstr_id,
    a.pg_response_log_key, 
    a.clnsd_first_nm,
    a.clnsd_last_nm,
    a.cmpny_nm,
    a.clnsd_email_addr, 
    a.derived_campaign,
    a.response_group_dsc,
    a.cds_image_id,
    a.frwl_gift_id,
    a.hist_seqnum,
    a.history_record_id,
    a.first_response_dt,
    Cast(b.stuart_upld_ts AS DATE) AS stuart_list_proc_dt,
    a.appl_src_cd,
    Row_Number() Over (PARTITION BY history_record_id
                              ORDER BY stuart_list_proc_dt ASC) as rn
  FROM mktg_ops_vws.bzfc_pg_response_log a
  INNER JOIN mktg_ops_tbls.pg_calc_stuart_upld_lkp b  
      ON
      (a.clnsd_first_nm = b.clnsd_first_nm OR (a.clnsd_first_nm IS NULL AND b.clnsd_first_nm IS NULL))
      AND (a.clnsd_last_nm = b.clnsd_last_nm OR (a.clnsd_last_nm IS NULL AND  b.clnsd_last_nm IS NULL)) 
      AND (a.clnsd_email_addr = b.clnsd_email_addr OR (a.clnsd_email_addr IS NULL AND  b.clnsd_email_addr IS NULL)) 
      AND (a.addr_ln1 = b.addr_ln1 OR (a.addr_ln1 IS NULL AND  b.addr_ln1 IS NULL)) 
      AND (a.city = b.city OR (a.city IS NULL AND  b.city IS NULL)) 
      AND (a.state = b.state OR (a.state IS NULL AND  b.state IS NULL)) 
      AND (a.zip_cd = b.zip_cd OR (a.zip_cd IS NULL AND  b.zip_cd IS NULL))
  LEFT JOIN 
    (
      SELECT cnst_mstr_id, cnst_email_addr
      from(
      		SELECT cnst_mstr_id, cnst_email_addr, Row_Number()  Over (PARTITION BY  cnst_email_addr ORDER BY dw_srcsys_trans_ts DESC) as rn
      		FROM eda.arc_mdm_vws.bz_cnst_email 
      		WHERE arc_srcsys_cd = 'SNHQ'
      
      ) as subqry
      
      where subqry.rn =1
    ) c (cnst_mstr_id, cnst_email_addr) ON a.clnsd_email_addr = c.cnst_email_addr 
  WHERE --(a.cnst_mstr_id = 0 and 
    (coalesce(c.cnst_mstr_id,0) <> 0 AND a.cnst_mstr_id = 0) --or (a.appl_src_cd in ('FRWL', 'PGC') and stuart_list_proc_dt is null and a.cnst_mstr_id = 0)
    AND a.appl_src_cd = 'ADBE'
    
    ) as sqry
    
    where sqry.rn=1
    
) a (cnst_mstr_id, log_cnst_mstr_id, pg_response_log_key, clnsd_first_nm,clnsd_last_nm, cmpny_nm, clnsd_email_addr, derived_campaign, response_group_dsc,cds_image_id, frwl_gift_id, hist_seqnum, history_record_id, first_response_dt, stuart_list_proc_dt, appl_src_cd)

WHERE 
  ((mktg_ops_tbls.bzfc_pg_response_log.cnst_mstr_id = 0) OR (mktg_ops_tbls.bzfc_pg_response_log.appl_src_cd IN 
      ('ADBE') AND mktg_ops_tbls.bzfc_pg_response_log.stuart_list_proc_dt IS NULL))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_first_nm, 'NULL') = Coalesce(a.clnsd_first_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_last_nm, 'NULL') = Coalesce(a.clnsd_last_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cmpny_nm, 'NULL') = Coalesce(a.cmpny_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_email_addr, 'NULL') = Coalesce(a.clnsd_email_addr, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.derived_campaign, 'NULL') = Coalesce(a.derived_campaign, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.response_group_dsc, 'NULL') = Coalesce(a.response_group_dsc, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cds_image_id, 'NULL') = Coalesce(a.cds_image_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.first_response_dt, Cast('01/01/1900' AS DATE)) = 
      Coalesce(a.first_response_dt,  Cast('01/01/1900' AS DATE))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.frwl_gift_id, 'NULL') = Coalesce(a.frwl_gift_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.hist_seqnum, -1) = Coalesce(a.hist_seqnum, -1)
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.history_record_id, -1) = Coalesce(a.history_record_id, -1);



UPDATE mktg_ops_tbls.bzfc_pg_response_log
SET 
  cnst_mstr_id = a.cnst_mstr_id,
  stuart_list_proc_dt = a.stuart_list_proc_dt,
  cnst_mstr_id_src = 'SNHQ'
FROM
(

  SELECT 
    cnst_mstr_id,
    log_cnst_mstr_id,
    pg_response_log_key, 
    clnsd_first_nm,
    clnsd_last_nm,
    cmpny_nm,
    clnsd_email_addr, 
    derived_campaign,
    response_group_dsc,
    cds_image_id,
    frwl_gift_id,
    hist_seqnum,
    history_record_id,
    first_response_dt,
    stuart_list_proc_dt,
    appl_src_cd
    
    from(
    		SELECT 
    coalesce(c.cnst_mstr_id,0) as cnst_mstr_id,
    a.cnst_mstr_id AS log_cnst_mstr_id,
    a.pg_response_log_key, 
    a.clnsd_first_nm,
    a.clnsd_last_nm,
    a.cmpny_nm,
    a.clnsd_email_addr, 
    a.derived_campaign,
    a.response_group_dsc,
    a.cds_image_id,
    a.frwl_gift_id,
    a.hist_seqnum,
    a.history_record_id,
    a.first_response_dt,
    Cast(b.stuart_upld_ts AS DATE) AS stuart_list_proc_dt,
    a.appl_src_cd,
    Row_Number() Over (PARTITION BY cds_image_id
                              ORDER BY stuart_list_proc_dt ASC) as rn
  FROM mktg_ops_vws.bzfc_pg_response_log a
  INNER JOIN mktg_ops_tbls.pg_calc_stuart_upld_lkp b  
      ON
      (a.clnsd_first_nm = b.clnsd_first_nm OR (a.clnsd_first_nm IS NULL AND b.clnsd_first_nm IS NULL))
      AND (a.clnsd_last_nm = b.clnsd_last_nm OR (a.clnsd_last_nm IS NULL AND  b.clnsd_last_nm IS NULL)) 
      AND (a.clnsd_email_addr = b.clnsd_email_addr OR (a.clnsd_email_addr IS NULL AND  b.clnsd_email_addr IS NULL)) 
      AND (a.addr_ln1 = b.addr_ln1 OR (a.addr_ln1 IS NULL AND  b.addr_ln1 IS NULL)) 
      AND (a.city = b.city OR (a.city IS NULL AND  b.city IS NULL)) 
      AND (a.state = b.state OR (a.state IS NULL AND  b.state IS NULL)) 
      AND (a.zip_cd = b.zip_cd OR (a.zip_cd IS NULL AND  b.zip_cd IS NULL))
  LEFT JOIN 
    (
      
      SELECT cnst_mstr_id, cnst_email_addr
      from(
      		SELECT cnst_mstr_id, cnst_email_addr, Row_Number()  Over (PARTITION BY  cnst_email_addr ORDER BY dw_srcsys_trans_ts DESC) as rn
      		FROM eda.arc_mdm_vws.bz_cnst_email 
      		WHERE arc_srcsys_cd = 'SNHQ'
      
      ) as subqry
      
      where subqry.rn =1
    ) c (cnst_mstr_id, cnst_email_addr) ON a.clnsd_email_addr = c.cnst_email_addr 
  WHERE --(a.cnst_mstr_id = 0 and 
    (coalesce(c.cnst_mstr_id,0) <> 0 AND a.cnst_mstr_id = 0) --or (a.appl_src_cd in ('FRWL', 'PGC') and stuart_list_proc_dt is null and a.cnst_mstr_id = 0)
    AND a.appl_src_cd = 'CDS'
    
    ) as sqry
    
    where sqry.rn=1  
) a (cnst_mstr_id, log_cnst_mstr_id, pg_response_log_key, clnsd_first_nm,clnsd_last_nm, cmpny_nm, clnsd_email_addr, derived_campaign, response_group_dsc,cds_image_id, frwl_gift_id, hist_seqnum, history_record_id, first_response_dt, stuart_list_proc_dt, appl_src_cd)

WHERE 
  ((mktg_ops_tbls.bzfc_pg_response_log.cnst_mstr_id = 0) OR (mktg_ops_tbls.bzfc_pg_response_log.appl_src_cd IN 
      ('CDS') AND mktg_ops_tbls.bzfc_pg_response_log.stuart_list_proc_dt IS NULL))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_first_nm, 'NULL') = Coalesce(a.clnsd_first_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_last_nm, 'NULL') = Coalesce(a.clnsd_last_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cmpny_nm, 'NULL') = Coalesce(a.cmpny_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_email_addr, 'NULL') = Coalesce(a.clnsd_email_addr, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.derived_campaign, 'NULL') = Coalesce(a.derived_campaign, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.response_group_dsc, 'NULL') = Coalesce(a.response_group_dsc, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cds_image_id, 'NULL') = Coalesce(a.cds_image_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.first_response_dt, Cast('01/01/1900' AS DATE)) = 
      Coalesce(a.first_response_dt,  Cast('01/01/1900' AS DATE))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.frwl_gift_id, 'NULL') = Coalesce(a.frwl_gift_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.hist_seqnum, -1) = Coalesce(a.hist_seqnum, -1)
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.history_record_id, -1) = Coalesce(a.history_record_id, -1);


UPDATE mktg_ops_tbls.bzfc_pg_response_log

SET
  cnst_mstr_id = a.cnst_mstr_id,
  stuart_list_proc_dt = a.stuart_list_proc_dt,
  cnst_mstr_id_src = 'SNHQ'
  
FROM
(
	SELECT 
    cnst_mstr_id,
    log_cnst_mstr_id,
    pg_response_log_key, 
    clnsd_first_nm,
    clnsd_last_nm,
    cmpny_nm,
    clnsd_email_addr, 
    derived_campaign,
    response_group_dsc,
    cds_image_id,
    frwl_gift_id,
    hist_seqnum,
    history_record_id,
    first_response_dt,
    stuart_list_proc_dt,
    appl_src_cd
    
    from (
    		SELECT 
    coalesce(c.cnst_mstr_id) as cnst_mstr_id,
    a.cnst_mstr_id AS log_cnst_mstr_id,
    a.pg_response_log_key, 
    a.clnsd_first_nm,
    a.clnsd_last_nm,
    a.cmpny_nm,
    a.clnsd_email_addr, 
    a.derived_campaign,
    a.response_group_dsc,
    a.cds_image_id,
    a.frwl_gift_id,
    a.hist_seqnum,
    a.history_record_id,
    a.first_response_dt,
    Cast(b.stuart_upld_ts AS DATE) AS stuart_list_proc_dt,
    a.appl_src_cd,
    Row_Number() Over (PARTITION BY frwl_gift_id
                              ORDER BY stuart_list_proc_dt ASC) as rn
  FROM mktg_ops_vws.bzfc_pg_response_log a
  INNER JOIN mktg_ops_tbls.pg_calc_stuart_upld_lkp b  
      ON
      (a.clnsd_first_nm = b.clnsd_first_nm OR (a.clnsd_first_nm IS NULL AND b.clnsd_first_nm IS NULL))
      AND (a.clnsd_last_nm = b.clnsd_last_nm OR (a.clnsd_last_nm IS NULL AND  b.clnsd_last_nm IS NULL)) 
      AND (a.clnsd_email_addr = b.clnsd_email_addr OR (a.clnsd_email_addr IS NULL AND  b.clnsd_email_addr IS NULL)) 
      AND (a.addr_ln1 = b.addr_ln1 OR (a.addr_ln1 IS NULL AND  b.addr_ln1 IS NULL)) 
      AND (a.city = b.city OR (a.city IS NULL AND  b.city IS NULL)) 
      AND (a.state = b.state OR (a.state IS NULL AND  b.state IS NULL)) 
      AND (a.zip_cd = b.zip_cd OR (a.zip_cd IS NULL AND  b.zip_cd IS NULL))
  LEFT JOIN 
    (
       SELECT cnst_mstr_id, cnst_email_addr
      from(
      		SELECT cnst_mstr_id, cnst_email_addr, Row_Number()  Over (PARTITION BY  cnst_email_addr ORDER BY dw_srcsys_trans_ts DESC) as rn
      		FROM eda.arc_mdm_vws.bz_cnst_email 
      		WHERE arc_srcsys_cd = 'SNHQ'
      
      ) as subqry
      
      where subqry.rn =1
    ) c (cnst_mstr_id, cnst_email_addr) ON a.clnsd_email_addr = c.cnst_email_addr 
  WHERE --(a.cnst_mstr_id = 0 and 
    (coalesce(c.cnst_mstr_id,0) <> 0 AND a.cnst_mstr_id = 0) --or (a.appl_src_cd in ('FRWL', 'PGC') and stuart_list_proc_dt is null and a.cnst_mstr_id = 0)
    AND a.appl_src_cd = 'FRWL'
      
    ) as sqry
   
    where sqry.rn =1
  
) a (cnst_mstr_id, log_cnst_mstr_id, pg_response_log_key, clnsd_first_nm,clnsd_last_nm, cmpny_nm, clnsd_email_addr, derived_campaign, response_group_dsc,cds_image_id, frwl_gift_id, hist_seqnum, history_record_id, first_response_dt, stuart_list_proc_dt, appl_src_cd)

WHERE 
  ((mktg_ops_tbls.bzfc_pg_response_log.cnst_mstr_id = 0) OR (mktg_ops_tbls.bzfc_pg_response_log.appl_src_cd IN 
      ('FRWL') AND mktg_ops_tbls.bzfc_pg_response_log.stuart_list_proc_dt IS NULL))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_first_nm, 'NULL') = Coalesce(a.clnsd_first_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_last_nm, 'NULL') = Coalesce(a.clnsd_last_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cmpny_nm, 'NULL') = Coalesce(a.cmpny_nm, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.clnsd_email_addr, 'NULL') = Coalesce(a.clnsd_email_addr, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.derived_campaign, 'NULL') = Coalesce(a.derived_campaign, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.response_group_dsc, 'NULL') = Coalesce(a.response_group_dsc, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.cds_image_id, 'NULL') = Coalesce(a.cds_image_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.first_response_dt, Cast('01/01/1900' AS DATE)) = Coalesce(a.first_response_dt,  Cast('01/01/1900' AS DATE))
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.frwl_gift_id, 'NULL') = Coalesce(a.frwl_gift_id, 'NULL')
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.hist_seqnum, -1) = Coalesce(a.hist_seqnum, -1)
  AND Coalesce(mktg_ops_tbls.bzfc_pg_response_log.history_record_id, -1) = Coalesce(a.history_record_id, -1);


INSERT INTO mktg_ops_tbls.bzfc_pg_response_log_ref
SELECT 
	Row_Number() Over (ORDER BY a.clnsd_first_nm, a.clnsd_last_nm, a.clnsd_email_addr, a.derived_campaign, a.response_group_dsc, a.first_response_dt ASC) + coalesce(c.max_pg_response_log_key,0) AS pg_response_log_key,
	a.first_response_dt,
	a.org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.src_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	a.dw_create_ts, 
	a.dw_trans_ts,
	a.appl_src_cd,
	a.row_insert_ts
FROM
(
  SELECT
	a.first_response_dt,
	a.cmpny_nm AS org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.scr_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id, 
	Current_Timestamp(0) AS dw_create_ts, 
	Current_Timestamp(0) AS dw_trans_ts,
	a.appl_src_cd,
	Current_Timestamp(0),
	Count(*)
  FROM mktg_ops_tbls.bzfc_pg_response_log a
  LEFT JOIN mktg_ops_tbls.bzfc_pg_response_log_ref b
      ON  (a.frwl_gift_id = b.frwl_gift_id OR (a.frwl_gift_id IS NULL AND  b.frwl_gift_id IS NULL))  
  WHERE b.pg_response_log_key IS NULL AND a.appl_src_cd = 'FRWL'
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
) a (first_response_dt, org_nm, clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign, response_group_dsc, cds_image_id, frwl_gift_id, src_cd, hist_seqnum, 
    history_record_id, pgc_response_id, mds_unq_id, dw_create_ts, dw_trans_ts, appl_src_cd, row_insert_ts,row_cnt)
LEFT JOIN (SELECT Max(pg_response_log_key) FROM mktg_ops_tbls.bzfc_pg_response_log_ref) c (max_pg_response_log_key) ON 1=1;


INSERT INTO mktg_ops_tbls.bzfc_pg_response_log_ref
SELECT 
	Row_Number() Over (ORDER BY a.clnsd_first_nm, a.clnsd_last_nm, a.clnsd_email_addr, a.derived_campaign, a.response_group_dsc, a.first_response_dt ASC) + coalesce(c.max_pg_response_log_key,0) AS pg_response_log_key,
	a.first_response_dt,
	a.org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.src_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	a.dw_create_ts, 
	a.dw_trans_ts,
	a.appl_src_cd,
	a.row_insert_ts
FROM
(
  SELECT
	a.first_response_dt,
	a.cmpny_nm AS org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.scr_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id, 
	Current_Timestamp(0) AS dw_create_ts, 
	Current_Timestamp(0) AS dw_trans_ts,
	a.appl_src_cd,
	Current_Timestamp(0),
	Count(*)
  FROM mktg_ops_tbls.bzfc_pg_response_log a
  LEFT JOIN mktg_ops_tbls.bzfc_pg_response_log_ref b
      ON  (a.cds_image_id = b.cds_image_id OR (a.cds_image_id IS NULL AND  b.cds_image_id IS NULL))  
  WHERE b.pg_response_log_key IS NULL AND a.appl_src_cd = 'CDS'
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
) a (first_response_dt, org_nm, clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign, response_group_dsc, cds_image_id, frwl_gift_id, src_cd, hist_seqnum, 
    history_record_id, pgc_response_id, mds_unq_id, dw_create_ts, dw_trans_ts, appl_src_cd, row_insert_ts,row_cnt)
LEFT JOIN (SELECT Max(pg_response_log_key) FROM mktg_ops_tbls.bzfc_pg_response_log_ref) c (max_pg_response_log_key) ON 1=1;


INSERT INTO mktg_ops_tbls.bzfc_pg_response_log_ref
SELECT 
	Row_Number() Over (ORDER BY a.clnsd_first_nm, a.clnsd_last_nm, a.clnsd_email_addr, a.derived_campaign, a.response_group_dsc, a.first_response_dt ASC) + coalesce(c.max_pg_response_log_key,0) AS pg_response_log_key,
	a.first_response_dt,
	a.org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.src_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	a.dw_create_ts, 
	a.dw_trans_ts,
	a.appl_src_cd,
	a.row_insert_ts
FROM
(
  SELECT
	a.first_response_dt,
	a.cmpny_nm AS org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.scr_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	Current_Timestamp(0) AS dw_create_ts, 
	Current_Timestamp(0) AS dw_trans_ts,
	a.appl_src_cd,
	Current_Timestamp(0),
	Count(*)
  FROM mktg_ops_tbls.bzfc_pg_response_log a
  LEFT JOIN mktg_ops_tbls.bzfc_pg_response_log_ref b
      ON  (a.history_record_id = b.history_record_id OR (a.history_record_id IS NULL AND  b.history_record_id IS NULL))  
  WHERE b.pg_response_log_key IS NULL AND a.appl_src_cd = 'ADBE'
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
) a (first_response_dt, org_nm, clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign, response_group_dsc, cds_image_id, frwl_gift_id, src_cd, hist_seqnum, 
    history_record_id, pgc_response_id, mds_unq_id, dw_create_ts, dw_trans_ts, appl_src_cd, row_insert_ts,row_cnt)
LEFT JOIN (SELECT Max(pg_response_log_key) FROM mktg_ops_tbls.bzfc_pg_response_log_ref) c (max_pg_response_log_key) ON 1=1;


INSERT INTO mktg_ops_tbls.bzfc_pg_response_log_ref
SELECT 
	Row_Number() Over (ORDER BY a.clnsd_first_nm, a.clnsd_last_nm, a.clnsd_email_addr, a.derived_campaign, a.response_group_dsc, a.first_response_dt ASC) + coalesce(c.max_pg_response_log_key,0) AS pg_response_log_key,
	a.first_response_dt,
	a.org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.src_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	a.dw_create_ts, 
	a.dw_trans_ts,
	a.appl_src_cd,
	a.row_insert_ts
FROM 
(
  SELECT
	a.first_response_dt,
	a.cmpny_nm AS org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.scr_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	Current_Timestamp(0) AS dw_create_ts, 
	Current_Timestamp(0) AS dw_trans_ts,
	a.appl_src_cd,
	Current_Timestamp(0),
	Count(*)
  FROM mktg_ops_tbls.bzfc_pg_response_log a
  LEFT JOIN mktg_ops_tbls.bzfc_pg_response_log_ref b
      ON  (a.hist_seqnum = b.hist_seqnum OR (a.hist_seqnum IS NULL AND  b.hist_seqnum IS NULL))  
  WHERE b.pg_response_log_key IS NULL AND a.appl_src_cd = 'HIST'
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
) a (first_response_dt, org_nm, clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign, response_group_dsc, cds_image_id, frwl_gift_id, src_cd, hist_seqnum, 
    history_record_id, pgc_response_id, mds_unq_id, dw_create_ts, dw_trans_ts, appl_src_cd, row_insert_ts,row_cnt)
LEFT JOIN (SELECT Max(pg_response_log_key) FROM mktg_ops_tbls.bzfc_pg_response_log_ref) c (max_pg_response_log_key) ON 1=1;




INSERT INTO mktg_ops_tbls.bzfc_pg_response_log_ref
SELECT 
	Row_Number() Over (ORDER BY a.clnsd_first_nm, a.clnsd_last_nm, a.clnsd_email_addr, a.derived_campaign, a.response_group_dsc, a.first_response_dt ASC) + coalesce(c.max_pg_response_log_key) AS pg_response_log_key,
	a.first_response_dt,
	a.org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.src_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	a.dw_create_ts, 
	a.dw_trans_ts,
	a.appl_src_cd,
	a.row_insert_ts
FROM
(
  SELECT
	a.first_response_dt,
	a.cmpny_nm AS org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.scr_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	Current_Timestamp(0) AS dw_create_ts, 
	Current_Timestamp(0) AS dw_trans_ts,
	a.appl_src_cd,
	Current_Timestamp(0),
	Count(*)
  FROM mktg_ops_tbls.bzfc_pg_response_log a
  LEFT JOIN mktg_ops_tbls.bzfc_pg_response_log_ref b
      ON 
      (a.first_response_dt = b.first_response_dt OR (a.first_response_dt IS NULL AND  b.first_response_dt IS NULL)) 
      AND (a.clnsd_first_nm = b.clnsd_first_nm OR (a.clnsd_first_nm IS NULL AND b.clnsd_first_nm IS NULL))
      AND (a.clnsd_last_nm = b.clnsd_last_nm OR (a.clnsd_last_nm IS NULL AND  b.clnsd_last_nm IS NULL)) 
      AND (a.clnsd_email_addr = b.clnsd_email_addr OR (a.clnsd_email_addr IS NULL AND  b.clnsd_email_addr IS NULL)) 
      AND (a.derived_campaign = b.derived_campaign OR (a.derived_campaign IS NULL AND  b.derived_campaign IS NULL)) 
      AND (a.response_group_dsc = b.response_group_dsc OR (a.response_group_dsc IS NULL AND  b.response_group_dsc IS NULL)) 
      AND (a.cds_image_id = b.cds_image_id OR (a.cds_image_id IS NULL AND  b.cds_image_id IS NULL)) 
      AND (a.frwl_gift_id = b.frwl_gift_id OR (a.frwl_gift_id IS NULL AND  b.frwl_gift_id IS NULL)) 
      AND (a.hist_seqnum = b.hist_seqnum OR (a.hist_seqnum IS NULL AND  b.hist_seqnum IS NULL)) 
      AND (a.history_record_id = b.history_record_id OR (a.history_record_id IS NULL AND  b.history_record_id IS NULL)) 
      AND (a.scr_cd = b.src_cd OR (a.scr_cd IS NULL AND  b.src_cd IS NULL)) 
  WHERE b.pg_response_log_key IS NULL AND a.appl_src_cd = 'PGC' AND a.pgc_response_id = 0
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
) a (first_response_dt, org_nm, clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign, response_group_dsc, cds_image_id, frwl_gift_id, src_cd, hist_seqnum, 
    history_record_id, pgc_response_id, mds_unq_id, dw_create_ts, dw_trans_ts, appl_src_cd, row_insert_ts,row_cnt)
LEFT JOIN (SELECT Max(pg_response_log_key) FROM mktg_ops_tbls.bzfc_pg_response_log_ref) c (max_pg_response_log_key) ON 1=1;



INSERT INTO mktg_ops_tbls.bzfc_pg_response_log_ref
SELECT 
	Row_Number() Over (ORDER BY a.clnsd_first_nm, a.clnsd_last_nm, a.clnsd_email_addr, a.derived_campaign, a.response_group_dsc, a.first_response_dt ASC) + coalesce(c.max_pg_response_log_key) AS pg_response_log_key,
	a.first_response_dt,
	a.org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.src_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	a.dw_create_ts, 
	a.dw_trans_ts,
	a.appl_src_cd,
	a.row_insert_ts
FROM
(
  SELECT
	a.first_response_dt,
	a.cmpny_nm AS org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.scr_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	Current_Timestamp(0) AS dw_create_ts, 
	Current_Timestamp(0) AS dw_trans_ts,
	a.appl_src_cd,
	Current_Timestamp(0),
	Count(*)
  FROM mktg_ops_tbls.bzfc_pg_response_log a
  LEFT JOIN mktg_ops_tbls.bzfc_pg_response_log_ref b
      ON (a.pgc_response_id = b.pgc_response_id OR (a.pgc_response_id IS NULL AND  b.pgc_response_id IS NULL)) 
  WHERE b.pg_response_log_key IS NULL AND a.appl_src_cd = 'PGC' AND a.pgc_response_id <> 0
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
) a (first_response_dt, org_nm, clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign, response_group_dsc, cds_image_id, frwl_gift_id, src_cd, hist_seqnum, 
    history_record_id, pgc_response_id, mds_unq_id, dw_create_ts, dw_trans_ts, appl_src_cd, row_insert_ts,row_cnt)
LEFT JOIN (SELECT Max(pg_response_log_key) FROM mktg_ops_tbls.bzfc_pg_response_log_ref) c (max_pg_response_log_key) ON 1=1;



INSERT INTO mktg_ops_tbls.bzfc_pg_response_log_ref
SELECT 
	Row_Number() Over (ORDER BY a.clnsd_first_nm, a.clnsd_last_nm, a.clnsd_email_addr, a.derived_campaign, a.response_group_dsc, a.first_response_dt ASC) + coalesce(c.max_pg_response_log_key,0) AS pg_response_log_key,
	a.first_response_dt,
	a.org_nm,
	a.clnsd_first_nm, 
	a.clnsd_last_nm, 
	a.clnsd_email_addr, 
	a.derived_campaign, 
	a.response_group_dsc,
	a.cds_image_id,
	a.frwl_gift_id, 
	a.src_cd, 
	a.hist_seqnum, 
	a.history_record_id, 
	a.pgc_response_id,
	a.mds_unq_id,
	a.dw_create_ts, 
	a.dw_trans_ts,
	a.appl_src_cd,
	a.row_insert_ts
FROM
(
  SELECT
      a.first_response_dt,
      a.cmpny_nm AS org_nm,
      a.clnsd_first_nm, 
      a.clnsd_last_nm, 
      a.clnsd_email_addr, 
      a.derived_campaign, 
      a.response_group_dsc,
      a.cds_image_id,
    a.frwl_gift_id, 
    a.scr_cd, 
    a.hist_seqnum, 
    a.history_record_id, 
    a.pgc_response_id,
		a.mds_unq_id,
    Current_Timestamp(0) AS dw_create_ts, 
    Current_Timestamp(0) AS dw_trans_ts,
      a.appl_src_cd,
      Current_Timestamp(0),
    Count(*)
  FROM mktg_ops_tbls.bzfc_pg_response_log a
  LEFT JOIN mktg_ops_tbls.bzfc_pg_response_log_ref b
      ON  (a.mds_unq_id = b.mds_unq_id OR (a.mds_unq_id IS NULL AND  b.mds_unq_id IS NULL))  
  WHERE b.pg_response_log_key IS NULL AND a.appl_src_cd = 'MDS'
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
) a (first_response_dt, org_nm, clnsd_first_nm, clnsd_last_nm, clnsd_email_addr, derived_campaign, response_group_dsc, cds_image_id, frwl_gift_id, src_cd, hist_seqnum, 
    history_record_id, pgc_response_id, mds_unq_id, dw_create_ts, dw_trans_ts, appl_src_cd, row_insert_ts,row_cnt)
LEFT JOIN (SELECT Max(pg_response_log_key) FROM mktg_ops_tbls.bzfc_pg_response_log_ref) c (max_pg_response_log_key) ON 1=1;



		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.bzfc_pg_response_log) as INTEGER)
			WHERE proc_name = 'ld_bzfc_pg_response_log' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bzfc_pg_response_log', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$_$
