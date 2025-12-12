CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_sms_bio_prfl AS 
--drop view mktg_ops_vws.bzfc_sms_bio_prfl;
CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_sms_bio_prfl
/*
Created By:	Michael Andrien
Create Date:	09/17/2024
Purpose:	This view links the mobile phone numbers from the SMS Profile view (bzfc_sms_profile) to the CDI phone locator view (arc_mdm_vws.bzfc_cnst_phn) to
match the mobile phone numbers to the CDI master ids associated with the numbers.  Note, this is a loose match in that we are linking incoming SMS texts responses, which 
are anonymous texts with CDI phone numbers from known Red Cross source systems.  After pairing the SMS numbers to the 'Usable' CDI phone numbers, the view joins the CDI master id
to the Mktg Biomed preferred profile on the master id.  An SMS number may be associated with more than one CDI master id and a master id may be associated with more than one number.  The
grain of the view is CDI master (cnst_mstr_id) and SMS mobile number.  Lastly, this view is limited to master ids in the Mktg Biomed preferred profile.

Modified By: Michael Andrien
Modified Date: 10/22/2024
Purpose: Replace the a to b join logic below with Substr(RegExp_Replace(a.locator_phn_num,'[^0-9]', ''),1,10) = b.mobile_num.  This strips non-numeric characters from the profile phone
number rather than adding the non-numeric characters to the SMS profile number.  This is a cleaner method for the join.
ON a.locator_phn_num = CASE WHEN Length(b.mobile_num) = 10 THEN '(' || Substr(b.mobile_num, 1,3) ||') ' || Substr(b.mobile_num, 4,3) || '-' || Substr(b.mobile_num, 7,4) 
																		ELSE b.mobile_num
																	END

Modified By: 			Greg Seaberg
Implemented By:		Michael Andrien
Modified Date:		1/3/2024
Purpose:					Updated join logic between bzfc_sms_profile and the union of bzfc_cnst_phn and bzfc_phone_append.
									
									Old logic:
									Substr(RegExp_Replace(a.locator_phn_num,'[^0-9]', ''),1,10) = b.mobile_num
									
									New logic:
									OTRANSLATE(a.locator_phn_num, OTRANSLATE(a.locator_phn_num, '0123456789',''), '') = b.mobile_num
									
							Also, changed the bzfc_phone_append UNION to a UNION ALL and added correlated subquery logic to avoid duplicating interaction rows.  Lastly, we removed the 
							SELECT DISTINCTS and updated the QUALIFY statements to include cnst_mstr_id.
Modified By: Michael Andrien
Modified Date: 04/03/2025
Purpose: Added time_zone_dsc to the view 

Modified By: Michael Andrien
Modified Date: 08/12/2025
Purpose: Modified the select and join logic to strip non-numeric values from the phone number before joining.  This fixed the issue with most 
records not having CDI master id matches.  We now have a much higher master id match rate.
*/
AS
SELECT 
	c.cnst_mstr_id
	, b.src_mobile_num
	, b.mobile_num
    , b.time_zone_dsc
	, CASE WHEN ok_to_text_flg IS NULL THEN 'N' ELSE ok_to_text_flg END AS ok_to_text_flg
	, active_carrier_nm
	, active_create_ts
	, active_status
	, active_source_typ
	, active_source_nm
	, active_status_dsc
	, active_opt_out_dt
	, active_opt_out_source
	, coalesce(active_subscrbr_ind,0) AS active_subscrbr_ind
	, unsbscrb_carrier_nm
	, unsbscrb_created_ts
	, unsbscrb_status
	, unsbscrb_source_typ
	, unsbscrb_source_nm
	, unsbscrb_status_dsc
	, unsbscrb_opt_out_dt
	, unsbscrb_opt_out_source
	, coalesce(unsbscrb_ind,0) AS unsbscrb_ind
	, adobe_first_unsbscrb_ts
	, adobe_first_unsbscrb_dt
	, adobe_last_unsbscrb_ts
	, adobe_last_unsbscrb_dt
	, adobe_opt_out_ind
	, first_adobe_opt_in_ts
	, first_adobe_opt_in_dt
	, last_adobe_opt_in_ts
	, last_adobe_opt_in_dt
	, coalesce(adobe_opt_in_ind,0) AS adobe_opt_in_ind
	, first_mc_opt_in_ts
	, last_mc_opt_in_ts
	, first_mc_opt_out_ts
	, last_mc_opt_out_ts
	, coalesce(mc_opt_out_cnt,0) AS mc_opt_out_cnt
FROM 
(
	(
			SELECT 
	        cnst_mstr_id,
	        locator_phn_num
	        from (
	        		SELECT 
			        cnst_mstr_id,
			        collate(REGEXP_REPLACE(locator_phn_num, '[^0-9]', '')::text, 'CI' ) as locator_phn_num,
			        ROW_NUMBER() OVER (
			        PARTITION BY a.locator_phn_num
			        ORDER BY 
			            CASE 
			                WHEN b.line_of_service_cd = 'BIO' THEN 1
			                WHEN b.line_of_service_cd IN ('FR','ATG','MDON','MKTG','RCO') THEN 2
			                WHEN b.line_of_service_cd = 'VMS' THEN 3
			                WHEN b.line_of_service_cd = 'PHSS' THEN 4
			                ELSE 5
			            END,
			            a.cnst_phn_strt_ts DESC,
			            a.cnst_mstr_id ASC
			    	) as rn
				    FROM eda.arc_mdm_vws.bzfc_cnst_phn a
				    LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys b 
				        ON a.arc_srcsys_cd = b.arc_srcsys_cd
				    WHERE a.assessmnt_ctg IN ('Usable', 'Use With Caution')
	        
	        ) as subqry 
	        where subqry.rn=1
			   
	) 
	
	UNION ALL
	(	
		SELECT 
        cnst_mstr_id,
        locator_phn_num
        from(
        		SELECT 
		        cnst_mstr_id,
		        collate(REGEXP_REPLACE(a.append_phone_num, '[^0-9]', '')::text,'CI') AS locator_phn_num,
		        ROW_NUMBER() OVER (
		        PARTITION BY a.append_phone_num
		        ORDER BY a.list_upload_ts DESC, a.cnst_mstr_id ASC
		    	) as rn
			    FROM mktg_ops_vws.bzfc_phone_append a
			    WHERE a.line_typ = 'Cell'
			      AND NOT EXISTS (
			            SELECT 1
			            FROM eda.arc_mdm_vws.bzfc_cnst_phn b
			            WHERE b.assessmnt_ctg IN ('Usable', 'Use With Caution')
			              AND COLLATE(a.append_phone_num::text, 'CI') = COLLATE(b.locator_phn_num::text, 'CI')
			       )
        ) as subqry 
        where subqry.rn=1
		
	  
	) 
)a (cnst_mstr_id, locator_phn_num)
INNER JOIN mktg_ops_vws.bzfc_sms_profile b ON collate(a.locator_phn_num::text,'CI') = collate(b.mobile_num::text,'CI') --OTranslate(a.locator_phn_num, OTranslate(a.locator_phn_num, '0123456789',''), '') = b.mobile_num	
/*
ON Substr(RegExp_Replace(a.locator_phn_num,'[^0-9]', ''),1,10)= b.mobile_num	
ON a.locator_phn_num = CASE WHEN Length(b.mobile_num) = 10 THEN '(' || Substr(b.mobile_num, 1,3) ||') ' || Substr(b.mobile_num, 4,3) || '-' || Substr(b.mobile_num, 7,4) 
																		ELSE b.mobile_num
																	END
*/
RIGHT JOIN mktg_ops_vws.cnst_cdi_smry_bio_prfr c ON a.cnst_mstr_id = c.cnst_mstr_id
with no schema binding;