CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_bzfc_sms_profile()
 LANGUAGE plpgsql
AS $_$

/*
Modified By:	Michael Andrien
Modified Date:	04/10/2025
Purpose:    Created this macro to address performance issues with the mktg_ops_vws.bzfc_sms_profile view. I've transferred the original header comments and SQL 
from the view into the macro.  We'll load a physical table and will redefine the view to read the new table. The comments below explain the purpose of the view.
    ***
    Created By: 	Michael Andrien
    Create Date:	06/11/2024
    Purpose:		This view contains mobile phone number metadata and is referenced in the Adobe Campaign schema.  The base records originated
    from the final Mobile Commons active subscriber and unsubscribe reports.  The view references the adb_arcinsms_report_intermediate and adb_arckaleyradeactivation 
    tables from the Adobe Campaign database to include opt-in and opt-out metrics within the view.  We capture the min and max dates for the SMS opt-ins and opt-outs.  The metadata
    in the view is referenced by the ok_to_text_flg and determines whether the mobile number can be included in text/SMS campaigns within the Adobe Campaign platform.

    Modified By:	Michael Andrien
    Modified Date 	07/01/2024
    Purpose:		Added clnsd_mobile_num

    Modified By:	Michael Andrien
    Modified Date 	08/08/2024
    Purpose:	 Added FULL OUTER JOIN e to include the final Mobile Commons opt_out numbers

    Modified By:	Michael Andrien
    Modified Date:	11/26/2024
    Purpose: Added 'STOP2END' to the opt-out logic

    Modified By:	Michael Andrien
    Modified Date:	01/07/2025
    Purpose: Updated ok_to_text_flg logic to set the flag = 'N' when the mobile number is null.  Also, added the RCO phone opt-ins.
    NOTE: All RCO phone numbers added to CDI on or after 8/10/2024 are considered automatic opt-ins. We don't know the phone type for these,
    but assume most will be mobile phone numbers.  Given the low data volume, the business teams agreed to include these without confirming the phone type.

    Modified By:	Michael Andrien
    Modified Date:	01/22/2025
    Purpose:  Modified the FULL OUTER JOIN logic to join on the mobile number without the exchange.  This was done to eliminate duplicates across the joined data sets.  This was an issue because
    the Mobile Commons data source files included the exchange on the mobile number and the other sources did not.

    Modified By:	Michael Andrien
    Modified Date:	04/01/2025
    Purpose: Added the time zone join mktg_ops_vws.bz_area_code_2_time_zone and time_zone_dsc attribute to the view
    
	Modified By:	Michael Andrien
    Modified Date:	08/13/2025
    Purpose: Added an update statements after the table insert to suppress mobile numbers associated with major donors and SF managed account with a 'Green' status.
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_bzfc_sms_profile', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN


TRUNCATE TABLE mktg_ops_tbls.bzfc_sms_profile;

INSERT INTO mktg_ops_tbls.bzfc_sms_profile

select 


cast(coalesce(cast(a.mobile_num as bigint),cast(b.mobile_num as bigint),cast(c.mobile_num as bigint),cast(d.mobile_num as bigint),cast(e.mobile_num as bigint),cast(f.mobile_num as bigint),0) as VARCHAR )

AS src_mobile_num
,
cast(CASE
	WHEN CAST(SUBSTRING(coalesce(cast(a.mobile_num as bigint),cast(b.mobile_num as bigint),cast(c.mobile_num as bigint),cast(d.mobile_num as bigint),cast(e.mobile_num as bigint),cast(f.mobile_num as bigint),0), 1, 1) AS CHAR(1)) = '1'
	THEN cast(SUBSTRING(REGEXP_REPLACE(coalesce(cast(a.mobile_num as bigint),cast(b.mobile_num as bigint),cast(c.mobile_num as bigint),cast(d.mobile_num as bigint),cast(e.mobile_num as bigint),cast(f.mobile_num as bigint),0), '[^0-9]', ''), 2, 10) as BIGINT)
	ELSE cast(coalesce(cast(a.mobile_num as bigint),cast(b.mobile_num as bigint),cast(c.mobile_num as bigint),cast(d.mobile_num as bigint),cast(e.mobile_num as bigint),cast(f.mobile_num as bigint),0) as bigint)
end as VARCHAR(12)) AS mobile_num,
    cast(g.time_zone_dsc as varchar(20))  ,
cast(CASE

	WHEN COALESCE(d.opt_in_cnt, 0) > 0 AND COALESCE(c.opt_out_cnt, 0) = 0 THEN 'Y'
	WHEN COALESCE(d.opt_in_cnt, 0) > 0 AND COALESCE(c.opt_out_cnt, 0) > 0 AND d.last_adobe_opt_in_ts > c.last_unsbscrb_ts THEN 'Y'
	WHEN coalesce(f.rco_opt_in_cnt,0) > 0 AND COALESCE(c.opt_out_cnt, 0) = 0 THEN 'Y'
	WHEN COALESCE(a.active_subscrbr_ind, 0) = 1 AND COALESCE(b.unsbscrb_ind, 0) = 0 AND COALESCE(c.opt_out_cnt, 0) = 0 THEN 'Y'
	WHEN COALESCE(a.active_subscrbr_ind, 0) = 1 AND COALESCE(b.unsbscrb_ind, 0) = 1 AND COALESCE(c.opt_out_cnt, 0) = 0 AND active_create_ts > unsbscrb_created_ts THEN 'Y'
	WHEN COALESCE(a.active_subscrbr_ind, 0) = 1 AND COALESCE(b.unsbscrb_ind, 0) = 1 AND COALESCE(c.opt_out_cnt, 0) = 0 AND active_create_ts < unsbscrb_created_ts THEN 'N'
	WHEN COALESCE(a.active_subscrbr_ind, 0) = 0 AND COALESCE(b.unsbscrb_ind, 0) = 1 AND COALESCE(c.opt_out_cnt, 0) = 0 THEN 'N'
	WHEN COALESCE(a.active_subscrbr_ind, 0) = 0 AND COALESCE(d.opt_in_cnt, 0) = 0 THEN 'N'
	WHEN COALESCE(b.unsbscrb_ind, 0) = 1 OR COALESCE(c.opt_out_cnt, 0) > 0 THEN 'N'
	WHEN COALESCE(e.mc_opt_out_cnt, 0) > 0 THEN 'N'
	WHEN coalesce(cast(a.mobile_num as bigint),cast(b.mobile_num as bigint),cast(c.mobile_num as bigint),cast(d.mobile_num as bigint),cast(e.mobile_num as bigint),cast(f.mobile_num as bigint),0)= 0 THEN 'N'
	ELSE 'Y'
END as varchar(256))AS ok_to_text_flg,

  a.active_carrier_nm,
    a.active_create_ts::timestamp,
    a.active_status,
    a.active_source_typ,
    a.active_source_nm,
    a.active_status_dsc::smallint,
    a.active_opt_out_dt::smallint,
    a.active_opt_out_source::smallint,
    COALESCE(a.active_subscrbr_ind, 0) AS active_subscrbr_ind,
    b.unsbscrb_carrier_nm,
    b.unsbscrb_created_ts,
    b.unsbscrb_status,
    b.unsbscrb_source_typ,
    b.unsbscrb_source_nm,
    b.unsbscrb_status_dsc,
    b.unsbscrb_opt_out_dt::timestamp,
    b.unsbscrb_opt_out_source,
    COALESCE(b.unsbscrb_ind, 0) AS unsbscrb_ind,
    c.first_unsbscrb_ts AS adobe_first_unsbscrb_ts, 
    c.first_unsbscrb_dt AS adobe_first_unsbscrb_dt,
    c.last_unsbscrb_ts AS adobe_last_unsbscrb_ts, 
    c.last_unsbscrb_dt AS adobe_last_unsbscrb_dt,
    CASE WHEN COALESCE(c.opt_out_cnt, 0) > 0 THEN 1 ELSE 0 END AS adobe_opt_out_ind,
    d.first_adobe_opt_in_ts, 
    d.first_adobe_opt_in_dt, 
    d.last_adobe_opt_in_ts,
    d.last_adobe_opt_in_dt, 
    CASE WHEN COALESCE(d.opt_in_cnt, 0) > 0  THEN 1 ELSE 0 END AS adobe_opt_in_ind,
    e.first_mc_opt_in_ts, 
    e.last_mc_opt_in_ts, 
    e.first_mc_opt_out_ts, 
    e.last_mc_opt_out_ts,
    COALESCE(e.mc_opt_out_cnt, 0) AS mc_opt_out_cnt,
    f.first_rco_phn_opt_in_ts, 
    f.first_rco_phn_opt_in_dt, 
    f.last_rco_phn_opt_in_ts,
    f.last_rco_phn_opt_in_dt, 
    COALESCE(f.rco_opt_in_cnt, 0) AS rco_opt_in_cnt,
    CASE WHEN f.rco_opt_in_cnt > 0 THEN 1 ELSE 0 END AS rco_opt_in_ind,
    0 AS major_donor_suprsn_ind,
    0 AS sf_green_mangd_acct_ind
FROM 

(
SELECT REGEXP_REPLACE(phone_num, '[^0-9]', '')::bigint AS mobile_num,
    TRIM(carrier_nm),
    TRIM(created_ts) AS create_ts,
    TRIM(status) AS active_status,
    TRIM(source_typ),
    TRIM(source_nm),
    TRIM(description) AS status_dsc,
    TRIM(opted_out_at) AS opt_out_dt,
    TRIM(opt_out_source),
    1 AS active_subscrbr_ind

FROM mods_bi.mktg_ops_tbls.mobile_commons_20240507_active

) a (mobile_num,active_carrier_nm,active_create_ts,active_status,active_source_typ,active_source_nm,active_status_dsc,active_opt_out_dt,active_opt_out_source, active_subscrbr_ind)
FULL OUTER JOIN
(
	SELECT 
    REGEXP_REPLACE(phone_number, '[^0-9]', '')::bigint AS mobile_num,
    CAST(NULL AS VARCHAR(100)) AS unsbscrb_carrier_nm,
    opted_out_at AS unsbscrb_created_ts,
    CAST(NULL AS VARCHAR(50)) AS unsbscrb_status,
    CAST(NULL AS VARCHAR(50)) AS unsbscrb_source_typ,
    CAST(NULL AS VARCHAR(50)) AS unsbscrb_source_nm,
    CAST(NULL AS VARCHAR(50)) AS unsbscrb_status_dsc,
    TRIM(opted_out_at) AS unsbscrb_opt_out_dt,
    CAST(NULL AS VARCHAR(50)) AS unsbscrb_opt_out_source,
    1 AS unsbscrb_ind
FROM mods_bi.mktg_ops_tbls.fundraising_profiles_20240507_unsubscribe_trimmed
 --mobile_commons_20240507_unsubscribe
) b (mobile_num,unsbscrb_carrier_nm,unsbscrb_created_ts,unsbscrb_status,unsbscrb_source_typ,unsbscrb_source_nm,unsbscrb_status_dsc,unsbscrb_opt_out_dt,unsbscrb_opt_out_source,unsbscrb_ind) 
	ON 
CASE 
    WHEN CAST(SUBSTRING(TRIM(a.mobile_num), 1, 1) AS CHAR(1)) = '1' 
    THEN SUBSTRING(REGEXP_REPLACE(a.mobile_num, '[^0-9]', ''), 2, 10)::bigint
    ELSE a.mobile_num::bigint 
end = 
CASE 
    WHEN CAST(SUBSTRING(TRIM(b.mobile_num), 1, 1) AS CHAR(1)) = '1' 
    THEN SUBSTRING(REGEXP_REPLACE(b.mobile_num, '[^0-9]', ''), 2, 10)::bigint 
    ELSE b.mobile_num::bigint 
end


-----******


FULL OUTER JOIN 
(

SELECT 
	REGEXP_REPLACE(sorigin, '[^0-9]', '')::bigint AS mobile_num,
    --trim(sorigin) AS mobile_num,
    MIN(CAST(tscreated AS TIMESTAMP)) AS first_unsbscrb_ts,
    MIN(CAST(tscreated AS DATE)) AS first_unsbscrb_dt,
    MAX(CAST(tscreated AS TIMESTAMP)) AS last_unsbscrb_ts,
    MAX(CAST(tscreated AS DATE)) AS last_unsbscrb_dt,
    SUM(
        CASE 
            WHEN TRIM(UPPER(REGEXP_REPLACE(smessage, '[^0-9A-Za-z]', ''))) IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END','STOP2END') THEN 1
            WHEN REGEXP_REPLACE(TRIM(UPPER(REPLACE(smessage, ' ', ''))), '[^0-9A-Za-z]', '') IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END','STOP2END') THEN 1
            ELSE 0
        END
    ) AS opt_out_cnt
FROM mktg_ops_vws.bz_adb_nmsinsms
WHERE 
    CASE 
        WHEN TRIM(UPPER(REGEXP_REPLACE(smessage, '[^0-9A-Za-z]', ''))) IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END','STOP2END') THEN 1
        WHEN REGEXP_REPLACE(TRIM(UPPER(REPLACE(smessage, ' ', ''))), '[^0-9A-Za-z]', '') IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END','STOP2END') THEN 1
        ELSE 0
    END = 1
GROUP BY REGEXP_REPLACE(sorigin, '[^0-9]', '')::bigint--query tested fine with recs


) c (mobile_num, first_unsbscrb_ts, first_unsbscrb_dt, last_unsbscrb_ts,last_unsbscrb_dt, opt_out_cnt) 
--    ON c.mobile_num = Coalesce(a.mobile_num, b.mobile_num)
	ON 
CASE 
    WHEN CAST(SUBSTRING(c.mobile_num, 1, 1) AS CHAR(1)) = '1' 
    THEN SUBSTRING(REGEXP_REPLACE(c.mobile_num, '[^0-9]', ''), 2, 10) :: bigint
    ELSE coalesce(c.mobile_num,0)
END = 
CASE 
    WHEN CAST(SUBSTRING(COALESCE(a.mobile_num, b.mobile_num), 1, 1) AS CHAR(1)) = '1' 
    THEN SUBSTRING(REGEXP_REPLACE(COALESCE(a.mobile_num, b.mobile_num), '[^0-9]', ''), 2, 10) :: bigint
    ELSE COALESCE(REGEXP_REPLACE(a.mobile_num, '[^0-9]', '')::bigint, REGEXP_REPLACE(b.mobile_num, '[^0-9]', '')::bigint,0) 
end

-------*************-----------------------------------------------
FULL OUTER JOIN

(
SELECT REGEXP_REPLACE(sorigin, '[^0-9]', '')::bigint AS mobile_num,
    --trim(sorigin) AS mobile_num,
    MIN(CAST(tscreated AS TIMESTAMP)) AS first_adobe_opt_in_ts,
    MIN(CAST(tscreated AS DATE)) AS first_adobe_opt_in_dt,
    MAX(CAST(tscreated AS TIMESTAMP)) AS last_adobe_opt_in_ts,
    MAX(CAST(tscreated AS DATE)) AS last_adobe_opt_in_dt,
    SUM(
        CASE 
            WHEN TRIM(UPPER(REGEXP_REPLACE(smessage, '[^0-9A-Za-z]', ''))) IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END','STOP2END') THEN 0
            WHEN REGEXP_REPLACE(TRIM(UPPER(REPLACE(smessage, ' ', ''))), '[^0-9A-Za-z]', '') IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END','STOP2END') THEN 0
            WHEN sorigin IS NULL THEN 0
            ELSE 1
        END
    ) AS opt_in_cnt
FROM mktg_ops_vws.bz_adb_nmsinsms
WHERE 
    CASE 
        WHEN TRIM(UPPER(REGEXP_REPLACE(smessage, '[^0-9A-Za-z]', ''))) IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END','STOP2END') THEN 1
        WHEN REGEXP_REPLACE(TRIM(UPPER(REPLACE(smessage, ' ', ''))), '[^0-9A-Za-z]', '') IN ('STOP','QUIT','UNSUBSCRIBE','CANCEL','END','STOP2END') THEN 1
        ELSE 0
    END = 0
GROUP BY REGEXP_REPLACE(sorigin, '[^0-9]', '')::bigint

) d (mobile_num, first_adobe_opt_in_ts, first_adobe_opt_in_dt, last_adobe_opt_in_ts,last_adobe_opt_in_dt, opt_in_cnt) 
    --ON d.mobile_num = Coalesce(a.mobile_num, b.mobile_num, c.mobile_num)
	ON 
CASE 
    WHEN CAST(SUBSTRING(d.mobile_num, 1, 1) AS CHAR(1)) = '1' 
    THEN SUBSTRING(REGEXP_REPLACE(d.mobile_num, '[^0-9]', ''), 2, 10) :: bigint
    ELSE coalesce(d.mobile_num,0) :: bigint
END = 
CASE 
    WHEN CAST(SUBSTRING(COALESCE(a.mobile_num, b.mobile_num, c.mobile_num), 1, 1) AS CHAR(1)) = '1' 
    THEN SUBSTRING(REGEXP_REPLACE(COALESCE(a.mobile_num, b.mobile_num, c.mobile_num), '[^0-9]', ''), 2, 10) :: bigint
    ELSE COALESCE(a.mobile_num, b.mobile_num, c.mobile_num,0) :: bigint
end

-----------------------------------------------------------------------------------------

FULL OUTER JOIN 

(
SELECT REGEXP_REPLACE(phone, '[^0-9]', '')::bigint AS mobile_num,
    --CAST(trim(phone) AS VARCHAR(20)) AS mobile_num,
    MIN(opt_in_ts) AS first_mc_opt_in_ts,
    MAX(opt_in_ts) AS last_mc_opt_in_ts,
    MIN(opt_out_ts) AS first_mc_opt_out_ts,
    MAX(opt_out_ts) AS last_mc_opt_out_ts,
    SUM(CASE WHEN opt_out_ts > opt_in_ts THEN 1 ELSE 0 END) AS mc_opt_out_cnt
FROM mktg_ops_tbls.final_mobile_common_opt_out
GROUP BY REGEXP_REPLACE(phone, '[^0-9]', '')::bigint

)e (mobile_num, first_mc_opt_in_ts, last_mc_opt_in_ts, first_mc_opt_out_ts, last_mc_opt_out_ts, mc_opt_out_cnt) 
    --ON e.mobile_num = Coalesce(a.mobile_num, b.mobile_num, c.mobile_num, d.mobile_num)
	ON 
CASE 
    WHEN CAST(SUBSTRING(e.mobile_num, 1, 1) AS CHAR(1)) = '1' 
    THEN SUBSTRING(REGEXP_REPLACE(e.mobile_num, '[^0-9]', ''), 2, 10)::bigint 
    ELSE coalesce(e.mobile_num,0)::bigint 
END = 
CASE 
    WHEN CAST(SUBSTRING(COALESCE(a.mobile_num, b.mobile_num, c.mobile_num, d.mobile_num), 1, 1) AS CHAR(1)) = '1' 
    THEN SUBSTRING(REGEXP_REPLACE(COALESCE(a.mobile_num, b.mobile_num, c.mobile_num, d.mobile_num), '[^0-9]', ''), 2, 10) :: bigint
    ELSE COALESCE(a.mobile_num, b.mobile_num, c.mobile_num, d.mobile_num,0)::bigint 
end

------------------------------------------------------------------------------------------

FULL OUTER JOIN

(
SELECT 
	REGEXP_REPLACE(locator_phn_num, '[^0-9]', '')::bigint AS mobile_num,
    --REGEXP_REPLACE(trim(locator_phn_num), '[^0-9]', '') AS locator_phn_num,
    MIN(cnst_phn_strt_ts) AS first_rco_phn_opt_in_ts,
    MIN(CAST(cnst_phn_strt_ts AS DATE)) AS first_rco_phn_opt_in_dt,
    MAX(cnst_phn_strt_ts) AS last_rco_phn_opt_in_ts,
    MAX(CAST(cnst_phn_strt_ts AS DATE)) AS last_rco_phn_opt_in_dt,
    COUNT(*) AS rco_opt_in_cnt
FROM eda.arc_mdm_vws.bzfc_cnst_phn
--select cnst_phn_strt_ts >=  '2024-08-10' from eda.arc_mdm_vws.bzfc_cnst_phn
WHERE 
    arc_srcsys_cd = 'RCO' 
    AND CAST(cnst_phn_strt_ts AS DATE) >= DATE '2024-08-10'
    AND assessmnt_ctg IN ('Usable', 'Use With Caution')
GROUP BY REGEXP_REPLACE(locator_phn_num, '[^0-9]', '')::bigint

) f (mobile_num, first_rco_phn_opt_in_ts, first_rco_phn_opt_in_dt, last_rco_phn_opt_in_ts,last_rco_phn_opt_in_dt, rco_opt_in_cnt) 
	ON 
Cast(CASE

WHEN Substring(f.mobile_num, 1, 1) = '1'

THEN Substring(RegExp_Replace(f.mobile_num, '[^0-9]', ''), 2, 10)::bigint

ELSE coalesce(f.mobile_num,0)::bigint

end AS BIGINT)

=

Cast(CASE

WHEN Substring(Coalesce(a.mobile_num, b.mobile_num, c.mobile_num, d.mobile_num, e.mobile_num), 1, 1) = '1'

THEN Substring(RegExp_Replace(Coalesce(a.mobile_num, b.mobile_num, c.mobile_num, d.mobile_num, e.mobile_num), '[^0-9]', ''), 2, 10)::bigint

ELSE Coalesce(a.mobile_num, b.mobile_num, c.mobile_num, d.mobile_num, e.mobile_num,0)::bigint

end AS BIGINT)

LEFT JOIN (
select 
coalesce(REGEXP_REPLACE(area_cd_num, '[^0-9]', '')::bigint,0) as area_cd_num,
time_zone_dsc
from mktg_ops_vws.bz_area_code_2_time_zone )g

on g.area_cd_num :: bigint = 
coalesce(SUBSTRING(REGEXP_REPLACE(coalesce(a.mobile_num,b.mobile_num,c.mobile_num,d.mobile_num,e.mobile_num,f.mobile_num), '[^0-9]', ''), 2, 3)::bigint,0);


/* Last updates-
Now apply updates to suppress major donors - those with rolling 12 month donation amount is $10,000 or more
*/

UPDATE mktg_ops_tbls.bzfc_sms_profile

SET 
    ok_to_text_flg = 'N',
    major_donor_suprsn_ind = a.major_donor_suprsn_ind
	
FROM
(
SELECT DISTINCT mobile_num, 1
FROM mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr a
LEFT JOIN mktg_ops_vws.bzfc_sms_fr_prfl b ON a.cnst_mstr_id = b.cnst_mstr_id
WHERE a.cnst_mstr_id IN 
    (
    SELECT   a.cnst_mstr_id
    FROM mktg_ops_vws.gms_arc_fr_smry a  
    WHERE a.fr_ry0_dntn_amt >= 10000
    AND EXISTS (SELECT * FROM mktg_ops_vws.bzfc_sms_fr_prfl b WHERE b.ok_to_text_flg = 'Y' AND a.cnst_mstr_id = b.cnst_mstr_id)
    ) 
)a (mobile_num, major_donor_suprsn_ind)
WHERE 
    mktg_ops_tbls.bzfc_sms_profile.mobile_num = a.mobile_num
;

/*
Now apply updates to suppress SalesForce Managed Donors with a 'Green' status.
*/

UPDATE mktg_ops_tbls.bzfc_sms_profile

SET 
    ok_to_text_flg = 'N',
    sf_green_mangd_acct_ind = a.sf_green_mangd_acct_ind
	
FROM
(
SELECT DISTINCT mobile_num, 1
FROM mktg_ops_vws.gms_cnst_cdi_smry_fr_prfr a
LEFT JOIN mktg_ops_vws.bzfc_sms_fr_prfl b ON a.cnst_mstr_id = b.cnst_mstr_id
WHERE a.sf_acct_fmd_ind = 1 AND frf_status_cd = 'Green'
)a (mobile_num, sf_green_mangd_acct_ind)
WHERE 
    mktg_ops_tbls.bzfc_sms_profile.mobile_num = a.mobile_num
;



 	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message ='';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=cast((select count(*) from mktg_ops_tbls.bzfc_sms_profile) as integer)
        WHERE proc_name = 'ld_bzfc_sms_profile' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_bzfc_sms_profile', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$_$
