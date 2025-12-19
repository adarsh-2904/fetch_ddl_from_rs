CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fact_phone_interaction_pg (cnst_mstr_id, orig_cnst_mstr_id, campgn_key, script_key, dspstn_key, adtnl_reqst_key, unit_key, orig_unit_key, call_trans_key, src_key, unq_id, cmpgn_cd, scrpt_num, addi_rqst_cd, pgm_typ, src_cd, call_ts_src, call_ts, call_dt, sf_acct_id, sf_cntct_id, sf_rm, sf_mng_dnr_ind, nk_ecode, ttl, first_nm, middle_nm, last_nm, sfx, birth_dt_src, birth_dt, altrd_dt_flg, drvd_age, lftm_gfts, last_gift_dt_src, last_gift_dt, lrgst_gift_amt, vlntr_flg, biomed_flg, trng_svc_flg, pgwg_scr_val, pgcga_scr_val, pgbeq_scr_val, pg_lob, cga_rspndr_ind, wg_rspndr_ind, srvy_rspndr_ind, lgcy_ind, non_rspndr_ind, addr_line1, addr_line2, addr_line3, city, state, zip_cd, addr_line1_updt, addr_line2_updt, addr_line3_updt, city_updt, state_updt, zip_cd_updt, phn_num_src, phn_num_updt_src, home_phn_num, home_phn_num_cln, mbl_phn_num, mbl_phn_num_cln, phn_num_updt_cln, phone_mobile_ind, phone_home_ind, email_addr, email_addr_updt, pg_rspns_typ, do_not_mail_ind, do_not_call_ind, cmnt, rpt_cell_cd, rpt_cell_cd_id, trtmnt_cd, trtmnt_dsc, trtmnt_id, call_sgmt, call_start_ts_src, call_start_ts, call_end_ts_src, call_end_ts, elapsed_call_tm, dspstn_id, dspstn1_cd, dspstn2_cd, fiscal_yr, fiscal_qtr, rcrdg_file_nm, curr_prcsd_file_nm, dw_trans_ts, row_stat_cd, appl_src_cd, load_id) AS

/*
Modidfied By: Michael Andrien
Modified Date: 07/23/2024
Purpose: This view captures Planned Giving telerecruitment results.  We receive weekly campaign files current vendor MDS as well as an end of campaign (EOC) for each
telerecruitment campaign.  The weekly files are limited to the completed calls for the week whereas the EOC file contains one row for every constituent included
in the campaign.  The PG EOC file can contain call attempt rows for completed calls we receive in the weekly file.  We attempt to account for these duplicates and limit the
view to the final call result row.  We have noticed we can receive more than one final call row for a constituent - one for each phone number contacted.  There may be more than one
landline and more than one cell or a combination of cell and landline.  The view contains one row for the final call status for each unique phone line contacted.

Modified by: Michael Andrien
Modified date: 2025-04-23
Purpose: Added call recording file name attribute to the view - rcrdg_file_nm.
*/
/* Truncate existing data */
/* DELETE FROM mktg_ops_tbls.bzfc_fact_phone_interaction_pg ALL; */

/* Now reload the fact table */
/* INSERT INTO mktg_ops_tbls.bzfc_fact_phone_interaction_pg */
SELECT
/* Dimension Surrogate Keys */
    a.cnst_mstr_id, a.orig_cnst_mstr_id, b.campgn_key, CAST (0 AS INTEGER) AS script_key, d.dspstn_key, CAST (0 AS INTEGER) AS adtnl_reqst_key, um.unit_key, um.orig_unit_key, row_number() OVER (ORDER BY cnst_mstr_id NULLS FIRST, call_dt NULLS FIRST) AS call_trans_key, /* Dimension Natural Keys/ids */ e.src_key, a.unq_id, a.cmpgn_cd, CAST (NULL AS SMALLINT) AS scrpt_num, CAST (NULL AS CHARACTER VARYING(2)) AS addi_rqst_cd, a.pgm_typ, a.src_cd, /* Campaign Source Code */ a.call_ts_src, a.call_ts, a.call_dt, a.sf_acct_id, a.sf_cntct_id, a.sf_rm, a.sf_mng_dnr_ind, a.nk_ecode, a.ttl, a.first_nm, a.middle_nm, a.last_nm, a.sfx, a.birth_dt_src, a.birth_dt, a.altrd_dt_flg, a.drvd_age, a.lftm_gfts, a.last_gift_dt_src, a.last_gift_dt, a.lrgst_gift_amt, a.vlntr_flg, a.biomed_flg, a.trng_svc_flg, a.pgwg_scr_val, a.pgcga_scr_val, a.pgbeq_scr_val, a.pg_lob, a.cga_rspndr_ind, a.wg_rspndr_ind, a.srvy_rspndr_ind, a.lgcy_ind, a.non_rspndr_ind, a.addr_line1, a.addr_line2, a.addr_line3, a.city, a.state, a.zip_cd, a.addr_line1_updt, a.addr_line2_updt, a.addr_line3_updt, a.city_updt, a.state_updt, a.zip_cd_updt, a.phn_num_src, a.phn_num_updt_src, a.home_phn_num, a.home_phn_num_cln, a.mbl_phn_num, a.mbl_phn_num_cln, a.phn_num_updt_cln, a.phone_mobile_ind, a.phone_home_ind, a.email_addr, a.email_addr_updt, a.pg_rspns_typ, a.do_not_mail_ind, a.do_not_call_ind, a.cmnt, a.rpt_cell_cd, a.rpt_cell_cd_id, a.trtmnt_cd, a.trtmnt_dsc, a.trtmnt_id, a.call_sgmt, a.call_start_ts_src, a.call_start_ts, a.call_end_ts_src, a.call_end_ts, a.elapsed_call_tm, d.dspstn_id, a.dspstn1 AS dspstn1_cd, a.dspstn2 AS dspstn2_cd,
    /* Call Campaign Time Period */
    c.fiscal_yr, c.fiscal_qtr, a.rcrdg_file_nm, a.curr_prcsd_file_nm, a.dw_trans_ts, a.row_stat_cd, a.appl_src_cd, a.load_id
FROM mktg_ops_tbls.phone_interaction_pg_eoc AS a
LEFT OUTER JOIN mktg_ops_vws.bz_dim_phone_campgn AS b ON a.cmpgn_cd = b.campgn_cd
LEFT OUTER JOIN mktg_ops_vws.dim_calendar AS c ON a.call_dt = c.calendar_dt
LEFT OUTER JOIN mktg_ops_tbls.dim_phone_call_dspstn AS d ON COALESCE(a.dspstn1, '') = d.dspstn1_cd AND COALESCE(a.dspstn2, '') = d.dspstn2_cd
LEFT OUTER JOIN 
(
	SELECT
        src_key, src_cd
    FROM mktg_ops_vws.gmpbzal_dim_src AS gmpbzal_dim_src
    QUALIFY row_number() OVER (PARTITION BY src_cd ORDER BY src_key DESC NULLS LAST) = 1
) AS e (src_key, src_cd) ON a.src_cd = e.src_cd
LEFT OUTER JOIN mktg_ops_vws.dim_unit_merged AS um ON a.nk_ecode = um.orig_nk_ecode
WHERE a.row_stat_cd <> 'L'
WITH NO SCHEMA BINDING
;