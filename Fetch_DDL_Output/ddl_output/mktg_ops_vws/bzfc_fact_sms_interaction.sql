CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fact_sms_interaction AS

/*
Created By: 	Michael Andrien
Created Date:	09/18/2024
Purpose:	This view contain the SMS interaction records from the Adobe nmsbroadlogrcp table and links the SMS interaction to a CDI master id.
The view includes the CDI master id associated with the Adobe recipient (bicnst_mstr_id) and the CDI master id (cnst_mstr_id) derived from join 'k',
which UNIONs the query results from the CDI phone table with the Mktg phone append data.  We're giving priority to the master id from join 'k'.  This
join is on the mobile phone number.  We include logic to dedup the results and priorize the FR phone source and the most recently added phone start date entry
within the line of business to avoid duplicates in the view.

Modified By: 		Greg Seaberg
Implemented By:		Michael Andrien
Modified Date:		12/31/2024
Purpose:					Updated join logic between bz_adb_nmsbroadlogrcp and the union of bzfc_cnst_phn and bzfc_phone_append. Previous logic added characters
									(parentheses, spaces, n-dash) to the saddress field; updated logic uses otranslate to remove non-numeric characters from both sides of
									the join.

									Old logic:
									k.locator_phn_num = CASE WHEN Length(a.saddress) = 10 THEN '(' || Substr(a.saddress, 1,3) ||') ' || Substr(a.saddress, 4,3) || '-' || Substr(a.saddress, 7,4)
																		ELSE a.saddress
																	END
									New logic:
									OTRANSLATE(k.locator_phn_num, OTRANSLATE(k.locator_phn_num, '0123456789',''), '') = OTRANSLATE(a.saddress, OTRANSLATE(a.saddress, '0123456789',''), '')

							Also, changed the bzfc_phone_append UNION to a UNION ALL and added correlated subquery logic to avoid duplicating interaction rows.  Lastly, we removed the
							SELECT DISTINCTS and updated the QUALIFY statements to include cnst_mstr_id.

Modified By: 		Michael Andrien
Modified Date:		06/10/2025
Purpose:            Changed the view to be a straight read from mktg_ops_tbls.bzfc_fact_sms_interaction and move the original view SQL into a macro (ld_bzfc_fact_sms_interaction)
to load the table.
*/
SELECT
    cnst_mstr_id, irecipientid, recipient_cnst_mstr_id, mobile_num, unit_key, nk_intrctn_id, delivery_key, campgn_key, channel_key, intrctn_status_key, src_key, src_cd, subsrc_cd, 	delivery_status_cd, delivery_status_dsc, intrctn_status_id, intrctn_status_dsc, channel_dsc, intrctn_ts, intrctn_dt, sms_intrctn_ind, srcsys_trans_ts, dw_trans_ts, row_stat_cd, 	appl_src_cd, load_id
FROM mktg_ops_tbls.bzfc_fact_sms_interaction
WITH NO SCHEMA BINDING
;