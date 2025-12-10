CREATE OR REPLACE VIEW mktg_ops_vws.atg_registrants AS
SELECT 
    CAST(z.cnst_mstr_id AS INTEGER) AS cnst_mstr_id,
    CAST(0 AS INTEGER) AS cnst_hsld_id,
    z.person_key AS atg_prsn_key,
    z.nk_person_id AS nk_atg_person_id,
    z.email_opt_ind AS atg_email_opt_in_ind,
    MIN(ta_id) AS ta_id,
    first_nm AS atg_cnst_f_name,
    last_nm AS atg_cnst_l_name,
    email AS atg_email,
    registration_dt AS atg_registration_dt,
    MAX(CASE WHEN addr_type = 'Billing' THEN addr_type ELSE NULL END) AS atg_b_addr_typ,
    MAX(CASE WHEN addr_type = 'Billing' THEN addr1 ELSE NULL END) AS atg_b_addr_line_1,
    MAX(CASE WHEN addr_type = 'Billing' THEN addr2 ELSE NULL END) AS atg_b_addr_line_2,
    MAX(CASE WHEN addr_type = 'Billing' THEN city ELSE NULL END) AS atg_b_city,
    MAX(CASE WHEN addr_type = 'Billing' THEN state ELSE NULL END) AS atg_b_state_cd,
    MAX(CASE WHEN addr_type = 'Billing' THEN zip_cd ELSE NULL END) AS atg_b_zip,
    MAX(CASE WHEN addr_type = 'Billing' THEN phone ELSE NULL END) AS atg_b_phn,
    MAX(CASE WHEN addr_type = 'Home' THEN addr_type ELSE NULL END) AS atg_h_addr_typ,
    MAX(CASE WHEN addr_type = 'Home' THEN addr1 ELSE NULL END) AS atg_h_addr_line_1,
    MAX(CASE WHEN addr_type = 'Home' THEN addr2 ELSE NULL END) AS atg_h_addr_line_2,
    MAX(CASE WHEN addr_type = 'Home' THEN city ELSE NULL END) AS atg_h_city,
    MAX(CASE WHEN addr_type = 'Home' THEN state ELSE NULL END) AS atg_h_state_cd,
    MAX(CASE WHEN addr_type = 'Home' THEN zip_cd ELSE NULL END) AS atg_h_zip,
    MAX(CASE WHEN addr_type = 'Home' THEN phone ELSE NULL END) AS atg_h_phn,
    MAX(CASE WHEN addr_type = 'SHIPPING' THEN addr_type ELSE NULL END) AS atg_s_addr_typ,
    MAX(CASE WHEN addr_type = 'SHIPPING' THEN addr1 ELSE NULL END) AS atg_s_addr_line_1,
    MAX(CASE WHEN addr_type = 'SHIPPING' THEN addr2 ELSE NULL END) AS atg_s_addr_line_2,
    MAX(CASE WHEN addr_type = 'SHIPPING' THEN city ELSE NULL END) AS atg_s_city,
    MAX(CASE WHEN addr_type = 'SHIPPING' THEN state ELSE NULL END) AS atg_s_state_cd,
    MAX(CASE WHEN addr_type = 'SHIPPING' THEN zip_cd ELSE NULL END) AS atg_s_zip,
    MAX(CASE WHEN addr_type = 'SHIPPING' THEN phone ELSE NULL END) AS atg_s_phn,
    COALESCE(atg_counts.atg_gift_cnt, 0) AS atg_gift_cnt,
    COALESCE(atg_counts.atg_course_cnt, 0) AS atg_course_cnt
FROM (
    SELECT DISTINCT 
        p.person_key,
        m.cnst_mstr_id,
        m.cnst_hsld_id,
        p.nk_person_id,
        f.email_opt_ind,
        p.ta_id,
        p.first_nm,
        p.last_nm,
        p.email,
        d.addr_type,
        d.addr1,
        d.addr2,
        d.city,
        d.state,
        d.zip_cd,
        p.registration_dt,
        d.phone,
        ROW_NUMBER() OVER (PARTITION BY p.person_key, p.nk_person_id, f.email_opt_ind, p.ta_id, p.first_nm, p.last_nm, p.email, p.registration_dt ORDER BY d.addr_type) AS rnum
    FROM eda.atg_vws.dim_person_atg p
    LEFT JOIN eda.atg_vws.dim_person_pref f ON p.person_key = f.person_key      
    LEFT JOIN eda.atg_vws.dim_address d ON p.nk_person_id = d.nk_person_id 
    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge mb ON mb.cnst_mstr_subj_area_id = p.person_key AND mb.cnst_mstr_subj_area_cd = 'ATG'
    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr m ON m.cnst_mstr_id = mb.cnst_mstr_id
) z
LEFT JOIN (
    SELECT 
        o.person_key,
        SUM(CASE WHEN p.nk_product_cd LIKE 'prod%' THEN 1 ELSE 0 END) AS atg_gift_cnt,
        SUM(CASE WHEN p.nk_product_cd LIKE 'cours%' THEN 1 ELSE 0 END) AS atg_course_cnt
    FROM eda.atg_vws.fact_atg_order_line o 
    LEFT JOIN eda.atg_vws.dim_product p ON o.product_key = p.product_key
    GROUP BY o.person_key
) atg_counts ON z.person_key = atg_counts.person_key
GROUP BY 
    z.cnst_mstr_id, 
    z.person_key, 
    z.nk_person_id, 
    z.email_opt_ind, 
    z.ta_id, 
    first_nm, 
    last_nm, 
    email, 
    registration_dt, 
    atg_counts.atg_gift_cnt, 
    atg_counts.atg_course_cnt
WITH NO SCHEMA BINDING
;