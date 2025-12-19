CREATE OR REPLACE VIEW mktg_ops_vws.cnst_addr_ncoa_log 
AS
/*
Created by: Majeed Mohammad
Created on: 06/20/2017
Purpose:  This view select all columns from arc_mdm_tbls.cnst_addr_ncoa_log. 
The columns assessmnt_ctg & county name of the new address are selected from arc_mdm_vws.bzfc_cnst_addr. 
This view is used in the update statements in the macro mktg_ops_tbls.ld_cnst_cdi_smry_fr_prfr

Modifed by: Majeed Mohammad 
Modified on: 06/22/2017
Purpose: Changed the partition on the qualify statement from old_locator_addr_key, old_cnst_mstr_id to old_locator_addr_key, new_cnst_mstr_id

Modifed by: Michael Andrien
Modified on: 10/30/2020
Purpose:  Modified the where clause to account for NULL ncoa.old_locator_addr_key values.  This was causing rows to be missing from our view.  Also, changed the inner join to a left join to ensure that we see all rows in the table.  Lastly, I added
the UNION to pickup all records.

Modifed by: Michael Andrien
Modified on: 10/01/2020
Purpose: Modified the partition for the qualify to address duplicate records in the view.  Also had to wrap the UNION with an outer SELECT to eliminate duplicates across the 2 unioned results.
*/ 

WITH first_part AS (
    SELECT 
        ncoa.old_cnst_mstr_id,
        ncoa.old_locator_addr_key,
        ncoa.cnst_addr_old_addr1,
        ncoa.cnst_addr_old_addr2,
        ncoa.cnst_addr_old_city_nm,
        ncoa.cnst_addr_old_state_cd,
        ncoa.cnst_addr_old_zip_5_cd,
        ncoa.new_cnst_mstr_id,
        ncoa.new_locator_addr_key,
        ncoa.cnst_addr_new_addr1,
        ncoa.cnst_addr_new_addr2,
        ncoa.cnst_addr_new_city_nm,
        ncoa.cnst_addr_new_state_cd,
        ncoa.cnst_addr_new_zip_5_cd,
        ncoa.cnst_addr_new_zip_4_cd,
        ncoa.file_nm,
        ncoa.load_id,
        ncoa.appl_src_cd,
        ncoa.dw_trans_ts,
        addr.assessmnt_ctg,
        addr.bz_cnst_addr_county_nm,
        ROW_NUMBER() OVER (PARTITION BY ncoa.new_cnst_mstr_id ORDER BY ncoa.dw_trans_ts DESC, ncoa.file_nm DESC) AS rn
    FROM eda.arc_mdm_vws.bza_cnst_addr_ncoa_log ncoa 
    INNER JOIN eda.arc_mdm_vws.bzfc_cnst_addr addr 
        ON ncoa.new_cnst_mstr_id = addr.cnst_mstr_id 
        AND ncoa.new_locator_addr_key = addr.locator_addr_key
    WHERE ncoa.old_locator_addr_key IS NOT NULL 
        AND (ncoa.old_locator_addr_key <> ncoa.new_locator_addr_key)
),

second_part AS (
    SELECT 
        ncoa.old_cnst_mstr_id,
        ncoa.old_locator_addr_key,
        ncoa.cnst_addr_old_addr1,
        ncoa.cnst_addr_old_addr2,
        ncoa.cnst_addr_old_city_nm,
        ncoa.cnst_addr_old_state_cd,
        ncoa.cnst_addr_old_zip_5_cd,
        ncoa.new_cnst_mstr_id,
        ncoa.new_locator_addr_key,
        ncoa.cnst_addr_new_addr1,
        ncoa.cnst_addr_new_addr2,
        ncoa.cnst_addr_new_city_nm,
        ncoa.cnst_addr_new_state_cd,
        ncoa.cnst_addr_new_zip_5_cd,
        ncoa.cnst_addr_new_zip_4_cd,
        ncoa.file_nm,
        ncoa.load_id,
        ncoa.appl_src_cd,
        ncoa.dw_trans_ts,
        addr.assessmnt_ctg,
        addr.bz_cnst_addr_county_nm,
        ROW_NUMBER() OVER (PARTITION BY ncoa.new_cnst_mstr_id ORDER BY ncoa.dw_trans_ts DESC, ncoa.file_nm DESC) AS rn
    FROM eda.arc_mdm_vws.bza_cnst_addr_ncoa_log ncoa 
    LEFT JOIN eda.arc_mdm_vws.bzfc_cnst_addr addr 
        ON ncoa.new_cnst_mstr_id = addr.cnst_mstr_id  
        AND ncoa.cnst_addr_new_addr1 = addr.locator_line1_addr
        AND ncoa.cnst_addr_new_addr2 = addr.locator_line2_addr
        AND ncoa.cnst_addr_new_city_nm = addr.locator_city
        AND ncoa.cnst_addr_new_state_cd = addr.locator_state
        AND ncoa.cnst_addr_new_zip_5_cd = addr.locator_zip_5
        AND ncoa.cnst_addr_new_zip_4_cd = addr.locator_zip_4
    WHERE ncoa.old_locator_addr_key IS NULL 
),

union_result AS (
    SELECT 
        old_cnst_mstr_id,
        old_locator_addr_key,
        cnst_addr_old_addr1,
        cnst_addr_old_addr2,
        cnst_addr_old_city_nm,
        cnst_addr_old_state_cd,
        cnst_addr_old_zip_5_cd,
        new_cnst_mstr_id,
        new_locator_addr_key,
        cnst_addr_new_addr1,
        cnst_addr_new_addr2,
        cnst_addr_new_city_nm,
        cnst_addr_new_state_cd,
        cnst_addr_new_zip_5_cd,
        cnst_addr_new_zip_4_cd,
        file_nm,
        load_id,
        appl_src_cd,
        dw_trans_ts,
        assessmnt_ctg,
        bz_cnst_addr_county_nm
    FROM first_part
    WHERE rn = 1
    
    UNION
    
    SELECT 
        old_cnst_mstr_id,
        old_locator_addr_key,
        cnst_addr_old_addr1,
        cnst_addr_old_addr2,
        cnst_addr_old_city_nm,
        cnst_addr_old_state_cd,
        cnst_addr_old_zip_5_cd,
        new_cnst_mstr_id,
        new_locator_addr_key,
        cnst_addr_new_addr1,
        cnst_addr_new_addr2,
        cnst_addr_new_city_nm,
        cnst_addr_new_state_cd,
        cnst_addr_new_zip_5_cd,
        cnst_addr_new_zip_4_cd,
        file_nm,
        load_id,
        appl_src_cd,
        dw_trans_ts,
        assessmnt_ctg,
        bz_cnst_addr_county_nm
    FROM second_part
    WHERE rn = 1
),

final_result AS (
    SELECT 
        old_cnst_mstr_id,
        old_locator_addr_key,
        cnst_addr_old_addr1,
        cnst_addr_old_addr2,
        cnst_addr_old_city_nm,
        cnst_addr_old_state_cd,
        cnst_addr_old_zip_5_cd,
        new_cnst_mstr_id,
        new_locator_addr_key,
        cnst_addr_new_addr1,
        cnst_addr_new_addr2,
        cnst_addr_new_city_nm,
        cnst_addr_new_state_cd,
        cnst_addr_new_zip_5_cd,
        cnst_addr_new_zip_4_cd,
        file_nm,
        load_id,
        appl_src_cd,
        dw_trans_ts,
        assessmnt_ctg,
        bz_cnst_addr_county_nm,
        ROW_NUMBER() OVER (PARTITION BY new_cnst_mstr_id ORDER BY dw_trans_ts DESC, file_nm DESC) AS rn
    FROM union_result
)

SELECT 
    old_cnst_mstr_id,
    old_locator_addr_key,
    cnst_addr_old_addr1,
    cnst_addr_old_addr2,
    cnst_addr_old_city_nm,
    cnst_addr_old_state_cd,
    cnst_addr_old_zip_5_cd,
    new_cnst_mstr_id,
    new_locator_addr_key,
    cnst_addr_new_addr1,
    cnst_addr_new_addr2,
    cnst_addr_new_city_nm,
    cnst_addr_new_state_cd,
    cnst_addr_new_zip_5_cd,
    cnst_addr_new_zip_4_cd,
    file_nm,
    load_id,
    appl_src_cd,
    dw_trans_ts,
    assessmnt_ctg,
    bz_cnst_addr_county_nm
FROM final_result
WHERE rn = 1
with no schema binding;