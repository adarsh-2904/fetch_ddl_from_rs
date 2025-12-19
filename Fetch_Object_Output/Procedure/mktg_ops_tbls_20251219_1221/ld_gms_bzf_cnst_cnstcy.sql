CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_gms_bzf_cnst_cnstcy()
 LANGUAGE plpgsql
AS $_$
/*
Created by: Michael Andrien
Created date: 04/07/2021
Purpose: This macro flattened 'frf_cnst_cnstcy' data and loads into ufds_tbls.bzf_cnst_cnstcy table . Full Data Load.  NOTE: This is a copy of the UFDS_TBLS version, but we've applied the following updates:
	1. Modified the case statement for setting the tifny_crcle_bmh_mmbr_ind attribute to  include both cntstcy_typ values below.  Prior to this update only the 'Tiffany Circle BMH Member' description was included in the definition.
	,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ in ('Tiffany Circle BMH Member', 'Tiffany Circle BMH Member ($100,000 cumulative)') THEN 1 ELSE 0 END),0)
	
	2. Added the Leadership Society Gold attribute
*/	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := GETDATE();
	INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_gms_bzf_cnst_cnstcy', 'Stored Procedure', 'Inprogress', v_start_time);


begin
/* Insert the records updated after previous run into the change data capture table */

/* Deletion of all the records  */
truncate table mktg_stage_tbls.gms_bzf_cnst_cnstcy_stg;


/*  Inserting all records into the ufds_tbls.bzf_cnst_cnstcy */

insert into mktg_stage_tbls.gms_bzf_cnst_cnstcy_stg
with cte as (
Select 
cnst_cnstcy.cnst_mstr_id
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='$1K' THEN 1 ELSE 0 END),0) as one_k_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='$5K' THEN 1 ELSE 0 END),0) as five_k_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='ADGP' THEN 1 ELSE 0 END),0) as adgp_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Red Cross Leadership Society' THEN 1 ELSE 0 END),0) as arc_ldrshp_scty_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Blood Donor' THEN 1 ELSE 0 END),0) as blood_dnr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='BMH Silver Member' THEN 1 ELSE 0 END),0) as bmh_slvr_dnr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Board of Governors' THEN 1 ELSE 0 END),0) as bog_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Clara Barton Society - Bronze' THEN 1 ELSE 0 END),0) as cb_scty_bronze_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Clara Barton Society - Silver' THEN 1 ELSE 0 END),0) as cb_scty_slvr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Clara Barton Society - Gold' THEN 1 ELSE 0 END),0) as cb_scty_gold_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Clara Barton Society - Platinum' THEN 1 ELSE 0 END),0) as cb_scty_pltnm_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Clara Barton Society' THEN 1 ELSE 0 END),0) as cb_scty_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Chairman''s Council' THEN 1 ELSE 0 END),0) as chairman_cncl_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Chapter Board Chair' THEN 1 ELSE 0 END),0) as chpt_board_chair_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Chapter Board Member' THEN 1 ELSE 0 END),0) as chpt_board_mmbr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Corporate Advisory Council' THEN 1 ELSE 0 END),0) as corp_advsry_cncl_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Disaster Responder' THEN 1 ELSE 0 END),0) as distr_respndr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Gift Planning Donor Spotlight' THEN 1 ELSE 0 END),0) as gp_dnr_spotlight_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Honorary Board Member' THEN 1 ELSE 0 END),0) as hon_board_mmbr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Humanitarian Circle' THEN 1 ELSE 0 END),0) as hmntrn_crcle_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Humanitarian Circle Disaster Responder' THEN 1 ELSE 0 END),0) as hmntrn_crcle_distr_respndr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Humanitarian Circle - Disaster Supporter (HCDS)' THEN 1 ELSE 0 END),0) as hmntrn_crcle_distr_suprtr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Legacy Society' THEN 1 ELSE 0 END),0) as leg_scty_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Leadership Society' THEN 1 ELSE 0 END),0) as ldrshp_scty_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Leadership Society Gold' THEN 1 ELSE 0 END),0) as ldrshp_scty_gold_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Mission Leader' THEN 1 ELSE 0 END),0) as mission_ldr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='National Philanthropic Board' THEN 1 ELSE 0 END),0) as npt_board_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='President''s Council' THEN 1 ELSE 0 END),0) as president_cncl_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Ready 365 - Gold' THEN 1 ELSE 0 END),0) as ready_365_scty_gold_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Ready 365 - Bronze' THEN 1 ELSE 0 END),0) as ready_365_scty_bronze_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Ready 365 - Silver' THEN 1 ELSE 0 END),0) as ready_365_scty_slvr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Ready 365 - Platinum' THEN 1 ELSE 0 END),0) as ready_365_scty_pltnm_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Ready Rating' THEN 1 ELSE 0 END),0) as ready_rating_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='SAF Advisory Board' THEN 1 ELSE 0 END),0) as saf_advsry_board_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='SAF Leadership' THEN 1 ELSE 0 END),0) as saf_ldrshp_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='SAF Giving Program' THEN 1 ELSE 0 END),0) as saf_gvng_prog_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Staff' THEN 1 ELSE 0 END),0) as staff_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ in ('Tiffany Circle BMH Member', 'Tiffany Circle BMH Member ($100,000 cumulative)') THEN 1 ELSE 0 END),0) as tifny_crcle_bmh_mmbr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ in ('Tiffany Circle BMH Silver Member','Tiffany Circle BMH Silver Member ($250,000 cumulative)') THEN 1 ELSE 0 END),0) as tifny_crcle_bmh_slvr_mmbr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ in ('Tiffany Circle BMH Gold ($500,000 cumulative)') THEN 1 ELSE 0 END),0) as tifny_crcle_bmh_gold_mmbr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ in ('Tiffany Circle BMH Platinum ($750,000 cumulative)') THEN 1 ELSE 0 END),0) as tifny_crcle_bmh_pltnm_mmbr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Tiffany Circle Lifetime Member' THEN 1 ELSE 0 END),0) as tifny_crcle_lftm_mmbr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Tiffany Circle Member' THEN 1 ELSE 0 END),0) as tifny_crcle_mmbr_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Tiffany Circle National Council' THEN 1 ELSE 0 END),0) as tifny_crcle_ntnl_cncl_ind
,Coalesce(Max(CASE WHEN cnst_cnstcy.cnstcy_typ ='Volunteer' THEN 1 ELSE 0 END),0) as volntr_ind
,current_timestamp as dw_trans_time
FROM (
SELECT 
		bzfc_dim_unf_fr_cnst.cnst_mstr_id,
		coalesce(frf_cnst_cnstcy.cnstcy_typ,chpt_cnst_cnstcy.cnstcy_typ_dsc, '' ) as cnstcy_typ
	FROM eda.ufds_vws.bzfc_dim_unf_fr_cnst bzfc_dim_unf_fr_cnst
	LEFT JOIN   eda.ufds_vws.frfbz_frf_cnst_cnstcy  frf_cnst_cnstcy ON bzfc_dim_unf_fr_cnst.unf_fr_cnst_key = frf_cnst_cnstcy.frf_cnst_key 
	LEFT JOIN  eda.ufds_vws.gmpbz_chpt_cnst_cnstcy chpt_cnst_cnstcy ON bzfc_dim_unf_fr_cnst.unf_fr_cnst_key = chpt_cnst_cnstcy.gmp_cnst_key
	WHERE 
		NOT ( bzfc_dim_unf_fr_cnst.cnst_typ_cd  in ('IG','OG')  OR bzfc_dim_unf_fr_cnst.cnst_mstr_id is null )
		
)   cnst_cnstcy
GROUP BY cnst_mstr_id
)

select * from cte;

truncate table mktg_ops_tbls.gms_bzf_cnst_cnstcy;

insert into mktg_ops_tbls.gms_bzf_cnst_cnstcy select * from mktg_stage_tbls.gms_bzf_cnst_cnstcy_stg;

	
	--audit update	
	v_end_time := GETDATE();
	v_ok_message = cast((select count(*) from mktg_ops_tbls.gms_bzf_cnst_cnstcy) as nvarchar)+ ' Records inserted.';
        UPDATE mods_bi.etl_config.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_gms_bzf_cnst_cnstcy' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := GETDATE();
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mods_bi.etl_config.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_gms_bzf_cnst_cnstcy', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$_$
