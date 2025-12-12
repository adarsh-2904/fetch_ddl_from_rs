CREATE OR REPLACE VIEW mktg_ops_vws.atg_order_registrants AS
SELECT 
    CAST(z.cnst_mstr_id AS INTEGER) AS cnst_mstr_id,
    CAST(0 AS INTEGER) AS cnst_hsld_id,
    z.order_key AS atg_order_key,
    z.nk_order_id AS nk_atg_order_id,
    bill_to_first_nm AS bill_to_first_nm,
    bill_to_middle_nm AS bill_to_middle_nm,
    bill_to_last_nm AS bill_to_last_nm,
    email AS bill_to_email,
    MAX(CASE WHEN addr_type = 'Billing' THEN addr_type ELSE NULL END) AS atg_b_addr_typ,
    MAX(CASE WHEN addr_type = 'Billing' THEN addr1 ELSE NULL END) AS atg_b_addr_line_1,
    MAX(CASE WHEN addr_type = 'Billing' THEN addr2 ELSE NULL END) AS atg_b_addr_line_2,
    MAX(CASE WHEN addr_type = 'Billing' THEN addr3 ELSE NULL END) AS atg_b_addr_line_3,
    MAX(CASE WHEN addr_type = 'Billing' THEN city ELSE NULL END) AS atg_b_city,
    MAX(CASE WHEN addr_type = 'Billing' THEN state ELSE NULL END) AS atg_b_state_cd,
    MAX(CASE WHEN addr_type = 'Billing' THEN zip_cd ELSE NULL END) AS atg_b_zip,
    COALESCE(atg_counts.atg_gift_cnt, 0) AS atg_gift_cnt,
    COALESCE(atg_counts.atg_course_cnt, 0) AS atg_course_cnt
FROM (
    SELECT DISTINCT 
        b.order_key,
        m.cnst_mstr_id,
        m.cnst_hsld_id,
        b.nk_order_id,
        b.bill_to_first_nm,
        b.bill_to_middle_nm,
        b.bill_to_last_nm,
        b.email,
        'Billing' AS addr_type,
        b.addr1,
        b.addr2,
        b.addr3,
        b.city,
        b.state,
        b.zip_cd,
        ROW_NUMBER() OVER (PARTITION BY b.order_key, b.nk_order_id, b.bill_to_last_nm, b.email ORDER BY addr_type) AS rnum
    FROM eda.atg_vws.dim_order_billing b
    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr_bridge mb 
        ON mb.cnst_mstr_subj_area_id = b.order_key AND mb.cnst_mstr_subj_area_cd = 'ATGO'
    LEFT JOIN eda.arc_mdm_vws.bz_cnst_mstr m ON m.cnst_mstr_id = mb.cnst_mstr_id
) z
LEFT JOIN (
    SELECT 
        b.order_key,
        SUM(CASE WHEN p.nk_product_cd LIKE 'prod%' THEN 1 ELSE 0 END) AS atg_gift_cnt,
        SUM(CASE WHEN p.nk_product_cd LIKE 'cours%' THEN 1 ELSE 0 END) AS atg_course_cnt
    FROM eda.atg_vws.fact_atg_order_line o 
    LEFT JOIN eda.atg_vws.dim_product p ON o.product_key = p.product_key
    LEFT JOIN eda.atg_vws.dim_order_billing b ON o.order_id = b.nk_order_id
    GROUP BY b.order_key
) atg_counts ON z.order_key = atg_counts.order_key
GROUP BY 
    z.cnst_mstr_id, 
    z.order_key, 
    z.nk_order_id, 
    bill_to_first_nm, 
    bill_to_middle_nm, 
    bill_to_last_nm, 
    email, 
    atg_counts.atg_gift_cnt, 
    atg_counts.atg_course_cnt
WITH NO SCHEMA BINDING;