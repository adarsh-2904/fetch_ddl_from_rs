CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_arc_biomed_smry()
 LANGUAGE plpgsql
AS $$
	
/*
Modified By:  Hitansu Sahoo
Modified Date: 10/24/2025
Purpose:	This Redshift stored proc was created from the PDO sql of Informatica mapping.

*/	
	
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_arc_biomed_smry', 'Stored Procedure', 'Inprogress', v_start_time);


begin

/*Execution time: 15m*/
truncate TABLE mktg_stage_tbls.arc_biomed_smry_stg;

insert into mktg_stage_tbls.arc_biomed_smry_stg


/*----Execution time 6 mins*/
WITH ranked_txn AS (
 SELECT *,
 ROW_NUMBER() OVER (PARTITION BY cnst_mstr_id ORDER BY nk_donat_dt DESC) AS rn
 FROM mktg_ops_tbls.arc_biomed_txn
),
latest_txn AS (
 SELECT *, nk_donat_dt AS last_donat_dt
 FROM ranked_txn
 WHERE rn = 1
)
SELECT 
    biomed_txn.cnst_mstr_id,
    MAX(c.abo_dsc) AS abo_dsc,
    max(latest.nk_donat_dt) AS last_donat_dt,
    MIN(CASE WHEN biomed_txn.apptmt_show_ind = 1 OR biomed_txn.walk_in_ind = 1 THEN biomed_txn.nk_donat_dt END) AS fst_donat_dt,
    SUM(CASE WHEN biomed_txn.apptmt_show_ind = 0 AND biomed_txn.walk_in_ind = 0 THEN 1 ELSE 0 END) AS no_show_cnt,
    MAX(CASE WHEN biomed_txn.apptmt_show_ind = 0 AND biomed_txn.walk_in_ind = 0 THEN biomed_txn.apptmt_dt END) AS last_no_show_dt,
    MIN(CASE WHEN biomed_txn.apptmt_show_ind = 0 AND biomed_txn.walk_in_ind = 0 THEN biomed_txn.apptmt_dt END) AS fst_no_show_dt,
    SUM(CASE WHEN biomed_txn.walk_in_ind = 1 THEN 1 ELSE 0 END) AS walk_in_cnt,
    MAX(CASE WHEN biomed_txn.walk_in_ind = 1 THEN biomed_txn.nk_donat_dt END) AS last_walk_in_dt,
    MIN(CASE WHEN biomed_txn.walk_in_ind = 1 THEN biomed_txn.nk_donat_dt END) AS fst_walk_in_dt,
COALESCE(COUNT(DISTINCT CASE WHEN biomed_txn.donation_ind = 1 AND (biomed_txn.apptmt_show_ind = 1 OR biomed_txn.walk_in_ind = 1) THEN biomed_txn.nk_donat_dt END), 0) AS lftm_donat_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_donat_type_cd = 'H' THEN 1 ELSE 0 END), 0) AS lftm_allo_donat_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_donat_type_cd = 'A' THEN 1 ELSE 0 END), 0) AS lftm_autol_donat_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_donat_type_cd IN ('D', 'L') THEN 1 ELSE 0 END), 0) AS lftm_directed_donat_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_donat_type_cd = 'R' THEN 1 ELSE 0 END), 0) AS lftm_research_donat_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_donat_type_cd = 'T' THEN 1 ELSE 0 END), 0) AS lftm_therap_donat_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_phleb_proc_cd = 'WB' THEN 1 ELSE 0 END), 0) AS lftm_whole_blood_coll_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_phleb_fam_type_cd IN ('C', 'R', 'P') THEN 1 ELSE 0 END), 0) AS lftm_pheresis_coll_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_phleb_proc_cd = 'R2' THEN 1 ELSE 0 END), 0) AS lftm_r2_coll_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_phleb_proc_cd = 'PP' THEN 1 ELSE 0 END), 0) AS lftm_pp_coll_cnt,
COALESCE(SUM(CASE WHEN dim_phleb.dw_phleb_proc_cd IN ('P3', 'P4') THEN 1 ELSE 0 END), 0) AS lftm_rbc_coll_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN biomed_txn.prodctv_unit_wb_cnt > 0 THEN biomed_txn.nk_donat_dt END), 0) AS lftm_prodctv_wb_cnt,
COALESCE(SUM(biomed_txn.prodctv_unit_wb_cnt), 0) AS lftm_prodctv_wb_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN biomed_txn.prodctv_unit_pltpheresis_cnt > 0 THEN biomed_txn.nk_donat_dt END), 0) AS lftm_prodctv_pltpheresis_cnt,
COALESCE(SUM(biomed_txn.prodctv_unit_pltpheresis_cnt), 0) AS lftm_prodctv_plt_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN biomed_txn.prodctv_unit_red_cell_cnt > 0 THEN biomed_txn.nk_donat_dt END), 0) AS lftm_prodctv_red_cell_cnt,
COALESCE(SUM(biomed_txn.prodctv_unit_red_cell_cnt), 0) AS lftm_prodctv_red_cell_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN biomed_txn.prodctv_unit_plspheresis_cnt > 0 THEN biomed_txn.nk_donat_dt END), 0) AS lftm_prodctv_plspheresis_cnt,
COALESCE(SUM(biomed_txn.prodctv_unit_plspheresis_cnt), 0) AS lftm_prodctv_pls_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN biomed_txn.prodctv_unit_dbl_red_cell_cnt > 0 THEN biomed_txn.nk_donat_dt END), 0) AS lftm_prodctv_dbl_red_cnt,
COALESCE(SUM(biomed_txn.prodctv_unit_dbl_red_cell_cnt), 0) AS lftm_prodctv_dbl_red_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN biomed_txn.phleb_ind = 1 AND (biomed_txn.apptmt_show_ind = 1 OR biomed_txn.walk_in_ind = 1) THEN biomed_txn.nk_donat_dt END) END), 0) AS cfy0_donat_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_donat_type_cd = 'H' THEN 1 ELSE 0 END) END), 0) AS cfy0_allo_donat_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_donat_type_cd = 'A' THEN 1 ELSE 0 END) END), 0) AS cfy0_autol_donat_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_donat_type_cd IN ('D', 'L') THEN 1 ELSE 0 END) END), 0) AS cfy0_directed_donat_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_donat_type_cd = 'R' THEN 1 ELSE 0 END) END), 0) AS cfy0_research_donat_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_donat_type_cd = 'T' THEN 1 ELSE 0 END) END), 0) AS cfy0_therap_donat_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_phleb_proc_cd = 'WB' THEN 1 ELSE 0 END) END), 0) AS cfy0_whole_blood_coll_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_phleb_fam_type_cd IN ('C', 'R', 'P') THEN 1 ELSE 0 END) END), 0) AS cfy0_pheresis_coll_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_phleb_proc_cd = 'R2' THEN 1 ELSE 0 END) END), 0) AS cfy0_r2_coll_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_phleb_proc_cd = 'PP' THEN 1 ELSE 0 END) END), 0) AS cfy0_pp_coll_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN dim_phleb.dw_phleb_proc_cd IN ('P3', 'P4') THEN 1 ELSE 0 END) END), 0) AS cfy0_rbc_coll_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN biomed_txn.prodctv_unit_wb_cnt > 0 THEN biomed_txn.nk_donat_dt END) END), 0) AS cfy0_prodctv_wb_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN biomed_txn.prodctv_unit_wb_cnt END), 0) AS cfy0_prodctv_wb_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN biomed_txn.prodctv_unit_pltpheresis_cnt > 0 THEN biomed_txn.nk_donat_dt END) END), 0) AS cfy0_prodctv_pltpheresis_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN biomed_txn.prodctv_unit_pltpheresis_cnt END), 0) AS cfy0_prodctv_plt_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN biomed_txn.prodctv_unit_red_cell_cnt > 0 THEN biomed_txn.nk_donat_dt END) END), 0) AS cfy0_prodctv_red_cell_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN biomed_txn.prodctv_unit_red_cell_cnt END), 0) AS cfy0_prodctv_red_cell_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN biomed_txn.prodctv_unit_plspheresis_cnt > 0 THEN biomed_txn.nk_donat_dt END) END), 0) AS cfy0_prodctv_plspheresis_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN biomed_txn.prodctv_unit_plspheresis_cnt END), 0) AS cfy0_prodctv_pls_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN cal.fiscal_yr = cal.FY0 THEN (CASE WHEN biomed_txn.prodctv_unit_dbl_red_cell_cnt > 0 THEN biomed_txn.nk_donat_dt END) END), 0) AS cfy0_prodctv_dbl_red_cnt,
COALESCE(SUM(CASE WHEN cal.fiscal_yr = cal.FY0 THEN biomed_txn.prodctv_unit_dbl_red_cell_cnt END), 0) AS cfy0_prodctv_dbl_red_unit_cnt,
COALESCE(COUNT(DISTINCT CASE WHEN (biomed_txn.nk_donat_dt <= CURRENT_DATE AND biomed_txn.nk_donat_dt >= CURRENT_DATE - 365) THEN (CASE WHEN (biomed_txn.phleb_ind = 1 AND (biomed_txn.apptmt_show_ind = 1 OR biomed_txn.walk_in_ind = 1)) THEN biomed_txn.nk_donat_dt END) END), 0) AS ry0_donat_cnt,
COALESCE(SUM(CASE WHEN (biomed_txn.nk_donat_dt <= CURRENT_DATE AND biomed_txn.nk_donat_dt >= CURRENT_DATE - 365) THEN (CASE WHEN dim_phleb.dw_donat_type_cd = 'H' THEN 1 ELSE 0 END) END), 0) AS ry0_allo_donat_cnt,
COALESCE(SUM(CASE WHEN (biomed_txn.nk_donat_dt <= CURRENT_DATE AND biomed_txn.nk_donat_dt >= CURRENT_DATE - 365) THEN (CASE WHEN dim_phleb.dw_donat_type_cd = 'A' THEN 1 ELSE 0 END) END), 0) AS ry0_autol_donat_cnt,
COALESCE(SUM(CASE WHEN (biomed_txn.nk_donat_dt <= CURRENT_DATE AND biomed_txn.nk_donat_dt >= CURRENT_DATE - 365) THEN (CASE WHEN dim_phleb.dw_donat_type_cd IN ('D', 'L') THEN 1 ELSE 0 END) END), 0) AS ry0_directed_donat_cnt,
COALESCE(SUM(CASE WHEN (biomed_txn.nk_donat_dt <= CURRENT_DATE AND biomed_txn.nk_donat_dt >= CURRENT_DATE - 365) THEN (CASE WHEN dim_phleb.dw_donat_type_cd = 'R' THEN 1 ELSE 0 END) END), 0) AS ry0_research_donat_cnt,
COALESCE(SUM(CASE WHEN (biomed_txn.nk_donat_dt <= CURRENT_DATE AND biomed_txn.nk_donat_dt >= CURRENT_DATE - 365) THEN (CASE WHEN dim_phleb.dw_donat_type_cd = 'T' THEN 1 ELSE 0 END) END), 0) AS ry0_therap_donat_cnt,
COALESCE(SUM(CASE WHEN (biomed_txn.nk_donat_dt <= CURRENT_DATE AND biomed_txn.nk_donat_dt >= CURRENT_DATE - 365) THEN (case when dim_phleb.dw_phleb_proc_cd = 'WB' then 1 else 0 end) end), 0) as ry0_whole_blood_coll_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when dim_phleb.dw_phleb_fam_type_cd IN ('C', 'R', 'P') then 1 else 0 end) end), 0) as ry0_pheresis_coll_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when dim_phleb.dw_phleb_proc_cd = 'R2' then 1 else 0 end) end), 0) as ry0_r2_coll_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when dim_phleb.dw_phleb_proc_cd = 'PP' then 1 else 0 end) end), 0) as ry0_pp_coll_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when dim_phleb.dw_phleb_proc_cd in ('P3', 'P4') then 1 else 0 end) end), 0) as ry0_rbc_coll_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when biomed_txn.prodctv_unit_wb_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry0_prodctv_wb_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then biomed_txn.prodctv_unit_wb_cnt end), 0) as ry0_prodctv_wb_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when biomed_txn.prodctv_unit_pltpheresis_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry0_prodctv_pltpheresis_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then biomed_txn.prodctv_unit_pltpheresis_cnt end), 0) as ry0_prodctv_plt_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when biomed_txn.prodctv_unit_red_cell_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry0_prodctv_red_cell_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then biomed_txn.prodctv_unit_red_cell_cnt end), 0) as ry0_prodctv_red_cell_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when biomed_txn.prodctv_unit_plspheresis_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry0_prodctv_plspheresis_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then biomed_txn.prodctv_unit_plspheresis_cnt end), 0) as ry0_prodctv_pls_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then (case when  biomed_txn.prodctv_unit_dbl_red_cell_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry0_prodctv_dbl_red_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= CURRENT_DATE and biomed_txn.nk_donat_dt>=current_date-365) then biomed_txn.prodctv_unit_dbl_red_cell_cnt end), 0) as ry0_prodctv_dbl_red_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when  (biomed_txn.phleb_ind=1 and  (biomed_txn.apptmt_show_ind = 1 or biomed_txn.walk_in_ind = 1)) then biomed_txn.nk_donat_dt end) end)), 0) as ry1_donat_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_donat_type_cd = 'H'  then 1 else 0 end) end), 0) as ry1_allo_donat_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_donat_type_cd = 'A'  then 1 else 0 end) end), 0) as ry1_autol_donat_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_donat_type_cd in ('D', 'L')  then 1 else 0 end) end), 0) as ry1_directed_donat_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_donat_type_cd = 'R'  then 1 else 0 end) end), 0) as ry1_research_donat_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_donat_type_cd = 'T'  then 1 else 0 end) end), 0) as ry1_therap_donat_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_phleb_proc_cd = 'WB'  then 1 else 0 end) end), 0) as ry1_whole_blood_coll_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_phleb_fam_type_cd IN ('C', 'R', 'P')  then 1 else 0 end) end), 0) as ry1_pheresis_coll_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_phleb_proc_cd = 'R2'  then 1 else 0 end) end), 0) as ry1_r2_coll_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_phleb_proc_cd = 'PP'  then 1 else 0 end) end), 0) as ry1_pp_coll_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when dim_phleb.dw_phleb_proc_cd in ('P3', 'P4')  then 1 else 0 end) end), 0) as ry1_rbc_coll_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when  biomed_txn.prodctv_unit_wb_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry1_prodctv_wb_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then biomed_txn.prodctv_unit_wb_cnt end), 0) as ry1_prodctv_wb_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when  biomed_txn.prodctv_unit_pltpheresis_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry1_prodctv_pltpheresis_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then biomed_txn.prodctv_unit_pltpheresis_cnt end), 0) as ry1_prodctv_plt_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when  biomed_txn.prodctv_unit_red_cell_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry1_prodctv_red_cell_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then biomed_txn.prodctv_unit_red_cell_cnt end), 0) as ry1_prodctv_red_cell_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when  biomed_txn.prodctv_unit_plspheresis_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry1_prodctv_plspheresis_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then biomed_txn.prodctv_unit_plspheresis_cnt end), 0) as ry1_prodctv_pls_unit_cnt,
COALESCE(count(distinct (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then (case when  biomed_txn.prodctv_unit_dbl_red_cell_cnt > 0 then biomed_txn.nk_donat_dt end) end)), 0) as ry1_prodctv_dbl_red_cnt,
COALESCE(sum (case when (biomed_txn.nk_donat_dt <= current_date-365 and biomed_txn.nk_donat_dt>=current_date-730) then biomed_txn.prodctv_unit_dbl_red_cell_cnt end), 0) as ry1_prodctv_dbl_red_unit_cnt,
TO_TIMESTAMP(getdate(), 'YYYY-MM-DD HH24:MI:SS', TRUE) as dw_trans_ts
--select TO_TIMESTAMP(getdate(), 'YYYY-MM-DD HH24:MI:SS', TRUE);
FROM
    mktg_ops_tbls.arc_biomed_txn biomed_txn
LEFT JOIN latest_txn latest ON biomed_txn.cnst_mstr_id = latest.cnst_mstr_id
LEFT JOIN eda.bio_common_vws.bz_dim_blood_type c 
    ON biomed_txn.blood_type_key = c.blood_type_key
LEFT JOIN eda.bio_common_vws.bz_dim_phleb dim_phleb 
    ON biomed_txn.phleb_key = dim_phleb.phleb_key
LEFT JOIN (
    SELECT a.calendar_dt, a.fiscal_yr, b.fiscal_yr AS FY0
    FROM eda.dw_common_vws.dim_calendar a
    CROSS JOIN eda.dw_common_vws.dim_calendar b
    WHERE b.calendar_dt = CURRENT_DATE
) cal 
    ON biomed_txn.nk_donat_dt = cal.calendar_dt
GROUP BY 
    biomed_txn.cnst_mstr_id;


truncate table mktg_ops_tbls.arc_biomed_smry ;
insert into mktg_ops_tbls.arc_biomed_smry select * from mktg_stage_tbls.arc_biomed_smry_stg;


	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.arc_biomed_smry) as nvarchar)+ ' Records inserted.';
        UPDATE etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_cnst_cdi_arc_biomed_smry' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

	--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_cnst_cdi_arc_biomed_smry', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));


			
    END;
END;



$$
