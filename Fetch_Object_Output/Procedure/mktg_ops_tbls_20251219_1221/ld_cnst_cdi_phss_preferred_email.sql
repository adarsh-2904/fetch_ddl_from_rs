CREATE OR REPLACE PROCEDURE mktg_ops_tbls.ld_cnst_cdi_phss_preferred_email()
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
    VALUES ('ld_cnst_cdi_phss_preferred_email', 'Stored Procedure', 'Inprogress', v_start_time);


begin

delete from mktg_ops_tbls.cnst_cdi_phss_preferred_email;

insert into  mktg_ops_tbls.cnst_cdi_phss_preferred_email
(cnst_mstr_id, cnst_hsld_id, cnst_dsp_deceased_cd, cnst_data_src_cd,
		cnst_prsn_prfx_nm, cnst_prsn_f_nm, cnst_prsn_m_nm, cnst_prsn_l_nm,
		cnst_prsn_sfx_nm, cnst_prsn_full_nm, cnst_alias_in_saltn_nm,
		cnst_alias_out_saltn_nm, locator_addr_key, cnst_addr_assessmnt_ctg,
		cnst_addr_typ_cd, cnst_line_1_addr, cnst_line_2_addr, cnst_city_nm,
		cnst_st_cd, cnst_zip_5_cd, cnst_zip_4_cd, cnst_email, cnst_email_key,
		cnst_email_assessmnt_ctg, cnst_org_nm, cnst_typ_dsc)
with rank_consolidate as(
select
  FR_main.cnst_mstr_id
, FR_main.cnst_hsld_id  
, FR_main.cnst_dsp_deceased_cd
,E.arc_srcsys_cd  cnst_data_src_cd                   
,P.bz_cnst_prsn_prefix_nm cnst_prsn_prfx_nm        
,P.bz_cnst_prsn_first_nm  cnst_prsn_f_nm        
,P.bz_cnst_prsn_middle_nm  cnst_prsn_m_nm      
,P.bz_cnst_prsn_last_nm   cnst_prsn_l_nm       
,P.bz_cnst_prsn_suffix_nm  cnst_prsn_sfx_nm 
,P.cnst_prsn_full_nm cnst_prsn_full_nm
,P.bz_cnst_alias_in_saltn_nm cnst_alias_in_saltn_nm
,P.bz_cnst_alias_out_saltn_nm cnst_alias_out_saltn_nm    
,addr.locator_addr_key
,bz_assmnt.assessmnt_ctg  cnst_addr_assessmnt_ctg
,addr.addr_typ_cd  cnst_addr_typ_cd
,addr.bz_cnst_addr_line1_addr  cnst_line_1_addr     
,addr.bz_cnst_addr_line2_addr   cnst_line_2_addr    
,addr.bz_cnst_addr_city_nm   cnst_city_nm       
,addr.cnst_addr_state_cd  cnst_st_cd          
,addr.cnst_addr_zip_5_cd   cnst_zip_5_cd         
,addr.cnst_addr_zip_4_cd   cnst_zip_4_cd         
,E.locator_email_addr  cnst_email
,E.email_key cnst_email_key
,E.assessmnt_ctg cnst_email_assessmnt_ctg
,ORG.cnst_org_nm
,cast(case when FR_main.cnst_typ_cd='IN' then 'Individual'
           when FR_main.cnst_typ_cd='OR' then 'Organization'
    end as varchar(50)) as cnst_typ_dsc,
    
 ------row_num-----
 ROW_NUMBER() OVER (PARTITION BY FR_main.cnst_mstr_id  
ORDER BY
E.dw_srcsys_trans_ts desc
,P.dw_srcsys_trans_ts desc
,ORG.dw_srcsys_trans_ts desc
,addr.dw_srcsys_trans_ts desc
) as row_num

 
    
from
(
select cnst_mstr_id,arc_srcsys_cd, locator_email_addr,dw_srcsys_trans_ts,valid_email,email_key,
assessmnt_ctg
from(
	select cnst_mstr_id,arc_srcsys_cd, locator_email_addr,dw_srcsys_trans_ts,
max(dw_srcsys_trans_ts) over (partition by cnst_mstr_id) as max_dw_srcsys_trans_ts,
  CASE 
  WHEN locator_email_addr ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
  THEN 'Y'
  ELSE 'N'
END AS valid_email,
email_key,
assessmnt_ctg
from
eda.arc_mdm_vws.bzfc_cnst_email 
where (arc_srcsys_cd in ('SABA', 'HSIP') 
OR arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='PHSS'))
 and      
( assessmnt_ctg in ('Validated','Use With Caution') or assessmnt_ctg is null)      

) as subqry

where valid_email = 'Y'
) E

inner join

(
select 
cnst_mstr_id,
cnst_hsld_id,
cnst_dsp_deceased_cd,
cnst_typ_cd 
  from 
eda.arc_mdm_vws.bz_cnst_mstr
) FR_main

ON FR_main.cnst_mstr_id = E.cnst_mstr_id

LEFT OUTER JOIN 
(
select * FROM eda.arc_mdm_vws.bz_cnst_prsn_nm 
where (
arc_srcsys_cd in  ('SABA', 'HSIP') 
OR 
arc_srcsys_cd in (select arc_srcsys_cd FROM eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='PHSS'))
AND
cnst_prsn_nm_typ_cd in ('PN','LN' ) 
AND 
cnst_prsn_nm_end_dt = '9999-12-31'
) P
ON 
E.cnst_mstr_id = P.cnst_mstr_id
AND 
P.arc_srcsys_cd = E.arc_srcsys_cd

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
 (arc_srcsys_cd in  ('SABA', 'HSIP') 
OR arc_srcsys_cd in (select arc_srcsys_cd FROM  eda.arc_mdm_vws.bz_arc_srcsys where line_of_service_cd='PHSS'))
) ORG

ON 
E.cnst_mstr_id = ORG.cnst_mstr_id
AND 
E.arc_srcsys_cd = ORG.arc_srcsys_cd


LEFT OUTER JOIN 
eda.arc_mdm_vws.bz_cnst_addr addr
ON 
E.cnst_mstr_id = addr.cnst_mstr_id
AND 
E.arc_srcsys_cd = addr.arc_srcsys_cd
AND
addr.cnst_addr_end_dt = '9999-12-31'
 
left outer join eda.arc_mdm_vws.bza_locator_addr loc_addr on addr.locator_addr_key=loc_addr.locator_addr_key
left outer join eda.arc_mdm_vws.bz_assessmnt bz_assmnt on loc_addr.assessmnt_key=bz_assmnt.assessmnt_key
 
)

select cnst_mstr_id, cnst_hsld_id, cnst_dsp_deceased_cd, cnst_data_src_cd,
		cnst_prsn_prfx_nm, cnst_prsn_f_nm, cnst_prsn_m_nm, cnst_prsn_l_nm,
		cnst_prsn_sfx_nm, cnst_prsn_full_nm, cnst_alias_in_saltn_nm,
		cnst_alias_out_saltn_nm, locator_addr_key, cnst_addr_assessmnt_ctg,
		cnst_addr_typ_cd, cnst_line_1_addr, cnst_line_2_addr, cnst_city_nm,
		cnst_st_cd, cnst_zip_5_cd, cnst_zip_4_cd, cnst_email, cnst_email_key,
		cnst_email_assessmnt_ctg, cnst_org_nm, cnst_typ_dsc from rank_consolidate where row_num=1;	
	--audit update	
	v_end_time := CURRENT_TIMESTAMP;
	v_ok_message = cast((select count(*) from mktg_ops_tbls.cnst_cdi_phss_preferred_dmail) as nvarchar)+ ' Records inserted.';
        UPDATE mktg_ops_tbls.audit_log
        SET status = 'Complete', end_time = v_end_time,TaskMessage = v_ok_message
        WHERE proc_name = 'ld_cnst_cdi_phss_preferred_email' AND task_name = 'Stored Procedure' AND start_time = v_start_time;

--Insert in audit to Error
    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := CURRENT_TIMESTAMP;
			RAISE NOTICE 'NOTICE: An exception occurred.';
			
    INSERT INTO mktg_ops_tbls.audit_log (proc_name, task_name, status, start_time,end_time,TaskMessage)
    VALUES ('ld_cnst_cdi_phss_preferred_email', 'Stored Procedure', 'ERROR', v_start_time,v_end_time,SUBSTRING(SQLERRM, 1, 500));

--			UPDATE mktg_ops_tbls.audit_log
--            SET status = 'ERROR1', end_time = v_end_time--,TaskMessage = SUBSTRING(SQLERRM, 1, 100)
--            WHERE proc_name = 'ld_cnst_cdi_vms_preferred_dmail' AND task_name = 'Stored Procedure' AND start_time = v_start_time;
         
			--RAISE EXCEPTION 'An error occurred: %', SQLERRM;
			
    END;
END;




$_$
