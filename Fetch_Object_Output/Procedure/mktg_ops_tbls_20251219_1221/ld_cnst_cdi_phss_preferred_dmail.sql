CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_phss_preferred_dmail()
 LANGUAGE plpgsql
AS $_$
	
	
	
	
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
	v_error_message VARCHAR(500);
	v_ok_message VARCHAR(500);

BEGIN
	v_start_time := CURRENT_TIMESTAMP;
	INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time)
    VALUES ('ld_cnst_cdi_phss_preferred_dmail', 'Stored Procedure', 'Inprogress', v_start_time);


begin
delete from mktg_ops_tbls.cnst_cdi_phss_preferred_dmail;

insert into  mktg_ops_tbls.cnst_cdi_phss_preferred_dmail (
cnst_mstr_id,cnst_hsld_id,cnst_dsp_deceased_cd,cnst_data_src_cd,cnst_prsn_prfx_nm,cnst_prsn_f_nm,cnst_prsn_m_nm,cnst_prsn_l_nm,cnst_prsn_sfx_nm,cnst_prsn_full_nm,cnst_alias_in_saltn_nm,cnst_alias_out_saltn_nm,locator_addr_key,cnst_addr_assessmnt_ctg,dpv_cd,cnst_addr_typ_cd,cnst_line_1_addr,cnst_line_2_addr,cnst_city_nm,cnst_st_cd,cnst_zip_5_cd,cnst_zip_4_cd,cnst_email,cnst_org_nm,cnst_typ_dsc)
with ranked_consolidated_data as (
select
  cnst_mstr.cnst_mstr_id
, cnst_mstr.cnst_hsld_id  
, cnst_mstr.cnst_dsp_deceased_cd
,cnst_addr.arc_srcsys_cd       cnst_data_src_cd               
,P.bz_cnst_prsn_prefix_nm         cnst_prsn_prfx_nm
,P.bz_cnst_prsn_first_nm      cnst_prsn_f_nm    
,P.bz_cnst_prsn_middle_nm        cnst_prsn_m_nm
,P.bz_cnst_prsn_last_nm          cnst_prsn_l_nm
,P.bz_cnst_prsn_suffix_nm        cnst_prsn_sfx_nm
,P.cnst_prsn_full_nm cnst_prsn_full_nm
,P.bz_cnst_alias_in_saltn_nm cnst_alias_in_saltn_nm
,P.bz_cnst_alias_out_saltn_nm cnst_alias_out_saltn_nm
,cnst_addr.locator_addr_key
,cnst_addr.cnst_addr_assessmnt_ctg
,cnst_addr.dpv_cd
,cnst_addr.cnst_addr_typ_cd
,cnst_addr.bz_cnst_addr_line1_addr       cnst_line_1_addr
,cnst_addr.bz_cnst_addr_line2_addr       cnst_line_2_addr
,cnst_addr.bz_cnst_addr_city_nm      cnst_city_nm    
,cnst_addr.cnst_addr_state_cd        cnst_st_cd    
,cnst_addr.cnst_addr_zip_5_cd     cnst_zip_5_cd       
,cnst_addr.cnst_addr_zip_4_cd          cnst_zip_4_cd  
,E.locator_email_addr      cnst_email  
,ORG.cnst_org_nm
,case when cnst_mstr.cnst_typ_cd='IN' then 'Individual'
           when cnst_mstr.cnst_typ_cd='OR' then 'Organization'
           when cnst_mstr.cnst_typ_cd='AG' then 'Account Group'
  end as cnst_typ_dsc,
 
 ---case conditions--
 ROW_NUMBER() OVER (PARTITION BY cnst_addr.cnst_mstr_id  
ORDER BY
CASE
---- Prioritize Deliverable Home addresses with a DPV Code = Y 
WHEN cnst_addr.arc_srcsys_cd='SABA' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 1
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABA'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H')THEN 2
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='PHSF' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H')  THEN 3
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABO' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 4
WHEN cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='LN')  THEN 5
---- Prioritize Deliverable Non-Home addresses with a DPV Code = Y 
WHEN cnst_addr.arc_srcsys_cd='SABA' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 6
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABA'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')THEN 6
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='PHSF' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')  THEN 7
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABO' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 8
WHEN cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'LN')  THEN 9
---- Prioritize Deliverable Home addresses with a DPV Code = Y  that are older than 1 year
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='SABA' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 10
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABA'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 11
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='PHSF'  and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H')   THEN 12
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABO' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd='H')  THEN 13
---- Prioritize Deliverable Non-Home addresses with a DPV Code = Y  that are older than 1 year
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='SABA' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 14
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABA'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 15
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='PHSF'  and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')   THEN 16
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABO' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd = 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')  THEN 17

---- Prioritize Deliverable Home addresses with a DPV Code <> Y 
WHEN cnst_addr.arc_srcsys_cd='SABA' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 18
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABA'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H')THEN 19
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='PHSF' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H')  THEN 20
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABO' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 21
WHEN cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='LN')  THEN 22
---- Prioritize Deliverable Non-Home addresses with a DPV Code<> Y 
WHEN cnst_addr.arc_srcsys_cd='SABA' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 23
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABA'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')THEN 24
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='PHSF' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')  THEN 25
WHEN cnst_addr.dw_srcsys_trans_ts>CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABO' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 26
WHEN cnst_addr.arc_srcsys_cd='CDIM' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'LN')  THEN 5
---- Prioritize Deliverable Home addresses with a DPV Code <> Y  that are older than 1 year
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='SABA' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 27
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABA'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H') THEN 28
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='PHSF'  and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H')   THEN 29
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABO' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd='H')  THEN 30
---- Prioritize Deliverable Non-Home addresses with a DPV Code <> Y  that are older than 1 year
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' and cnst_addr.arc_srcsys_cd='SABA' and cnst_addr.cnst_addr_prefd_ind = 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 31
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABA'   and cnst_addr.cnst_addr_prefd_ind <> 1 and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H') THEN 32
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='PHSF'  and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')   THEN 33
WHEN cnst_addr.dw_srcsys_trans_ts<=CURRENT_DATE - INTERVAL '365 days' AND cnst_addr.arc_srcsys_cd='SABO' and (coalesce(cnst_addr.cnst_addr_assessmnt_ctg, '') = 'Deliverable' and cnst_addr.dpv_cd <> 'Y' and cnst_addr.cnst_addr_typ_cd <> 'H')  THEN 34

ELSE 35 END
,cnst_addr.dw_srcsys_trans_ts desc
,E.dw_srcsys_trans_ts desc
,P.dw_srcsys_trans_ts desc
,ORG.dw_srcsys_trans_ts desc
) as row_num

from 
(
	select  addr.cnst_mstr_id
, addr.locator_addr_key locator_addr_key
,addr.assessmnt_ctg  cnst_addr_assessmnt_ctg
,addr.dpv_cd 
,addr.addr_typ_cd  cnst_addr_typ_cd
,addr.bz_cnst_addr_line1_addr 
,addr.bz_cnst_addr_line2_addr  
,addr.bz_cnst_addr_city_nm  
,addr.cnst_addr_state_cd  
,addr.cnst_addr_zip_5_cd      
,addr.cnst_addr_zip_4_cd 
,addr.arc_srcsys_cd 
,addr.dw_srcsys_trans_ts
,addr.cnst_addr_prefd_ind 
from eda.arc_mdm_vws.bzfc_cnst_addr addr
--left outer join arc_mdm_tbls.locator_addr loc_addr on addr.locator_addr_key=loc_addr.locator_addr_key
--left outer join eda.arc_mdm_vws.bz_assessmnt bz_assmnt on loc_addr.assessmnt_key=bz_assmnt.assessmnt_key 
where  
( 
(addr.bz_cnst_addr_line1_addr is not null) or 
(addr.bz_cnst_addr_line2_addr is not null) or 
(addr.bz_cnst_addr_city_nm is not null)  or 
(addr.cnst_addr_state_cd is not null)  or 
(addr.cnst_addr_zip_5_cd is not null) or 
(addr.cnst_addr_zip_4_cd is not null) 
) 
AND 
(addr.arc_srcsys_cd in   ('SABA', 'HSIP') 
OR 
/*  Below condition is to check all FR LOB source systems*/
addr.arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='PHSS')
)

) cnst_addr

INNER JOIN
eda.arc_mdm_vws.bz_cnst_mstr cnst_mstr
ON
cnst_addr.cnst_mstr_id = cnst_mstr.cnst_mstr_id


LEFT OUTER join
(
 SELECT cnst_mstr_id,
    arc_srcsys_cd,
    locator_email_addr,
    dw_srcsys_trans_ts,
    max_dw_srcsys_trans_ts,
    valid_email,
     email_key
FROM (
  SELECT 
    cnst_mstr_id,
    arc_srcsys_cd,
    locator_email_addr,
    dw_srcsys_trans_ts,
    MAX(dw_srcsys_trans_ts) OVER (PARTITION BY cnst_mstr_id) AS max_dw_srcsys_trans_ts,
    CASE 
  WHEN locator_email_addr ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
  THEN 'Y'
  ELSE 'N'
END AS valid_email,
    email_key
  FROM eda.arc_mdm_vws.bzfc_cnst_email
  WHERE (
      arc_srcsys_cd IN ('SABA', 'HSIP') 
      OR arc_srcsys_cd IN (
        SELECT arc_srcsys_cd 
        FROM eda.arc_mdm_vws.bz_arc_srcsys 
        WHERE line_of_service_cd = 'PHSS'
      )
  )
) AS sub
WHERE valid_email = 'Y'
) E

ON
cnst_addr.cnst_mstr_id=E.cnst_mstr_id
AND
cnst_addr.arc_srcsys_cd=E.arc_srcsys_cd

LEFT OUTER JOIN 

(
select
cnst_mstr_id
,bz_cnst_prsn_prefix_nm         
,bz_cnst_prsn_first_nm          
,bz_cnst_prsn_middle_nm        
,bz_cnst_prsn_last_nm          
,bz_cnst_prsn_suffix_nm 
,cnst_prsn_full_nm
,bz_cnst_alias_in_saltn_nm
,bz_cnst_alias_out_saltn_nm
,cnst_prsn_nm_typ_cd
,dw_srcsys_trans_ts
,arc_srcsys_cd
,cnst_prsn_nm_end_dt
from 
eda.arc_mdm_vws.bz_cnst_prsn_nm 
where cnst_prsn_nm_typ_cd in ('PN','LN')
AND
 (arc_srcsys_cd in  ('SABA', 'HSIP', 'CDIM') 
OR arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='PHSS'))

) P
ON 
cnst_addr.cnst_mstr_id = P.cnst_mstr_id
AND 
cnst_addr.arc_srcsys_cd=P.arc_srcsys_cd
LEFT OUTER JOIN 
(
select
cnst_mstr_id,
arc_srcsys_cd,
cnst_org_nm,
dw_srcsys_trans_ts
from
eda.arc_mdm_vws.bz_cnst_org_nm
where
cnst_org_nm_typ_cd  in ('PN','LN')
AND
 (arc_srcsys_cd in   ('SABA', 'HSIP', 'CDIM') 
OR arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='PHSS'))

) ORG

ON 
cnst_addr.cnst_mstr_id = ORG.cnst_mstr_id
AND 
cnst_addr.arc_srcsys_cd=ORG.arc_srcsys_cd

)

select  cnst_mstr_id,cnst_hsld_id,cnst_dsp_deceased_cd,cnst_data_src_cd,cnst_prsn_prfx_nm,cnst_prsn_f_nm,cnst_prsn_m_nm,cnst_prsn_l_nm,cnst_prsn_sfx_nm,cnst_prsn_full_nm,cnst_alias_in_saltn_nm,cnst_alias_out_saltn_nm,locator_addr_key,cnst_addr_assessmnt_ctg,dpv_cd,cnst_addr_typ_cd,cnst_line_1_addr,cnst_line_2_addr,cnst_city_nm,cnst_st_cd,cnst_zip_5_cd,cnst_zip_4_cd,cnst_email,cnst_org_nm,cnst_typ_dsc
from ranked_consolidated_data where row_num = 1;	
	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.cnst_cdi_phss_preferred_dmail) as nvarchar)+ ' Records inserted.';
        UPDATE mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_cnst_cdi_phss_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_cnst_cdi_phss_preferred_dmail', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$_$
