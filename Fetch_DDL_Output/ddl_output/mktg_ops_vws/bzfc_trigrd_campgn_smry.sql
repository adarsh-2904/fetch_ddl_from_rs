CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_trigrd_campgn_smry AS
SELECT  
    launch_date AS launch_dt, 
    'Email'::varchar(10) AS channel, 
    lob, 
    target_audience,  
    delivery_label,
    calendar_yr::varchar(4) || 'Q' || calendar_qtr::varchar(1) AS yrqtr,
    src_cd,
    subsrc_cd,
    campgn_program_nm,
    xpromo_ind, 
    is_trigg_msg_ind, 
    sent_cnt, 
    open_cnt, 
    click_cnt, 
    bounce_cnt, 
    unsub_cnt
FROM 
(
    SELECT
        DATE(calendar_yr::varchar || '-' || 
            CASE cal.calendar_qtr
                WHEN 1 THEN '01'
                WHEN 2 THEN '04'
                WHEN 3 THEN '07'
                WHEN 4 THEN '10'
            END || '-01') AS launch_date,
        cal.calendar_qtr, 
        cal.calendar_yr,
        CASE
            WHEN a.subsrc_cd ILIKE '%lobwelcomebio%' THEN 'Multi'
            WHEN a.subsrc_cd ILIKE '%newdonor%sustainer%' THEN 'CFR'
            WHEN a.subsrc_cd ILIKE '%newdonorwelcome%' THEN 'CFR'
            WHEN a.src_cd ILIKE '%NHQFY%%MKRS%' THEN 'Market Research'
            WHEN a.src_cd ILIKE '%TIFNY%' THEN 'CFR'
            WHEN a.src_cd ILIKE '%NHQLOB_YOUTH%' THEN 'CFR'
            WHEN a.src_cd ILIKE '%NHQLOB_SAF%' THEN 'SAF'
            WHEN b.campgn_program_nm ILIKE 'FR Welcome Series%' THEN 'CFR'
            WHEN b.campgn_program_nm = 'Triggered Series' THEN 'CFR'
            ELSE b.campgn_program_nm
        END AS lob,

        -- Target audience determination
        CASE
            WHEN a.subsrc_cd ILIKE '%lobwelcomebio%' THEN 'BIO'
            WHEN a.subsrc_cd ILIKE '%NewDonor3phss%' THEN 'CFR'
            WHEN a.subsrc_cd = 'NewDonor1Thankyou' THEN 'CFR'
            WHEN a.subsrc_cd = 'NewDonor2Survey' THEN 'CFR'
            WHEN a.subsrc_cd = 'newdonor4sustainerapp1' THEN 'CFR'
            ELSE 'Unknown'
        END AS target_audience,
		1 AS channel_key,
        CASE
            WHEN d.delivery_label ILIKE 'New Donor Welcome Series 1%' THEN 'New Donor Welcome Series 1'
            WHEN d.delivery_label ILIKE 'New Donor Welcome Series 2%' THEN 'New Donor Welcome Series 2'
            WHEN d.delivery_label ILIKE 'New Donor Welcome Series 3%' THEN 'New Donor Welcome Series 3'
            WHEN d.delivery_label ILIKE 'New Donor Welcome Series 4%' THEN 'New Donor Welcome Series 4'
            ELSE d.delivery_label 
        END AS delivery_label,
        a.src_cd,
        a.subsrc_cd,
        b.campgn_program_nm,
        d.xpromo_ind,
        d.is_trigg_msg_ind,
        SUM(a.email_sent_cnt) AS sent_cnt,
        SUM(a.email_open_ind) AS open_cnt,
        SUM(a.email_link_click_ind) AS click_cnt,
        SUM(a.total_bounce_cnt) AS bounce_cnt,
        SUM(a.unsbscrb_ind) AS unsub_cnt
        
    FROM mktg_ops_vws.gms_bzfc_fact_email_intrctn_smry a
        LEFT JOIN mktg_ops_vws.bz_dim_campgn b 
            ON a.campaign_key = b.campgn_key
        LEFT JOIN mktg_ops_vws.bz_dim_delivery d 
            ON a.delivery_key = d.delivery_key
        LEFT JOIN mktg_ops_vws.dim_email_segmnt e 
            ON a.email_segmnt_key = e.email_segmnt_key
        LEFT JOIN eda.dw_common_vws.dim_calendar cal 
            ON d.delivery_start_dt = cal.calendar_dt
    
    WHERE a.email_launch_dt >= '2017-01-01'::date
        AND a.src_cd NOT IN ('TESTIGNORE', '123456789012')
        AND d.is_trigg_msg_ind = 1
        
    GROUP BY
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
    HAVING
        SUM(a.email_sent_cnt) > 0 
) trigged_campaign_query
with no schema binding;