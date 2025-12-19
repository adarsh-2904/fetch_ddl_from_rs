create or REPLACE VIEW mktg_ops_vws.bzfc_sms_phss_prfl 
AS
SELECT 
	c.cnst_mstr_id
	, b.src_mobile_num
	, b.mobile_num
    , b.time_zone_dsc
	, ok_to_text_flg
	, active_carrier_nm
	, active_create_ts
	, active_status
	, active_source_typ
	, active_source_nm
	, active_status_dsc
	, active_opt_out_dt
	, active_opt_out_source
	, active_subscrbr_ind
	, unsbscrb_carrier_nm
	, unsbscrb_created_ts
	, unsbscrb_status
	, unsbscrb_source_typ
	, unsbscrb_source_nm
	, unsbscrb_status_dsc
	, unsbscrb_opt_out_dt
	, unsbscrb_opt_out_source
	, unsbscrb_ind
	, adobe_first_unsbscrb_ts
	, adobe_first_unsbscrb_dt
	, adobe_last_unsbscrb_ts
	, adobe_last_unsbscrb_dt
	, adobe_opt_out_ind
	, first_adobe_opt_in_ts
	, first_adobe_opt_in_dt
	, last_adobe_opt_in_ts
	, last_adobe_opt_in_dt
	, adobe_opt_in_ind
	, first_mc_opt_in_ts
	, last_mc_opt_in_ts
	, first_mc_opt_out_ts
	, last_mc_opt_out_ts
	, mc_opt_out_cnt
FROM 
(
	(
		SELECT /*DISTINCT*/ cnst_mstr_id::bigint, REGEXP_REPLACE(locator_phn_num, '[^0-9]', '')::bigint as locator_phn_num
		FROM eda.arc_mdm_vws.bzfc_cnst_phn a
		LEFT JOIN eda.arc_mdm_vws.bz_arc_srcsys b ON a.arc_srcsys_cd = b.arc_srcsys_cd
		WHERE a.assessmnt_ctg IN ('Usable', 'Use With Caution')
		QUALIFY Row_Number() Over (PARTITION BY a.locator_phn_num  ORDER BY 
						CASE WHEN b.line_of_service_cd = 'PHSS' THEN 1
									WHEN b.line_of_service_cd IN ('FR', 'ATG', 'MDON', 'MKTG', 'RCO') THEN 2
									WHEN b.line_of_service_cd = 'BIO' THEN 3
									WHEN b.line_of_service_cd = 'VMS'  THEN 4
									ELSE 5
							end, a.cnst_phn_strt_ts DESC, a.cnst_mstr_id ASC) = 1
	) 
	
	UNION
	(
		SELECT /*DISTINCT*/ cnst_mstr_id::bigint, append_phone_num::bigint
		FROM mktg_ops_vws.bzfc_phone_append a
		WHERE a.line_typ = 'Cell'
			AND NOT EXISTS (
				SELECT * FROM eda.arc_mdm_vws.bzfc_cnst_phn b
				WHERE b.assessmnt_ctg IN ('Usable', 'Use With Caution')
					AND coalesce(a.append_phone_num,'0')::bigint = coalesce(b.locator_phn_num,'0')::bigint
				)
		QUALIFY Row_Number() Over(PARTITION BY a.append_phone_num ORDER BY a.list_upload_ts DESC, a.cnst_mstr_id ASC) = 1
	) 
)a (cnst_mstr_id, locator_phn_num)
INNER JOIN mktg_ops_vws.bzfc_sms_profile b ON REGEXP_REPLACE(a.locator_phn_num, '[^0-9]', '')::bigint= REGEXP_REPLACE(b.mobile_num, '[^0-9]', '')::bigint
/*
ON Substr(RegExp_Replace(a.locator_phn_num,'[^0-9]', ''),1,10)= b.mobile_num	
ON a.locator_phn_num = CASE WHEN Length(b.mobile_num) = 10 THEN '(' || Substr(b.mobile_num, 1,3) ||') ' || Substr(b.mobile_num, 4,3) || '-' || Substr(b.mobile_num, 7,4) 
																		ELSE b.mobile_num
																	END
*/
RIGHT JOIN mktg_ops_vws.cnst_cdi_smry_phss_prfr c ON a.cnst_mstr_id = c.cnst_mstr_id
with no schema binding;