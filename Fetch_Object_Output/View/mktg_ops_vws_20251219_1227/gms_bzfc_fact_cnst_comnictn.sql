CREATE OR REPLACE VIEW mktg_ops_vws.gms_bzfc_fact_cnst_comnictn 
AS
/*
Created By: Michael Andrien
Create Date: 09/15/2020
Purpose: This view is a copy of the GMS UFDS_VWS view.  The MODS team needs this view to produce a gift premium report from the Mktg Campaign
Effectiveness report.
*/

SELECT	cnst_comnictn_key, nk_cnst_comnictn_id, comnictn_rqst_dt,
		comnictn_dw_extr_dt, comnictn_sent_dt, comnictn_bounce_return_dt,
		salutn, addressee, comnictn_prpse_key, comnictn_key, dlvry_mthd_key,
		comnictn_addr_key, comnictn_extr_addr_key, comnictn_email_key,
		comnictn_phn_key, comnictn_premium_key, comnictn_trbt_key, trbt_card_typ_key,
		rgnrt_reason_key, dim_comnictn_held_reason_key, rgnrt_ind, locator_override_ind,
		trbt_msg_line, comnictn_note_txt, giftran_key, nk_giftran_id,
		nk_gpp_id, nk_batch_id, nk_basket_id, nk_gift_id, gift_grp_id,
		adj_seq, gift_versn, pledge_num, gift_num, gift_rec_dt, gift_rec_dt_key,
		gift_dt, gift_dt_key, released_dt, released_dt_key, deposit_dt,
		deposit_dt_key, adj_dt, adj_dt_key, gift_amt, totl_gift_amt,
		gift_exps_amt, intended_gift_amt, active_ind, ack_ind, thankyou_ind,
		do_not_feed_gl_ind, gift_anon_ind, sc_ind, split_gift_ind, trbt_gift_ind,
		adj_ind, installment_ind, gift_in_care_of_ind, dnr_geogrphc_intrst_local_ind,
		bdgt_rlvng_ind, released_ind, manual_entry_ind, reject_ind, misdirected_ind,
		evnt_benefit_ind, confidence_ind, prior_prd_ind, gl_override_ind,
		treatment_cd, sub_src_cd, gl_credit_acct_string, gl_debit_acct_string,
		gmp_gift_locator_key, dim_gift_sku_key, dim_gift_stock_key, dim_gift_inkind_key,
		dim_gift_premium_key, dim_gift_trbt_key, dim_giftran_key, acctng_batch_key,
		bypass_batch_key, rlse_key, gift_cnst_grp_key, adj_typ_key, gift_stg_key,
		sustnr_typ_key, pmt_mthd_key, giftran_typ_key, dntn_chan_key,
		vendor_key, merchant_key, prog_key, gl_fcc_key, gl_credit_acct_key,
		gl_debit_acct_key, gift_rev_credit_key, sending_lctn_key, dnr_specified_lctn_key,
		sc_affl_key, fund_key, src_key, qlty_assrnc_rslt_key, pended_reason_key,
		reject_reason_key, back_out_batch_key, vendor_src_cd, srcsys_create_ts,
		srcsys_update_ts, srcsys_created_by, srcsys_modified_by, row_status_cd,
		dw_trans_ts, load_id, appl_src_cd
FROM eda.ufds_vws.bzfc_fact_cnst_comnictn
WITH NO SCHEMA BINDING;