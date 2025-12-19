CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_pbi_model_perf_dashbrd()
 LANGUAGE plpgsql
AS $_$

	/*
    CREATED BY: Majeed Mohammad
    CREATED DATE: 06/23/2023
    PURPOSE: Macro to load the tables used for the performance model dashboard 
    
    Modified By: Majeed Mohammad
    Modified Date: 07/06/2023
    Purpose: Updated the alias names in the INSERT statement for the table mktg_ops_tbls.pbi_model_perf_auc 
    					Removed the WITH query for the table mktg_ops_tbls.pbi_model_perf_tlres. The macro execution gave error when this was present. 
    					
    Modified By: Nadav Rindler
    Implemented by: Majeed Mohammad
    Modified Date: 01/24/2024
    Purpose: Updated the section for ACQUISITION - ARC CFR GIVING HISTORY *AS OF 120 DAYS PRE-DROP DATE. 
    					Updated the logic for mods_fr_scr and expected_val in the INSERT statement for mktg_ops_tbls.pbi_model_perf_dashbrd 		
    					
    Modified By: Majeed Mohammad
    Modified Date: 02/22/2024
    Purpose: Updated the bteq to point to mktg_ops_tbls.pbi_model_perf_dashbrd instead of data_lab_mktg_tbls.nr_pbi_model_perf 	    					
    */
		
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_pbi_model_perf_dashbrd', 'Stored Procedure', 'Inprogress', v_start_time);


begin
		
		-- SOURCE CODE DIMENSION TABLE
    
--    DELETE
--        FROM mktg_ops_tbls.pbi_model_perf_dim_src ;
--    INSERT	INTO mktg_ops_tbls.pbi_model_perf_dim_src
--        (dm_file, src_cd, drop_dt, src_key, camp_rank)
--        SEL SUBSTR(src_cd,1,3) dm_file,
--            src_cd,
--            MIN(intrctn_dt) drop_dt,
--            ROW_NUMBER() OVER (
--            ORDER BY dm_file,
--                drop_dt,
--                src_cd) AS src_key,
--                ROW_NUMBER() OVER (PARTITION BY dm_file
--            ORDER BY drop_dt DESC) AS camp_rank
--            FROM mktg_ops_vws.bzfc_fact_dmail_interaction
--            WHERE mail_drop_cnt>0
--                AND  (SUBSTR(src_cd,1,3) IN ('RQL','RQD','RQP')
--            AND intrctn_dt BETWEEN ADD_MONTHS(DATE,-16) AND DATE-42)
--                OR  (SUBSTR(src_cd,1,3) IN ('RQA','RQC','RQS')
--            AND intrctn_dt BETWEEN ADD_MONTHS(DATE,-16) AND DATE-42)
--            GROUP BY 1,
--                2; -- RAW DM INTERACTION RECORDS

		truncate table mktg_stage_tbls.pbi_model_perf_interaction_stg ;
		    INSERT	INTO mktg_stage_tbls.pbi_model_perf_interaction_stg
		        (cnst_mstr_id, src_key, src_cd, intrctn_dt, target_tag_scr, vigintile, mods_fr_scr,
		        superdupe_ind, dm_program, select_grp_dsc, reclass_multi_ind, hpg_1kplus_ind,
		        mail_cnt)
		       select cnst_mstr_id,
					src_key,
				    src_cd,
					intrctn_dt,
		            target_tag_scr,
		            vigintile,
		            mods_fr_scr,
		            superdupe_ind,
		            dm_program,
		            select_grp_dsc,
		            reclass_multi_ind,
		            hpg_1kplus_ind,
		            mail_cnt
		           from(
		           
		           			select a.cnst_mstr_id,
							a.src_key,
						    a.src_cd,
							a.intrctn_dt,
				            a.target_tag_scr,
				            a.vigintile,
				            a.mods_fr_scr,
				            b.superdupe_ind,
				            (
				            CASE
				            WHEN STRPOS(UPPER(b.dm_program),'DDO')>0 THEN 'REDBOX'
							WHEN STRPOS(UPPER(b.dm_program),'ORGANIZATION')>0 THEN 'ORG'
							WHEN LEFT(a.src_cd,3)='RQP' and STRPOS(upper(b.dm_program),'BIO')>0 THEN 'BIO'
							WHEN LEFT(a.src_cd,3)='RQP' and STRPOS(upper(b.dm_program),'VOL')>0 THEN 'VOL'
							WHEN LEFT(a.src_cd,3)='RQP' and STRPOS(upper(b.dm_program),'TS')>0 THEN 'TS'
							WHEN LEFT(a.src_cd,3)='RQP' and STRPOS(upper(b.dm_program),'DEEPLY')>0 THEN 'BIO'
							WHEN LEFT(a.src_cd,3)='RQP' and STRPOS(upper(b.dm_program),'MULTI-LOB')>0 THEN 'NON-FIN'
							WHEN LEFT(a.src_cd,3)='RQD' and STRPOS(upper(b.dm_program),'DOD')>0 THEN 'DOD'
							WHEN LEFT(a.src_cd,3)='RQD' and STRPOS(upper(b.dm_program),'DISASTER-ONLY')>0 THEN 'DOD'
							WHEN LEFT(a.src_cd,3)='RQL' and STRPOS(upper(b.dm_program),'LAPSED')>0 THEN 'LAPSED'
							WHEN LEFT(a.src_cd,3)='RQL' and STRPOS(upper(b.dm_program),'HOUSE')>0 THEN 'LAPSED'	
				            ELSE b.dm_program
				            END) dm_program,
				                (
				            CASE
				            WHEN LEFT(a.src_cd,3)='RQP' AND STRPOS(UPPER(b.select_grp_dsc),'0-2')>0 THEN '0-2 yrs'
							WHEN LEFT(a.src_cd,3)='RQP' AND STRPOS(UPPER(b.select_grp_dsc),'2-5')>0 THEN '2-5 yrs'
							WHEN LEFT(a.src_cd,3)='RQP' AND STRPOS(UPPER(b.select_grp_dsc),'5-10')>0 THEN '5-10 yrs'
							WHEN LEFT(a.src_cd,3)='RQP' AND STRPOS(UPPER(b.select_grp_dsc),'10+')>0 THEN 'Deeply Lapsed 10+ yrs'
							WHEN LEFT(a.src_cd,3)='RQP' AND STRPOS(UPPER(b.select_grp_dsc),'DEEPLY')>0 THEN 'Deeply Lapsed 10+ yrs'
							WHEN LEFT(a.src_cd,3)='RQP' AND STRPOS(UPPER(b.select_grp_dsc),'PERM')>0 THEN 'Permanently Deferred'
							WHEN LEFT(a.src_cd,3)='RQP' AND STRPOS(UPPER(b.select_grp_dsc),'RECLASS')>0 THEN 'Reclassified Multis'
							WHEN LEFT(a.src_cd,3)='RQD' AND STRPOS(UPPER(b.dm_program),'DOD')>0 AND STRPOS(UPPER(b.dm_program),'120')>0 THEN TRIM(b.select_grp_dsc)||' '||TRIM('120+mo')
							WHEN LEFT(a.src_cd,3)='RQD' AND STRPOS(UPPER(b.dm_program),'0-12')>0 THEN TRIM('0-12mo')
							WHEN LEFT(a.src_cd,3)='RQD' AND STRPOS(UPPER(b.dm_program),'13-24')>0 THEN TRIM('13-24mo')
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 1' THEN 'VIGINTILE 01'
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 2' THEN 'VIGINTILE 02'
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 3' THEN 'VIGINTILE 03'
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 4' THEN 'VIGINTILE 04'
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 5' THEN 'VIGINTILE 05'
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 6' THEN 'VIGINTILE 06'
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 7' THEN 'VIGINTILE 07'
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 8' THEN 'VIGINTILE 08'
							WHEN TRIM(UPPER(b.select_grp_dsc))='VIGINTILE 9' THEN 'VIGINTILE 09'
							WHEN STRPOS(UPPER(b.segmnt_dsc),'RECLASS')>0 THEN 'Reclassified Multis'
							WHEN LEFT(a.src_cd,3)='RQL' AND STRPOS(UPPER(b.dm_program),'HOUSE')>0 AND STRPOS(UPPER(b.select_grp_dsc),'0-12')>0 THEN 'PENNY 0-12mo'	
							WHEN LEFT(a.src_cd,3)='RQL' AND STRPOS(UPPER(b.dm_program),'HOUSE')>0 AND STRPOS(UPPER(b.select_grp_dsc),'13-24')>0 THEN 'PENNY 13-24mo'	
				            ELSE b.select_grp_dsc
				            END) select_grp_dsc,
				                (
				            CASE
				                WHEN (STRPOS(TRIM(UPPER(b.dm_program)),'RECLASS')>0 OR STRPOS(TRIM(UPPER(b.select_grp_dsc)),'RECLASS')>0) THEN 1 ELSE 0
				            END) reclass_multi_ind,
				                (
				            CASE
				                WHEN (STRPOS(TRIM(UPPER(b.segmnt_dsc)),'1,000')>0 OR STRPOS(TRIM(UPPER(b.segmnt_dsc)),'1000')>0) THEN 1 ELSE 0
				            END) hpg_1kplus_ind,
				            COALESCE(SUM(a.mail_drop_cnt),0) mail_cnt,
				            COUNT(*) OVER (PARTITION BY a.cnst_mstr_id||a.src_key ROWS UNBOUNDED PRECEDING) as cnt
				            FROM mktg_ops_vws.bzfc_fact_dmail_interaction a
				            LEFT JOIN mktg_ops_vws.rr_rqq_rql_file_xref_mtvtn_cd b ON a.motivtn_cd=b.motivtn_cd           
				            WHERE 
				            a.mail_drop_cnt>0
				            	and LEFT(a.src_cd,3) IN ('RQA','RQC','RQL','RQD','RQP','RQS')
								AND a.intrctn_dt BETWEEN ADD_MONTHS(CURRENT_DATE,-16) AND ADD_MONTHS(CURRENT_DATE,-1)
				            GROUP BY 1,
				                2,
				                3,
				                4,
				                5,
				                6,
				                7,
				                8,
				                9,
				                10,
				                11,
				                12
		          
		           ) as subqry
		        where cnt = 1; 
		           
		           
		 
		truncate table  mktg_ops_tbls.pbi_model_perf_dim_lol ;
		    INSERT	INTO mktg_ops_tbls.pbi_model_perf_dim_lol
		        (dm_program, select_grp_dsc, reclass_multi_ind, hpg_1kplus_ind, lol_sel_key)
		        Select dm_program,
		            select_grp_dsc,
		            reclass_multi_ind,
		            hpg_1kplus_ind,
		            ROW_NUMBER() OVER (
		            ORDER BY FNV_HASH(dm_program || select_grp_dsc || reclass_multi_ind || hpg_1kplus_ind)) AS lol_sel_key     /*HASHROW() is replaced by FNV_HASH(dm_program || select_grp_dsc || reclass_multi_ind || hpg_1kplus_ind)*/
		            FROM (
		            Select DISTINCT dm_program, 
		            	select_grp_dsc, 
		            	reclass_multi_ind, 
		            	hpg_1kplus_ind
		                FROM mktg_stage_tbls.pbi_model_perf_interaction_stg
		            ) a ; 
		           
		
		
		
		truncate table mktg_stage_tbls.pbi_model_perf_adb_txn_stg  ;
		    INSERT	INTO mktg_stage_tbls.pbi_model_perf_adb_txn_stg
		        (cnst_mstr_id, txn_src_cd, src_key, dir_dntn_dt, dir_dntn_cnt,
		        dir_dntn_amt, ind_dntn_dt, ind_dntn_cnt, ind_dntn_amt)
		        
		        with GMS_bzfc_adb_fact_donation as(
		        
		        SELECT *,COALESCE(a.indrct_dm_src_cd, a.campgn_src_cd) as txn_src_cd
		            FROM mktg_ops_vws.GMS_bzfc_adb_fact_donation a
		            
		        )
		        select a.cnst_mstr_id,
		            txn_src_cd,
		            camps.src_key,
		            MIN(
		            CASE
		                WHEN greatest(tgt_dm_gift_ind,non_tgt_dm_gift_ind)>0 THEN dntn_gift_dt ELSE NULL
		            END) dir_dntn_dt,
		                SUM(tgt_dm_gift_ind+non_tgt_dm_gift_ind) dir_dntn_cnt,
		                SUM(tgt_dm_gift_amt+non_tgt_dm_gift_amt) dir_dntn_amt,
		                MIN(
		            CASE
		                WHEN indrct_dm_donat_ind>0 THEN dntn_gift_dt ELSE NULL
		            END) ind_dntn_dt,
		                SUM(indrct_dm_donat_ind) ind_dntn_cnt,
		                SUM(indrct_dm_gift_amt) ind_dntn_amt
		            FROM GMS_bzfc_adb_fact_donation a
		            INNER JOIN (select	distinct src_key, src_cd from mktg_stage_tbls.pbi_model_perf_interaction_stg) camps ON txn_src_cd=camps.src_cd
		            WHERE ( tgt_dm_gift_amt>0 OR non_tgt_dm_gift_amt>0 OR indrct_dm_gift_amt>0)
		            GROUP BY 1,
		                2,
		                3; 
		        
		     
		    truncate table mktg_stage_tbls.pbi_model_perf_adb_txn_hist_stg ;
		    INSERT	INTO mktg_stage_tbls.pbi_model_perf_adb_txn_hist_stg
		        (src_key, intrctn_dt, cnst_mstr_id, lst_dntn_dt, lst_msn_dntn_dt,
		        BlackJack, last_dntn_amt)
		        SELECT a.src_key,
		            a.intrctn_dt,
		            a.cnst_mstr_id,
		            a.lst_dntn_dt,
		            a.lst_msn_dntn_dt,
		            a.BlackJack,
		            SUM(b.fr_pmt_amt) last_dntn_amt
		            FROM (
		            SELECT intxn.src_key,
		                intxn.intrctn_dt,
		                txn.cnst_mstr_id,
		                MAX(txn.dntn_gift_dt) lst_dntn_dt,
		                MAX(
		                CASE
		                    WHEN txn.fr_distr_dntn_ind=0 THEN txn.dntn_gift_dt ELSE NULL
		                END) lst_msn_dntn_dt,
		                     --BLACKJACK
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-12) AND intxn.intrctn_dt-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-24) AND ADD_MONTHS(intxn.intrctn_dt,-12)-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-36) AND ADD_MONTHS(intxn.intrctn_dt,-24)-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-48) AND ADD_MONTHS(intxn.intrctn_dt,-36)-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-60) AND ADD_MONTHS(intxn.intrctn_dt,-48)-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-72) AND ADD_MONTHS(intxn.intrctn_dt,-60)-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-84) AND ADD_MONTHS(intxn.intrctn_dt,-72)-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-96) AND ADD_MONTHS(intxn.intrctn_dt,-84)-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-108) AND ADD_MONTHS(intxn.intrctn_dt,-96)-1 THEN 1 ELSE 0
		                END) +
		                MAX(
		                CASE
		                    WHEN dntn_gift_dt BETWEEN ADD_MONTHS(intxn.intrctn_dt,-120) AND ADD_MONTHS(intxn.intrctn_dt,-108)-1 THEN 1 ELSE 0
		                END) 
		                AS BlackJack
		                FROM mktg_stage_tbls.pbi_model_perf_interaction_stg intxn
		                	-- ACQUISITION - ARC CFR GIVING HISTORY *AS OF 120 DAYS PRE-DROP DATE* (THE CURRENT LEAD TIME BUILT INTO CAMPAIGNS - THE TIME BETWEEN MODEL SCORING AND THE CAMPAIGN DROP DATE)
		                INNER JOIN mktg_ops_vws.GMS_arc_fr_txn txn ON intxn.cnst_mstr_id=txn.cnst_mstr_id AND txn.fr_pmt_amt>0 
		                AND ((LEFT(intxn.src_cd,3) IN ('RQA','RQC','RQS') AND intxn.intrctn_dt > (txn.dntn_gift_dt + 45))
		                OR (LEFT(intxn.src_cd,3) IN ('RQL','RQD') AND intxn.intrctn_dt > (txn.dntn_gift_dt + 120)))
		                GROUP BY 1,
		                    2,
		                    3
		            ) a
		            LEFT JOIN mktg_ops_vws.GMS_arc_fr_txn b ON a.cnst_mstr_id=b.cnst_mstr_id AND b.fr_pmt_amt>0 AND b.dntn_gift_dt=a.lst_dntn_dt
		            GROUP BY 1,
		                2,
		                3,
		                4,
		                5,
		                6; 
		    
		    
		 
		truncate table mktg_ops_tbls.pbi_model_perf_dashbrd ;
		    INSERT	INTO mktg_ops_tbls.pbi_model_perf_dashbrd
		        (cnst_mstr_id, src_key, dm_file, lol_sel_key, mail_cnt, superdupe_ind,
		        vigintile, mods_fr_scr, dir_dntn_cnt, dir_dntn_amt, ind_dntn_cnt,
		        ind_dntn_amt, cnst_typ_cd, lst_dntn_amt, BlackJack,
		        expected_val, age, recency, sm_custom_scr, sm_children_scr, vig_cutoff, wfall_key)
		        SELECT 
		        	COALESCE(a.cnst_mstr_id, b.cnst_mstr_id) cnst_mstr_id,
		            COALESCE(a.src_key, b.src_key) src_key,
		            SUBSTRING(COALESCE(a.src_cd, b.txn_src_cd),1,3) AS dm_file,
		            x.lol_sel_key,
		            a.mail_cnt,
		            a.superdupe_ind,
		            (
		            CASE
		                WHEN a.reclass_multi_ind>0 THEN 'RM'
		                WHEN a.vigintile<10 THEN CAST(TRIM('0'||CAST(a.vigintile AS CHAR(1))) AS CHAR(2)) 
		                WHEN a.vigintile between 10 and 19 THEN CAST(a.vigintile AS CHAR(2))
		                WHEN a.vigintile=20 and a.mods_fr_scr>0 THEN CAST(a.vigintile AS CHAR(2))
		            ELSE 'NS'
		            END) vigintile,
		            (
		            CASE
		                WHEN dm_file IN ('RQL') AND a.intrctn_dt BETWEEN DATE'2024-01-01' AND DATE'2024-06-30' THEN 
		                		cast(((((cast((a.mods_fr_scr*0.1214617) as decimal(20,16))-0.169953722)/9.761546626)*0.034) + 0.0005)*10000 as decimal(12,4))
		                WHEN dm_file IN ('RQD') AND a.intrctn_dt BETWEEN DATE'2024-01-01' AND DATE'2024-03-31' THEN 
		                		cast(((((cast((a.mods_fr_scr*0.0650915) as decimal(20,16))-0.421098324)/5.647046484)*0.018) + 0.00001)*10000 as decimal(12,4))
		                WHEN dm_file IN ('RQD') AND a.intrctn_dt BETWEEN DATE'2024-04-01' AND DATE'2024-06-30' THEN 
		                		cast(((((cast((a.mods_fr_scr*0.0650915) as decimal(20,16))-0.007632422)/0.049110513)*0.0195) + 0.0005)*10000 as decimal(12,4))
		            	ELSE a.mods_fr_scr
		            END) mods_fr_scr,
		            COALESCE(b.dir_dntn_cnt,0) dir_dntn_cnt,
		            COALESCE(b.dir_dntn_amt,0) dir_dntn_amt,
		            COALESCE(b.ind_dntn_cnt,0) ind_dntn_cnt,
		            COALESCE(b.ind_dntn_amt,0) ind_dntn_amt,
		            (
		            CASE
		                WHEN e.cnst_typ_cd='IN' THEN 1
		                WHEN e.cnst_typ_cd='OR' THEN 0 ELSE NULL
		            END) cnst_typ_cd,
		            f.last_dntn_amt AS lst_dntn_amt,
		            f.BlackJack,
		            CAST((
		            CASE
		            	WHEN (a.mods_fr_scr=0 OR a.mods_fr_scr IS NULL) THEN NULL
		            	WHEN dm_file IN ('RQP') THEN NULL
		            	WHEN dm_file IN ('RQA','RQC','RQS') THEN a.mods_fr_scr 	-- CULTIV MODEL USING EXPECTED VALUE SCORE IN ALL OF FY23 AND FY24
		            	WHEN dm_file IN ('RQL','RQD') AND a.intrctn_dt < date'2023-06-10' THEN a.mods_fr_scr 	-- ACQ MODELS USED EXPECTED VALUE SCORE IN FY23 BUT *NOT* IN FY24
		            	WHEN dm_file IN ('RQL','RQD') AND a.intrctn_dt BETWEEN date'2023-06-10' AND DATE'2023-12-31' THEN least(((a.mods_fr_scr/10000.00000) * f.last_dntn_amt),10000000) 	-- ACQ MODEL SCORE WAS PRED_RESP*10000 IN RQX2308 AND RQX2311
		                WHEN dm_file IN ('RQL') AND a.intrctn_dt BETWEEN DATE'2024-01-01' AND DATE'2024-06-30' THEN least((cast(((((cast((a.mods_fr_scr*0.1214617) as decimal(20,16))-0.169953722)/9.761546626)*0.034) + 0.0005) as decimal(12,4)) * f.last_dntn_amt),10000000) -- LAPSED MODEL SCORE WAS NOT ADJUSTED IN RQL2402 AND RQL2405
		                WHEN dm_file IN ('RQD') AND a.intrctn_dt BETWEEN DATE'2024-01-01' AND DATE'2024-03-31' THEN least((cast(((((cast((a.mods_fr_scr*0.0650915) as decimal(20,16))-0.421098324)/5.647046484)*0.018) + 0.00001) as decimal(12,4)) * f.last_dntn_amt),10000000) -- DOD MODEL SCORE WAS NOT ADJUSTED IN RQD2402
		                WHEN dm_file IN ('RQD') AND a.intrctn_dt BETWEEN DATE'2024-04-01' AND DATE'2024-06-30' THEN least((cast(((((cast((a.mods_fr_scr*0.0650915) as decimal(20,16))-0.007632422)/0.049110513)*0.0195) + 0.0005) as decimal(12,4)) * f.last_dntn_amt),10000000) -- DOD MODEL SCORE WAS NOT ADJUSTED IN RQD2405
		                WHEN dm_file IN ('RQL','RQD') AND a.intrctn_dt > DATE'2024-06-30' THEN least(((a.mods_fr_scr/10000.00000) * f.last_dntn_amt),10000000) 	-- ACQ MODEL SCORE WAS ADJ_PRED_RESP*10000 STARTING IN RQX2408
		            	ELSE NULL
		            END) AS DECIMAL(13,4)) AS expected_val,
		                (
		            CASE
		                WHEN c.bzd_derived_age BETWEEN 18 AND 100 THEN c.bzd_derived_age 
		                WHEN c.simio_derived_age BETWEEN 18 AND 100 THEN c.simio_derived_age
		                ELSE NULL
		            END) AS age,
		            CAST((
		            CASE
		                WHEN dm_file IN ('RQA','RQC','RQS') THEN least(floor(COALESCE((a.intrctn_dt - f.lst_msn_dntn_dt)/365.0000, (a.intrctn_dt - f.lst_dntn_dt)/365.0000)*12),26)
		                WHEN dm_file IN ('RQD') THEN least(floor((a.intrctn_dt - f.lst_dntn_dt)/365.0000*2)/2,15)
		                WHEN dm_file IN ('RQL') THEN least(floor((a.intrctn_dt - f.lst_msn_dntn_dt)/365.0000*2)/2,20)
		            ELSE NULL
		            END) AS DECIMAL(4,1)) recency,
					(CASE WHEN dm_file IN ('RQA','RQC','RQS') THEN COALESCE(p.sm_arc_active_scrval,21)
						WHEN dm_file='RQL' THEN COALESCE(p.sm_arc_lapsed_scrval,21)
						WHEN dm_file='RQD' THEN COALESCE(p.sm_arc_disaster_scrval,21)
						WHEN dm_file='RQP' THEN COALESCE(p.sm_arc_non_fr_scrval,21)
						ELSE 21 END) sm_custom_scr,
					COALESCE(p.sm_children_dnr_scrval,41) sm_children_scr,                               
		            g.vig_cutoff,
		                (
		            CASE 
		                WHEN a.reclass_multi_ind>0 THEN 0 -- RECLASSIFIED MULTIS 
		            
		                WHEN e.cnst_typ_cd='OR' THEN 1 -- ORGS 
		            
		                WHEN STRPOS(UPPER(x.dm_program), 'REDBOX')>0 OR STRPOS(UPPER(x.dm_program), 'RED BOX')>0 THEN 2 -- REDBOX 
		            
		                WHEN (STRPOS(UPPER(x.select_grp_dsc),'EXPECTED VALUE')>0 AND STRPOS(UPPER(x.select_grp_dsc),'CONTROL')>0) OR STRPOS(upper(x.select_grp_dsc),'HIGH RESPONSE')>0 THEN 3 -- TEST SEGMENTS
		                WHEN (STRPOS(UPPER(x.select_grp_dsc),'EXPECTED VALUE')>0 AND STRPOS(UPPER(x.select_grp_dsc),'TEST')>0) THEN 4
		                WHEN STRPOS(UPPER(x.select_grp_dsc),'120+')>0 THEN 5 
		            
		                WHEN a.vigintile<=g.vig_cutoff THEN 6 -- MODEL SELECT
		            
		                WHEN x.hpg_1kplus_ind>0 THEN 7 -- HPG $1K+
		            
		                WHEN STRPOS(UPPER(x.select_grp_dsc),'0-12')>0 THEN 8	-- RECENCY
		                WHEN STRPOS(UPPER(x.select_grp_dsc),'13-24')>0 THEN 9 
		            
		                WHEN sm_custom_scr in (1,2) THEN 10 -- TOP SIMIO SCORE
		            
		                WHEN a.superdupe_ind > 0 THEN 11 -- SUPERDUPES
		            
		                WHEN STRPOS(UPPER(x.select_grp_dsc),'VIGINTILE')>0 THEN 12 -- VIGINTILE SELECT
		            
		                WHEN a.mods_fr_scr IS NOT NULL AND a.mods_fr_scr <> 0 THEN 13	-- NULL SCORE
		            ELSE 14
		            END) wfall_key
		            
		            FROM mktg_stage_tbls.pbi_model_perf_interaction_stg a
		               
		            	--DIRECT & INDIRECT ATTRIBUTION FROM ADOBE FACT DONATION TABLE
		            FULL JOIN mktg_stage_tbls.pbi_model_perf_adb_txn_stg b ON a.cnst_mstr_id=b.cnst_mstr_id AND a.src_key=b.src_key
		            	
		            	-- ARC AGE
		            LEFT JOIN mktg_ops_vws.bz_cnst_birth_best c ON a.cnst_mstr_id=c.cnst_mstr_id
		            	
		            	-- FR PREFERRED CONTACT VIEW
		            LEFT JOIN mktg_ops_vws.GMS_cnst_cdi_smry_fr_prfr e ON a.cnst_mstr_id=e.cnst_mstr_id
		            
		            	-- IDENTIFY HIGH-DOLLAR DONORS AND LAST GIFT AMOUNT PRIOR TO CAMPAIGN DROP DATE
		            LEFT JOIN mktg_stage_tbls.pbi_model_perf_adb_txn_hist_stg f ON a.cnst_mstr_id=f.cnst_mstr_id AND a.src_key=f.src_key
		            		
		            	-- LAPSED/DOD VIGINTILE CUTOFF SCORES
		            LEFT JOIN (
		            SELECT src_key,
		                MAX(vigintile) vig_cutoff
		                FROM (
		                SELECT a.src_key,
		                    vigintile,
		                    SUM(mail_cnt) mail_cnt
		                    FROM mktg_stage_tbls.pbi_model_perf_interaction_stg a
		                    WHERE vigintile IS NOT NULL
		                        AND  left(src_cd,3) IN ('RQL','RQD')
		                    GROUP BY 1,
		                        2
		                ) a
		                WHERE mail_cnt>=99000
		                GROUP BY 1
		            ) g ON a.src_key=g.src_key 
		            	
		            	-- LOL SELECT SEGMENTS DIMENSION TABLE
		            LEFT JOIN mktg_ops_tbls.pbi_model_perf_dim_lol x ON TRIM(UPPER(a.dm_program))=TRIM(UPPER(x.dm_program)) 
		            AND TRIM(UPPER(a.select_grp_dsc))=TRIM(UPPER(x.select_grp_dsc))
		            AND a.reclass_multi_ind=x.reclass_multi_ind 
		            and a.hpg_1kplus_ind=x.hpg_1kplus_ind
		            
		            -- SIMIO MODEL SCORES
		            left join mktg_ops_vws.bzf_cnst_scr_simio p on a.cnst_mstr_id=p.cnst_mstr_id
		            
		            -- EXCLUDE MANAGED DONORS + DECEASED. INCLUDE ORGS!
		            WHERE ( e.sf_acct_fmd_ind IS NULL OR e.sf_acct_fmd_ind=0) --and (e.cnst_typ_cd is null or e.cnst_typ_cd='IN')
		                AND  (e.cnst_arc_deceased_cd IS NULL OR e.cnst_arc_deceased_cd='N')
		            ; 
		    
		 
		            
		            
		           
		   truncate table mktg_ops_tbls.pbi_model_perf_tlres ;
		    INSERT	INTO mktg_ops_tbls.pbi_model_perf_tlres
		        (src_cd, rn_typ, typ, run_dt, CPP, drop_dt, pct_mature_, recip_cnt, mail_cnt_,
		        dntn_cnt_, dntn_amt_, pct_crossover, resp_rt, avg_gift_amt, total_cost,
		        net_rev, npd, ctrd, rpm, dntn_cnt_1k, dntn_amt_1k)
		        SELECT src_cd,
		            rn_typ,
		            typ,
		            run_dt,
		            CPP,
		            drop_dt,
		            pct_mature_,
		            recip_cnt,
		            mail_cnt_,
		            dntn_cnt_,
		            dntn_amt_,
		            pct_crossover,
		            resp_rt,
		            avg_gift_amt,
		            total_cost,
		            net_rev,
		            npd,
		            ctrd,
		            rpm,
		            dntn_cnt_1k,
		            dntn_amt_1k
		            FROM (
		            SELECT z.src_cd,
		                1 AS rn_typ,
		                CAST('YoY Actuals' AS CHAR(50)) AS typ,
		                CURRENT_DATE AS run_dt,
		                b.CPP,
		                c.drop_dt,
		                cast(null as decimal(8,6)) as pct_mature_,
		                c.recip_cnt,
		                c.mail_cnt AS mail_cnt_,
		                a.dntn_cnt AS dntn_cnt_,
		                a.dntn_amt AS dntn_amt_,
		                000.0000 AS pct_crossover,
		                (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_cnt_/(mail_cnt_/1.0000) ELSE 0
		                END) AS resp_rt,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN dntn_amt_/(dntn_cnt_/1.0000) ELSE 0
		                END) AS avg_gift_amt,
		                    (mail_cnt_ * CPP) AS total_cost,
		                    (dntn_amt_ - (mail_cnt_ * CPP)) AS net_rev,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN (dntn_amt_ - (mail_cnt_ * CPP))/(dntn_cnt_/1.0000) ELSE 0
		                END) npd,
		                    (
		                CASE
		                    WHEN dntn_amt_>0 THEN (mail_cnt_ * CPP)/(dntn_amt_/1.0000) ELSE 0
		                END) ctrd,
		                    (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_amt_/(mail_cnt_/1000.0000) ELSE 0
		                END) AS rpm,
		                    a.dntn_cnt_1k,
		                    a.dntn_amt_1k
		                FROM (
							select distinct src_key, 
								src_cd, 
								intrctn_dt, 
								trim(substring(src_cd,1,3))||trim(cast(cast(substring(src_cd,4,2) as int)-1 as char(2)))||trim(substring(src_cd,6,7)) as yoy_src_cd
							from mktg_stage_tbls.pbi_model_perf_interaction_stg
							) z
		                LEFT JOIN (
		                SELECT campgn_src_cd AS src_cd,
		                    COUNT(giftran_key) AS dntn_cnt,
		                    SUM(fr_pmt_amt) dntn_amt,
		                    SUM(
		                    CASE
		                        WHEN fr_pmt_amt>=1000 THEN 1 ELSE 0
		                    END) dntn_cnt_1k,
		                        SUM(
		                    CASE
		                        WHEN fr_pmt_amt>=1000 THEN fr_pmt_amt ELSE 0
		                    END) dntn_amt_1k
		                    FROM mktg_ops_vws.gms_arc_fr_txn
		                    WHERE fr_pmt_amt>0
		                        AND  primary_gift_ind>0 --  and campgn_src_cd in (sel yoy_src_cd from yoy_src_cd)   /*Removed this as the subquery joins to this later */
		                    
		                    GROUP BY 1
		                ) a ON z.yoy_src_cd=a.src_cd
		                LEFT JOIN data_lab_mktg_tbls.nr_cdrp_fy_budget b ON z.yoy_src_cd=b.src_cd
		                LEFT JOIN (
		                SELECT src_cd,
		                    MIN(intrctn_dt) drop_dt,
		                    COUNT(*) recip_cnt,
		                    SUM(mail_drop_cnt) mail_cnt
		                    FROM mktg_ops_vws.bzfc_fact_dmail_interaction
		                    WHERE mail_drop_cnt>0 --	and src_cd in (sel yoy_src_cd from yoy_src_cd) /*Removed this as the subquery joins to this later */
		                    
		                    GROUP BY 1
		                ) c ON z.yoy_src_cd=c.src_cd
		            UNION ALL
		            SELECT c.src_cd,
		                3 AS rn_typ,
		                CAST('Direct Revenue Only' AS CHAR(50)) AS typ,
		                CURRENT_DATE AS run_dt,
		                b.CPP,
		                c.intrctn_dt as drop_dt,
		                cast(null as decimal(8,6)) as pct_mature_,
		                COUNT(*) recip_cnt,
		                SUM(a.mail_cnt) mail_cnt_,
		                SUM(a.dir_dntn_cnt) dntn_cnt_,
		                SUM(a.dir_dntn_amt) dntn_amt_,
		                000.0000 AS pct_crossover,
		                (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_cnt_/(mail_cnt_/1.0000) ELSE 0
		                END) AS resp_rt,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN dntn_amt_/(dntn_cnt_/1.0000) ELSE 0
		                END) AS avg_gift_amt,
		                    (mail_cnt_ * CPP) AS total_cost,
		                    (dntn_amt_ - (mail_cnt_ * CPP)) AS net_rev,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN (dntn_amt_ - (mail_cnt_ * CPP))/(dntn_cnt_/1.0000) ELSE 0
		                END) npd,
		                    (
		                CASE
		                    WHEN dntn_amt_>0 THEN (mail_cnt_ * CPP)/(dntn_amt_/1.0000) ELSE 0
		                END) ctrd,
		                    (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_amt_/(mail_cnt_/1000.0000) ELSE 0
		                END) AS rpm,
		                    SUM(
		                CASE
		                    WHEN a.dir_dntn_amt>=1000 THEN 1 ELSE 0
		                END) dntn_cnt_1k,
		                    SUM(
		                CASE
		                    WHEN a.dir_dntn_amt>=1000 THEN a.dir_dntn_amt ELSE 0
		                END) dntn_amt_1k
		                FROM mktg_ops_tbls.pbi_model_perf_dashbrd a
		                LEFT JOIN (select distinct src_key, src_cd, intrctn_dt from mktg_stage_tbls.pbi_model_perf_interaction_stg) c ON a.src_key=c.src_key
		                LEFT JOIN data_lab_mktg_tbls.nr_cdrp_fy_budget b ON c.src_cd=b.src_cd
		                GROUP BY 1,
		                    2,
		                    3,
		                    4,
		                    5,
		                    6,
		                    7
		            UNION ALL
		            SELECT c.src_cd,
		                4 AS rn_typ,
		                CAST('Incl. Online Crossover' AS CHAR(50)) AS typ,
		                CURRENT_DATE AS run_dt,
		                b.CPP,
		                c.intrctn_dt as drop_dt,
		                cast(null as decimal(8,6)) as pct_mature_,
		                COUNT(*) recip_cnt,
		                SUM(a.mail_cnt) mail_cnt_,
		                SUM(a.dir_dntn_cnt + a.ind_dntn_cnt) dntn_cnt_,
		                SUM(a.dir_dntn_amt + a.ind_dntn_amt) dntn_amt_,
		                (
		                CASE
		                    WHEN SUM(a.dir_dntn_amt)>0 THEN SUM(a.ind_dntn_amt)/(SUM(a.dir_dntn_amt)/1.0000) ELSE 0
		                END) AS pct_crossover,
		                    (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_cnt_/(mail_cnt_/1.0000) ELSE 0
		                END) AS resp_rt,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN dntn_amt_/(dntn_cnt_/1.00) ELSE 0
		                END) AS avg_gift_amt,
		                    (mail_cnt_ * CPP) AS total_cost,
		                    (dntn_amt_ - (mail_cnt_ * CPP)) AS net_rev,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN (dntn_amt_ - (mail_cnt_ * CPP))/(dntn_cnt_/1.0000) ELSE 0
		                END) npd,
		                    (
		                CASE
		                    WHEN dntn_amt_>0 THEN (mail_cnt_ * CPP)/(dntn_amt_/1.0000) ELSE 0
		                END) ctrd,
		                    (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_amt_/(mail_cnt_/1000.0000) ELSE 0
		                END) AS rpm,
		                    SUM(
		                CASE
		                    WHEN (a.dir_dntn_amt + a.ind_dntn_amt)>=1000 THEN 1 ELSE 0
		                END) dntn_cnt_1k,
		                    SUM(
		                CASE
		                    WHEN (a.dir_dntn_amt + a.ind_dntn_amt)>=1000 THEN (a.dir_dntn_amt + a.ind_dntn_amt) ELSE 0
		                END) dntn_amt_1k
		                FROM mktg_ops_tbls.pbi_model_perf_dashbrd a
		                LEFT JOIN (select distinct src_key, src_cd, intrctn_dt from mktg_stage_tbls.pbi_model_perf_interaction_stg) c ON a.src_key=c.src_key
		                LEFT JOIN data_lab_mktg_tbls.nr_cdrp_fy_budget b ON c.src_cd=b.src_cd
		                GROUP BY 1,
		                    2,
		                    3,
		                    4,
		                    5,
		                    6,
		                    7
		            UNION ALL
		            SELECT a.src_cd,
		                2 AS rn_typ,
		                CAST('Budget Projection' AS CHAR(50)) AS typ,
		                CURRENT_DATE AS run_dt,
		                CPP,
		                intrctn_dt AS drop_dt,
		                cast(null as decimal(8,6)) as pct_mature_,
		                NULL AS recip_cnt,
		                mail_cnt AS mail_cnt_,
		                dntn_cnt AS dntn_cnt_,
		                dntn_amt AS dntn_amt_,
		                000.0000 AS pct_crossover,
		                (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_cnt_/(mail_cnt_/1.0000) ELSE 0
		                END) AS resp_rt,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN dntn_amt_/(dntn_cnt_/1.0000) ELSE 0
		                END) AS avg_gift_amt,
		                    (mail_cnt_ * CPP) AS total_cost,
		                    (dntn_amt_ - (mail_cnt_ * CPP)) AS net_rev,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN (dntn_amt_ - (mail_cnt_ * CPP))/(dntn_cnt_/1.0000) ELSE 0
		                END) npd,
		                    (
		                CASE
		                    WHEN dntn_amt_>0 THEN (mail_cnt_ * CPP)/(dntn_amt_/1.0000) ELSE 0
		                END) ctrd,
		                    (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_amt_/(mail_cnt_/1000.0000) ELSE 0
		                END) AS rpm,
		                    NULL AS dntn_cnt_1k,
		                    NULL dntn_amt_1k
		                FROM data_lab_mktg_tbls.nr_cdrp_fy_budget a
		                WHERE a.src_cd IN (
		                SELect distinct src_cd
		                    from mktg_stage_tbls.pbi_model_perf_interaction_stg)
		            UNION ALL
		            SELECT c.src_cd,
		                5 AS rn_typ,
		                CAST('Dir Rev Proj at Maturity' AS CHAR(50)) AS typ,
		                CURRENT_DATE AS run_dt,
		                b.CPP,
		                c.intrctn_dt AS drop_dt,
		                cast(d.pct_mature as decimal(8,6)) pct_mature_,
		                COUNT(*) AS recip_cnt,
		                SUM(a.mail_cnt) AS mail_cnt_,
		                (
		                CASE
		                    WHEN pct_mature_>0 THEN FLOOR(SUM(a.dir_dntn_cnt)/pct_mature_) ELSE SUM(a.dir_dntn_cnt)
		                END) AS dntn_cnt_,
		                (
		                CASE
		                    WHEN pct_mature_>0 THEN FLOOR(SUM(a.dir_dntn_amt)/pct_mature_) ELSE SUM(a.dir_dntn_amt)
		                END) AS dntn_amt_,
		                000.0000 AS pct_crossover,
		                (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_cnt_/(mail_cnt_/1.0000) ELSE 0
		                END) AS resp_rt,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN dntn_amt_/(dntn_cnt_/1.0000) ELSE 0
		                END) AS avg_gift_amt,
		                    (mail_cnt_ * CPP) AS total_cost,
		                    (dntn_amt_ - (mail_cnt_ * CPP)) AS net_rev,
		                    (
		                CASE
		                    WHEN dntn_cnt_>0 THEN (dntn_amt_ - (mail_cnt_ * CPP))/(dntn_cnt_/1.0000) ELSE 0
		                END) npd,
		                    (
		                CASE
		                    WHEN dntn_amt_>0 THEN (mail_cnt_ * CPP)/(dntn_amt_/1.0000) ELSE 0
		                END) ctrd,
		                    (
		                CASE
		                    WHEN mail_cnt_>0 THEN dntn_amt_/(mail_cnt_/1000.0000) ELSE 0
		                END) AS rpm,
		                (
		                CASE
		                    WHEN pct_mature_>0 THEN FLOOR(SUM(CASE WHEN a.dir_dntn_amt>=1000 THEN 1 ELSE 0 END)/pct_mature_) 
		                    	ELSE SUM(CASE WHEN a.dir_dntn_amt>=1000 THEN 1 ELSE 0 END)
		                END) AS dntn_cnt_1k,
		                (
		                CASE
		                    WHEN pct_mature_>0 THEN FLOOR(SUM(CASE WHEN a.dir_dntn_amt>=1000 THEN a.dir_dntn_amt ELSE 0 END)/pct_mature_) 
		                    	ELSE SUM(CASE WHEN a.dir_dntn_amt>=1000 THEN a.dir_dntn_amt ELSE 0 END)
		                END) AS dntn_amt_1k
		                FROM mktg_ops_tbls.pbi_model_perf_dashbrd a
						LEFT JOIN (select DISTINCT src_key, src_cd, intrctn_dt FROM mktg_stage_tbls.pbi_model_perf_interaction_stg) c on a.src_key=c.src_key
						LEFT JOIN data_lab_mktg_tbls.nr_cdrp_fy_budget b on c.src_cd=b.src_cd
						LEFT JOIN data_lab_mktg_tbls.nr_cfr_dm_pct_mature_days d 
							on a.dm_file=d.dm_file 
							and cast(substring(c.src_cd,6,2) as int)=d.intxn_mth 
							and d.days_post_drop_dt=least((current_date - c.intrctn_dt),365)
						group by 1,
								 2,
								 3,
								 4,
								 5,
								 6,
								 7
		            ) a ;  
		    
		    
		                    
		truncate table mktg_ops_tbls.pbi_model_perf_auc;
		    INSERT	INTO mktg_ops_tbls.pbi_model_perf_auc
		        (src_cd, src_key, pctile_file, scr_mods, pctile_mail_qty_mods, fpr_mods,
		        tpr_mods, cumu_amt_pct_mods, lift_mods, lift_amt_mods, auc_mods,
		        scr_sm, pctile_mail_qty_sm, fpr_sm, tpr_sm, cumu_amt_pct_sm,
		        lift_sm, lift_amt_sm, auc_sm)
		        
		        SELECT x.src_cd,
		        	x.src_key,
		            x.indx AS pctile_file,
		            src_cd_agg_mods3.min_scr AS scr_mods,
		            src_cd_agg_mods3.pctile_mail_qty AS pctile_mail_qty_mods,
		            src_cd_agg_mods3.fpr_ AS fpr_mods,
		            (case when x.indx=0 then coalesce(src_cd_agg_mods3.tpr_,0) else src_cd_agg_mods3.tpr_ end) AS tpr_mods,
		            src_cd_agg_mods3.cumu_amt_pct_ AS cumu_amt_pct_mods,
		            src_cd_agg_mods3.lift AS lift_mods,
		            src_cd_agg_mods3.lift_amt AS lift_amt_mods,
		            src_cd_agg_mods3.auc AS auc_mods,
		            src_cd_agg_sm3.scr AS scr_sm,
		            src_cd_agg_sm3.pctile_mail_qty AS pctile_mail_qty_sm,
		            src_cd_agg_sm3.fpr_ AS fpr_sm,
		            src_cd_agg_sm3.tpr_ AS tpr_sm,
		            src_cd_agg_sm3.cumu_amt_pct_ AS cumu_amt_pct_sm,
		            src_cd_agg_sm3.lift AS lift_sm,
		            src_cd_agg_sm3.lift_amt AS lift_amt_sm,
		            src_cd_agg_sm3.auc AS auc_sm
		            FROM (
		            SELECT src_cd,
		            	src_key,
		                (calendar_doy-1)/100.00 AS indx
		                FROM eda.dw_common_vws.dim_calendar a
		                CROSS JOIN (
		                SELECT DISTINCT src_cd, src_key
		                    FROM mktg_stage_tbls.pbi_model_perf_interaction_stg) b
		                WHERE calendar_yr=2020
		                    AND  calendar_doy<=101 
		            ) x
		            LEFT JOIN (
		            SELECT src_key,
		                CAST(ceiling(cumu_x_pct*100)/100.00 AS DECIMAL(4,2)) AS pctile_file,
		                MIN(scr) AS min_scr,
		                MAX(cumu_mail_pct) pctile_mail_qty,
		                MAX(fpr) fpr_,
		                MAX(tpr) tpr_,
		                MAX(cumu_amt_pct) cumu_amt_pct_,
		                (tpr_ / NULLIF(pctile_file,0)) AS lift,
		                (cumu_amt_pct_ / NULLIF(pctile_file,0)) AS lift_amt,
		                SUM(auc) auc
		                FROM (
		                SELECT src_cd_agg_mods1.src_key,
		                    src_cd_agg_mods1.scr,
		                    src_cd_agg_mods1.cumu_x_pct,
		                    src_cd_agg_mods1.cumu_mail_pct,
		                    src_cd_agg_mods1.fpr,
		                    src_cd_agg_mods1.tpr,
		                    src_cd_agg_mods1.cumu_amt_pct,
		                    LEAD(tpr, 1) IGNORE NULLS OVER (PARTITION BY src_key
		                    ORDER BY scr DESC) AS tpr_lead,
		                        LEAD(fpr, 1) IGNORE NULLS OVER (PARTITION BY src_key
		                    ORDER BY scr DESC) AS fpr_lead,
		                        (
		                    CASE
		                        WHEN num_cnst = total_cnst THEN NULL
		                    ELSE (((tpr + tpr_lead)/2)*(fpr_lead - fpr))
		                    END) AS auc
		                    FROM (
		                    SELECT dim_src1.src_key,
		                        round(mods_fr_scr*100)/100 scr,
		                        src_key_agg_mods.total_cnst,
		                        src_key_agg_mods.total_mail_qty,
		                        src_key_agg_mods.total_resp,
		                        src_key_agg_mods.total_cnt,
		                        src_key_agg_mods.total_amt,
		                        src_key_agg_mods.total_fail,
		                        COUNT(*) num_cnst,
		                        SUM(mail_cnt) mail_cnt_,
		                        SUM(
		                        CASE
		                            WHEN dir_dntn_cnt>0 OR ind_dntn_cnt>0 THEN 1 ELSE 0
		                        END) num_resp,
		                            SUM(dir_dntn_cnt + ind_dntn_cnt) dntn_cnt_,
		                            SUM(dir_dntn_amt + ind_dntn_amt) dntn_amt_,
		                            SUM(num_cnst) OVER (PARTITION BY dim_src1.src_key
		                        ORDER BY scr DESC ROWS UNBOUNDED PRECEDING) AS cumu_x,
		                            SUM(num_resp) OVER (PARTITION BY dim_src1.src_key
		                        ORDER BY scr DESC ROWS UNBOUNDED PRECEDING) AS cumu_y,
		                            SUM(mail_cnt_) OVER (PARTITION BY dim_src1.src_key
		                        ORDER BY scr DESC ROWS UNBOUNDED PRECEDING) AS cumu_mail_qty,
		                            SUM(dntn_cnt_) OVER (PARTITION BY dim_src1.src_key
		                        ORDER BY scr DESC ROWS UNBOUNDED PRECEDING) AS cumu_cnt,
		                            SUM(dntn_amt_) OVER (PARTITION BY dim_src1.src_key
		                        ORDER BY scr DESC ROWS UNBOUNDED PRECEDING) AS cumu_amt,
		                            cumu_x - cumu_y AS cumu_f,
		                            (
		                        CASE
		                            WHEN total_cnst>0 THEN cumu_x / (total_cnst/1.0000) ELSE 0
		                        END) AS cumu_x_pct,
		                            (
		                        CASE
		                            WHEN total_mail_qty>0 THEN cumu_mail_qty / (total_mail_qty/1.0000) ELSE 0
		                        END) AS cumu_mail_pct,
		                            (
		                        CASE
		                            WHEN total_cnt>0 THEN cumu_cnt / (total_cnt/1.0000) ELSE 0
		                        END) AS cumu_cnt_pct,
		                            (
		                        CASE
		                            WHEN total_amt>0 THEN cumu_amt / (total_amt/1.0000) ELSE 0
		                        END) AS cumu_amt_pct,
		                            (
		                        CASE
		                            WHEN total_resp>0 THEN cumu_y / (total_resp/1.0000) ELSE 0
		                        END) AS tpr,
		                            (
		                        CASE
		                            WHEN total_fail>0 THEN cumu_f / (total_fail/1.0000) ELSE 0
		                        END) AS fpr,
		                            (
		                        CASE
		                            WHEN cumu_x_pct=0 THEN 0 ELSE tpr / cumu_x_pct
		                        END) AS lift
		                        FROM mktg_ops_tbls.pbi_model_perf_dashbrd perf_dashbrd1
		                        LEFT JOIN (SELECT DISTINCT src_key FROM mktg_stage_tbls.pbi_model_perf_interaction_stg) dim_src1 ON perf_dashbrd1.src_key=dim_src1.src_key
		                        LEFT JOIN (
		                        SELECT src_key,
		                            COUNT(*) total_cnst,
		                            SUM(mail_cnt) total_mail_qty,
		                            SUM((
		                            CASE
		                                WHEN dir_dntn_cnt>0 OR ind_dntn_cnt>0 THEN 1 ELSE 0
		                            END)) total_resp,
		                                SUM(dir_dntn_cnt + ind_dntn_cnt) total_cnt,
		                                SUM(dir_dntn_amt + ind_dntn_amt) total_amt,
		                                total_cnst - total_resp AS total_fail
		                            FROM mktg_ops_tbls.pbi_model_perf_dashbrd
		                            WHERE mods_fr_scr IS NOT NULL and mods_fr_scr <> 0
		                            GROUP BY 1
		                        ) src_key_agg_mods ON perf_dashbrd1.src_key=src_key_agg_mods.src_key
		                        WHERE mods_fr_scr IS NOT NULL and mods_fr_scr <> 0
		                        GROUP BY 1,
		                            2,
		                            3,
		                            4,
		                            5,
		                            6,
		                            7,
		                            8
		                    ) src_cd_agg_mods1
		                ) src_cd_agg_mods2
		                GROUP BY 1,
		                    2
		            ) src_cd_agg_mods3 ON x.src_key=src_cd_agg_mods3.src_key AND x.indx=src_cd_agg_mods3.pctile_file
		            	
		            	
		            LEFT OUTER JOIN 
		            (
		            SELECT src_key,
		                MAX(scr) scr,
		                CAST(ceiling(cumu_x_pct*100)/100.00 AS DECIMAL(4,2)) AS pctile_file,
		                MAX(cumu_mail_pct) pctile_mail_qty,
		                MAX(fpr) fpr_,
		                MAX(tpr) tpr_,
		                MAX(cumu_amt_pct) cumu_amt_pct_,
		                (tpr_ / NULLIF(pctile_file,0)) AS lift,
		                (cumu_amt_pct_ / NULLIF(pctile_file,0)) AS lift_amt,
		                    SUM(auc) auc
		                FROM (
		                SELECT src_cd_agg_sm1.src_key,
		                    src_cd_agg_sm1.scr,
		                    src_cd_agg_sm1.cumu_x_pct,
		                    src_cd_agg_sm1.cumu_mail_pct,
		                    src_cd_agg_sm1.fpr,
		                    src_cd_agg_sm1.tpr,
		                    src_cd_agg_sm1.cumu_amt_pct,
		                    LEAD(tpr, 1) IGNORE NULLS OVER (PARTITION BY src_key
		                    ORDER BY scr ASC) AS tpr_lead,
		                        LEAD(fpr, 1) IGNORE NULLS OVER (PARTITION BY src_key
		                    ORDER BY scr ASC) AS fpr_lead,
		                        (
		                    CASE
		                        WHEN num_cnst = total_cnst THEN NULL
		                    ELSE (((tpr + tpr_lead)/2)*(fpr_lead - fpr))
		                    END) AS auc
		                    FROM (
		                    SELECT dim_src2.src_key,
		                        sm_children_scr AS scr,
		                        src_key_agg_sm.total_cnst,
		                        src_key_agg_sm.total_mail_qty,
		                        src_key_agg_sm.total_resp,
		                        src_key_agg_sm.total_cnt,
		                        src_key_agg_sm.total_amt,
		                        src_key_agg_sm.total_fail,
		                        COUNT(*) num_cnst,
		                        SUM(mail_cnt) mail_cnt_,
		                        SUM(
		                        CASE
		                            WHEN dir_dntn_cnt>0 OR ind_dntn_cnt>0 THEN 1 ELSE 0
		                        END) num_resp,
		                            SUM(dir_dntn_cnt + ind_dntn_cnt) dntn_cnt_,
		                            SUM(dir_dntn_amt + ind_dntn_amt) dntn_amt_,
		                            SUM(num_cnst) OVER (PARTITION BY dim_src2.src_key
		                        ORDER BY scr ASC ROWS UNBOUNDED PRECEDING) AS cumu_x,
		                            SUM(num_resp) OVER (PARTITION BY dim_src2.src_key
		                        ORDER BY scr ASC ROWS UNBOUNDED PRECEDING) AS cumu_y,
		                            SUM(mail_cnt_) OVER (PARTITION BY dim_src2.src_key
		                        ORDER BY scr ASC ROWS UNBOUNDED PRECEDING) AS cumu_mail_qty,
		                            SUM(dntn_cnt_) OVER (PARTITION BY dim_src2.src_key
		                        ORDER BY scr ASC ROWS UNBOUNDED PRECEDING) AS cumu_cnt,
		                            SUM(dntn_amt_) OVER (PARTITION BY dim_src2.src_key
		                        ORDER BY scr ASC ROWS UNBOUNDED PRECEDING) AS cumu_amt,
		                            cumu_x - cumu_y AS cumu_f,
		                            (
		                        CASE
		                            WHEN total_cnst>0 THEN cumu_x / (total_cnst/1.0000) ELSE 0
		                        END) AS cumu_x_pct,
		                            (
		                        CASE
		                            WHEN total_mail_qty>0 THEN cumu_mail_qty / (total_mail_qty/1.0000) ELSE 0
		                        END) AS cumu_mail_pct,
		                            (
		                        CASE
		                            WHEN total_cnt>0 THEN cumu_cnt / (total_cnt/1.0000) ELSE 0
		                        END) AS cumu_cnt_pct,
		                            (
		                        CASE
		                            WHEN total_amt>0 THEN cumu_amt / (total_amt/1.0000) ELSE 0
		                        END) AS cumu_amt_pct,
		                            (
		                        CASE
		                            WHEN total_resp>0 THEN cumu_y / (total_resp/1.0000) ELSE 0
		                        END) AS tpr,
		                            (
		                        CASE
		                            WHEN total_fail>0 THEN cumu_f / (total_fail/1.0000) ELSE 0
		                        END) AS fpr,
		                            (
		                        CASE
		                            WHEN cumu_x_pct=0 THEN 0 ELSE tpr / cumu_x_pct
		                        END) AS lift
		                        FROM mktg_ops_tbls.pbi_model_perf_dashbrd perf_dashbrd2
		                        LEFT JOIN (SELECT DISTINCT src_key FROM mktg_stage_tbls.pbi_model_perf_interaction_stg) dim_src2 ON perf_dashbrd2.src_key=dim_src2.src_key
		                        LEFT JOIN (
		                        SELECT src_key,
		                            COUNT(*) total_cnst,
		                            SUM(mail_cnt) total_mail_qty,
		                            SUM(
		                            CASE
		                                WHEN dir_dntn_cnt>0 OR ind_dntn_cnt>0 THEN 1 ELSE 0
		                            END) total_resp,
		                                SUM(dir_dntn_cnt + ind_dntn_cnt) total_cnt,
		                                SUM(dir_dntn_amt + ind_dntn_amt) total_amt,
		                                total_cnst - total_resp AS total_fail
		                            FROM mktg_ops_tbls.pbi_model_perf_dashbrd
		                            WHERE sm_children_scr IS NOT NULL
		                            GROUP BY 1
		                        ) src_key_agg_sm ON perf_dashbrd2.src_key=src_key_agg_sm.src_key
		                        WHERE sm_children_scr IS NOT NULL
		                        GROUP BY 1,
		                            2,
		                            3,
		                            4,
		                            5,
		                            6,
		                            7,
		                            8
		                    ) src_cd_agg_sm1
		                ) src_cd_agg_sm2
		                GROUP BY 1,
		                    3 ) src_cd_agg_sm3 ON x.src_key=src_cd_agg_sm3.src_key AND x.indx=src_cd_agg_sm3.pctile_file ; 
    

		---audit_log update------
            v_end_time := GETDATE();
			v_ok_message = 'Records inserted.';
        
			UPDATE mods_bi.etl_config.audit_log
			SET status = 'Complete', end_time = v_end_time, TaskMessage = v_ok_message, recs_processed = cast((select count(*) from mods_bi.mktg_ops_tbls.pbi_model_perf_dashbrd) as INTEGER)
			WHERE proc_name = 'ld_pbi_model_perf_dashbrd' 
			AND task_name = 'Stored Procedure' 
			AND start_time = v_start_time;
       
--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_pbi_model_perf_dashbrd', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$_$
