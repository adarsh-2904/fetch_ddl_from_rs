CREATE OR REPLACE VIEW mktg_ops_vws.gms_pg_group_membrshp_src AS 
-- mktg_ops_vws.gms_pg_group_membrshp_src source
--drop view mktg_ops_vws.gms_pg_group_membrshp_src;
create or REPLACE VIEW /* View gms_pg_group_membrshp_src */
/* 
	Created By Michael Andrien
	Created Date 10-Feb-2015
	Purpose: To provide pre-built group membership logic to support Planned Giving compaign Segmentation List
					in Aprimo.
	
	Updated By Michael Andrien
	Update Date 06-July-2015
	Purpose: 
		- Add two new groups (groups 16 and 17 PGCLSDCGA	 -PG Closed CGA and PGINREQ65+ - PG Information Requesters 65+ respectively)  
		- Modified group key 6  PG65+.  Removed the giving history details from the query as this criteria is factored into the CGA score.  Also changed the score criteria from 20 to 60.
		
	Updated By Michael Andrien
	Update Date 08-Oct-2015 
	Purpose:  Applied the following list updates:
		1. Added LegacySociety constraints to list 15 - Closed PG.
		2. Changed last gift period from 48 to 24 in list 1 - Active Donors Age 50+

	Updated By Michael Andrien
	Update Date 16-Oct-2015 
	Purpose:  Applied the following list updates:
		1. Added bequest score 80+ group - Bequest Model Audience - group 18
		2. Added group 19 - Pin Package Respondents
		3. Added group 20 - Pin Package Recipients
		4. Added group 21 -  Wills Guide Requesters
		5. Added group 22 - PG Survey Recipients 4+ Years

	Updated By: Michael Andrien
	Update Date: 28-Oct-2015 
	Purpose:  Applied the following list updates:
		1. Modified group 8 - 65+ High Volume Donor Audience - per Rich Reider's direction, removed the CGA model score and gift amount constraints on the group.
		2. Fix the response type constraints on the group defs for groups 19 and 21 (WG Requestor and Pin Respondent groups)
		3. Added the PGWG 50+ group as group 23

	Updated By:	 Michael Andrien
	Update Date:	11/25/15
	Purpose: Modified the group 23 (PGWG50+ ) score value qualifier from 60 to 450
	
	Updated By: Michael Andrien
	Update Date: 1/8/2016 
	Purpose: 		Added 'Funded' to the stage contraints in the unioned queries in groups 15 and 16.
	
Updated By: Michael Andrien
Update Date: 1/13/2016 
Purpose:		Added 3rd UNION query to include the Legacy Society donors in the Closed PG group - group 15

Updated By: Michael Andrien
Update Date: 2/3/2016 
Purpose:	Added logice for PG Group 11 - PG Professional Advisors and PG Group 24 - PG Paid Search Prospects 

Updated By: Michael Andrien
Update Date: 3/10/2016 
Purpose:	Modified the PG Survey Recipients suppression group (group 22)  to include any constituent that has received the survey for 3 years rathter than 4.

Updated By: Michael Andrien
Update Date: 5/25/2016 
Purpose:	Changed view reference in groups 15 and 16 for reference aprimo_wrk_tbls.bzf_cnst_chrctrstc_arcpg view rather than the view in arc_mdm_vws.

Updated By: Michael Andrien
Update Date: 8/05/16 
Purpose:  PG CGA Model Audience Age 65+ update - Lowered the pgcga_acrval from 60 to 50.  NOTE: We may change this back but Rich wanted to test the change for Sept 2016 campaign

Updated By: Michael Andrien
Update Date: 8/31/16 
Purpose:  Created the mktg_ops_vws.pg_group_membrshp_src view on the 2700 as part of the 2700 merge project and changed most of the select statements to pull data from 
				mktg_ops_vws rather than aprimo_wrk_tbls as the view on the 2580 Marketing server did.  NOTE: We can now reference the arc_mdm_vws, ddcoe_vws and convio_tbls
				databases directly on the 2700.  In most instatnces I created the duplicate views in the mktg_ops_vws database though.  We can revisit this later.

Updated By: 	Michael Andrien
Update Date: 03/15/2017 
Purpose:  	Mike Andrien changed the count from 3 yrs to 2 years

Updated By: 	Michael Andrien
Update Date: 	06/21/2017
Purpose:			Added PG Group 26 - Donors age 65 and older with a populated PG response interaction category of PC OR a response interaction category/type of PF/FI

Updated By: 	Michael Andrien
Update Date: 	11/01/2017
Purpose:			Added PG Group 27 -  Volunteers Age 50-82
						Description: Supporters age 50 to age 82 by data selection date with a PG Wills Guide Model score of 800+; flagged as a volunteer (VMS) only or a volunteer and blood donor (VMS + BIOMED) only   
						does not include financial donor records (those with one or more gifts on file) or 
						records that are flagged as blood donors (BIOMED) only
						
Updated By: 	Majeed Mohammad
Update Date: 	11/24/2017
Purpose:		Changed the UNIONs to UNION ALLs. 

Updated By: 	Michael Andrien
Update Date: 	12/20/2017
Purpose:		Changed all references to the mktg_ops_vws.bz_cnst_birth view to mktg_ops_vws.bz_cnst_birth_best.  This view is instatiated through a daily macro and provides the best
					birth date for a cnst base on rules collected from business stakeholders.

Updated By: 	Michael Andrien
Update Date: 	11/08/2018
Purpose:			PG Wills Guide Offer Recipients 4+ Years
						Description: Supporters who have previously received the PG wills guide campaign for 4 or more years (supporters with 4 or more Campaign interactions where the effort is 2M AND the initiatives are different from one another)
						Also, added bzfc_dmail_fact_interaction query to group 22 and added the mailed_ind = 1 qualifier to the group 22 queries.

Updated By: 	Michael Andrien
Update Date: 	11/13/2018
Purpose:  Modified the PG group 2 'PG Response Model Audience'' - changed the score qualifier from 60 to 126 to limit the group size.  The PG team started scoring non-FR constituents so the group size changed from 8 millions to 105 million in the 60 score range.

Updated By: 	Michael Andrien
Update Date: 	12/21/2018
Purpose:  Due to model score changes, we lowwered the pgwg_scrval score requirement from 800 to 80

Updated By: 	Michael Andrien
Update Date: 	5/8/2019
Survey Responders - Group 14 - Modified the original query to include all Master IDs at the household as potential responders.  DRUM was matching our campaign files to their internal responder tables and suppressing all cnsts from with a matching address.

Updated By: 	Michael Andrien
Update Date: 	07/26/2019
Purpose: Changed the age restriction on grour 26 - (Donors age 64 and older with a populated PG response interaction category of PC OR a response interaction category/type of PF/FI) from 65 to 64.  

Updated By: 	Michael Andrien
Update Date: 10/03/2019
Purpose: 	Update group 16 - PG Closed CGA logic to include 'Accepted'' as a valid stage.  So the logic changed from .stage in ('Received', 'Funded')  to .stage in ('Received', 'Funded', 'Accepted') 

Modified By: Michael Andrien
Modified Date: 11/04/2019
Purpose: Modified the contact preference view reference in group 9 - contact Preference Appeal OK GPLG. The EDS team renamed the mktg_ops_vws.bzf_cnst_cntct_prefc view to mktg_ops_vws.bzf_cnst_cntct_prefc_legacy. 
The preference and DNC details were moved to the arc_cmm_vws database 2 years ago.  This data is now inactive.

Modified By: Michael Andrien
Modified Date: 02/29/2020
Purpose: Created GMS version of the view to reference the new GMS FR profiles tables and views

Modified By: Michael Andrien
Modified Date: 11/30/2020 
Purpose: 	Updated the UNION ALL logic for PG group 22 - responders
	Replaced bz_comnictn_src with gmpbzal_dim_src and added '4M'' to the qualifier - the PG team changed the 8th and 9th position of the source code from '0M' to '4M' starting with the APP20054M000' campaign

Modified By: Michael Andrien
Modified Date: 12/02/2020 
Purpose: Updated group 22 SQL Added the outer select to make sure we sum the mailed count across both interactions tables

Modified By: Michael Andrien
Modified Date: 12/31/2020 
Purpose: Modified group key 14 - Survey Responder definition to refernce the GSM source view (mktg_ops_vws.gmpbzal_dim_src) and added group 29 definition to identify the PG Survey Responder with a PG Interest response.
Notes, this is a subset of group 14.  This group definition should be updated anytime group 14 is updated.

Modified By: Michael Andrien
Modified Date: 01/04/2020 
Purpose: Modified group 29 to be limited PG responses with a PG Interest.  Included logic to match the response group master id list to the FR preferred profile on last name address and email match.  Still need to add match logic for non-FR cnsts.  Also, modified
group 14 qualify list to reference pg_src_cd in ('4E'', '4M') from ('0E', '0M')

Modified By: Michael Andrien
Modified Date: 01/05/2020 
Purpose:  After reviewing the logic for groups 14 and 29 with the MODS Ops team, we decided to include the last name/Address and email fuzzy matching logic in the group 14 survey responder group and removed
the fuzzy match logic from group 29.  Group 29 now returns the distinct list of master id the have a PG Interest response.

Modified By: Michael Andrien
Modified Date: 01/04/2020
Purpose: Modified PG Closed Group - 15.  Changed the constiuency view from ufds_vws.bzf_cnst_cnstcy to mktg_ops_vws.gms_bzf_cnst_cnstcy_curnt to limit the Legacy Society member filter to current/active legacty society members

Modified By: Michael Andrien
Modified Date: 06/04/2020
Purpose: Updated score range logic for the PG Wills Guide groups (2, 23,and 27).  The WG scrore ranges were rebuilt and changed t0 a 0-99 range.  Based on the new score range, the team 
recommended changing the group definitions the select scores values that are >=61.

Modified By: Michael Andrien
Modified Date: 07/15/2021
Purpose: Changed PG Group 17 - Information Requesters 65+ Audience Group definition from 65+ to 64+.

Modified By: Michael Andrien
Modified Date: 07/16/2021
Purpose:  Added Wills Guide Responder group definition - Group Key 30

Modified By: Michael Andrien
Modified Date: 10/21/2021
Purpose: Added Digital Responder groups 31-36.

Modified By: Michael Andrien
Modified Date: 11/08/2021
Purpose: Added group key 37 - PG Survey Recipient 4+ year Exclusion group.

Modified By: Michael Andrien
Modified Date: 11/16/2021
Purpose Modified the logic for groups 10 and 14 to include householding logic to the responder groups.  Group 10
is the super set, which includes all PG hand raiser or responders and Group 14 is the survey respond subset.  The queries
for both groups takes the distinct master id list from the bzfc_fact_response_all view and does 2 self joins from the gms_cnst_cdi_smry_fr_prfr
view to itself to retrieve master is from the FR preferred view that share the same last name and mailing address or that share the same
email address.  The modified logic added 47K master ids to group 10 and 31K new masters to group 14.

Modified By: Majeed Mohammad
Modified Date: 10/21/2022
Purpose: Updated the logic (cnst_mstr_id is not null) for the pg_grp_key=11 UNION . 
					The macro mktg_ops_tbls.ld_gms_bz_pg_group_membrshp  failed on 10/21/2022 with NOT NULL error in the table mktg_ops_tbls.gms_bz_pg_group_membrshp. The cnst_mstr_id column had null values in the union in the view. There are  29 records with NULL cnst_mstr_id values. Added this filter to remove these records. The macro succeeded. 

Modified By: Michael Andrien
Modified Date: 11/16/2022
Purpose:  Added the Training Services Suppression group 38 - These are master ids associated with email and mailing addresses in PHSS Preferred profile
but the the master ids are not in PHSS Preferred.  These are household associations to be used as a suppression group.

Modified By: Michael Andrien
Modified Date: 11/19/2022
Purpose:	Renamec cnst_cdi_phss_smry_prfr to cnst_cdi_smry_phss_prfr

Modified By: Michael Andrien
Modified Date: 11/19/2022
Purpose:	Modified group 15 - Closed PG Asks - removed the legacy TA characteristics query from the select group.  The group now contains 2 unioned queries to 
capture SalesForce closed asks and current Legacy Society members.

Modified By: Majeed Mohammad
Modified Date: 11/07/2023
Purpose:	Added the new sections for 39,40,41 . Deleted/commented out the sections 3,5,6,7,12,13,22,23. 
For section 10 & 14, the reference to the FR Prfr was removed. Now, it selects all records from the bzfc_fact_response_all table. For section 14, the existing filters on bzfc_fact_response_all were applied. 
For section 2, the score filter was changed from 61 to 80

Modified By: Majeed Mohammad
Modified Date: 12/06/2023
Purpose:For section 21, the filters were changed from W1, W3, W5, W8, W9 to W1,W3,W4,W5
For section 26, removed the age filter  bzd_derived_age >= 64  and added the filter PF/F9
For section 29, added the filter PB/W2
For section 30, added the filters for PW/W3,W4,W5 and PF/FN
For section 31, added the lander type = Wills Guide Facebook Campaign
For section 32, added the lander types = 'CGA Search Engine Campaign', 'CGA Facebook Campaign' 
For section 33, added the lander types = 'CGA Search Engine Campaign', 'CGA Facebook Campaign' 
For section 36, added the lander types =  'Wills Guide Facebook Campaign', 'Wills Guide Search Engine Campaign'
For section 10, added the filter for PO/O1, O2, O4, O5, O6, OA, OD, OE

Modified By: Michael Andrien
Modified Date: 01/11/2024
Purpose: Reenabled group 6 but removed the 65+ age constraint.  The model score group is now purely base on a model score of 61 and above. Increased the score qualification from 50 to 61.

Modified By: Michael Andrien
Modified Date: 03/05/2024
Purpose: Modified group key 6 score constraint from 61+ to 81+.  Updated the group reference row as well to align with the group changes from 1/11/24 and today.

Modified By: Michael Andrien
Modified Date: 10/25/2024 
Purpose: Re-enabled group 22 and modified the definition to include recipient between 1 and 3 years.

Modified By: Michael Andrien
Modified Date: 01/23/2025
Purpose: Modified the fact ask to dim_ask join for group 15.  The original select was joining on ask_key vs dim_ask_key
    LEFT JOIN ufds_vws.frfbz_dim_ask da ON a.dim_ask_key = da.dim_ask_key

Modified By: Michael Andrien
Modified Date: 05/15/2025
Purpose: Modified the Group 10 definition.  Added the 'OF','OG') )  AND NOT (d.response_ctg_cd = 'PN' AND d.response_typ_cd = 'N2') code to the qualifier below. Note, the 
changes had no impact on the existing counts.
	NOT  (d.response_ctg_cd = 'PO' AND d.response_typ_cd   IN ('O1', 'O2', 'O4', 'O5', 'O6', 'OA', 'OD', 'OE', 'OF','OG') ) 
    AND NOT (d.response_ctg_cd = 'PN' AND d.response_typ_cd = 'N2')
*/

mktg_ops_vws.gms_pg_group_membrshp_src AS 

 
/* Query to derive the PG 50+ Donor Age membership list, which includes donors 50 Years and up, 5+ lifetime gifts, most recent donation within last 48 months 

10/8/15 - Mike Andrien - changed most recent gift date from 48 months to 24 months.
*/

SELECT	 /* PG 50+ Donor Age */
	1 AS pg_group_key , 
	a.cnst_mstr_id, 
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM	mktg_ops_vws.gms_arc_fr_smry a
LEFT JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr b ON a.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN (SELECT  cnst_mstr_id, arc_srcsys_cd, bzd_birth_dt FROM mktg_ops_vws.bz_cnst_birth_best 
                WHERE Current_Date BETWEEN Cast(cnst_birth_strt_ts AS DATE ) AND cnst_birth_end_dt
                QUALIFY Row_Number() Over (PARTITION BY cnst_mstr_id ORDER BY  bzd_birth_dt DESC) = 1)
                 bd(cnst_mstr_id, arc_srcsys_cd, birth_dt) ON b.cnst_mstr_id = bd.cnst_mstr_id
WHERE  
a.fr_lftm_dntn_cnt >= 5 AND -- This is the 5 lifetime gift check.
a.fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE) -- This compares the last donation date for the constituent to the current date minus 24 months to ensure the last gift date is within the past 4 years.
AND DATEDIFF(year, bd.birth_dt, CURRENT_DATE) >= 50 -- This is the check to make sure the constituent is 50 years old or older.

UNION ALL 

/*
Respond model - likelihood of people who will respond.  Criteria Wills Guide score >60.  May change based on quantity, could set desired quantity as parameter
*/
SELECT	 /* PG Response Model Audience*/
	2 AS pg_grp_key, -- PG Response Model Audience Group Key
	cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzf_cnst_scr
WHERE Cast(pgwg_scrval AS INTEGER) >= 80 

UNION ALL 
 
/* 
Query to derive the Bequest Model Audience -  Donors with a Bequest Model score of 60 and above are included in the 
Audience membership group. 
*/ 
SELECT 
	3 AS pg_grp_key, -- Bequest Model Audience Group Key
	cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzf_cnst_scr
WHERE Cast(pgbeq_scrval AS INTEGER) >= 60

UNION ALL  

/*
Query to derive the PG IRA Prospects - Groupy Key 4.
*/

SELECT  /* PG IRA Prospect */
    4 AS pg_group_key, 
    a.cnst_mstr_id, 
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.gms_arc_fr_smry a
LEFT JOIN (
    SELECT  
        cnst_mstr_id, 
        arc_srcsys_cd, 
        bzd_birth_dt 
    FROM mktg_ops_vws.bz_cnst_birth_best 
    WHERE CURRENT_DATE BETWEEN CAST(cnst_birth_strt_ts AS DATE) AND cnst_birth_end_dt
    QUALIFY ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY bzd_birth_dt DESC) = 1
) bd(cnst_mstr_id, arc_srcsys_cd, birth_dt) 
    ON a.cnst_mstr_id = bd.cnst_mstr_id
WHERE  
    a.fr_last_dntn_dt >= DATEADD(month, -48, CURRENT_DATE) 
    AND DATEDIFF(month, bd.birth_dt, CURRENT_DATE) >= 846 -- 846 months is our check for 70.5 years


UNION ALL 

/*Query to derive the 74+ Donor Audience -  Donors that are 74 years old and above, have a CGA score value of 20 and above and have 
   3 or more lifetime gifts,  the last gift date is within the past 48 months and the last gift amount is $10 or more
Audience membership group. 
*/
/* 11/7/2023: Disabled this section based on Rich's  spreadsheet */ 
/*select 
	5 as pg_grp_key, -- 74+ Donors Model Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
from  mktg_ops_vws.gms_arc_fr_smry a
left join mktg_ops_vws.bzf_cnst_scr b on a.cnst_mstr_id = b.cnst_mstr_id
left join (select  cnst_mstr_id, arc_srcsys_cd, bzd_birth_dt from mktg_ops_vws.bz_cnst_birth_best 
                where current_date between cast(cnst_birth_strt_ts as date format 'mm/dd/yyyy') and cnst_birth_end_dt
                qualify row_number() over (partition by cnst_mstr_id order by  bzd_birth_dt desc) = 1)
                 bd(cnst_mstr_id, arc_srcsys_cd, birth_dt) on a.cnst_mstr_id = bd.cnst_mstr_id
where   	(current_date - bd.birth_dt) YEAR(4) >=74 and 
				cast(pgcga_scrval as integer) >= 20 and
			  	 a.fr_lftm_dntn_cnt >= 3 and (a.fr_last_dntn_dt >= add_months(date, -48) and a.fr_last_dntn_amt >= 10)

UNION ALL  */

/* Query to derive the 65+ Donor Audience -  ( Group Name - PG CGA Model Audience Age 65+)
65+ age in addition to CGA model score 60 and above - score threshold may be dependent on quantity.  Giving history is factored into model score which was 3+  lifetime gifts, 
with last within previous 48 months and last donation $10 or more.

7/6/15  Mike Andrien - Modified the pgcga_scrval criteria from 20 to 60 and commented out the giving history criteria as this is factored into the CGA model score.
8/05/16 Mike Andrien - Lowered the pgcga_acrval from 60 to 50.  NOTE: We may change this back but Rich wanted to test the change for Sept 2016 campaign
*/ 
/* 11/7/2023: Disabled this section based on Rich's  spreadsheet */ 
/* 01/11/2024 MTA - Reenabled the group but removed the 65+ age constraint. Increased the score qualification to 61 */
SELECT 
	6 AS pg_grp_key, -- 65+ Donors Model Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM  mktg_ops_vws.gms_arc_fr_smry a
LEFT JOIN mktg_ops_vws.bzf_cnst_scr b ON a.cnst_mstr_id = b.cnst_mstr_id

-- Replace the join below with join to aprimo_wrk_tbls.bz_cnst_birth_best_pg, which includes rules logic for selecting the correct birth date.
--left join (select  cnst_mstr_id, arc_srcsys_cd, bzd_birth_dt from mktg_ops_vws.bz_cnst_birth_best 
      --          where current_date between cast(cnst_birth_strt_ts as date format 'mm/dd/yyyy') and cnst_birth_end_dt
      --          qualify row_number() over (partition by cnst_mstr_id order by  bzd_birth_dt desc) = 1)
    --             bd(cnst_mstr_id, arc_srcsys_cd, birth_dt) on a.cnst_mstr_id = bd.cnst_mstr_id 
LEFT JOIN mktg_ops_vws.bz_cnst_birth_best bd  ON a.cnst_mstr_id = bd.cnst_mstr_id
WHERE   	--bd.bzd_derived_age >= 65 and 
	Cast(pgcga_scrval AS INTEGER) >= 81
				--(current_date - bd.birth_dt) YEAR(4) >=65 and 
				--and  a.fr_lftm_dntn_cnt >= 3 and (a.fr_last_dntn_dt <= add_months(date, -24) and a.fr_last_dntn_amt >= 10)
UNION ALL 

/* Query to derive the 65+ Lapsed Donor Audience -  
65+ age in addition to CGA model score 20 and above - score threshold may be dependent on quantity.  Giving history is factored into model score which was 3+  lifetime gifts, 
with last donation date greater than 24 months and last donation $10 or more.
*/
/* 11/7/2023: Disabled this section based on Rich's  spreadsheet */ 
/*select 
	7 as pg_grp_key, -- 65+ Lapsed Donors Model Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
from  mktg_ops_vws.gms_arc_fr_smry a
left join mktg_ops_vws.bzf_cnst_scr b on a.cnst_mstr_id = b.cnst_mstr_id
left join (select  cnst_mstr_id, arc_srcsys_cd, bzd_birth_dt from mktg_ops_vws.bz_cnst_birth_best 
                where current_date between cast(cnst_birth_strt_ts as date format 'mm/dd/yyyy') and cnst_birth_end_dt
                qualify row_number() over (partition by cnst_mstr_id order by  bzd_birth_dt desc) = 1)
                 bd(cnst_mstr_id, arc_srcsys_cd, birth_dt) on a.cnst_mstr_id = bd.cnst_mstr_id
where   	(current_date - bd.birth_dt) YEAR(4) >=65 and 
				cast(pgcga_scrval as integer) >= 20 and
			  	 a.fr_lftm_dntn_cnt >= 3 and (a.fr_last_dntn_dt <= add_months(date, -24) and a.fr_last_dntn_amt >= 10)

UNION ALL */

/* Query to derive the 65+ High Volume Donor Audience -  
65 years +, given 11+ gifts, last gift within last 24 months and last donation $10 or more, CGA model score 20 and above - score threshold may be dependent on quantity, 
capped at 900 volume per gift officer, have not received or responded to this package previously.
***Need to add logic to filter out constituents that have received the package previously or have responded***.

Updated By;  Michael Andrien
Update Date: 10/28/15
Purpose:  As per Rich Reider - removed the CGA score and gift amount criteria from the group definitions
*/

SELECT 
 8 AS pg_grp_key, -- 65+ High Volume Donor Audience Group Key
 a.cnst_mstr_id,
 CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.gms_arc_fr_smry a
LEFT JOIN mktg_ops_vws.bzf_cnst_scr b 
 ON a.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN (
 SELECT 
 cnst_mstr_id, 
 arc_srcsys_cd, 
 bzd_birth_dt 
 FROM mktg_ops_vws.bz_cnst_birth_best 
 WHERE CURRENT_DATE BETWEEN CAST(cnst_birth_strt_ts AS DATE) AND cnst_birth_end_dt
 QUALIFY ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY bzd_birth_dt DESC) = 1
) bd(cnst_mstr_id, arc_srcsys_cd, birth_dt) 
 ON a.cnst_mstr_id = bd.cnst_mstr_id
WHERE 
 DATEDIFF(year, bd.birth_dt, CURRENT_DATE) >= 65 -- Age check: 65 or older
 -- AND CAST(pgcga_scrval AS INTEGER) >= 20 -- removed by Mike Andrien 10/28/15
 AND a.fr_lftm_dntn_cnt >= 11 
 AND a.fr_last_dntn_dt >= DATEADD(month, -24, CURRENT_DATE)

			  	 --and a.fr_last_dntn_amt >= 10)  -- commented out by Mike Andrien 10/28/15
				 

 UNION ALL 

/*
Contact Preference Appeal OK GPLG - Group Selection.
The first UNION captures the CDI contact preferences.  The next UNION  associates the FSA contact
preferences to the same  OK GPLG group.
*/
SELECT
    9 AS pg_grp_key, -- Appeal OK GPLG Donor Audience Group Key    
    c.cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM eda.arc_cmm_vws.bzf_cnst_msg_pref a
LEFT JOIN mktg_ops_vws.cnst_mstr_id_map b ON a.cnst_mstr_id = b.cnst_mstr_id
INNER JOIN mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr c ON c.cnst_mstr_id = Coalesce(b.new_cnst_mstr_id,a.cnst_mstr_id)
WHERE a.bzd_frgp_all_appeal_yes_ind = 1



UNION  ALL

/*
Contact Preference Appeal OK GPLG - Group Selection.
This is the second UNION to add the  FSA contact preferences to the OK GPLG group.
*/
SELECT 
	9 AS pg_grp_key, -- Appeal OK GPLG Donor Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr a
LEFT JOIN mktg_ops_vws.bzfc_fsa_cnst_indv_cntct_prefc b ON a.cnst_mstr_id = b.cnst_mstr_id
WHERE bzd_appeal_okgplg_ind = 1



UNION ALL 

/*
Information requesters	(Inclusion) Hand Raiser - This list contains the disctinct list of cnst_mstr_ids contained in mktg_ops_vws.fact_response_all.  NOTE 
This is the superset of people that have responded to Planned Giving solicitations.  The Survey Response group is a subset of this group and is 
determined by the 2 character Effort Code within the source code (characters 8 and 9).   
*/
	/* 11/7/2023: Majeed: Removed the joins to the FR profile */ 
SELECT 
	DISTINCT
	10 AS pg_grp_key, -- Information Requesters Audience Group Key
	cnst_mstr_id, 
	CURRENT_TIMESTAMP AS dw_trans_ts	
FROM mktg_ops_vws.bzfc_fact_response_all b
LEFT JOIN (select * from mktg_ops_vws.gmpbz_dim_arcpg_response_typ )d ON b.response_typ_key = d.response_type_key
WHERE 
	NOT  (d.response_category_code = 'PO' AND d.response_type_code  IN ('O1', 'O2', 'O4', 'O5', 'O6', 'OA', 'OD', 'OE', 'OF','OG') ) 
    AND NOT (d.response_category_code = 'PN' AND d.response_type_code = 'N2')
/* This NOT filter excludes the records with Category of PO and type of O1, O2, O4, O5, O6, OA, OD, OE.*'/ 

/*
(
	select 
		cnst_mstr_id,
		em_cnst_email,
		dm_cnst_prsn_l_nm,
		em_cnst_prsn_l_nm,
		dm_cnst_line_1_addr, 
		dm_cnst_line_2_addr, 
		dm_cnst_city_nm, 
		dm_cnst_st_cd, 
		dm_cnst_zip_5_cd
	from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr 
	where cnst_mstr_id in 
	(	
		select distinct cnst_mstr_id
		from mktg_ops_vws.bzfc_fact_response_all
	)
) a (cnst_mstr_id,em_cnst_email, dm_cnst_prsn_l_nm, em_cnst_prsn_l_nm, dm_cnst_line_1_addr, dm_cnst_line_2_addr, dm_cnst_city_nm, dm_cnst_st_cd, dm_cnst_zip_5_cd) 
left join 
(
	select 
		cnst_mstr_id,
		em_cnst_email,
		dm_cnst_prsn_l_nm,
		em_cnst_prsn_l_nm,
		dm_cnst_line_1_addr, 
		dm_cnst_line_2_addr, 
		dm_cnst_city_nm, 
		dm_cnst_st_cd, 
		dm_cnst_zip_5_cd
	from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr 
	where dm_cnst_addr_assessmnt_ctg = 'Deliverable' 
	) b (cnst_mstr_id, em_cnst_email, dm_cnst_prsn_l_nm, em_cnst_prsn_l_nm, dm_cnst_line_1_addr, dm_cnst_line_2_addr, dm_cnst_city_nm, dm_cnst_st_cd, dm_cnst_zip_5_cd) 
	on
		(a.dm_cnst_prsn_l_nm = b.dm_cnst_prsn_l_nm or a.em_cnst_prsn_l_nm = b.em_cnst_prsn_l_nm)
		and a.dm_cnst_line_1_addr = b.dm_cnst_line_1_addr  
		and  a.dm_cnst_line_2_addr = b.dm_cnst_line_2_addr   
		and a.dm_cnst_city_nm = b.dm_cnst_city_nm  
		and a.dm_cnst_st_cd = b.dm_cnst_st_cd  
		and a.dm_cnst_zip_5_cd =b.dm_cnst_zip_5_cd 
left join 
(
	select 
		cnst_mstr_id,
		em_cnst_email,
		dm_cnst_prsn_l_nm,
		em_cnst_prsn_l_nm,
		dm_cnst_line_1_addr, 
		dm_cnst_line_2_addr, 
		dm_cnst_city_nm, 
		dm_cnst_st_cd, 
		dm_cnst_zip_5_cd
	from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr 
	where  em_cnst_email_assessmnt_ctg in ('Validated', 'Use with Caution')
) c (cnst_mstr_id, em_cnst_email, dm_cnst_prsn_l_nm, em_cnst_prsn_l_nm, dm_cnst_line_1_addr, dm_cnst_line_2_addr, dm_cnst_city_nm, dm_cnst_st_cd, dm_cnst_zip_5_cd) 
	on a.em_cnst_email = c.em_cnst_email 
	*/
	

/*
	2/3/16 Mike Andrien - Added PG Group 11 - PGADVSR - PG Professional Advisors
	PG Group 11 will union the Convio and CDI/Stuart PG Advisor group lists into a single PG Professional Advisors group.
*/

-- Stuart List Source for PG Group 11*/
UNION ALL 
SELECT 
	11 AS pg_grp_key, -- PG Professional Advisors Group
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bz_grp_mbrshp a
WHERE grp_key IN (135)  -- These are the PG Professional Advisor group keys defined in the CMM grp_ref table

UNION  ALL

-- Convio List source for PG group 11
SELECT 
	DISTINCT
	11 AS pg_grp_key, -- PG Professional Advisors Group
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.cnvo_cnst a
 LEFT JOIN convio_tbls.cnvo_group_members b ON a.cnvo_cnst_id = b.cnvo_cnst_id
 WHERE b.cnvo_group_id = 17262 -- Convio Gift Planning - Professional Advisor List
  AND a.cnst_mstr_id IS NOT NULL 
  
  UNION ALL 
/*Query to derive the 74+ Lapsed Donor Audience -  Donors that are 74 years old and above, have a CGA score value of 20 and above and have 
   3 or more lifetime gifts the last gift date is between 24 and 48 months and the last gift amount is $10 or more.
Audience membership group. 
*/
/* 11/7/2023: Disabled this section based on Rich's  spreadsheet */ 
/* select 
	12 as pg_grp_key, -- 74+ Lapsed Donors Model Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
from  mktg_ops_vws.gms_arc_fr_smry a
left join mktg_ops_vws.bzf_cnst_scr b on a.cnst_mstr_id = b.cnst_mstr_id
left join (select  cnst_mstr_id, arc_srcsys_cd, bzd_birth_dt from mktg_ops_vws.bz_cnst_birth_best 
                where current_date between cast(cnst_birth_strt_ts as date format 'mm/dd/yyyy') and cnst_birth_end_dt
                qualify row_number() over (partition by cnst_mstr_id order by  bzd_birth_dt desc) = 1)
                 bd(cnst_mstr_id, arc_srcsys_cd, birth_dt) on a.cnst_mstr_id = bd.cnst_mstr_id
where   (current_date - bd.birth_dt) YEAR(4) >=74 and --Donor is 74 and above
				cast(pgcga_scrval as integer) >= 20 and  -- CGA Score is 20 or above
			   a.fr_lftm_dntn_cnt >= 3 and -- Donor has 3 or more lifetime gifts
			   (( a.fr_last_dntn_dt >= add_months(date, -48)  and a.fr_last_dntn_dt  <= add_months(date, -24) )  and a.fr_last_dntn_amt >= 10) -- Last donation date is between 24 and 48 months and the last gift amount is $10 or more.

UNION ALL */

/*Query to derive the 74+ Active Donor Audience -  Donors that are 74 years old and above, have a CGA score value of 20 and above and have 
   3 or more lifetime gifts the last gift date is within the last 24 months and the last gift amount is $10 or more.
Audience membership group. 
*/
/* 11/7/2023: Disabled this section based on Rich's  spreadsheet */ 
/* 
select 
	13 as pg_grp_key, -- 74+ Lapsed Donors Model Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
from  mktg_ops_vws.gms_arc_fr_smry a
left join mktg_ops_vws.bzf_cnst_scr b on a.cnst_mstr_id = b.cnst_mstr_id
left join (select  cnst_mstr_id, arc_srcsys_cd, bzd_birth_dt from mktg_ops_vws.bz_cnst_birth_best 
                where current_date between cast(cnst_birth_strt_ts as date format 'mm/dd/yyyy') and cnst_birth_end_dt
                qualify row_number() over (partition by cnst_mstr_id order by  bzd_birth_dt desc) = 1)
                 bd(cnst_mstr_id, arc_srcsys_cd, birth_dt) on a.cnst_mstr_id = bd.cnst_mstr_id
where   (current_date - bd.birth_dt) YEAR(4) >=74 and --Donor is 74 and above
				cast(pgcga_scrval as integer) >= 20 and  -- CGA Score is 20 or above
			   a.fr_lftm_dntn_cnt >= 3 and -- Donor has 3 or more lifetime gifts
			   (a.fr_last_dntn_dt >= add_months(date, -24) and a.fr_last_dntn_amt >= 10) -- Last donation date is within the last 24 and the last gift amount is $10 or more.

UNION ALL */

/*
Survey Responders -  The Survey Response group is a subset of the Information Requester group and is determined by the 2 character Effort Code within the 
source code. This list contains the disctinct list of cnst_mstr_ids contained in mktg_ops_vws.fact_response_all where the Effort, characters 8 and 9, within the source code 
associated with the response = 0M or 0E. 

NOTE: Update group 29 PG Survey Responders with a PG Interest response any time this group is updated.
*/
SELECT
	DISTINCT
	14 AS pg_grp_key, -- Survey Responders Group Key
	b.cnst_mstr_id  AS cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM 
	/* 11/7/2023: Majeed: Removed the joins to the FR profile */ 
  mktg_ops_vws.bzfc_fact_response_all b 
 JOIN mktg_ops_vws.gmpbzal_dim_src c ON b.src_key = c.src_key
WHERE Substring(c.src_cd,8,2) IN ('4M', '4E') AND Substring(c.src_cd,1,2) = 'AP'

UNION ALL 
/*  Closed Planned Giving - Exclusion Group
Combination of migrated TA information, Salesforce (future state)

10/8/15 - Mike Andrien - Added Legacy Society suppression to the PG Closed list (List 15)
1/8/2016 - Mike Andrien - Added 'Funded' to the stage contraint in the unioned group 15 query below.

*/
/* Removed the legacy ARCPG characteristics select below from the group 15 - PG Closed Cnst group on 01/19/2023 */
/*
select
	15 as pg_grp_key, -- Closed PG Constituents Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr a
left join  mktg_ops_vws.bzf_cnst_chrctrstc_arcpg b on a.cnst_mstr_id = b.cnst_mstr_id
where (bzd_pg_closed_cga = 'Y' or bzd_pg_closed_pg = 'Y' or bzd_pg_arc_in_will = 'Y') and 
a.cnst_mstr_id not in (select distinct cnst_mstr_id from mktg_ops_vws.gms_bzf_cnst_cnstcy_curnt where leg_scty_ind = 1)

UNION  ALL

/* UNION the bzfc_fsa_ask data to the legacy PG Closed data captured in the bzf_cnst_chrctrstc_arcpg view.  Currently, mapped the 
	table to the DDCOE view, but need to change this once the data in migrated from the2700 to Aprimo work tables. 
NOTE: This query returns duplicate master id recs because of the 1:M join through the bzl view, but the dups are eliminated when UNIONed with the previous select.	
*/*/
SELECT DISTINCT
	15 AS pg_grp_key, -- Closed PG Constituents Group Key
	 c.cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM eda.ufds_vws.bzfc_fact_ask a
LEFT JOIN eda.ufds_vws.frfbz_dim_ask da ON a.dim_ask_key = da.dim_ask_key
LEFT JOIN eda.ufds_vws.bzfc_dim_unf_fr_acct b ON b.frf_acct_key = a.ask_acct_key
LEFT JOIN eda.ufds_vws.bzl_cnst_mstr_fsa_acct c ON b.unf_fr_cnst_key = c.cnst_key
WHERE  da.ask_stg IN ('Accepted', 'Received', 'Funded') AND c.cnst_typ_cd IN ('AG', 'OR') AND da.ask_rec_typ= 'Planned Gift' AND 
c.cnst_mstr_id NOT IN (SELECT DISTINCT cnst_mstr_id FROM mktg_ops_vws.gms_bzf_cnst_cnstcy_curnt WHERE leg_scty_ind = 1)
UNION  ALL

/* Mike Andrien - 1/13/2015 - Added 3rd UNION query to include the Legacy Society donors in the Closed PG group - group 15 */

SELECT 
	15 AS pg_grp_key, -- Closed PG Constituents Group Key
	cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
 FROM   mktg_ops_vws.gms_bzf_cnst_cnstcy_curnt WHERE leg_scty_ind = 1

UNION ALL 

/*  NEW Group 16  added by Mike Andrien 7/6/2015 
Closed Planned Giving CGA  - Exclusion Group
Combination of migrated TA information, Salesforce (future state)

1/8/2016 - Mike Andrien - Added 'Funded' to the stage contraint in the unioned group 16 query below.
*/
SELECT
	16 AS pg_grp_key, -- PG Closed CGA Constituents Group Key
	a.cnst_mstr_id,
	Current_Timestamp AS dw_trans_ts
FROM mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr a
LEFT JOIN  mktg_ops_vws.bzf_cnst_chrctrstc_arcpg b ON a.cnst_mstr_id = b.cnst_mstr_id
WHERE bzd_pg_closed_cga = 'Y'

UNION   ALL

/*  
	UNION the bzfc_fsa_ask data to the legacy PG Closed CGA data captured in the bzf_cnst_chrctrstc_arcpg view.  
NOTE: This query returns duplicate master id recs because of the 1:M join through the bzl view, but the dups are eliminated when UNIONed with the previous select.	
*/

 SELECT
	16 AS pg_grp_key, -- PG Closed CGA Constituents Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
FROM mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr a
LEFT JOIN eda.arc_mdm_vws.bzl_cnst_mstr_fsa b ON  a.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN  mktg_ops_vws.bzfc_fsa_ask c ON b.bzd_acct_fsa_key = c.ask_acct_cnst_fsa_key
WHERE c.stage IN ('Received', 'Funded', 'Accepted') AND b.cnst_typ_cd IN ('IN', 'OR') AND c.rec_typ= 'Planned Gift' AND sf_gift_vehicle LIKE  '%CGA%'

UNION ALL 
/*
Information requesters 65+	(Inclusion) Hand Raisers 65+ - NOTE: This list is a subset of PG group 10  (Information Requesters) and is limited to constituents 65 and above.  
The list contains the disctinct list of cnst_mstr_ids contained in mktg_ops_vws.fact_response_all that are 65 years old and above.   7/15/2021 Note: We lowered the age to 64
*/
/*
select 
	17 as pg_grp_key, -- Information Requesters 64+ Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
from mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr a
left join mktg_ops_vws.bz_cnst_birth_best b  on a.cnst_mstr_id = b.cnst_mstr_id
where a.cnst_mstr_id in  (select distinct cnst_mstr_id from  mktg_ops_vws.bzfc_fact_response_all)
and b.bzd_derived_age >= 64

UNION ALL 
*/
/*  10/16/15 - Added By Mike Andrien
Query to derive the Bequest Model Audience -  Donors with a Bequest Model score of 60 and above are included in the 
Audience membership group. 
*/
SELECT 
	18 AS pg_grp_key, -- Bequest Model Audience Group Key
	cnst_mstr_id,
	CURRENT_TIMESTAMP
FROM mktg_ops_vws.bzf_cnst_scr
WHERE Cast(pgbeq_scrval AS INTEGER) >= 80

UNION ALL 

/*  10/22/15 - Added By Mike Andrien - (PGPINRSP)	PG Pin Package Respondents
		Query to derive the BPG Pin Package Respondents -  Donors who have responded to a previous Pin Package Mailing (donors with a populated 
		PG response interaction category/type of PO/O3, PO/O7, PO/OA or PO/O1).
*/
SELECT 
	19 AS pg_grp_key, -- PG Pin Package Respondents Group Key
	cnst_mstr_id,
	CURRENT_TIMESTAMP	
FROM mktg_ops_vws.bzfc_fact_response_all a
LEFT JOIN (select * from mktg_ops_vws.gmpbz_dim_arcpg_response_typ )b ON a.response_typ_key = b.response_type_key
WHERE b.response_category_code = 'PO' AND response_type_code IN ('O1', 'O3', 'O7', 'OA')		
	
UNION ALL 

/*  10/22/15 - Added By Mike Andrien - (PGPINRCPNT)	PG Pin Package Recipients
		Donors who have received a previous Pin Package Mailing (donors with Campaign interactions where the effort is 
		8M and the campaign description contains the word "pin"). 
*/
SELECT 
	20 AS pg_grp_key, -- PG Pin Package Recipients Key
	cnst_mstr_id,
	CURRENT_TIMESTAMP
FROM mktg_ops_vws.bzfc_fact_interaction_all
WHERE SUBSTRING (cell_src_cd,8,2) = '8M' AND comnictn_dsc LIKE '%pin%'

UNION ALL 
/*  10/22/15 - Added By Mike Andrien - (WGREQ)	Wills Guide Requesters
		Wills Guide Requesters - Donors who have previously requested or downloaded the Wills Guide 
		(donors with a PG response interaction with category/type of PW/W1, PW/W3, PW/W5, PW/W8, PW/W9).
*/
SELECT 
	21 AS pg_grp_key, -- Wills Guide Requester Group Key
	cnst_mstr_id,
	CURRENT_TIMESTAMP	
FROM mktg_ops_vws.bzfc_fact_response_all a
LEFT JOIN mktg_ops_vws.gmpbz_dim_arcpg_response_typ b ON a.response_typ_key = b.response_type_key
WHERE b.response_category_code = 'PW' AND response_type_code IN ('W1', 'W3', 'W4', 'W5')

UNION ALL 

/*  10/22/15 - Added By Mike Andrien - (PGSRVYRCPT) PG Survey Recipients 4+ Years
		PG Survey Recipients 4+ Years - 	Donors who have previously received the PG survey 
		campaign for 4+ years (effort is 0M, the campaign desc contains the word survey AND the initiatives are different from one another).
		NOTE: This is used as an exclusion group.  The PG group does not want to send the survey to people that have already received the survey two or more times
		
	3/10/2016 - Mike Andrien changed the count from 4 yrs to 3 years
	3/15/2017 - Mike Andrien changed the count from 3 yrs to 2 years 
	11/30/2020 - Mike Andrien replaced bz_comnctn_src with gmpbzal_dim_src and added '4M'' to the qualifier - the PG team changed the 8th and 9th position of the source code from '0M' to '4M' starting with the APP20054M000' campaign
	12/02/2020 - Mike Andrien Added the outer select to make sure we sum the mailed count across both interactions tables
	11/08/2021 - Mike Andrien Added group 37 for the PG Survey Recipients 4+ years.
*/
/* 11/7/2023: Disabled this section based on Rich's  spreadsheet */ 
/* 10/25/2024 Re-enabled the group and modified the definition to include recipient between 1 and 3 */	

 SELECT 
	22 AS pg_grp_key, -- PG Survey Recipients between 1 and 3 Years Group Key
	cnst_mstr_id,
	CURRENT_TIMESTAMP	
FROM
(
	SELECT 
		cnst_mstr_id, cell_src_cd AS src_cd
	FROM mktg_ops_vws.bzfc_fact_interaction_all
	WHERE SUBSTRING(cell_src_cd,8,2) = '0M' AND comnictn_dsc LIKE '%survey%' AND mailed_ind = 1 
	UNION ALL
	SELECT 
		a.cnst_mstr_id, a.src_cd
	FROM mktg_ops_vws.bzfc_fact_dmail_interaction a
	LEFT JOIN mktg_ops_vws.gmpbzal_dim_src b ON a.src_key = b.src_key
	WHERE SUBSTRING(a.src_cd,8,2) IN ('4M', '0M')  AND b.src_dsc LIKE '%survey%' AND mailed_ind = 1 
) a (cnst_mstr_id, src_cd)
GROUP BY a.cnst_mstr_id
HAVING Count(DISTINCT a.src_cd) BETWEEN 1 AND 3
UNION ALL 

/*
PG Wills Guide Model Audience Age 50+	Donors with a PG Wills Guide Model score of 60 and above and are age 50 and older
*/
/* 11/7/2023: Disabled this section based on Rich's  spreadsheet */ 
/* select	 -- (PGWG50+) - PG Wills Guide Model Audience Age 50+  
	23 as pg_grp_key, -- PG Response Model Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
from mktg_ops_vws.bzf_cnst_scr a
left join mktg_ops_vws.bz_cnst_birth_best b on a.cnst_mstr_id = b.cnst_mstr_id
where cast(pgwg_scrval as integer) >= 61
and b.bzd_derived_age >=50 -- This is the check to make sure the constituent is 50 years old or older.

UNION ALL */
/*
	2/3/16 Mike Andrien - Added PG Group 24 - PGPDSRCH - PG Paid Search Prospects
	PG Group 11 will union the Convio and CDI/Stuart PG Advisor group lists into a single PG Professional Advisors group.
*/

-- Stuart List Source for PG Group 24
SELECT 
	24 AS pg_grp_key, -- PG Professional Advisors Group
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
FROM mktg_ops_vws.bz_grp_mbrshp a
WHERE grp_key IN (134)  -- These are the PG Paid Search Prospects group keys defined in the CMM grp_ref table

UNION  ALL

-- Convio List source for PG group 24
SELECT 
	DISTINCT
	24 AS pg_grp_key, -- PG Paid Search Prospects Group
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
FROM mktg_ops_vws.cnvo_cnst a
 LEFT JOIN convio_tbls.cnvo_group_members b ON a.cnvo_cnst_id = b.cnvo_cnst_id
 WHERE b.cnvo_group_id = 47810 -- Convio Gift Planning - Paid Search Prospects list

UNION ALL 

--PG Group 26 - Donors age 64 and older with a populated PG response interaction category of PC OR a response interaction category/type of PF/FI

SELECT 
	DISTINCT
	26 AS pg_grp_key, -- Survey Responders Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP
FROM mktg_ops_vws.bzfc_fact_response_all a
LEFT JOIN mktg_ops_vws.bz_cnst_birth_best b  ON a.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN mktg_ops_vws.gmpbz_dim_arcpg_response_typ c ON a.response_typ_key = c.response_type_key
WHERE 	
	 (c.response_category_code = 'PC') OR
	 (c.response_category_code = 'PF' AND response_type_code IN ( 'FI', 'F9')) 

UNION ALL 

/*  PG Group 27 -  Volunteers Age 50-82
Description: Supporters age 50 to age 82 by data selection date with a PG Wills Guide Model score of 800+; flagged as a volunteer (VMS) only or a volunteer and blood donor (VMS + BIOMED) only   
does not include financial donor records (those with one or more gifts on file) or 
records that are flagged as blood donors (BIOMED) only
*/	 

SELECT	 /* (PGVOL50-82) - PG Group 27 -  Volunteers Age 50-82 */
	27 AS pg_grp_key, -- PG Response Model Audience Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_arc_best_smry a
LEFT JOIN mktg_ops_vws.bzf_cnst_scr b ON a.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN mktg_ops_vws.bz_cnst_birth_best c ON a.cnst_mstr_id = c.cnst_mstr_id
WHERE Cast(b.pgwg_scrval AS INTEGER) >= 61  -- Must have a Will Guide score of 800 or above. 12/21/2018 due to model changes, we lowered the score req't to 80
AND c.bzd_derived_age BETWEEN 50 AND 82 -- This is the check to make sure the constituent is between 50  to 82 years old
AND a.lst_volntrng_dt IS NOT NULL AND (lst_phss_cours_cmpltn_dt IS NULL AND lst_fr_dntn_dt IS NULL)

UNION ALL

/* PG Wills Guide Offer Recipients 4+ Years
Description: Supporters who have previously received the PG wills guide campaign for 4 or more years (supporters with 4 or more Campaign interactions where the effort is 2M AND the initiatives are different from one another)
*/
SELECT 
	28 AS pg_grp_key, -- PG Wills Guide Offer Recipients 4+ Years
	cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts	
FROM mktg_ops_vws.bzfc_fact_interaction_all
WHERE SUBSTRING(cell_src_cd,8,2) = '2M' AND mailed_ind =1
GROUP BY cnst_mstr_id
HAVING Count(DISTINCT cell_src_cd) >=4

UNION ALL

SELECT 
	28 AS pg_grp_key, -- PG Wills Guide Offer Recipients 4+ Years
	cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts	
FROM mktg_ops_vws.bzfc_fact_dmail_interaction
WHERE SUBSTRING(src_cd,8,2) = '2M' AND mailed_ind =1
GROUP BY cnst_mstr_id
HAVING Count(DISTINCT src_cd) >=4

UNION ALL

SELECT 
	DISTINCT
	29 AS pg_grp_key, -- PG Responders with PG Interest Group Key
	a.cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
FROM 
(
	SELECT DISTINCT a.cnst_mstr_id
	FROM mktg_ops_vws.bzfc_fact_response_all a 
	LEFT JOIN mktg_ops_vws.gmpbz_dim_arcpg_response_typ b ON a.response_typ_key = b.response_type_key
	WHERE 
		(
			(b.response_category_code = 'PF' AND b.response_type_code IN ( 'FI', 'FN'))
			OR (b.response_category_code = 'PB' AND b.response_type_code IN ( 'W1', 'W2'))
			OR (b.response_category_code = 'PN' AND b.response_type_code = 'N1')
		)
) a (cnst_mstr_id)

 UNION ALL
/*Wills Guide Responders Group Key 30*/
 SELECT 
	DISTINCT
	30 AS pg_grp_key, 
	b.cnst_mstr_id,
	CURRENT_TIMESTAMP AS dw_trans_ts
 FROM mktg_ops_vws.bzfc_fact_response_all b 
 JOIN mktg_ops_vws.gmpbzal_dim_src c ON b.src_key = c.src_key
 LEFT JOIN mktg_ops_vws.gmpbz_dim_arcpg_response_typ d ON b.response_typ_key = d.response_type_key
WHERE 
	Substring(c.src_cd,8,1) = '2'
	AND ((response_category_code = 'PW' AND response_type_code IN ('W1', 'W3','W4','W5')) OR 
	(response_category_code = 'PB' AND response_type_code = 'W1') OR 
	(response_category_code = 'PN' AND response_type_code = 'N1') OR 
	(response_category_code = 'PF' AND response_type_code = 'FN'))

 UNION ALL
 /*Group Key 31 - DGTLWGROI	- Digital WG Guide Respondents Opt in*/
SELECT DISTINCT
    31 AS pg_grp_key, 
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE 
    lander_type IN (
        'Digital Campaign WG Request', 
        'Wills Guide Facebook Campaign'
    )
    AND email_opt_in = 'x'
    AND cnst_mstr_id <> 0


UNION ALL 


 /*Group Key 32 - DGTLCGARSP	Digital CGA Respondents */
SELECT DISTINCT
    32 AS pg_grp_key, 
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE 
    lander_type IN (
        'Digital Campaign CGA Illustration Request', 
        'CGA Search Engine Campaign', 
        'CGA Facebook Campaign'
    )
    AND cnst_mstr_id <> 0
    
union ALL

 /*Group Key 33 - DGTLCGAOI	Digital CGA Respondent Opt in */--Hitansu: modified from here
SELECT DISTINCT
    33 AS pg_grp_key,
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE 
    lander_type IN (
        'Digital Campaign CGA Illustration Request', 
        'CGA Search Engine Campaign', 
        'CGA Facebook Campaign'
    )
    AND email_opt_in = 'x'
    AND cnst_mstr_id <> 0

	
UNION ALL

-- Group Key 34 - DGTLGPGRSP Digital GPG Respondents
SELECT DISTINCT
    34 AS pg_grp_key,
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE 
    lander_type = 'Digital Campaign General Gift Planning Info Request'
    AND cnst_mstr_id <> 0

UNION ALL

-- Group Key 35 - DGTLGPGOI Digital GPG Respondent Opt in
SELECT DISTINCT
    35 AS pg_grp_key,
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE 
    lander_type = 'Digital Campaign General Gift Planning Info Request'
    AND email_opt_in = 'x'
    AND cnst_mstr_id <> 0
UNION ALL


-- Group Key 36 - DGTLWGRSP Digital WG Guide Respondents
SELECT DISTINCT
    36 AS pg_grp_key,
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE 
    lander_type IN (
        'Digital Campaign WG Request', 
        'Wills Guide Facebook Campaign', 
        'Wills Guide Search Engine Campaign'
    )
    AND cnst_mstr_id <> 0
    
 union all 
/*  
	11/08/2021 - Mike Andrien Added group 37 for the PG Survey Recipients 4+ years.  NOTE, This is a mirror copy of group 22, which has been configured
	for the 2+ year recipient group.
*/
SELECT 
    37 AS pg_grp_key, -- PG Survey Recipients 4+ Years Group Key
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM (
    SELECT 
        cnst_mstr_id, 
        cell_src_cd AS src_cd
    FROM mktg_ops_vws.bzfc_fact_interaction_all
    WHERE SUBSTRING(cell_src_cd, 8, 2) = '0M' 
        AND comnictn_dsc ILIKE '%survey%' 
        AND mailed_ind = 1

    UNION ALL

    SELECT 
        a.cnst_mstr_id, a.src_cd
    FROM mktg_ops_vws.bzfc_fact_dmail_interaction a
    LEFT JOIN mktg_ops_vws.gmpbzal_dim_src b 
        ON a.src_key = b.src_key
    WHERE SUBSTRING(a.src_cd, 8, 2) IN ('4M', '0M') 
        AND b.src_dsc ILIKE '%survey%' 
        AND mailed_ind = 1
) a (cnst_mstr_id, src_cd)
GROUP BY a.cnst_mstr_id
HAVING COUNT(DISTINCT a.src_cd) >= 4
UNION ALL

/* Added the Training Service External Suppress Group; - These are master ids associated with email and mailing addresses in PHSS Preferred profile
but the the master ids are not in PHSS Preferred.  These are household associations to be used as a suppression group.
*/
SELECT 
    38 AS segmnt_group_key, 
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.suprsn_ts_cnst
WHERE cnst_mstr_id NOT IN (
    SELECT cnst_mstr_id 
    FROM mktg_ops_vws.cnst_cdi_smry_phss_prfr
)
UNION ALL
/*  Group Key 39 - DGTLBDRSP - Digital Beneficiary Designation Respondents */
SELECT DISTINCT
    39 AS pg_grp_key, 
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE 
    lander_type IN (
        'Beneficiary Designation Facebook Campaign', 
        'Beneficiary Designation Search Engine Campaign'
    )
    AND cnst_mstr_id <> 0

	
	UNION ALL
-- Group Key 40 - FWRESPNB - FreeWill Respondents Non Branded
SELECT DISTINCT
    40 AS pg_grp_key, 
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE  
    CASE 
        WHEN site_url IN (
            'arc', 'amredcross', 'arcwill', 'givearc', 
            'americanredcross', 'redcross', 'giveamredcross', 'aredcross'
        ) THEN 1 
        ELSE 0 
    END = 0
    AND appl_src_cd = 'FRWL'
    AND cnst_mstr_id <> 0

UNION ALL

-- Group Key 41 - FWRESPB - FreeWill Respondents Branded
SELECT DISTINCT
    41 AS pg_grp_key, 
    cnst_mstr_id,
    CURRENT_TIMESTAMP AS dw_trans_ts
FROM mktg_ops_vws.bzfc_pg_response_log
WHERE 
    site_url IN (
        'arc', 'amredcross', 'arcwill', 'givearc', 
        'americanredcross', 'redcross', 'giveamredcross', 'aredcross'
    )
    AND cnst_mstr_id <> 0
with no schema binding;