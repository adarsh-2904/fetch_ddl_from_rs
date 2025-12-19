CREATE OR REPLACE PROCEDURE mktg_ops_tbls.updt_email_append_suprsn()
 LANGUAGE plpgsql
AS $$
/*
Created by: Michael Andrien
Create Date:08/23/2021
Purpose:  This macro runs daily and was created to identify potentially bad email append records and to 'Logically' delete the records by setting the row_stat_cd = 'L'.  The macro has been created initially with two
SQL update statements to run against the Fresh Address Email Append and Pacific East Email Append tables to identify append records where the append email address joins to more than one CDI master ID 
when appended email address is joined to the 'best' constituent email address in the CDI ARC Best Summary profile.  For the email addresses that join to more than one master id, we'll suppress the append record 
if the last name on the append record does not match the last name associated with the ARC Best profile record.  

The MODS team implemented this suppression process to address complaints received from a small number of constituents following the last Pacific East email append.  We had 4 or 5 instances 
where the email address was appended to a constituent that was different than the ARC constituent to whom was associated with the email address through one of our internally manged ARC systems.  By suppressing the 
email append record, we preserve the preferred email assignment details from our internally managed systems and suppress the less reliable append record.
	row_stat_cd = 'L',
	append_comnt = 'Logically deleted email append row based on daily macro configured to identify bad append email records to avoid issues with our email communications'
	
Modified By: Michael Andrien
Modified Date: 08/25/2021
Purpose:  Added two additional apply suppression update SQL statements to Fresh Address (FA) and Pacific East (PE) email append records that are associated with only one CDI ARC Best record.

Modified By: Michael Andrien
Modified Date: 07/27/2022
Purpose: Added orig_cnst_mstr_id to the update logic to avoid duplicate update failures that occur when master ids merge.
*/
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);
	v_update_count1 INT;
	v_update_count2 INT;
	v_update_count3 INT;
	v_update_count4 INT;
	

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('updt_email_append_suprsn', 'Stored Procedure', 'Inprogress', v_start_time);
BEGIN

/* UPDATE1:Apply Logical Delete Updates to Fresh Address Email Append data. */
--Hitansu: Redshift follows the pattern update...set...from...where

update mktg_ops_tbls.fresh_address_email_append
set 
	row_stat_cd = 'L',
	append_comnt = 'Logically deleted email append row based on daily macro configured to identify bad append email records to avoid issues with our email communications'
	
	from
(
	select 
		cnst_mstr_id,
		orig_cnst_mstr_id,
		cnst_email,
		list_nm
	from mktg_ops_tbls.fresh_address_email_append
	where 
		row_stat_cd <> 'L'
		and cnst_email in 
	(
		select 
			distinct  a.cnst_email
		from mktg_ops_vws.bzfc_email_append a
		left join eda.arc_mdm_vws.bzfc_arc_best_smry b on a.cnst_email = b.cnst_email_addr
		where a.cnst_email in
		(
		    select cnst_email_addr
		    from eda.arc_mdm_vws.bzfc_arc_best_smry
		    where cnst_email_addr in 
		    (
		        select distinct cnst_email
		        from mktg_ops_vws.bzfc_email_append
		    )
		    group by 1
		having count(distinct cnst_mstr_id) > 1
		)
		and a.cnst_prsn_l_nm <> b.prsn_last_nm
	)
) a(cnst_mstr_id, orig_cnst_mstr_id, cnst_email, list_nm)
where mktg_ops_tbls.fresh_address_email_append.cnst_mstr_id = a.cnst_mstr_id 
and mktg_ops_tbls.fresh_address_email_append.orig_cnst_mstr_id = a.orig_cnst_mstr_id
and mktg_ops_tbls.fresh_address_email_append.cnst_email = a.cnst_email 
and mktg_ops_tbls.fresh_address_email_append.list_nm = a.list_nm 
and mktg_ops_tbls.fresh_address_email_append.row_stat_cd <> 'L';

-- Capture number of affected rows
    GET DIAGNOSTICS v_update_count1 = ROW_COUNT;

/* UPDATE2: Apply Logical Delete Updates to Pacific East Email Append data. */
UPDATE mktg_ops_tbls.pacific_east_email_append AS tgt
SET 
    row_stat_cd = 'L',
    append_comnt = 'Logically deleted email append row based on daily macro configured to identify bad append email records to avoid issues with our email communications'
FROM (
    SELECT 
        fa.cnst_mstr_id,
        fa.orig_cnst_mstr_id,
        fa.cnst_email,
        fa.list_source_nm
    FROM mktg_ops_tbls.pacific_east_email_append fa
    WHERE fa.row_stat_cd <> 'L'
      AND fa.cnst_email IN (
        SELECT DISTINCT a.cnst_email
        FROM mktg_ops_vws.bzfc_email_append a
        LEFT JOIN eda.arc_mdm_vws.bzfc_arc_best_smry b 
            ON a.cnst_email = b.cnst_email_addr
        WHERE a.cnst_email IN (
            SELECT cnst_email_addr
            FROM eda.arc_mdm_vws.bzfc_arc_best_smry
            WHERE cnst_email_addr IN (
                SELECT DISTINCT cnst_email
                FROM mktg_ops_vws.bzfc_email_append
            )
            GROUP BY cnst_email_addr
            HAVING COUNT(DISTINCT cnst_mstr_id) > 1
        )
        AND a.cnst_prsn_l_nm <> b.prsn_last_nm
      )
) AS src
WHERE tgt.cnst_mstr_id = src.cnst_mstr_id
  AND tgt.orig_cnst_mstr_id = src.orig_cnst_mstr_id
  AND tgt.cnst_email = src.cnst_email
  AND tgt.list_source_nm = src.list_source_nm
  AND tgt.row_stat_cd <> 'L';

-- Capture number of affected rows
    GET DIAGNOSTICS v_update_count2 = ROW_COUNT;


	
/* UPDATE 3: 
Apply PE suppressions for email append records the link to only one CDI ARC Best record. Note, the records that are associated with more than one ARC Best record are suppresse
in the PE suppression UPDATE SQL earlier in this macro.
*/	
	
	UPDATE mktg_ops_tbls.pacific_east_email_append AS tgt
SET 
    row_stat_cd = 'L',
    append_comnt = 'Logically deleted email append row based on daily macro configured to identify bad append email records to avoid issues with our email communications'
FROM (
    SELECT 
        a.cnst_mstr_id, 
        a.orig_cnst_mstr_id, 
        a.cnst_email, 
        a.list_source_nm,
        CASE 
            WHEN a.cnst_prsn_f_nm = b.prsn_first_nm 
              OR a.cnst_email ILIKE '%' || a.cnst_prsn_l_nm || '%' 
              OR a.cnst_email ILIKE '%' || a.cnst_prsn_f_nm || '%' 
            THEN 0 
            ELSE 1 
        END AS suppress_email_ind
    FROM mktg_ops_vws.bzfc_email_append a
    LEFT JOIN eda.arc_mdm_vws.bzfc_arc_best_smry b 
        ON a.cnst_email = b.cnst_email_addr
    WHERE a.cnst_prsn_l_nm <> b.prsn_last_nm 
      AND a.cnst_mstr_id <> b.cnst_mstr_id 
      AND a.row_stat_cd <> 'L'
) AS src
WHERE tgt.cnst_mstr_id = src.cnst_mstr_id 
  AND tgt.orig_cnst_mstr_id = src.orig_cnst_mstr_id 
  AND tgt.cnst_email = src.cnst_email 
  AND tgt.list_source_nm = src.list_source_nm 
  AND src.suppress_email_ind = 1
  AND tgt.row_stat_cd <> 'L';
  
-- Capture number of affected rows
    GET DIAGNOSTICS v_update_count3 = ROW_COUNT;
  
 /* UPDATE 4:  Apply FA suppressions for email append records the link to only one CDI ARC Best record. Note, the records that are associated with more than one ARC Best record are suppresse
in the FA suppression UPDATE SQL earlier in this macro.
*/	
update mktg_ops_tbls.fresh_address_email_append

set 
	row_stat_cd = 'L',
	append_comnt = 'Logically deleted email append row based on daily macro configured to identify bad append email records to avoid issues with our email communications'
from 
(
	select 
		a.cnst_mstr_id, a.orig_cnst_mstr_id, a.cnst_email, list_source_nm,
		case when a.cnst_prsn_f_nm = b.prsn_first_nm or (a.cnst_email like '%'||a.cnst_prsn_l_nm||'%' or a.cnst_email like '%'||a.cnst_prsn_f_nm||'%') then 0 else 1 end as suppress_email_ind
	from mktg_ops_vws.bzfc_email_append a
	left join eda.arc_mdm_vws.bzfc_arc_best_smry b on a.cnst_email = b.cnst_email_addr
	where a.cnst_prsn_l_nm <> b.prsn_last_nm and a.cnst_mstr_id <> b.cnst_mstr_id and a.row_stat_cd <> 'L' and suppress_email_ind = 1
) a(cnst_mstr_id, orig_cnst_mstr_id, cnst_email, list_source_nm, suppress_email_ind)
where 
	mktg_ops_tbls.fresh_address_email_append.cnst_mstr_id = a.cnst_mstr_id 
	and mktg_ops_tbls.fresh_address_email_append.orig_cnst_mstr_id = a.orig_cnst_mstr_id
	and mktg_ops_tbls.fresh_address_email_append.cnst_email = a.cnst_email 
	and mktg_ops_tbls.fresh_address_email_append.list_nm = a.list_source_nm 
	and a.suppress_email_ind = 1
	and mktg_ops_tbls.fresh_address_email_append.row_stat_cd <> 'L';
	
-- Capture number of affected rows
    GET DIAGNOSTICS v_update_count4 = ROW_COUNT;
	
--audit update	
	v_end_time := CURRENT_TIMESTAMP;
v_ok_message := 'Update1:' || v_update_count1::VARCHAR || ' || Update2:' || v_update_count2::VARCHAR || ' || Update3:' || v_update_count3::VARCHAR|| ' || Update4:' || v_update_count4::VARCHAR;
UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message, recs_processed=	v_update_count1::int+v_update_count2::int+v_update_count3::int+v_update_count4::int
        WHERE proc_name = 'updt_email_append_suprsn' AND task_name = 'Stored Procedure' AND start_time = v_start_time;


	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('updt_email_append_suprsn', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));
	END;
END;
$$
