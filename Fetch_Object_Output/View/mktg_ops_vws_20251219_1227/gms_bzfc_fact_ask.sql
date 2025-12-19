CREATE OR REPLACE VIEW mktg_ops_vws.gms_bzfc_fact_ask 
(ask_key, nk_sf_ask_guid, ask_id, ask_rec_typ, ask_acct_ctg, ask_gift_typ, ask_gift_vehicle, ask_gift_src, ask_strat_nm, ask_stg, ask_solicitn_typ, ask_solicitn_strat, ask_strat_typ, ask_fr_pckge, ask_fr_prog, dsgntn_nm, gift_honor_roll, anm_dcln_reason, recognition_prog, bdgt_rlvng, ldrshp, next_step, third_prty, dim_ask_key, frf_grp_key, ask_acct_key, ask_ownr_key, prev_ask_ownr_key, ask_modified_key, ask_dnr_key, ask_influencer_key, ask_decision_maker_key, ask_chpt_staff_key, ask_executive_key, ask_volntr_key, ask_nhq_staff_key, ask_referrer_key, ask_acct_hst_key, ask_ownr_hst_key, prev_ask_ownr_hst_key, ask_modified_hst_key, ask_rgn_key, ask_ownr_rgn_key, ask_influencer_rgn_key, ask_rev_credit_key, plnd_gvng_ask_key, grant_ask_key, ask_amt_tier_key, expected_ask_amt_tier_key, solicited_amt_tier_key, gift_source_key, gift_src_cd, ask_src_key, ask_src_cd, ask_dt, created_dt, clse_dt, orig_clse_dt, expected_ask_dt, expected_gift_dt, solicit_dt, pledged_dt, rcvd_dt, gift_dt, intrctn_dt_key, intrctn_dt, ask_amt, intl_ask_amt, totl_ask_amt, linked_gift_amt, val_in_kind_gift, expected_ask_amt, expected_gift_amt, solicited_amt, pledged_amt, prospected_amt, rcvd_ask_amt, gift_amt, ask_children_cnt, gift_ask_lnk_cnt, anon_ind, orig_ask_ind, first_pledge_installment_ind, clse_dt_change_ind, linked_gift_grp_ind, influencer_board_mmbr_ind, influencer_tifny_mmbr_ind, evnt_spnsrshp_ind, inkind_ind, graysky_ind, ldrshp_engmnt_ind, gift_ask_mult_lnk_ind, prev_ownr_assign_ts, prev_ownr_nm_list, prblty_pct, srcsys_create_ts, srcsys_update_ts, srcsys_created_by, srcsys_modified_by, row_status_cd, dw_trans_ts, load_id, appl_src_cd) 
AS

/*
Created By Michael Andrien
Create Date 3/25/2020
Purpose:  MODS/Mktg team needed the fact ask view to include in our Adobe schema and in our GMS CE Webi Universe for Campaign Effectiveness reporting.
We added joins to the fact giftran view to derive the gifr source key and code and included join logic to derive the ask source key and code from the ask_gift_src text attribute in the fact ask view.

Modified By:  Michael Andrien
Modified Date: 4/7/2020
Purpose:  Added interactio date and date key from the dim_src_2_intrctn_brdg table.

Modified By:  Michael Andrien
Modified Date: 5/5/2020
Purpose: Modifed the join logic for the ask src details to include  where ask_gift_src like any ('%APP%','%APC%','%ENR%')

Modified By:  Michael Andrien
Modified Date: 06/14/2022
Purpose: Added graysky_ind to the view.

Modified By:  Greg Seaberg
Implemented By:   Michael Andrien
Modified Date: 03/23/2023
Purpose: Modified case statement in subquery deriving ask_src_cd field to look at the last 12 characters of the ask_gift_src and return any that
  start with APP, APC, or ENR and end with 000.

Modified By:  Greg Seaberg
Implemented By:   Michael Andrien
Modified Date: 09/20/2023
Purpose: Modified join with gmpbzal_dim_src to take the most recent source key value for each source code; this addresses cases where there are
  multiple source description values for a single source code in the source code table, which previously resulted in duplicate rows for a single
  ask.

Modified By:  Greg Seaberg
Implemented By:   Michael Andrien
Modified Date: 04/01/2024
Purpose: Added join to ufds_vws.frfbz_dim_gift_source to capture ask_gift_src; this dimension table was added to frf_sf_tbls and ufds_vws to capture
				changes in the ask_gift_src field; previously this field was static, so changes made in Salesforce were not reflected in the EDW; this field
				is used to derive ask source code based on the last twelve characters, which in turn helps us tie asks back to GPLG campaigns.
*/
SELECT
a.ask_key, nk_sf_ask_guid, ask_id, ask_rec_typ, ask_acct_ctg, ask_gift_typ, ask_gift_vehicle, dgs.gift_source_name AS ask_gift_src, ask_strat_nm, ask_stg, ask_solicitn_typ, ask_solicitn_strat, ask_strat_typ, ask_fr_pckge, ask_fr_prog, dsgntn_nm, gift_honor_roll, anm_dcln_reason, recognition_prog, bdgt_rlvng, ldrshp, next_step, third_prty, dim_ask_key, frf_grp_key, ask_acct_key, ask_ownr_key, prev_ask_ownr_key, ask_modified_key, ask_dnr_key, ask_influencer_key, ask_decision_maker_key, ask_chpt_staff_key, ask_executive_key, ask_volntr_key, ask_nhq_staff_key, ask_referrer_key, ask_acct_hst_key, ask_ownr_hst_key, prev_ask_ownr_hst_key, ask_modified_hst_key, ask_rgn_key, ask_ownr_rgn_key, ask_influencer_rgn_key, ask_rev_credit_key, plnd_gvng_ask_key, grant_ask_key, ask_amt_tier_key, expected_ask_amt_tier_key, solicited_amt_tier_key, b.gift_source_key AS gift_source_key, b.gift_src_cd AS gift_src_cd, c.ask_src_key AS ask_src_key, c.ask_src_cd AS ask_src_cd, to_date(ask_dt, 'MM/DD/YYYY') AS ask_dt, to_date(created_dt, 'MM/DD/YYYY') AS created_dt, to_date(clse_dt, 'MM/DD/YYYY') AS clse_dt, to_date(orig_clse_dt, 'MM/DD/YYYY') AS orig_clse_dt, to_date(expected_ask_dt, 'MM/DD/YYYY') AS expected_ask_dt, to_date(expected_gift_dt, 'MM/DD/YYYY') AS expected_gift_dt, to_date(solicit_dt, 'MM/DD/YYYY') AS solicit_dt, to_date(pledged_dt, 'MM/DD/YYYY') AS pledged_dt, to_date(rcvd_dt, 'MM/DD/YYYY') AS rcvd_dt, to_date(a.gift_dt, 'MM/DD/YYYY') AS gift_dt, d.intrctn_dt_key AS intrctn_dt_key, d.intrctn_dt AS intrctn_dt, ask_amt, intl_ask_amt, totl_ask_amt, linked_gift_amt, val_in_kind_gift, expected_ask_amt, expected_gift_amt, solicited_amt, pledged_amt, prospected_amt, rcvd_ask_amt, a.gift_amt, ask_children_cnt, gift_ask_lnk_cnt, anon_ind, orig_ask_ind, first_pledge_installment_ind, clse_dt_change_ind, linked_gift_grp_ind, influencer_board_mmbr_ind, influencer_tifny_mmbr_ind, evnt_spnsrshp_ind, inkind_ind, graysky_ind, ldrshp_engmnt_ind, a.gift_ask_mult_lnk_ind, CAST (prev_ownr_assign_ts AS TIMESTAMP) AS prev_ownr_assign_ts, prev_ownr_nm_list, prblty_pct, CAST (a.srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts, CAST (a.srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts, a.srcsys_created_by, a.srcsys_modified_by, a.row_status_cd, CAST (a.dw_trans_ts AS TIMESTAMP) AS dw_trans_ts, a.load_id, a.appl_src_cd
    FROM eda.ufds_vws.bzfc_fact_ask AS a
    LEFT OUTER JOIN eda.ufds_vws.frfbz_dim_gift_source AS dgs
        ON a.gift_source_key = dgs.gift_source_key
    LEFT OUTER JOIN /* join to ask source dimension table from sf to capture current value */ (SELECT
        ask_key, a.src_key, b.src_cd
        FROM eda.ufds_vws.bzfc_fact_giftran AS a
        LEFT OUTER JOIN eda.ufds_vws.gmpbzal_dim_src AS b
            ON a.src_key = b.src_key
        WHERE ask_key IS NOT NULL AND ask_key <> 0) AS b (ask_key, gift_source_key, gift_src_cd)
        ON a.ask_key = b.ask_key
    LEFT OUTER JOIN (SELECT
        ask_key, NVL(b.src_key, '0') AS ask_src_key,
        CASE
            WHEN REGEXP_INSTR(dgs.gift_source_name, '- AP', 1, 1) > 0 THEN SUBSTRING(dgs.gift_source_name, REGEXP_INSTR(dgs.gift_source_name, '- AP', 1, 1) + 2, 12)
            WHEN REGEXP_INSTR(dgs.gift_source_name, '- ENR', 1, 1) > 0 THEN SUBSTRING(dgs.gift_source_name, REGEXP_INSTR(dgs.gift_source_name, '- ENR', 1, 1) + 2, 12)
            WHEN LEFT(RIGHT(TRIM(dgs.gift_source_name), 12), 3) IN ('APC', 'APP', 'ENR') AND RIGHT(TRIM(dgs.gift_source_name), 3) = '000' THEN RIGHT(TRIM(dgs.gift_source_name), 12)
            ELSE NULL
        END AS ask_src_cd
        FROM eda.ufds_vws.bzfc_fact_ask AS a
        LEFT OUTER JOIN eda.ufds_vws.frfbz_dim_gift_source AS dgs
            ON a.gift_source_key = dgs.gift_source_key
        LEFT OUTER JOIN /* join to ask source dimension table from sf to capture current value */ (SELECT
            src_key, src_cd
            FROM eda.ufds_vws.gmpbzal_dim_src
            WHERE ((src_cd LIKE '%APP%') OR (src_cd LIKE '%APC%') OR (src_cd LIKE '%ENR%'))
            QUALIFY row_number() OVER (PARTITION BY src_cd ORDER BY active_ind DESC NULLS LAST, src_key DESC NULLS LAST) = 1) AS b (src_key, src_cd)
            ON
            CASE
                WHEN REGEXP_INSTR(dgs.gift_source_name, '- AP', 1, 1) > 0 THEN SUBSTRING(dgs.gift_source_name, REGEXP_INSTR(dgs.gift_source_name, '- AP', 1, 1) + 2, 12)
                WHEN LEFT(RIGHT(TRIM(dgs.gift_source_name), 12), 3) IN ('APC', 'APP', 'ENR') AND RIGHT(TRIM(dgs.gift_source_name), 3) = '000' THEN RIGHT(TRIM(dgs.gift_source_name), 12)
                WHEN REGEXP_INSTR(dgs.gift_source_name, '- ENR', 1, 1) > 0 THEN SUBSTRING(dgs.gift_source_name, REGEXP_INSTR(dgs.gift_source_name, '- ENR', 1, 1) + 2, 12)
            END = b.src_cd
        WHERE ((dgs.gift_source_name LIKE '%APP%') OR (dgs.gift_source_name LIKE '%APC%') OR (dgs.gift_source_name LIKE '%ENR%'))) AS c (ask_key, ask_src_key, ask_src_cd)
        ON a.ask_key = c.ask_key
    LEFT OUTER JOIN (SELECT
        a.src_key, b.calendar_key AS intrctn_dt_key, a.intrctn_dt
        FROM mktg_ops_vws.dim_src_2_intrctn_brdg AS a
        LEFT OUTER JOIN mktg_ops_vws.dim_calendar AS b
            ON a.intrctn_dt = b.calendar_dt) AS d (src_key, intrctn_dt_key, intrctn_dt)
        ON c.ask_src_key = d.src_key
    WHERE a.row_status_cd <> 'L'
WITH NO SCHEMA binding 

;