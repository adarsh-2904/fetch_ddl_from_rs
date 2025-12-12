CREATE OR REPLACE VIEW mktg_ops_vws.gms_arc_fr_txn_sustnr AS
    WITH 
    -- CTE for sustnr_base QUALIFY logic
    sustnr_base_ranked AS (
        SELECT 
            a.giftran_key, 
            a.cnst_mstr_id, 
            b.gift_src_cd, 
            a.gift_src_cd AS orig_src_cd, 
            a.dntn_gift_dt,
            b.dntn_gift_dt AS zero_dollar_gift_dt, 
            1 AS sustnr_gift_ind,
            ROW_NUMBER() OVER (
                PARTITION BY a.giftran_key, a.cnst_mstr_id 
                ORDER BY a.dntn_gift_dt ASC, 
                         SUBSTRING(a.gift_src_cd, 4, 4) ASC, 
                         b.dntn_gift_dt DESC
            ) AS rn
        FROM mktg_ops_vws.gms_arc_fr_txn a
        LEFT JOIN (
            SELECT  
                cnst_mstr_id, 
                gift_src_cd, 
                dntn_gift_dt, 
                fr_pmt_amt
            FROM mktg_ops_vws.gms_arc_fr_txn
            WHERE 
                fr_pmt_amt = 0 
                AND (gift_src_dsc <> 'RQZ00000M000' 
                     AND SUBSTRING(gift_src_cd, 1, 2) IN ('RQ', 'RP', 'RR') 
                     AND SUBSTRING(gift_src_cd, 1, 3) NOT IN ('RRD', 'RRS', 'RQS')) 
                AND dntn_gift_dt BETWEEN '12/15/2014' AND '01/01/2030'
        ) b ON a.cnst_mstr_id = b.cnst_mstr_id
        WHERE 
            a.gift_src_cd = 'RQZ00000M000' 
            AND (b.dntn_gift_dt <= a.dntn_gift_dt AND b.fr_pmt_amt = 0)  
            AND (a.dntn_gift_dt >= '07/01/2014' AND a.dntn_gift_dt < '01/01/2030')
    ),
    
    sustnr_base AS (
        SELECT 
            giftran_key, 
            cnst_mstr_id, 
            gift_src_cd, 
            orig_src_cd, 
            dntn_gift_dt AS gift_dt, 
            zero_dollar_gift_dt, 
            sustnr_gift_ind
        FROM sustnr_base_ranked
        WHERE rn = 1
    ),
    
    -- CTE for sustnr_frst_dntn QUALIFY logic
    sustnr_frst_dntn_ranked AS (
        SELECT 
            a.giftran_key, 
            a.cnst_mstr_id, 
            b.gift_src_cd, 
            a.gift_src_cd AS orig_src_cd, 
            a.dntn_gift_dt,
            b.dntn_gift_dt AS zero_dollar_gift_dt, 
            1 AS sustnr_gift_ind,
            ROW_NUMBER() OVER (
                PARTITION BY a.cnst_mstr_id, b.gift_src_cd, b.dntn_gift_dt 
                ORDER BY a.dntn_gift_dt ASC, 
                         SUBSTRING(a.gift_src_cd, 4, 4) ASC, 
                         b.dntn_gift_dt DESC
            ) AS rn
        FROM mktg_ops_vws.gms_arc_fr_txn a
        LEFT JOIN (
            SELECT  
                cnst_mstr_id, 
                gift_src_cd, 
                dntn_gift_dt, 
                fr_pmt_amt
            FROM mktg_ops_vws.gms_arc_fr_txn
            WHERE 
                fr_pmt_amt = 0 
                AND (gift_src_dsc <> 'RQZ00000M000' 
                     AND SUBSTRING(gift_src_cd, 1, 2) IN ('RQ', 'RP', 'RR') 
                     AND SUBSTRING(gift_src_cd, 1, 3) NOT IN ('RRD', 'RRS', 'RQS')) 
                AND dntn_gift_dt BETWEEN '12/15/2014' AND '01/01/2030'
        ) b ON a.cnst_mstr_id = b.cnst_mstr_id
        WHERE 
            a.gift_src_cd = 'RQZ00000M000' 
            AND (b.dntn_gift_dt <= a.dntn_gift_dt AND b.fr_pmt_amt = 0)  
            AND (a.dntn_gift_dt >= '07/01/2014' AND a.dntn_gift_dt < '01/01/2030')
    ),
    
    sustnr_frst_dntn AS (
        SELECT 
            giftran_key, 
            cnst_mstr_id, 
            gift_src_cd, 
            orig_src_cd, 
            dntn_gift_dt AS gift_dt, 
            zero_dollar_gift_dt, 
            sustnr_gift_ind
        FROM sustnr_frst_dntn_ranked
        WHERE rn = 1
    ),
    
    -- CTE for phone first sustainer donation QUALIFY logic
    phone_frst_sustnr_dntn_ranked AS (
        SELECT 
            a.giftran_key,
            a.cnst_mstr_id, 
            a.gift_src_cd, 
            a.dntn_gift_dt,
            ROW_NUMBER() OVER (
                PARTITION BY a.cnst_mstr_id, a.gift_src_cd 
                ORDER BY a.dntn_gift_dt
            ) AS rn
        FROM mktg_ops_vws.gms_arc_fr_txn a
        LEFT JOIN mktg_ops_vws.gmpbz_dim_gl_fcc b ON a.fcc_key = b.gl_fcc_key
        WHERE 
            (SUBSTRING(gift_src_cd, 1, 3) = 'RPG' 
             AND (SUBSTRING(gift_src_cd, 9, 1) = 'S' OR SUBSTRING(gift_src_cd, 9, 4) = 'T001'))  
            AND b.gl_fcc_cd = '27762'
    ),
    
    phone_frst_sustnr_dntn AS (
        SELECT 
            giftran_key, 
            cnst_mstr_id, 
            gift_src_cd, 
            dntn_gift_dt
        FROM phone_frst_sustnr_dntn_ranked
        WHERE rn = 1
    ),
    
    -- CTE for f2f first sustainer donation QUALIFY logic
    f2f_frst_sustnr_dntn_ranked AS (
        SELECT 
            a.giftran_key,
            a.cnst_mstr_id, 
            a.gift_src_cd, 
            a.dntn_gift_dt,
            ROW_NUMBER() OVER (
                PARTITION BY a.cnst_mstr_id, a.gift_src_cd 
                ORDER BY a.dntn_gift_dt
            ) AS rn
        FROM mktg_ops_vws.gms_arc_fr_txn a
        LEFT JOIN mktg_ops_vws.gmpbz_dim_gl_fcc b ON a.fcc_key = b.gl_fcc_key
        WHERE 
            SUBSTRING(gift_src_cd, 1, 3) = 'AFG'  
            AND b.gl_fcc_cd = '27010'
    ),
    
    f2f_frst_sustnr_dntn AS (
        SELECT 
            giftran_key, 
            cnst_mstr_id, 
            gift_src_cd, 
            dntn_gift_dt
        FROM f2f_frst_sustnr_dntn_ranked
        WHERE rn = 1
    ),
    
    -- CTE for online channel aggregations
    first_od_dntn AS (
        SELECT 
            cnst_mstr_id,  
            MIN(dntn_gift_dt) AS first_od_dntn_dt
        FROM mktg_ops_vws.gms_arc_fr_txn
        WHERE 
            recurring_ind = 1 
            AND SUBSTRING(gift_src_cd, 1, 3) <> 'AFG' 
            AND online_channel_cd = 'OD'
        GROUP BY cnst_mstr_id
    ),
    
    first_rd_dntn AS (
        SELECT 
            cnst_mstr_id,  
            MIN(dntn_gift_dt) AS first_rd_dntn_dt
        FROM mktg_ops_vws.gms_arc_fr_txn
        WHERE 
            recurring_ind = 1 
            AND SUBSTRING(gift_src_cd, 1, 3) <> 'AFG' 
            AND online_channel_cd = 'RD'
        GROUP BY cnst_mstr_id
    )
    
    -- Main SELECT with UNION ALL
    SELECT 
        sustnr_gifts.giftran_key, 
        sustnr_gifts.cnst_mstr_id, 
        sustnr_base.gift_src_cd, 
        sustnr_gifts.gift_src_cd AS sustnr_src_cd, 
        sustnr_gifts.dntn_gift_dt,  
        sustnr_base.gift_dt AS base_sustnr_gift_dt, 
        sustnr_base.zero_dollar_gift_dt, 
        sustnr_frst_dntn.gift_dt AS sustnr_frst_dntn_dt,
        sustnr_base.sustnr_gift_ind,
        1 AS dm_sustnr_gift_ind,
        0 AS phone_sustnr_gift_ind,
        0 AS f2f_sustnr_gift_ind,
        0 AS online_sustnr_gift_ind,
        CASE 
            WHEN sustnr_frst_dntn.gift_dt = sustnr_gifts.dntn_gift_dt THEN 1 
            ELSE 0 
        END AS first_dm_sustnr_gift_ind,
        0 AS first_phone_sustnr_gift_ind,
        0 AS first_f2f_sustnr_gift_ind,
        0 AS first_online_sustnr_gift_ind
    FROM mktg_ops_vws.gms_arc_fr_txn sustnr_gifts
    LEFT JOIN sustnr_base ON 
        sustnr_gifts.cnst_mstr_id = sustnr_base.cnst_mstr_id 
        AND sustnr_gifts.giftran_key = sustnr_base.giftran_key
    LEFT JOIN sustnr_frst_dntn ON 
        sustnr_gifts.cnst_mstr_id = sustnr_frst_dntn.cnst_mstr_id 
        AND sustnr_base.gift_src_cd = sustnr_frst_dntn.gift_src_cd 
        AND sustnr_base.zero_dollar_gift_dt = sustnr_frst_dntn.zero_dollar_gift_dt
    WHERE 
        (sustnr_gifts.dntn_gift_dt >= '07/01/2014' AND sustnr_gifts.dntn_gift_dt < '01/01/2030') 
        AND sustnr_gifts.gift_src_cd = 'RQZ00000M000' 
        AND sustnr_gifts.dntn_gift_dt >= sustnr_base.gift_dt

    UNION ALL

    SELECT 
        a.giftran_key,
        a.cnst_mstr_id, 
        a.gift_src_cd, 
        a.gift_src_cd, 
        a.dntn_gift_dt,  
        a.dntn_gift_dt AS base_sustnr_gift_dt,
        CAST(NULL AS DATE) AS zero_dollar_gift_dt,
        frst_sustnr_dntn.dntn_gift_dt AS sustnr_frst_dntn_dt,
        1 AS sustnr_gift_ind, 
        0 AS dm_sustnr_gift_ind,
        1 AS phone_sustnr_gift_ind,
        0 AS f2f_sustnr_gift_ind,
        0 AS online_sustnr_gift_ind,
        0 AS first_dm_sustnr_gift_ind,
        CASE 
            WHEN frst_sustnr_dntn.dntn_gift_dt = a.dntn_gift_dt THEN 1 
            ELSE 0 
        END AS first_phone_sustnr_gift_ind,
        0 AS first_f2f_sustnr_gift_ind,
        0 AS first_online_sustnr_gift_ind
    FROM mktg_ops_vws.gms_arc_fr_txn a
    LEFT JOIN mktg_ops_vws.gmpbz_dim_gl_fcc b ON a.fcc_key = b.gl_fcc_key
    LEFT JOIN phone_frst_sustnr_dntn frst_sustnr_dntn ON 
        a.cnst_mstr_id = frst_sustnr_dntn.cnst_mstr_id 
        AND a.gift_src_cd = frst_sustnr_dntn.gift_src_cd 
        AND a.dntn_gift_dt >= frst_sustnr_dntn.dntn_gift_dt
    WHERE 
        (SUBSTRING(a.gift_src_cd, 1, 3) = 'RPG' 
         AND (SUBSTRING(a.gift_src_cd, 9, 1) = 'S' OR SUBSTRING(a.gift_src_cd, 9, 4) = 'T001'))  
        AND b.gl_fcc_cd = '27762'

    UNION ALL

    SELECT 
        a.giftran_key,
        a.cnst_mstr_id, 
        a.gift_src_cd, 
        a.gift_src_cd, 
        a.dntn_gift_dt,  
        a.dntn_gift_dt AS base_sustnr_gift_dt,
        CAST(NULL AS DATE) AS zero_dollar_gift_dt,
        frst_sustnr_dntn.dntn_gift_dt AS sustnr_frst_dntn_dt,
        1 AS sustnr_gift_ind, 
        0 AS dm_sustnr_gift_ind,
        0 AS phone_sustnr_gift_ind,
        1 AS f2f_sustnr_gift_ind,       
        0 AS online_sustnr_gift_ind,
        0 AS first_dm_sustnr_gift_ind,
        0 AS first_phone_sustnr_gift_ind,
        CASE 
            WHEN frst_sustnr_dntn.dntn_gift_dt = a.dntn_gift_dt THEN 1 
            ELSE 0 
        END AS first_f2f_sustnr_gift_ind,
        0 AS first_online_sustnr_gift_ind
    FROM mktg_ops_vws.gms_arc_fr_txn a
    LEFT JOIN mktg_ops_vws.gmpbz_dim_gl_fcc b ON a.fcc_key = b.gl_fcc_key
    LEFT JOIN f2f_frst_sustnr_dntn frst_sustnr_dntn ON 
        a.cnst_mstr_id = frst_sustnr_dntn.cnst_mstr_id 
        AND a.gift_src_cd = frst_sustnr_dntn.gift_src_cd 
        AND a.dntn_gift_dt >= frst_sustnr_dntn.dntn_gift_dt
    WHERE 
        SUBSTRING(a.gift_src_cd, 1, 3) = 'AFG'  
        AND b.gl_fcc_cd = '27010'

    UNION ALL

    SELECT 
        giftran_key,
        a.cnst_mstr_id, 
        gift_src_cd, 
        gift_src_cd, 
        dntn_gift_dt,  
        dntn_gift_dt AS base_sustnr_gift_dt,
        CAST(NULL AS DATE) AS zero_dollar_gift_dt,
        CAST(recurng_start_dt AS DATE) AS sustnr_frst_dntn_dt,
        1 AS sustnr_gift_ind, 
        0 AS dm_sustnr_gift_ind,
        0 AS phone_sustnr_gift_ind,
        0 AS f2f_sustnr_gift_ind,
        1 AS online_sustnr_gift_ind,
        0 AS first_dm_sustnr_gift_ind,
        0 AS first_phone_sustnr_gift_ind,
        0 AS first_f2f_sustnr_gift_ind,
        CASE 
            WHEN online_channel_cd = 'OD' 
                 OR (CAST(recurng_start_dt AS DATE) = dntn_gift_dt 
                     OR CAST(recurng_start_dt AS DATE) + 1 = dntn_gift_dt) THEN 1
            WHEN first_od_dntn_dt IS NULL AND first_rd_dntn_dt = dntn_gift_dt THEN 1
            ELSE 0 
        END AS first_online_sustnr_gift_ind
    FROM mktg_ops_vws.gms_arc_fr_txn a
    LEFT JOIN first_od_dntn b ON a.cnst_mstr_id = b.cnst_mstr_id
    LEFT JOIN first_rd_dntn c ON a.cnst_mstr_id = c.cnst_mstr_id
    WHERE 
        recurring_ind = 1 
        AND SUBSTRING(gift_src_cd, 1, 3) <> 'AFG' 
        AND online_channel_cd IN ('OD', 'RD')
WITH NO SCHEMA BINDING;