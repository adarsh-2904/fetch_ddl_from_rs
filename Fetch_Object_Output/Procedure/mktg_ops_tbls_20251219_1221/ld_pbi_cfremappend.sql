CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_pbi_cfremappend()
 LANGUAGE plpgsql
AS $$
	
/* ---------------------------------------------------------------------------------------------------------------------------
Created By: Majeed Mohammad
Create Date: 5/29/2025
Purpose: This macro loads to the pbi_cfremappend_cohort and pbi_cfremappend_cnst table 

Modified By: Majeed Mohammad
Modified on: 7/8/2025
Purpose: Updated the hardcoded filter for 5yr rolling period to a soft coded filter using the current date
---------------------------------------------------------------------------------------------------------------------------- */
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_pbi_cfremappend', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
		truncate table mktg_ops_tbls.pbi_cfremappend_cohort; 
		
		INSERT INTO mktg_ops_tbls.pbi_cfremappend_cohort
		(fy, grp_key,
				cohort_cd, append_dt, list_load_dt, list_upload_dt, append_data_src_cd,
				list_nm, list_source_nm, run_dt)
				
		with base2 as (
			  select distinct list_typ, list_nm, list_dsc, cast(dw_trans_ts as date) as append_dt,
					(case when POSITION('251' IN trim(lower(list_nm)))>0 then 251
						  when POSITION('395' IN trim(lower(list_nm)))>0 then 395
						  when POSITION('483' IN trim(lower(list_nm)))>0 then 483
						  when POSITION('484' IN trim(lower(list_nm)))>0 then 484
						  when POSITION('490' IN trim(lower(list_nm)))>0 then 490
						  when trim(lower(list_nm))='cfr_legacy_fy20' then 528
						  when trim(lower(list_nm))='cfr_testoffline_fy20' then 529
						  when trim(list_nm)='FY21_CFRAppend_DM' then 546
						  when trim(list_nm)='FY21_CFRAppend_Online' then 545
						  when trim(list_nm)='FY22_CFRAppend_DM' then 548
						  when trim(list_nm)='FY22_CFRAppend_Online' then 547
						  when trim(list_nm)='FY23NovAppDMValidated' then 550
						  when trim(list_nm)='FY23NovAppOnlineValdtd' then 549
						  when trim(list_nm)='PE_202302_2DMa' then 551
						  when trim(list_nm)='PE_202302_2DMb' then 552
						  when trim(list_nm)='PE_202302_2EMb' then 553
						  when trim(list_nm)='pe_11fy24EM1' then 554
						  when trim(list_nm)='pe_11fy24DM1' then 555
						  when trim(list_nm)='pe_11fy24DM2' then 556
						  when trim(list_nm)='pe_em_fy24prospA' then 557
						  when trim(list_nm)='pe_em_prospfy24_1' then 558
						  when trim(list_nm)='pe_em_mayfy24_other' then 559
						  when trim(list_nm)='pe_em_fy24other3' then 560
						  when trim(list_nm)='pe_em_fallfy24_online' then 561
						  when trim(list_nm)='pe_em_fallfy24_dm2' then 562
					 else null end) as grp_key
				from mktg_ops_vws.campgn_prospct_list
				where list_typ = 'Email Append' 
					and (POSITION('fresh' IN trim(lower(list_nm)))>0 OR
					 POSITION('cfr' IN trim(lower(list_nm)))>0 OR
						 POSITION('fv23nov' IN trim(lower(list_nm)))>0 OR
						 POSITION('pe_202302' IN trim(lower(list_nm)))>0 OR
						 trim(lower(list_nm)) in ('pe_em_fy24prospA','pe_em_prospfy24_1','pe_11fy24DM1','pe_11fy24DM2','pe_11fy24EM1') OR
						 POSITION('pe_em_mayfy24_other' IN trim(lower(list_nm)))>0 OR
						 POSITION('pe_em_fy24other3' IN trim(lower(list_nm)))>0 OR 
						 POSITION('pe_em_fallfy24_online' IN trim(lower(list_nm)))>0 OR 
						 POSITION('pe_em_fallfy24_dm2' IN trim(lower(list_nm)))>0 
						 )
				),
		bzfc_append as (
			select distinct append_data_src_cd,
				list_source_nm,
				cast(list_upload_ts as date) as list_upload_dt,
				(case when POSITION('2017' IN trim(lower(list_source_nm)))>0 then 251
						  when POSITION('2018' IN trim(lower(list_source_nm)))>0 then 395
						  when trim(list_source_nm)='EDW_NonResponders_62519' then 483
						  when trim(list_source_nm)='mobil_nonresponders_06252019' then 484
						  when trim(lower(list_source_nm))='cfr_legacy_fy20' then 528
						  when trim(lower(list_source_nm))='cfr_testoffline_fy20' then 529
						  when trim(list_source_nm)='FY21_CFRAppend_DM' then 546
						  when trim(list_source_nm)='FY21_CFRAppend_Online' then 545
						  when trim(list_source_nm)='FY22_CFRAppend_DM' then 548
						  when trim(list_source_nm)='FY22_CFRAppend_Online' then 547
						  when trim(list_source_nm)='FY23NovAppDMValidated' then 550
						  when trim(list_source_nm)='FY23NovAppOnlineValdtd' then 549
						  when trim(list_source_nm)='PE_202302_2DMa' then 551
						  when trim(list_source_nm)='PE_202302_2DMb' then 552
						  when trim(list_source_nm)='PE_202302_2EMb' then 553
						  when trim(list_source_nm)='pe_11fy24EM1' then 554
						  when trim(list_source_nm)='pe_11fy24DM1' then 555
						  when trim(list_source_nm)='pe_11fy24DM2' then 556
						  when trim(list_source_nm)='pe_em_fy24prospA' then 557
						  when trim(list_source_nm)='pe_em_prospfy24_1' then 558
						  when trim(list_source_nm)='pe_em_mayfy24_other' then 559
						  when trim(list_source_nm)='pe_em_fy24other3' then 560
						  when trim(list_source_nm)='pe_em_fallfy24_online' then 561
						  when trim(list_source_nm)='pe_em_fallfy24_dm2' then 562
					 else null end) as grp_key
			from mktg_ops_vws.bzfc_email_append
			where (append_data_src_cd='FAEM' OR 
				  POSITION('nonresp' IN trim(lower(list_source_nm)))>0 OR
				  POSITION('cfr' IN trim(lower(list_source_nm)))>0 OR
				  POSITION('fy23nov' IN trim(lower(list_source_nm)))>0 OR
				  POSITION('pe_202302' IN trim(lower(list_source_nm)))>0 OR
				  trim(lower(list_source_nm)) in ('pe_em_fy24prospA','pe_em_prospfy24_1','pe_11fy24DM1','pe_11fy24DM2','pe_11fy24EM1') OR
				  POSITION('pe_em_mayfy24_other' IN trim(lower(list_source_nm)))>0 OR
				  POSITION('pe_em_fy24other3' IN trim(lower(list_source_nm)))>0 OR 
				  POSITION('pe_em_fallfy24_online' IN trim(lower(list_source_nm)))>0 OR 
				  POSITION('pe_em_fallfy24_dm2' IN trim(lower(list_source_nm)))>0
				  )
			)
			
			
			
		select cast(trim('FY')||substring(trim(g.fiscal_yr),3,2) as char(4)) as fy,
			x.grp_key,
			(case when x.grp_key=251 then '2017-FA'
					when x.grp_key=395 then '2018-FA'
					when x.grp_key in (483,484) then '2019-FA'
					when x.grp_key=490 then '2019-C2'
					when x.grp_key=529 then '2020-PE-DM'
					when x.grp_key=528 then '2020-PE-OLN'
					when x.grp_key=546 then '2021-PE-DM'
					when x.grp_key=545 then '2021-PE-OLN'
					when x.grp_key=548 then '2022-PE-DM'
					when x.grp_key=547 then '2022-PE-OLN'
					when x.grp_key=550 then '202211-PE-DM'
					when x.grp_key=549 then '202211-PE-OLN'
					when x.grp_key in (551,552) then '2023-PE-DM'
					when x.grp_key=553 then '2023-PE-OLN'
					when x.grp_key=554 then '2024-PE-OLN'
					when x.grp_key in (555,556) then '2024-PE-DM'
					when x.grp_key=557 then '202312-PE-OTHR'
					when x.grp_key=558 then '202401-PE-PRSPCT'
					when x.grp_key in (559,560) then '202405-PE-OTHR'
					when x.grp_key=561 then '202412-PE-ONLN'
					when x.grp_key=562 then '202412-PE-DM'
					else null end) cohort_cd,
			x.append_dt,
			a.list_upload_dt as list_load_dt,	
			(case when x.grp_key = 251 then greatest(date'2019-09-01', list_load_dt)
				  when x.grp_key = 395 then greatest(date'2018-09-01', list_load_dt)
				  when x.grp_key in (483,484) then greatest(date'2019-08-01', list_load_dt)
				  when x.grp_key in (528,529) then greatest(date'2020-07-01', list_load_dt)
				  when x.grp_key in (545,546) then greatest(date'2021-07-01', list_load_dt)
				  when x.grp_key in (547,548) then greatest(date'2022-06-01', list_load_dt)
				  when x.grp_key in (549,550) then greatest(date'2022-12-01', list_load_dt)
				  when x.grp_key in (551,552,553) then greatest(date'2023-05-01', list_load_dt)
				  when x.grp_key in (554,555,556,557) then greatest(date'2023-12-01', list_load_dt)
				  when x.grp_key = 558 then greatest(date'2024-02-01', list_load_dt)
				  when x.grp_key = 559 then greatest(date'2024-05-01', list_load_dt)
				  when x.grp_key = 560 then greatest(date'2024-07-01', list_load_dt)
				  when x.grp_key in (561,562) then greatest(date'2024-12-01', list_load_dt)
				else cast(null as date) end) list_upload_dt,
			a.append_data_src_cd,
			x.list_nm,
			a.list_source_nm,
		    CURRENT_DATE as run_dt
		
		from base2 x
		left join bzfc_append a on x.grp_key=a.grp_key
		left join eda.dw_common_vws.dim_calendar g on a.list_upload_dt = g.calendar_dt
		-- KEEP ONLY LAST 5 FY (FY22+)
		where g.fiscal_yr BETWEEN (SELECT DISTINCT fiscal_yr-4 FROM eda.dw_common_vws.dim_calendar WHERE calendar_dt = CURRENT_DATE)
		
		                                                                                  AND (SELECT DISTINCT fiscal_yr FROM eda.dw_common_vws.dim_calendar WHERE calendar_dt = CURRENT_DATE);
		
		                                                                                  
		
		truncate table mktg_ops_tbls.pbi_cfremappend_cnst ; 
		
		INSERT INTO  mktg_ops_tbls.pbi_cfremappend_cnst ( 	grp_key, list_nm, list_source_nm, cnst_mstr_id, cnst_email, email_key ) 
			WITH base1 AS (
		    SELECT 
		        a.grp_key,
		        a.list_nm,
		        a.list_source_nm,
		        b.cnst_mstr_id
		    FROM mktg_ops_tbls.pbi_cfremappend_cohort a
		    INNER JOIN mktg_ops_vws.campgn_prospct_list b 
		        ON trim(lower(a.list_nm)) = trim(lower(b.list_nm))
		),
		subqry AS (
		    SELECT 
		        base1.grp_key, 
		        base1.list_nm, 
		        base1.list_source_nm, 
		        base1.cnst_mstr_id,
		        a.cnst_email,
		        a.email_key,
		        COUNT(*) OVER (
		            PARTITION BY base1.cnst_mstr_id, base1.grp_key 
		            ROWS UNBOUNDED PRECEDING
		        ) AS cnt
		    FROM base1
		    LEFT JOIN mktg_ops_vws.bzfc_email_append a 
		        ON base1.cnst_mstr_id = a.cnst_mstr_id 
		        AND trim(lower(base1.list_source_nm)) = trim(lower(a.list_source_nm))
		)
		SELECT 
		    subqry.grp_key, 
		    subqry.list_nm, 
		    subqry.list_source_nm, 
		    subqry.cnst_mstr_id,
		    subqry.cnst_email,
		    subqry.email_key
		FROM subqry
		WHERE subqry.cnt = 1;


		
		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records updated.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.pbi_cfremappend_cnst) as INTEGER)
			WHERE proc_name = 'ld_pbi_cfremappend' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
	    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
	    VALUES ('ld_pbi_cfremappend', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
