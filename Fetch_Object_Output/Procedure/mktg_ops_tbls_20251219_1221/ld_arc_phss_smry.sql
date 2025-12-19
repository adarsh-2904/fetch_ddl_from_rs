CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_arc_phss_smry()
 LANGUAGE plpgsql
AS $$

/*
modified by: Adarsh Ram
modified date: 05/07/2025
Purpose: This is conveted from PDO.



*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_arc_phss_smry', 'Stored Procedure', 'Inprogress', v_start_time);


begin
truncate table mktg_stage_tbls.arc_phss_smry_stg;

insert into mktg_stage_tbls.arc_phss_smry_stg(
cnst_mstr_id, cnst_hsld_id, length_of_engagmnt, 
  yr_takn_crs, fst_crs_cmptn_dt, last_rgstn_mthd, 
  last_crs_cmptn_dt, last_crs_cmptn, 
  last_crs_subject_area, last_crs_delivery_typ, 
  nxt_rc_crs_delivery_typ, lftm_crs_complt_cnt, 
  lftm_pro_cpr_crs_complt_cnt, lftm_Lay_cpr_crs_complt_cnt, 
  lftm_aqtcs_crs_complt_cnt, lftm_caregvng_crs_complt_cnt, 
  lftm_nrse_trn_crs_complt_cnt, lftm_othr_crs_complt_cnt, 
  lftm_crs_spnd_amt, lftm_coupon_svngs_amt, 
  lftm_avg_cst_per_crs_amt, lftm_w_b_cmplt_pct, 
  lftm_clrm_cmplt_pct,  
  lftm_bl_wc_cmplt_pct, lftm_othr_cmplt_pct, 
  lftm_ap_crs_cmplt_pct, lftm_fs_crs_cmplt_pct, 
  lftm_cmnty_crs_cmplt_pct, lftm_othr_crs_cmplt_pct, 
  lftm_stndt_drp_class_rt, lftm_arc_cancld_class_rt, 
  lftm_stndt_fail_class_cnt, last_pro_cpr_crs_dt, 
  last_pro_cpr_recert_dt, fst_pro_cpr_crs_dt, 
  last_pro_cpr_tot_spnd_amt, last_lay_cpr_crs_dt, 
  last_lay_cpr_recert_dt, fst_lay_cpr_crs_dt, 
  last_lay_cpr_tot_spnd_amt, last_aqtcs_crs_dt, 
  last_aqtcs_recert_dt, fst_aqtcs_crs_dt, 
  last_aqtcs_tot_spnd_amt, last_caregiving_crs_dt, 
  last_caregiving_recert_dt, fst_caregiving_crs_dt, 
  last_caregiving_tot_spnd_amt, last_nrse_trn_crs_dt, 
  last_nrse_trn_recert_dt, fst_nrse_trn_crs_dt, 
  last_nrse_trn_tot_spnd_amt, last_othr_crs_dt, 
  last_othr_recert_dt, fst_othr_crs_dt, 
  last_othr_tot_spnd_amt, tot_cmpnts_cmplt_cnt, 
  tot_cmpnt_cmplt_1yrcert_cnt, tot_cmpnt_cmplt_2yrcert_cnt, 
  tot_cmpnt_cmplt_3yrcert_cnt, tot_cmpnts_passed_cnt, 
  tot_cmpnts_fld_cnt, tot_cmpnts_nt_evltd_cnt,  
  upcmng_recert_1_dt, upcmng_recert_1_crs_nm, 
  upcmng_recert_2_dt, upcmng_recert_2_crs_nm, 
  upcmng_recert_3_dt, upcmng_recert_3_crs_nm, 
  upcmng_refresh_1_typ, upcmng_refresh_1_crs_nm, 
  upcmng_refresh_2_typ, upcmng_refresh_2_crs_nm, 
  upcmng_refresh_3_typ, upcmng_refresh_3_crs_nm, 
  lst_cancltn_dt, lst_cancltn_class_nm, 
  course_taker_ind, 
  first_dmw_store_dt, last_dmw_store_dt, 
  first_dmw_course_dt, last_dmw_course_dt, 
  instr_cnt, bst_cnt, nat_cnt, spanish_cnt, 
  course_cnt, unique_student_cnt, 
  student_match_cnt, instr_flg, bst_only_flg, 
  nat_only_flg, spanish_only_flg, 
  student_only_flg, student_bill_prsn_flg, 
  last_engmnt_dt, dw_trans_ts, appl_src_cd,
  load_id
)


with temp_smry as(
select
      pref.cnst_mstr_id as cnst_mstr_id,
      pref.cnst_hsld_id as cnst_hsld_id,
      coalesce(arc_phss_txn_main.phss_length_of_engagmnt,0)  as length_of_engagmnt,
      coalesce(arc_phss_txn_main.phss_Yr_takn_crs,0)  as yr_takn_crs,
      coalesce(arc_phss_txn_main.phss_tot_cmpnts_cmplt,0)  as tot_cmpnts_cmplt_cnt,
      coalesce(arc_phss_txn_main.phss_tot_cmpnt_cmplt_1yrcert,0)  as tot_cmpnt_cmplt_1yrcert_cnt,
      coalesce(arc_phss_txn_main.phss_tot_cmpnt_cmplt_2yrcert,0)  as tot_cmpnt_cmplt_2yrcert_cnt,
      coalesce(arc_phss_txn_main.phss_tot_cmpnt_cmplt_3yrcert,0)  as tot_cmpnt_cmplt_3yrcert_cnt,
      coalesce(arc_phss_txn_main.phss_tot_cmpnts_passed,0) as tot_cmpnts_passed_cnt,
      coalesce(arc_phss_txn_main.phss_tot_cmpnts_fld,0) as tot_cmpnts_fld_cnt,
      coalesce(arc_phss_txn_main.phss_tot_cmpnts_nt_evltd,0) as tot_cmpnts_nt_evltd_cnt,
      coalesce(arc_phss_txn_main.phss_lftm_stndt_drp_class,0)  as lftm_stndt_drp_class_rt,
      coalesce(arc_phss_txn_main.phss_lftm_ARC_drp_class,0) lftm_arc_cancld_class_rt,
      coalesce(arc_phss_txn_main.phss_lftm_stndt_fail_class,0)  as lftm_stndt_fail_class_cnt,
      coalesce(arc_phss_txn_main.phss_lftm_crs_spnd,0.00)  as lftm_crs_spnd_amt,
      coalesce(arc_phss_txn_main.phss_lftm_coupon_svngs,0.00)  as lftm_coupon_svngs_amt,
      coalesce(arc_phss_txn_main.phss_lftm_avg_cst_per_crs,0.00) as lftm_avg_cst_per_crs_amt,
      coalesce(arc_phss_txn_main.phss_last_pro_CPR_tot_spnd,0.00)  as last_pro_cpr_tot_spnd_amt,
      coalesce(arc_phss_txn_main.phss_last_lay_CPR_tot_spnd,0.00)  as last_lay_cpr_tot_spnd_amt,
      coalesce(arc_phss_txn_main.phss_last_aqtcs_tot_spnd,0.00) as last_aqtcs_tot_spnd_amt,
      coalesce(arc_phss_txn_main.phss_last_caregiving_tot_spnd,0.00)  as last_caregiving_tot_spnd_amt,
      coalesce(arc_phss_txn_main.phss_last_nrse_trn_tot_spnd,0.00)  as last_nrse_trn_tot_spnd_amt,
      coalesce(arc_phss_txn_main.phss_last_othr_tot_spnd,0.00)  as last_othr_tot_spnd_amt,
      arc_phss_txn_last_all.phss_last_rgstn_mthd as last_rgstn_mthd,  
      arc_phss_txn_last_all_can.phss_lst_cancltn_class as lst_cancltn_class_nm,
      arc_phss_txn_last_all_can.phss_lst_cancltn_dt as lst_cancltn_dt,
      arc_phss_txn_last_succ.phss_last_crs_cmptn as last_crs_cmptn,
      arc_phss_txn_last_succ.phss_last_crs_subject_area as last_crs_subject_area,
      arc_phss_txn_last_succ.phss_last_crs_delivery_typ as last_crs_delivery_typ,
      arc_phss_txn_succ.phss_fst_crs_cmptn_dt as fst_crs_cmptn_dt,
      arc_phss_txn_succ.phss_last_crs_cmptn_dt as last_crs_cmptn_dt,
      coalesce(arc_phss_txn_succ.phss_lftm_crs_complt,0)  as lftm_crs_complt_cnt,
      coalesce(arc_phss_txn_succ.phss_lftm_pro_CPR_crs_complt,0)  as lftm_pro_cpr_crs_complt_cnt,
      coalesce(arc_phss_txn_succ.phss_lftm_Lay_CPR_crs_complt,0)  as lftm_Lay_cpr_crs_complt_cnt,
      coalesce(arc_phss_txn_succ.phss_lftm_Aqtcs_crs_complt,0) as lftm_aqtcs_crs_complt_cnt,
      coalesce(arc_phss_txn_succ.phss_lftm_caregvng_crs_complt,0) as lftm_caregvng_crs_complt_cnt,
      coalesce(arc_phss_txn_succ.phss_lftm_nrse_trn_crs_complt,0) as lftm_nrse_trn_crs_complt_cnt,
      coalesce(arc_phss_txn_succ.phss_lftm_othr_crs_complt,0) as lftm_othr_crs_complt_cnt,
      coalesce(arc_phss_txn_succ.phss_lftm_p_w_b_Cmplt,0.00) as lftm_w_b_cmplt_pct,
      coalesce(arc_phss_txn_succ.phss_lftm_p_clrm_Cmp,0.00) as lftm_clrm_cmplt_pct,
      coalesce(arc_phss_txn_succ.phss_lftm_p_bl_wc_cmplt,0.00)  as lftm_bl_wc_cmplt_pct,
      coalesce(arc_phss_txn_succ.phss_lftm_p_othr_cmplt,0.00)  as lftm_othr_cmplt_pct,
      coalesce(arc_phss_txn_succ.phss_lftm_p_AP_crs_cmplt,0.00)  as lftm_ap_crs_cmplt_pct,
      coalesce(arc_phss_txn_succ.phss_lftm_p_FS_crs_cmplt,0.00) as lftm_fs_crs_cmplt_pct,
      coalesce(arc_phss_txn_succ.phss_lftm_p_cmnty_crs_cmplt,0.00)  as lftm_cmnty_crs_cmplt_pct,
      coalesce(arc_phss_txn_succ.phss_lftm_p_othr_crs_cmplt,0.00) as lftm_othr_crs_cmplt_pct,
      arc_phss_txn_succ.phss_last_pro_CPR_crs_dt as last_pro_cpr_crs_dt,
      arc_phss_txn_succ.phss_fst_pro_CPR_crs_dt as fst_pro_cpr_crs_dt,      
      arc_phss_txn_succ.phss_last_lay_CPR_crs_dt as last_lay_cpr_crs_dt,
      arc_phss_txn_succ.phss_fst_lay_CPR_crs_dt as fst_lay_cpr_crs_dt,      
      arc_phss_txn_succ.phss_last_aqtcs_crs_dt as last_aqtcs_crs_dt,
      arc_phss_txn_succ.phss_fst_aqtcs_crs_dt as fst_aqtcs_crs_dt,
      arc_phss_txn_succ.phss_last_caregiving_crs_dt as last_caregiving_crs_dt,
      arc_phss_txn_succ.phss_fst_caregiving_crs_dt as fst_caregiving_crs_dt,      
      arc_phss_txn_succ.phss_last_nrse_trn_crs_dt as last_nrse_trn_crs_dt,
      arc_phss_txn_succ.phss_fst_nrse_trn_crs_dt as fst_nrse_trn_crs_dt,
      arc_phss_txn_succ.phss_last_othr_crs_dt as last_othr_crs_dt,
      arc_phss_txn_succ.phss_fst_othr_crs_dt as fst_othr_crs_dt,
      arc_phss_txn_recert_main.phss_upcmng_recert_dt_1 as upcmng_recert_1_dt,
      arc_phss_txn_recert_main.phss_upcmng_recert_crs_1 as upcmng_recert_1_crs_nm,
      arc_phss_txn_recert_main.phss_nxt_rc_crs_delivery_typ as nxt_rc_crs_delivery_typ,
      arc_phss_txn_recert_main.phss_upcmng_recert_dt_2 as upcmng_recert_2_dt,
      arc_phss_txn_recert_main.phss_upcmng_recert_crs_2 as upcmng_recert_2_crs_nm,
      arc_phss_txn_recert_main.phss_upcmng_recert_dt_3 as upcmng_recert_3_dt,
      arc_phss_txn_recert_main.phss_upcmng_recert_crs_3 as upcmng_recert_3_crs_nm,
      arc_phss_txn_recert_main.phss_last_pro_CPR_recert_dt as last_pro_cpr_recert_dt,
      arc_phss_txn_recert_main.phss_last_lay_CPR_recert_dt as last_lay_cpr_recert_dt,
      arc_phss_txn_recert_main.phss_last_aqtcs_recert_dt as last_aqtcs_recert_dt,
      arc_phss_txn_recert_main.phss_last_caregiving_recert_dt as last_caregiving_recert_dt,
      arc_phss_txn_recert_main.phss_last_nrse_trn_recert_dt as last_nrse_trn_recert_dt, 
      arc_phss_txn_recert_main.phss_last_othr_recert_dt as last_othr_recert_dt,
      arc_phss_txn_ref_main.phss_upcmng_refresh_1 as upcmng_refresh_1_typ,
      arc_phss_txn_ref_main.phss_upcmng_refresh_crs_1 as upcmng_refresh_1_crs_nm,
      arc_phss_txn_ref_main.phss_upcmng_refresh_2 as upcmng_refresh_2_typ,
      arc_phss_txn_ref_main.phss_upcmng_refresh_crs_2 as upcmng_refresh_2_crs_nm,
      arc_phss_txn_ref_main.phss_upcmng_refresh_3 as upcmng_refresh_3_typ,
      arc_phss_txn_ref_main.phss_upcmng_refresh_crs_3 as upcmng_refresh_3_crs_nm,
      case when (dmwc.first_dmw_course_dt is not null or arc_phss_txn_succ.phss_fst_crs_cmptn_dt is not null) then 1 else 0 end as course_taker_ind, 
      -- not needed----
--      case when (dmws.first_dmw_store_dt is not null or rcs_cnst.cnst_mstr_id is not null) then 1 else 0 end as rcs_buyer_ind, 
	  /* Below are the first and last store and course order dates from the DemandWare system data */
	  dmws.first_dmw_store_dt as first_dmw_store_dt, 
	  dmws.last_dmw_store_dt as last_dmw_store_dt,
	  dmwc.first_dmw_course_dt as first_dmw_course_dt, 
	  dmwc.last_dmw_course_dt as last_dmw_course_dt,
	  dmwc.instr_cnt as instr_cnt, 
	  dmwc.bst_cnt as bst_cnt, 
	  dmwc.nat_cnt as nat_cnt, 
	  dmwc.spanish_cnt as spanish_cnt, 
	  dmwc.course_cnt as course_cnt, 
	  dmwc.unique_student_cnt as unique_student_cnt, 
	  dmwc.student_match_cnt as student_match_cnt, 
	  dmwc.instr_flg as instr_flg, 
	  dmwc.bst_only_flg as bst_only_flg, 
	  dmwc.nat_only_flg as nat_only_flg, 
	  dmwc.spanish_only_flg as spanish_only_flg, 
	  dmwc.student_only_flg as student_only_flg, 
	  dmwc.bill_prsn_only_flg,
	  dmwc.student_bill_prsn_flg as student_bill_prsn_flg,
	 NULLIF(
  GREATEST(
    COALESCE(phss_last_crs_cmptn_dt, TO_DATE('01/01/1900', 'MM/DD/YYYY')),
    COALESCE(last_dmw_store_dt, TO_DATE('01/01/1900', 'MM/DD/YYYY')),
    COALESCE(last_dmw_course_dt, TO_DATE('01/01/1900', 'MM/DD/YYYY'))
  ),
  TO_DATE('01/01/1900', 'MM/DD/YYYY')
) as last_engmnt_dt,
     current_timestamp as dw_trans_ts 
 
 from mktg_ops_tbls.cnst_cdi_smry_phss_prfr pref
  left join 
( 
  select arc_phss_txn.cnst_mstr_id,
      arc_phss_txn.cnst_hsld_id,
       max(arc_phss_txn.offer_start_dt) offer_start_dt_max,
       min(arc_phss_txn.offer_start_dt) offer_start_dt_min,
  /* Getting the length of engagement of the Constituent with ARC*/
      (current_date - offer_start_dt_min) phss_length_of_engagmnt,
  /* Getting the count of number of years constituent has taken courses*/
      count (distinct extract( year from arc_phss_txn.offer_start_dt)) phss_Yr_takn_crs,
    /* Getting the total money spent by a constitunet on taking ARC courses in his lifetime */
      sum(tot_payment_amt) phss_lftm_crs_spnd,
     /* Getting the total coupon savings received by constitunet while buying ARC courses in his lifetime */
      sum(coupn_amt) phss_lftm_coupon_svngs,
      count(0) tot_crs,
      /* Getting the Average cost per a course by a constitunet while buying ARC courses in his in his lifetime */
      case when tot_crs <> 0 then
      phss_lftm_crs_spnd / tot_crs
      else
      0
      end phss_lftm_avg_cst_per_crs,
      /* Getting the count of number of  PRO CPR couses taken in the constituent life time*/
      sum(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE '%FA/CPR%' and upper(arc_phss_txn.FOCIS_PGM) LIKE '%PRO%')) then arc_phss_txn.tot_payment_amt else 0 end) 
phss_last_pro_CPR_tot_spnd,
      /* Getting the count of number of  LAY CPR couses taken in the constituent life time*/
      sum(case when ((upper(FOCIS_PGM) LIKE '%FA/CPR%' and upper(FOCIS_PGM) LIKE '%LAY%') ) then arc_phss_txn.tot_payment_amt else 0 end) phss_last_lay_CPR_tot_spnd,
      /* Getting the count of number of  Acquatics couses taken in the constituent life time*/
      sum(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE '%AQUATICS%' or upper(arc_phss_txn.FOCIS_PGM) LIKE '%LIFEGUARDING%'  or 
       upper(arc_phss_txn.FOCIS_PGM) LIKE '%SWIMMING%' or upper(arc_phss_txn.FOCIS_PGM) LIKE '%WATER SAFETY%'))  then arc_phss_txn.tot_payment_amt else 0 end) 
phss_last_aqtcs_tot_spnd,
        /* Getting the count of number of  NURSE Training couses taken in the constituent life time*/
      sum(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE 'NURSE%'))  then arc_phss_txn.tot_payment_amt else 0 end) phss_last_nrse_trn_tot_spnd,
     /* Getting the count of number of  care giving couses taken in the constituent life time*/
      sum(case when ((upper(arc_phss_txn.SUBJECT_AREA) LIKE 'A4%' and upper(arc_phss_txn.FOCIS_PGM) not in 
     ('CHAPTER%' , 'NURSE%' ,'UNSPECIFIED'))) then arc_phss_txn.tot_payment_amt else 0 end) phss_last_caregiving_tot_spnd,
     /* Getting the count of number of  other couses taken in the constituent life time*/
     sum(case when ((upper(SUBJECT_AREA) NOT IN  ('A1%' ,'A3%' ,'A4%' ))) then arc_phss_txn.tot_payment_amt else 0 end) phss_last_othr_tot_spnd,
     /* Getting the count of total components completed in the constituent life time*/
     sum(course_totl_comp_mastrd_cnt) phss_tot_cmpnts_cmplt,
     /* Getting the count of total components passed in the constituent life time*/
     sum(course_totl_comp_mastrd_cnt) phss_tot_cmpnts_passed,
     /* Getting the count of total components  failed in the constituent life time*/
     sum(course_totl_comp_fail_cnt) phss_tot_cmpnts_fld,
     /* Getting the count of total components not evalutaed in the constituent life time*/
     sum(course_totl_comp_not_evltd_cnt) phss_tot_cmpnts_nt_evltd,
     /* Getting the count of total  1 year cert components completed in the constituent life time*/
     sum(course_tot_comp_1yrcert_cnt) phss_tot_cmpnt_cmplt_1yrcert,
     /* Getting the count of total  2 year components  completed in the constituent life time*/
     sum(course_tot_comp_2yrcert_cnt) phss_tot_cmpnt_cmplt_2yrcert,
     /* Getting the count of total 3 year components completed in the constituent life time*/
     sum(course_tot_comp_3yrcert_cnt) phss_tot_cmpnt_cmplt_3yrcert,
     /* Getting the count of total ARC Cancelled courses n the constituent life time*/
     sum(case when lower(course_delivery_stat) = 'cancelled . normal' then 1 else 0 end) phss_lftm_ARC_drp_class,
     /* Getting the count of total student cancelled courses n the constituent life time*/
     sum(case when lower(course_enrlmnt_stat) = 'dropped' then 1 else 0 end) phss_lftm_stndt_drp_class,
     /* Getting the count of total failed couses in the constituent life time*/
     sum(case when course_compl_stat = 'COURSE FAILURE' then 1 else 0 end) phss_lftm_stndt_fail_class
          
 from mktg_ops_tbls.arc_phss_txn arc_phss_txn
 group by
arc_phss_txn.cnst_mstr_id,
arc_phss_txn.cnst_hsld_id 

) arc_phss_txn_main on pref.cnst_mstr_id = arc_phss_txn_main.cnst_mstr_id

--left outer join 
-- arc_store_vws.bzl_dim_prsn_mstr rcs_cnst on arc_phss_txn_main.cnst_mstr_id=rcs_cnst.cnst_mstr_id
 /*Join to get the last registration method used by a constituent */
left outer join
(
	
with subqry as (select arc_phss_txn.cnst_mstr_id,
       arc_phss_txn.order_reg_method phss_last_rgstn_mthd ,
       row_number() over (partition by arc_phss_txn.cnst_mstr_id order by arc_phss_txn.offer_end_dt desc,arc_phss_txn.order_reg_method) as rn
 from 
 mktg_ops_tbls.arc_phss_txn arc_phss_txn)
 
 select subqry.cnst_mstr_id, subqry.phss_last_rgstn_mthd from subqry where rn=1
) arc_phss_txn_last_all  on arc_phss_txn_last_all.cnst_mstr_id = arc_phss_txn_main.cnst_mstr_id
left outer join
(
 
 with cte as(select arc_phss_txn.cnst_mstr_id,
        arc_phss_txn.course_nm  phss_lst_cancltn_class,
        arc_phss_txn.offer_cancellation_dt phss_lst_cancltn_dt,
        row_number() over (partition by arc_phss_txn.cnst_mstr_id order by arc_phss_txn.offer_cancellation_dt desc) as rn
 from 
 mktg_ops_tbls.arc_phss_txn arc_phss_txn
 )
 
 select cte.cnst_mstr_id,cte.phss_lst_cancltn_class, cte.phss_lst_cancltn_dt from cte where rn=1

) arc_phss_txn_last_all_can  on arc_phss_txn_last_all_can.cnst_mstr_id = arc_phss_txn_main.cnst_mstr_id

left outer join
(
 
select  arc_phss_txn.cnst_mstr_id,
       arc_phss_txn.course_num phss_last_crs_cmptn,
       arc_phss_txn.subject_Area phss_last_crs_subject_area,
       arc_phss_txn.course_delivery_typ phss_last_crs_delivery_typ             
 from 
 mktg_ops_tbls.arc_phss_txn arc_phss_txn
  where
  arc_phss_txn.course_compl_stat = 'COURSE SUCCESS' 
  /*This gives the latest constitunet course success date and its corresponding columns viz. subject are, delivery type etc.*/
  qualify  row_number() over (partition by arc_phss_txn.cnst_mstr_id order by arc_phss_txn.offer_end_dt desc,arc_phss_txn.course_num) =1
) arc_phss_txn_last_succ  on arc_phss_txn_last_succ.cnst_mstr_id = arc_phss_txn_main.cnst_mstr_id

left outer join
(
  select arc_phss_txn.cnst_mstr_id ,
/* Getting the latest oourse completion date of a constituent in his lifetime */
max(arc_phss_txn.offer_end_dt) phss_last_crs_cmptn_dt,
/* Getting the oldest oourse completion date of a constituent in his lifetime */
min(arc_phss_txn.offer_end_dt) phss_fst_crs_cmptn_dt,
/* Getting the total successful courses of a constituent in his lifetime */
sum(course_attd_cnt)  phss_lftm_crs_complt,
/* Getting the total successful PRO CPR courses of a constituent in his lifetime */
sum(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE '%FA/CPR%' and upper(arc_phss_txn.FOCIS_PGM) LIKE '%PRO%')) then arc_phss_txn.course_attd_cnt else 0 end) 
phss_lftm_pro_CPR_crs_complt,
/* Getting the total successful LAY CPR courses  of a constituent in his lifetime */
sum(case when ((upper(FOCIS_PGM) LIKE '%FA/CPR%' and upper(FOCIS_PGM) LIKE '%LAY%') )  then arc_phss_txn.course_attd_cnt else 0 end) phss_lftm_Lay_CPR_crs_complt,
/* Getting the total successful Aquatics courses  of a constituent in his lifetime */
sum(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE '%AQUATICS%' or upper(arc_phss_txn.FOCIS_PGM) LIKE '%LIFEGUARDING%'  or 
   upper(arc_phss_txn.FOCIS_PGM) LIKE '%SWIMMING%' or upper(arc_phss_txn.FOCIS_PGM) LIKE '%WATER SAFETY%'))  then arc_phss_txn.course_attd_cnt else 0 end) 
phss_lftm_Aqtcs_crs_complt,
/* Getting the total successful Caregiving courses  of a constituent in his lifetime */
sum(case when ((upper(arc_phss_txn.SUBJECT_AREA) LIKE 'A4%' and upper(arc_phss_txn.FOCIS_PGM) not in 
('CHAPTER%' , 'NURSE%' ,'UNSPECIFIED'))) then arc_phss_txn.course_attd_cnt else 0 end) phss_lftm_caregvng_crs_complt,
/* Getting the total successful nurse training courses  of a constituent in his lifetime */
sum(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE 'NURSE%'))  then arc_phss_txn.course_attd_cnt else 0 end) phss_lftm_nrse_trn_crs_complt,
/* Getting the total successful other courses  of a constituent in his lifetime */
sum(case when ((upper(SUBJECT_AREA) NOT IN  ('A1%' ,'A3%' ,'A4%' ))) then arc_phss_txn.course_attd_cnt else 0 end) phss_lftm_othr_crs_complt,
sum(case when (lower(arc_phss_txn.course_delivery_typ) = 'self paced') then arc_phss_txn.course_attd_cnt else 0 end) tot_attnd_crs_sp,
sum(case when (lower(arc_phss_txn.course_delivery_typ) = 'classroom') then arc_phss_txn.course_attd_cnt else 0 end) tot_attnd_crs_cr,
sum(case when (lower(arc_phss_txn.course_delivery_typ) = 'web based / classroom' ) then arc_phss_txn.course_attd_cnt else 0 end) tot_attnd_crs_bl,
sum(case when (arc_phss_txn.course_focis_ctg  like  'AP%') then arc_phss_txn.course_attd_cnt else 0 end) tot_attnd_crs_AP,
sum(case when (arc_phss_txn.course_focis_ctg = 'FS') then arc_phss_txn.course_attd_cnt else 0 end) tot_attnd_crs_FS,
sum(case when (arc_phss_txn.course_focis_ctg = 'Community') then arc_phss_txn.course_attd_cnt else 0 end) tot_attnd_crs_CMN,
/* Getting the percentage of  total web based successful courses  of a constituent in his lifetime */
  case when phss_lftm_crs_complt <> 0  then
      100 * tot_attnd_crs_sp / cast (phss_lftm_crs_complt as decimal(18,2))
  else 
      0
  end phss_lftm_p_w_b_Cmplt,
  /* Getting the percentage of total successful class room courses  of a constituent in his lifetime */
  case when phss_lftm_crs_complt <> 0  then
      100 * tot_attnd_crs_cr / cast (phss_lftm_crs_complt as decimal(18,2))
      else 
      0
  end phss_lftm_p_clrm_Cmp,
    /* Getting the percentage of total successful blended courses  of a constituent in his lifetime */
   case when phss_lftm_crs_complt <> 0  then
      100 * tot_attnd_crs_bl / cast (phss_lftm_crs_complt as decimal(18,2))
      else 
      0
  end phss_lftm_p_bl_wc_cmplt,
   /* Getting the percentage of total successful  other courses  of a constituent in his lifetime */
   (100 - (phss_lftm_p_w_b_Cmplt + phss_lftm_p_clrm_Cmp + phss_lftm_p_bl_wc_cmplt))  phss_lftm_p_othr_cmplt,   
    /* Getting the percentage of total successful  AP courses  of a constituent in his lifetime */
    case when phss_lftm_crs_complt <> 0  then
      100 * tot_attnd_crs_AP / cast (phss_lftm_crs_complt as decimal(18,2))
   else 
      0
   end phss_lftm_p_AP_crs_cmplt,
      /* Getting the percentage of total successful  Full service courses  of a constituent in his lifetime */
    case when phss_lftm_crs_complt <> 0  then
      100 * tot_attnd_crs_FS/ cast (phss_lftm_crs_complt as decimal(18,2))
   else 
      0
  end phss_lftm_p_FS_crs_cmplt,
     /* Getting the percentage of total successful  community courses  of a constituent in his lifetime */
     case when phss_lftm_crs_complt <> 0  then
      100 * tot_attnd_crs_CMN / cast (phss_lftm_crs_complt as decimal(18,2))
   else 
      0
  end phss_lftm_p_cmnty_crs_cmplt,
  /* Getting the percentage of total successful  other courses  of a constituent in his lifetime */
   (100 - (phss_lftm_p_AP_crs_cmplt + phss_lftm_p_FS_crs_cmplt + phss_lftm_p_cmnty_crs_cmplt))  phss_lftm_p_othr_crs_cmplt,
  /* Getting the latest successful  PRO CPR course completion date  of a constituent in his lifetime */
max(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE '%FA/CPR%' and upper(arc_phss_txn.FOCIS_PGM) LIKE '%PRO%')) then arc_phss_txn.offer_end_dt else null end) 
phss_last_pro_CPR_crs_dt,
 /* Getting the oldest successful  PRO CPR course completion date  of a constituent in his lifetime */
min(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE '%FA/CPR%' and upper(arc_phss_txn.FOCIS_PGM) LIKE '%PRO%')) then arc_phss_txn.offer_end_dt else null end) 
phss_fst_pro_CPR_crs_dt,
/* Getting the latest successful  LAY CPR course completion date  of a constituent in his lifetime */
max(case when ((upper(FOCIS_PGM) LIKE '%FA/CPR%' and upper(FOCIS_PGM) LIKE '%LAY%') ) then arc_phss_txn.offer_end_dt else null end) phss_last_lay_CPR_crs_dt,
 /* Getting the oldest successful  LAY CPR course completion date  of a constituent in his lifetime */
min(case when ((upper(FOCIS_PGM) LIKE '%FA/CPR%' and upper(FOCIS_PGM) LIKE '%LAY%') )  then arc_phss_txn.offer_end_dt else null end) phss_fst_lay_CPR_crs_dt,
/* Getting the latest successful  Aquatics course completion date  of a constituent in his lifetime */
max(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE '%AQUATICS%' or upper(arc_phss_txn.FOCIS_PGM) LIKE '%LIFEGUARDING%'  or 
   upper(arc_phss_txn.FOCIS_PGM) LIKE '%SWIMMING%' or upper(arc_phss_txn.FOCIS_PGM) LIKE '%WATER SAFETY%'))  then arc_phss_txn.offer_end_dt else null end) 
phss_last_aqtcs_crs_dt,
 /* Getting the oldest successful  Aquatics course completion date  of a constituent in his lifetime */
min(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE '%AQUATICS%' or upper(arc_phss_txn.FOCIS_PGM) LIKE '%LIFEGUARDING%'  or 
   upper(arc_phss_txn.FOCIS_PGM) LIKE '%SWIMMING%' or upper(arc_phss_txn.FOCIS_PGM) LIKE '%WATER SAFETY%'))  then arc_phss_txn.offer_end_dt else null end) 
phss_fst_aqtcs_crs_dt,
/* Getting the latest successful   Nurse Training course completion date  of a constituent in his lifetime */
max(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE 'NURSE%'))  then arc_phss_txn.offer_end_dt else null end) phss_last_nrse_trn_crs_dt,
 /* Getting the oldest successful   Nurse Training  course completion date  of a constituent in his lifetime */
min(case when ((upper(arc_phss_txn.FOCIS_PGM) LIKE 'NURSE%'))  then arc_phss_txn.offer_end_dt else null end) phss_fst_nrse_trn_crs_dt,
/* Getting the latest successful  Care Giving course completion date  of a constituent in his lifetime */
max(case when ((upper(arc_phss_txn.SUBJECT_AREA) LIKE 'A4%' and upper(arc_phss_txn.FOCIS_PGM) not in 
('CHAPTER%' , 'NURSE%' ,'UNSPECIFIED'))) then arc_phss_txn.offer_end_dt else null end) phss_last_caregiving_crs_dt, 
 /* Getting the oldest successful  Care Giving course completion date  of a constituent in his lifetime */
min(case when ((upper(arc_phss_txn.SUBJECT_AREA) LIKE 'A4%' and upper(arc_phss_txn.FOCIS_PGM) not in 
('CHAPTER%' , 'NURSE%' ,'UNSPECIFIED')))  then arc_phss_txn.offer_end_dt else null end) phss_fst_caregiving_crs_dt, 
/* Getting the latest successful  other course completion date  of a constituent in his lifetime */
max(case when ((upper(SUBJECT_AREA) NOT IN  ('A1%' ,'A3%' ,'A4%' ))) then arc_phss_txn.offer_end_dt else null end) phss_last_othr_crs_dt,
 /* Getting the oldest successful  other course completion date  of a constituent in his lifetime */
min(case when ((upper(SUBJECT_AREA) NOT IN  ('A1%' ,'A3%' ,'A4%' )))  then arc_phss_txn.offer_end_dt else null end) phss_fst_othr_crs_dt


 from
mktg_ops_tbls.arc_phss_txn arc_phss_txn
where arc_phss_txn.course_compl_stat = 'COURSE SUCCESS' 
group by 
arc_phss_txn.cnst_mstr_id

) arc_phss_txn_succ on arc_phss_txn_succ.cnst_mstr_id = arc_phss_txn_main.cnst_mstr_id

left outer join

(
select arc_phss_txn_recert.cnst_mstr_id,
/* Getting the upcoming first recertification date attributes of a constituent in his lifetime */
      max( case when rn = 1 then  arc_phss_txn_recert.course_nxt_recert_dt else null end) phss_upcmng_recert_dt_1,
      max( case when rn = 1 then   arc_phss_txn_recert.course_nm else null end) phss_upcmng_recert_crs_1,
      max( case when rn = 1 then  arc_phss_txn_recert.course_delivery_typ else null end) phss_nxt_rc_crs_delivery_typ,
  /* Getting the upcoming second recertification date attributes of a constituent in his lifetime */
      max( case when rn = 2 then  arc_phss_txn_recert.course_nxt_recert_dt else null end) phss_upcmng_recert_dt_2,
      max( case when rn = 2 then  arc_phss_txn_recert.course_nm else null end) phss_upcmng_recert_crs_2,
   /* Getting the upcoming third recertification date attributes of a constituent in his lifetime */
      max( case when rn = 3 then  arc_phss_txn_recert.course_nxt_recert_dt else null end) phss_upcmng_recert_dt_3,
      max( case when rn = 3 then  arc_phss_txn_recert.course_nm else null end) phss_upcmng_recert_crs_3,
    /* Getting the upcoming ecertification date of a LAY CPR courses of a constituent in his lifetime */
      min (case when ((upper(arc_phss_txn_recert.FOCIS_PGM) LIKE '%FA/CPR%' and upper(arc_phss_txn_recert.FOCIS_PGM) LIKE '%LAY%') )  then 
arc_phss_txn_recert.course_nxt_recert_dt  else null end) phss_last_lay_CPR_recert_dt,
     /* Getting the upcoming ecertification date of a PRO CPR courses of a constituent in his lifetime */  
      min (case when ((upper(arc_phss_txn_recert.FOCIS_PGM) LIKE '%FA/CPR%' and upper(arc_phss_txn_recert.FOCIS_PGM) LIKE '%PRO%')) then 
arc_phss_txn_recert.course_nxt_recert_dt 
             else null end) phss_last_pro_CPR_recert_dt,
     /* Getting the upcoming ecertification date of a Acquatics courses of a constituent in his lifetime */
      min (case when ((upper(arc_phss_txn_recert.FOCIS_PGM) LIKE '%AQUATICS%' or upper(arc_phss_txn_recert.FOCIS_PGM) LIKE '%LIFEGUARDING%'  or 
              upper(arc_phss_txn_recert.FOCIS_PGM) LIKE '%SWIMMING%' or upper(arc_phss_txn_recert.FOCIS_PGM) LIKE '%WATER SAFETY%'))   then 
arc_phss_txn_recert.course_nxt_recert_dt  
             else null end) phss_last_aqtcs_recert_dt,
     /* Getting the upcoming ecertification date of a Caregiving courses of a constituent in his lifetime */
     min (case when ((upper(arc_phss_txn_recert.SUBJECT_AREA) LIKE 'A4%' and upper(arc_phss_txn_recert.FOCIS_PGM) not in ('CHAPTER%' , 'NURSE%' ,'UNSPECIFIED')))  then
       arc_phss_txn_recert.course_nxt_recert_dt  else null end) phss_last_caregiving_recert_dt,
     /* Getting the upcoming ecertification date of a Nurse Training courses of a constituent in his lifetime */
      min (case when ((upper(arc_phss_txn_recert.FOCIS_PGM) LIKE 'NURSE%'))   then arc_phss_txn_recert.course_nxt_recert_dt  else null end) 
phss_last_nrse_trn_recert_dt,
      /* Getting the upcoming ecertification date of Other courses of a constituent in his lifetime */
      min (case when (upper(arc_phss_txn_recert.SUBJECT_AREA) NOT IN  ('A1%' ,'A3%' ,'A4%' )) then arc_phss_txn_recert.course_nxt_recert_dt else null end) 
phss_last_othr_recert_dt
      
 from     
  /* Getting only courses up for recert*/ 
(
select arc_phss_txn_recert1.cnst_mstr_id,
       arc_phss_txn_recert1.course_nm,
       arc_phss_txn_recert1.course_nxt_recert_dt,
       arc_phss_txn_recert1.course_renewal_period,
       arc_phss_txn_recert1.SUBJECT_AREA,
       arc_phss_txn_recert1.FOCIS_PGM,
       arc_phss_txn_recert1.course_delivery_typ,
       row_number () over(partition by arc_phss_txn_recert1.cnst_mstr_id  order by arc_phss_txn_recert1.course_nxt_recert_dt)  as rn
          
 from       
 /* Getting one row per a successful course which is up for refresh or recert */     
 (
 select 
cnst_mstr_id,
person_key,
course_key,
course_nm,
course_subject_area SUBJECT_AREA,
course_focis_pgm FOCIS_PGM,
course_delivery_typ,
course_refresher_flg,
course_end_date,
cert_exp_dt course_nxt_recert_dt,
renewal_period course_renewal_period
from
(select
cnst_mstr_id,
person_key,
course_key,
course_nm,
course_subject_area,
course_focis_pgm,
course_delivery_typ,
course_refresher_flg,
min(case when comp_per_crs = 1 then max_cal_dt_cmp else min_cal_dt_crs end) course_end_date,
min(case when comp_per_crs = 1 then cert_expire_dt_cmp_max  else cert_expire_dt_cmp end) cert_exp_dt,
case
  --When course is valid for 1 Year, only process Recertifications
  when (cert_exp_dt-course_end_date) = 365 and (current_date-course_end_date)  between 245 and 274  then 'Recert1'
  when (cert_exp_dt-course_end_date) = 365 and (current_date-course_end_date)  between 275 and 304  then 'Recert2'
  when (cert_exp_dt-course_end_date) = 365 and (current_date-course_end_date)  between 305 and 335 then 'Recert3'
  --When course is valid for 2 or 3 Years, process both Refreshers & Recertifications	
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 40   and 70 then 'Refresher1'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 130 and 160  then 'Refresher2'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 220 and 250  then 'Refresher3'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 310 and 340  then 'Refresher4'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 400 and 430  then 'Refresher5'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 490 and 520  then 'Refresher6'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 580 and 609  then 'Refresher7'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 610 and 639  then 'Recert1'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 640 and 669  then 'Recert2'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 670 and 700 then 'Recert3'
  --Validate date ranges for 3 Years..Only here for placeholder 10/12
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 60 and 90  then 'Refresher1'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 150 and 180  then 'Refresher2'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 270 and 300  then 'Refresher3'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 390 and 420  then 'Refresher4'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 510 and 540  then 'Refresher5'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 630 and 660  then 'Refresher6'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 750 and 780  then 'Refresher7'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 975 and 1004  then 'Recert1'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 1005 and 1034  then 'Recert2'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 1005 and 1035 then 'Recert3'
         when (cert_exp_dt = cast ('9999-12-31' as date)) then 'No recert/Refresh'
  else 'OTHER'
 end as renewal_period

from
(select 
cnst_mstr_id,
person_key,
component_key,
comp_valid_for,
comp_end_dt,
course_key,
course_nm,
course_subject_area,
course_focis_pgm,
course_delivery_typ,
course_refresher_flg,
count(component_key) over (partition by  cnst_mstr_id,person_key,course_key) as comp_per_crs,
min(comp_end_dt) over (partition by cnst_mstr_id,person_key,course_key)  min_cal_dt_crs,
max(comp_end_dt) over (partition by  cnst_mstr_id,person_key,component_key)  max_cal_dt_cmp,
(case when comp_valid_for = '1 Year' then 
comp_end_dt + cast ('365' as integer)
else
case when comp_valid_for = '2 Years' then 
comp_end_dt + cast ('730' as integer)
else
case when comp_valid_for = '3 Years' then 
comp_end_dt + cast ('1095' as integer)
else
case when comp_valid_for = 'Does not expire' then 
cast ('9999-12-31' as date)
else
null
end end end end
)as cert_expire_dt_cmp,
(case when comp_valid_for = '1 Year' then 
max_cal_dt_cmp + cast ('365' as integer)
else
case when comp_valid_for = '2 Years' then 
max_cal_dt_cmp + cast ('730' as integer)
else
case when comp_valid_for = '3 Years' then 
max_cal_dt_cmp + cast ('1095' as integer)
else
case when comp_valid_for = 'Does not expire' then 
cast ('9999-12-31' as date)
else
null
end end end end
)as cert_expire_dt_cmp_max

from
(select 
cnst_mstr_id,
person_key,
component_key,
comp_valid_for,
comp_end_dt,
course_key,
course_nm,
course_subject_area,
course_focis_pgm,
course_delivery_typ,
course_refresher_flg
from
mktg_ops_tbls.arc_phss_recert_txn
where course_discontinued_flg = 'N'
qualify (row_number() over (partition by  cnst_mstr_id,person_key,course_key,component_key order by comp_end_dt desc)) =1) recert_main) recert_main2
group by cnst_mstr_id,person_key,course_key,course_nm,course_subject_area,course_focis_pgm,course_delivery_typ,course_refresher_flg) recert_main3
where cert_exp_dt >= current_date and cert_exp_dt <> cast ('9999-12-31' as date) 
 ) arc_phss_txn_recert1
 ) arc_phss_txn_recert
 group by arc_phss_txn_recert.cnst_mstr_id
 
) arc_phss_txn_recert_main  on arc_phss_txn_recert_main.cnst_mstr_id = arc_phss_txn_main.cnst_mstr_id

 left outer join
 (
  select arc_phss_txn_ref.cnst_mstr_id,
/* Getting the upcoming first refresher date attributes of a constituent in his lifetime */
      max( case when rn = 1 then  arc_phss_txn_ref.course_renewal_period else null end) phss_upcmng_refresh_1,
      max( case when rn = 1 then   arc_phss_txn_ref.course_nm else null end) phss_upcmng_refresh_crs_1,       
 /* Getting the upcoming second refresher date attributes of a constituent in his lifetime */
      max( case when rn = 2 then  arc_phss_txn_ref.course_renewal_period else null end) phss_upcmng_refresh_2,
      max( case when rn = 2 then  arc_phss_txn_ref.course_nm else null end) phss_upcmng_refresh_crs_2,
 /* Getting the upcoming third efresher date attributes of a constituent in his lifetime */
      max( case when rn = 3 then  arc_phss_txn_ref.course_renewal_period else null end) phss_upcmng_refresh_3,
      max( case when rn = 3 then  arc_phss_txn_ref.course_nm else null end) phss_upcmng_refresh_crs_3
      
 from     
 /* Getting only courses up for refresh */     
(select arc_phss_txn_ref1.cnst_mstr_id,
       arc_phss_txn_ref1.course_nm,
       arc_phss_txn_ref1.course_nxt_recert_dt,
       arc_phss_txn_ref1.course_renewal_period,
       row_number () over(partition by arc_phss_txn_ref1.cnst_mstr_id  order by arc_phss_txn_ref1.course_nxt_recert_dt)  as rn
         
 from  
 /* Getting one row per a successful course which is up for refresh or recert */     
 (
select 
cnst_mstr_id,
person_key,
course_key,
course_nm,
course_subject_area,
course_focis_pgm,
course_refresher_flg,
course_end_date,
cert_exp_dt course_nxt_recert_dt,
renewal_period course_renewal_period
from
(select
cnst_mstr_id,
person_key,
course_key,
course_nm,
course_subject_area,
course_focis_pgm,
course_refresher_flg,
min(case when comp_per_crs = 1 then max_cal_dt_cmp else min_cal_dt_crs end) course_end_date,
min(case when comp_per_crs = 1 then cert_expire_dt_cmp_max  else cert_expire_dt_cmp end) cert_exp_dt,
case
  --When course is valid for 1 Year, only process Recertifications
  when (cert_exp_dt-course_end_date) = 365 and (current_date-course_end_date)  between 245 and 274  then 'Recert1'
  when (cert_exp_dt-course_end_date) = 365 and (current_date-course_end_date)  between 275 and 304  then 'Recert2'
  when (cert_exp_dt-course_end_date) = 365 and (current_date-course_end_date)  between 305 and 335 then 'Recert3'
  --When course is valid for 2 or 3 Years, process both Refreshers & Recertifications	
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 40   and 70 then 'Refresher1'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 130 and 160  then 'Refresher2'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 220 and 250  then 'Refresher3'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 310 and 340  then 'Refresher4'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 400 and 430  then 'Refresher5'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 490 and 520  then 'Refresher6'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 580 and 609  then 'Refresher7'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 610 and 639  then 'Recert1'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 640 and 669  then 'Recert2'
  when (cert_exp_dt-course_end_date) = 730 and (current_date-course_end_date) between 670 and 700   then 'Recert3'
  --Validate date ranges for 3 Years..Only here for placeholder 10/12
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 60 and 90  then 'Refresher1'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 150 and 180  then 'Refresher2'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 270 and 300  then 'Refresher3'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 390 and 420  then 'Refresher4'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 510 and 540  then 'Refresher5'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 630 and 660  then 'Refresher6'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 750 and 780  then 'Refresher7'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 975 and 1004  then 'Recert1'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 1005 and 1034  then 'Recert2'
  when (cert_exp_dt-course_end_date) = 1095 and (current_date-course_end_date) between 1005 and 1035 then 'Recert3'
         when (cert_exp_dt = cast ('9999-12-31' as date)) then 'No recert/Refresh'
  else 'OTHER'
 end as renewal_period

from
(select 
cnst_mstr_id,
person_key,
component_key,
comp_valid_for,
comp_end_dt,
course_key,
course_nm,
course_subject_area,
course_focis_pgm,
course_refresher_flg,
count(component_key) over (partition by  cnst_mstr_id,person_key,course_key) as comp_per_crs,
min(comp_end_dt) over (partition by cnst_mstr_id,person_key,course_key)  min_cal_dt_crs,
max(comp_end_dt) over (partition by  cnst_mstr_id,person_key,component_key)  max_cal_dt_cmp,
(case when comp_valid_for = '1 Year' then 
comp_end_dt + cast ('365' as integer)
else
case when comp_valid_for = '2 Years' then 
comp_end_dt + cast ('730' as integer)
else
case when comp_valid_for = '3 Years' then 
comp_end_dt + cast ('1095' as integer)
else
case when comp_valid_for = 'Does not expire' then 
cast ('9999-12-31' as date)
else
null
end end end end
)as cert_expire_dt_cmp,
(case when comp_valid_for = '1 Year' then 
max_cal_dt_cmp + cast ('365' as integer)
else
case when comp_valid_for = '2 Years' then 
max_cal_dt_cmp + cast ('730' as integer)
else
case when comp_valid_for = '3 Years' then 
max_cal_dt_cmp + cast ('1095' as integer)
else
case when comp_valid_for = 'Does not expire' then 
cast ('9999-12-31' as date)
else
null
end end end end
)as cert_expire_dt_cmp_max

from
(select 
cnst_mstr_id,
person_key,
component_key,
comp_valid_for,
comp_end_dt,
course_key,
course_nm,
course_subject_area,
course_focis_pgm,
course_refresher_flg
from
mktg_ops_tbls.arc_phss_recert_txn
where course_discontinued_flg = 'N'
qualify (row_number() over (partition by  cnst_mstr_id,person_key,course_key,component_key order by comp_end_dt desc)) =1) recert_main) recert_main2
group by cnst_mstr_id,person_key,course_key,course_nm,course_subject_area,course_focis_pgm,course_refresher_flg) recert_main3
where cert_exp_dt >= current_date and cert_exp_dt <> cast ('9999-12-31' as date) and course_refresher_flg = 'Y' 
 and course_renewal_period in ('Refresher1','Refresher2','Refresher3','Refresher4','Refresher5','Refresher6','Refresher7')) arc_phss_txn_ref1
) arc_phss_txn_ref
 group by arc_phss_txn_ref.cnst_mstr_id
 
 ) arc_phss_txn_ref_main  on arc_phss_txn_ref_main.cnst_mstr_id = arc_phss_txn_main.cnst_mstr_id
 
 left join 
 (
  select 
		d.cnst_mstr_id,
		min(c.calendar_dt) as first_dmw_store_dt,
		max(c.calendar_dt) as last_dmw_store_dt
	from eda.uhss_vws.sfbz_fact_product_ln pl
	left join eda.uhss_vws.sfbz_dim_odr a on a.odr_key = pl.odr_key
	left join eda.uhss_vws.sfbz_dim_prsn_addr ba on a.billing_prsn_addr_key = ba.prsn_addr_key
	left join eda.dw_common_vws.dim_calendar c on a.odr_dt_key = c.calendar_key
	left outer join  eda.arc_mdm_vws.bz_cnst_mstr_bridge d on d.cnst_mstr_subj_area_cd='SFCO' and d.cnst_mstr_subj_area_id=ba.prsn_addr_key
	where d.cnst_mstr_id is not null
	group by 1
 
 ) dmws (cnst_mstr_id, first_dmw_store_dt, last_dmw_store_dt) on pref.cnst_mstr_id = dmws.cnst_mstr_id
left join 
(

	select 
		d.cnst_mstr_id,
		min(c.calendar_dt) as first_dmw_course_dt,
		max(c.calendar_dt) as last_dmw_course_dt,
		sum(case when dco.course_nm LIKE '%Instructor%' then 1 else 0 end) as instr_cnt,
		sum(case when dco.course_nm LIKE '%Babysit%' then 1 else 0 end) as bst_cnt,
		sum(case when dco.course_nm LIKE 'NAT%' or dco.course_nm LIKE '%Nurse%' or dco.course_nm LIKE '%Nursing%' then 1 else 0 end) as nat_cnt,
		sum(case when dco.course_nm LIKE '%Spanish%' then 1 else 0 end) as spanish_cnt,
		count(*) as course_cnt,
		count(distinct ds.student_key) as unique_student_cnt,
		sum(case when ba.first_nm = ds.student_first_nm and ba.last_nm = ds.student_last_nm then 1 else 0 end) as student_match_cnt,
		case when instr_cnt > 0 then 'Y' else 'N' end as instr_flg,
		case when bst_cnt = course_cnt then 'Y' else 'N' end as bst_only_flg,
		case when nat_cnt = course_cnt then 'Y' else 'N' end as nat_only_flg,
		case when spanish_cnt = course_cnt then 'Y' else 'N' end as spanish_only_flg,
		case when student_match_cnt = course_cnt and unique_student_cnt = 1 then 'Y' else 'N' end as student_only_flg,
		case when student_match_cnt = 0 and course_cnt > 0 and unique_student_cnt > 0 then 'Y' else 'N' end as bill_prsn_only_flg,
		case when student_match_cnt <> course_cnt and student_match_cnt > 0  and unique_student_cnt > 1 then 'Y' else 'N' end as student_bill_prsn_flg
	from eda.uhss_vws.sfbz_fact_course_ln cl
	left join eda.uhss_vws.sfbz_dim_course_offering dco on cl.course_offer_key = dco.course_offer_key
	left join eda.uhss_vws.sfbz_dim_odr a on a.odr_key = cl.odr_key
	left join eda.uhss_vws.sfbz_dim_prsn_addr ba on a.billing_prsn_addr_key = ba.prsn_addr_key
	left join eda.uhss_vws.sfbz_dim_student ds on cl.student_key = ds.student_key
	left join eda.dw_common_vws.dim_calendar c on a.odr_dt_key = c.calendar_key
	left join  eda.arc_mdm_vws.bz_cnst_mstr_bridge d on d.cnst_mstr_subj_area_cd='SFCO' and d.cnst_mstr_subj_area_id=ba.prsn_addr_key
	where d.cnst_mstr_id is not null
	group by 1

) dmwc 	(cnst_mstr_id, first_dmw_course_dt, last_dmw_course_dt, instr_cnt, bst_cnt, nat_cnt, spanish_cnt, course_cnt, unique_student_cnt, student_match_cnt, instr_flg, bst_only_flg, nat_only_flg, spanish_only_flg, student_only_flg, bill_prsn_only_flg, student_bill_prsn_flg)
	 on pref.cnst_mstr_id = dmwc.cnst_mstr_id
where dmws.cnst_mstr_id is not null or dmwc.cnst_mstr_id is not null or arc_phss_txn_main.cnst_mstr_id is not null 


)

select 

  cnst_mstr_id, cnst_hsld_id, length_of_engagmnt, 
  yr_takn_crs, fst_crs_cmptn_dt, last_rgstn_mthd, 
  last_crs_cmptn_dt, last_crs_cmptn, 
  last_crs_subject_area, last_crs_delivery_typ, 
  nxt_rc_crs_delivery_typ, lftm_crs_complt_cnt, 
  lftm_pro_cpr_crs_complt_cnt, lftm_Lay_cpr_crs_complt_cnt, 
  lftm_aqtcs_crs_complt_cnt, lftm_caregvng_crs_complt_cnt, 
  lftm_nrse_trn_crs_complt_cnt, lftm_othr_crs_complt_cnt, 
  lftm_crs_spnd_amt, lftm_coupon_svngs_amt, 
  lftm_avg_cst_per_crs_amt, lftm_w_b_cmplt_pct, 
  lftm_clrm_cmplt_pct,  
  lftm_bl_wc_cmplt_pct, lftm_othr_cmplt_pct, 
  lftm_ap_crs_cmplt_pct, lftm_fs_crs_cmplt_pct, 
  lftm_cmnty_crs_cmplt_pct, lftm_othr_crs_cmplt_pct, 
  lftm_stndt_drp_class_rt, lftm_arc_cancld_class_rt, 
  lftm_stndt_fail_class_cnt, last_pro_cpr_crs_dt, 
  last_pro_cpr_recert_dt, fst_pro_cpr_crs_dt, 
  last_pro_cpr_tot_spnd_amt, last_lay_cpr_crs_dt, 
  last_lay_cpr_recert_dt, fst_lay_cpr_crs_dt, 
  last_lay_cpr_tot_spnd_amt, last_aqtcs_crs_dt, 
  last_aqtcs_recert_dt, fst_aqtcs_crs_dt, 
  last_aqtcs_tot_spnd_amt, last_caregiving_crs_dt, 
  last_caregiving_recert_dt, fst_caregiving_crs_dt, 
  last_caregiving_tot_spnd_amt, last_nrse_trn_crs_dt, 
  last_nrse_trn_recert_dt, fst_nrse_trn_crs_dt, 
  last_nrse_trn_tot_spnd_amt, last_othr_crs_dt, 
  last_othr_recert_dt, fst_othr_crs_dt, 
  last_othr_tot_spnd_amt, tot_cmpnts_cmplt_cnt, 
  tot_cmpnt_cmplt_1yrcert_cnt, tot_cmpnt_cmplt_2yrcert_cnt, 
  tot_cmpnt_cmplt_3yrcert_cnt, tot_cmpnts_passed_cnt, 
  tot_cmpnts_fld_cnt, tot_cmpnts_nt_evltd_cnt,  
  upcmng_recert_1_dt, upcmng_recert_1_crs_nm, 
  upcmng_recert_2_dt, upcmng_recert_2_crs_nm, 
  upcmng_recert_3_dt, upcmng_recert_3_crs_nm, 
  upcmng_refresh_1_typ, upcmng_refresh_1_crs_nm, 
  upcmng_refresh_2_typ, upcmng_refresh_2_crs_nm, 
  upcmng_refresh_3_typ, upcmng_refresh_3_crs_nm, 
  lst_cancltn_dt, lst_cancltn_class_nm, 
  course_taker_ind, 
  first_dmw_store_dt, last_dmw_store_dt, 
  first_dmw_course_dt, last_dmw_course_dt, 
  instr_cnt, bst_cnt, nat_cnt, spanish_cnt, 
  course_cnt, unique_student_cnt, 
  student_match_cnt, instr_flg, bst_only_flg, 
  nat_only_flg, spanish_only_flg, 
  student_only_flg, student_bill_prsn_flg, 
  last_engmnt_dt, dw_trans_ts, 'MKTG' as appl_src_cd,
  0 as load_id


from temp_smry;


truncate table mktg_ops_tbls.arc_phss_smry;

insert into mktg_ops_tbls.arc_phss_smry(
cnst_mstr_id, cnst_hsld_id, length_of_engagmnt, 
  yr_takn_crs, fst_crs_cmptn_dt, last_rgstn_mthd, 
  last_crs_cmptn_dt, last_crs_cmptn, 
  last_crs_subject_area, last_crs_delivery_typ, 
  nxt_rc_crs_delivery_typ, lftm_crs_complt_cnt, 
  lftm_pro_cpr_crs_complt_cnt, lftm_Lay_cpr_crs_complt_cnt, 
  lftm_aqtcs_crs_complt_cnt, lftm_caregvng_crs_complt_cnt, 
  lftm_nrse_trn_crs_complt_cnt, lftm_othr_crs_complt_cnt, 
  lftm_crs_spnd_amt, lftm_coupon_svngs_amt, 
  lftm_avg_cst_per_crs_amt, lftm_w_b_cmplt_pct, 
  lftm_clrm_cmplt_pct,  
  lftm_bl_wc_cmplt_pct, lftm_othr_cmplt_pct, 
  lftm_ap_crs_cmplt_pct, lftm_fs_crs_cmplt_pct, 
  lftm_cmnty_crs_cmplt_pct, lftm_othr_crs_cmplt_pct, 
  lftm_stndt_drp_class_rt, lftm_arc_cancld_class_rt, 
  lftm_stndt_fail_class_cnt, last_pro_cpr_crs_dt, 
  last_pro_cpr_recert_dt, fst_pro_cpr_crs_dt, 
  last_pro_cpr_tot_spnd_amt, last_lay_cpr_crs_dt, 
  last_lay_cpr_recert_dt, fst_lay_cpr_crs_dt, 
  last_lay_cpr_tot_spnd_amt, last_aqtcs_crs_dt, 
  last_aqtcs_recert_dt, fst_aqtcs_crs_dt, 
  last_aqtcs_tot_spnd_amt, last_caregiving_crs_dt, 
  last_caregiving_recert_dt, fst_caregiving_crs_dt, 
  last_caregiving_tot_spnd_amt, last_nrse_trn_crs_dt, 
  last_nrse_trn_recert_dt, fst_nrse_trn_crs_dt, 
  last_nrse_trn_tot_spnd_amt, last_othr_crs_dt, 
  last_othr_recert_dt, fst_othr_crs_dt, 
  last_othr_tot_spnd_amt, tot_cmpnts_cmplt_cnt, 
  tot_cmpnt_cmplt_1yrcert_cnt, tot_cmpnt_cmplt_2yrcert_cnt, 
  tot_cmpnt_cmplt_3yrcert_cnt, tot_cmpnts_passed_cnt, 
  tot_cmpnts_fld_cnt, tot_cmpnts_nt_evltd_cnt,  
  upcmng_recert_1_dt, upcmng_recert_1_crs_nm, 
  upcmng_recert_2_dt, upcmng_recert_2_crs_nm, 
  upcmng_recert_3_dt, upcmng_recert_3_crs_nm, 
  upcmng_refresh_1_typ, upcmng_refresh_1_crs_nm, 
  upcmng_refresh_2_typ, upcmng_refresh_2_crs_nm, 
  upcmng_refresh_3_typ, upcmng_refresh_3_crs_nm, 
  lst_cancltn_dt, lst_cancltn_class_nm, 
  course_taker_ind, 
  first_dmw_store_dt, last_dmw_store_dt, 
  first_dmw_course_dt, last_dmw_course_dt, 
  instr_cnt, bst_cnt, nat_cnt, spanish_cnt, 
  course_cnt, unique_student_cnt, 
  student_match_cnt, instr_flg, bst_only_flg, 
  nat_only_flg, spanish_only_flg, 
  student_only_flg, student_bill_prsn_flg, 
  last_engmnt_dt, dw_trans_ts, appl_src_cd,
  load_id

)

select 

cnst_mstr_id, cnst_hsld_id, length_of_engagmnt, 
  yr_takn_crs, fst_crs_cmptn_dt, last_rgstn_mthd, 
  last_crs_cmptn_dt, last_crs_cmptn, 
  last_crs_subject_area, last_crs_delivery_typ, 
  nxt_rc_crs_delivery_typ, lftm_crs_complt_cnt, 
  lftm_pro_cpr_crs_complt_cnt, lftm_Lay_cpr_crs_complt_cnt, 
  lftm_aqtcs_crs_complt_cnt, lftm_caregvng_crs_complt_cnt, 
  lftm_nrse_trn_crs_complt_cnt, lftm_othr_crs_complt_cnt, 
  lftm_crs_spnd_amt, lftm_coupon_svngs_amt, 
  lftm_avg_cst_per_crs_amt, lftm_w_b_cmplt_pct, 
  lftm_clrm_cmplt_pct,  
  lftm_bl_wc_cmplt_pct, lftm_othr_cmplt_pct, 
  lftm_ap_crs_cmplt_pct, lftm_fs_crs_cmplt_pct, 
  lftm_cmnty_crs_cmplt_pct, lftm_othr_crs_cmplt_pct, 
  lftm_stndt_drp_class_rt, lftm_arc_cancld_class_rt, 
  lftm_stndt_fail_class_cnt, last_pro_cpr_crs_dt, 
  last_pro_cpr_recert_dt, fst_pro_cpr_crs_dt, 
  last_pro_cpr_tot_spnd_amt, last_lay_cpr_crs_dt, 
  last_lay_cpr_recert_dt, fst_lay_cpr_crs_dt, 
  last_lay_cpr_tot_spnd_amt, last_aqtcs_crs_dt, 
  last_aqtcs_recert_dt, fst_aqtcs_crs_dt, 
  last_aqtcs_tot_spnd_amt, last_caregiving_crs_dt, 
  last_caregiving_recert_dt, fst_caregiving_crs_dt, 
  last_caregiving_tot_spnd_amt, last_nrse_trn_crs_dt, 
  last_nrse_trn_recert_dt, fst_nrse_trn_crs_dt, 
  last_nrse_trn_tot_spnd_amt, last_othr_crs_dt, 
  last_othr_recert_dt, fst_othr_crs_dt, 
  last_othr_tot_spnd_amt, tot_cmpnts_cmplt_cnt, 
  tot_cmpnt_cmplt_1yrcert_cnt, tot_cmpnt_cmplt_2yrcert_cnt, 
  tot_cmpnt_cmplt_3yrcert_cnt, tot_cmpnts_passed_cnt, 
  tot_cmpnts_fld_cnt, tot_cmpnts_nt_evltd_cnt,  
  upcmng_recert_1_dt, upcmng_recert_1_crs_nm, 
  upcmng_recert_2_dt, upcmng_recert_2_crs_nm, 
  upcmng_recert_3_dt, upcmng_recert_3_crs_nm, 
  upcmng_refresh_1_typ, upcmng_refresh_1_crs_nm, 
  upcmng_refresh_2_typ, upcmng_refresh_2_crs_nm, 
  upcmng_refresh_3_typ, upcmng_refresh_3_crs_nm, 
  lst_cancltn_dt, lst_cancltn_class_nm, 
  course_taker_ind, 
  first_dmw_store_dt, last_dmw_store_dt, 
  first_dmw_course_dt, last_dmw_course_dt, 
  instr_cnt, bst_cnt, nat_cnt, spanish_cnt, 
  course_cnt, unique_student_cnt, 
  student_match_cnt, instr_flg, bst_only_flg, 
  nat_only_flg, spanish_only_flg, 
  student_only_flg, student_bill_prsn_flg, 
  last_engmnt_dt, dw_trans_ts, appl_src_cd,
  load_id

from mktg_stage_tbls.arc_phss_smry_stg;



	
	--audit update	
	v_end_time := GETDATE();
	v_ok_message = cast((select count(*) from mktg_ops_tbls.arc_phss_smry) as nvarchar)+ ' Records inserted.';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_arc_phss_smry' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_arc_phss_smry', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$$
