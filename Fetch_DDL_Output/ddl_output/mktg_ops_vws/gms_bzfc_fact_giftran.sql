CREATE OR REPLACE VIEW mktg_ops_vws.gms_bzfc_fact_giftran 
AS
/*
Created by Michael Andrien
Create Date 02/09/2021
Purpose: This view is a copy of the ufds_vws.bzfc_fact_giftran view.  The MODS team needs a copy of the view in the mktg_ops_vws database to enable access to the view
in the Adobe Campaign schema.  We also reference the view in the GMS Campaign Effectiveness universe.  The view is the base for our gms_arc_fr_txn table, but we haven't include every attribute
from the bzfc_giftran view in our TXN table.  Having the view in our mktg_ops_vws database enables us to join the TXN to the giftran view when additional attribute are needed
*/

SELECT
giftran_key,-- (TITLE 'Gift Transaction Key'),
gift_cnst_grp_key,-- (TITLE 'Gift Constituent Group Key'),
nk_giftran_id,-- (TITLE 'Nk Gift Transaction Identifier'),
nk_gpp_id, -- (TITLE 'Nk Gift Pre Processor Identifier'),
nk_batch_id, -- (TITLE 'Nk Batch Identifier'),
nk_basket_id, -- (TITLE 'Nk Basket Identifier'),
nk_gift_id, -- (TITLE 'Nk Gift Identifier'),
nk_ta_acct_id, -- (TITLE 'Nk TA Account Identifier'),
nk_ta_gift_seq, -- (TITLE 'Nk TA Gift Sequence'),
nk_ta_gift_adj_seq, -- (TITLE 'Nk Ta Gift Adjustment Sequence'),
nk_ta_batch_num, -- (TITLE 'Nk TA Batch Number'),
nk_ta_batch_seq, -- (TITLE 'Nk Ta Batch Sequence'),
nk_sf_gift_id, -- (TITLE 'Nk Salesforce Gift Identifier'),
gift_grp_id, -- (TITLE 'Gift Group Identifier'),
adj_seq, -- (TITLE 'Adjustment Sequence'),
gift_versn, -- (TITLE 'Gift Version'),
pledge_num, -- (TITLE 'Pledge Number'),
gift_num, -- (TITLE 'Gift Number'),
gift_rec_dt, -- (TITLE 'Gift Record Date') 
gift_rec_dt_key, -- (TITLE 'Gift Record Date Key'),
gift_dt, -- (TITLE 'Gift Date') 
gift_dt_key, -- (TITLE 'Gift Date Key'),
released_dt, -- (TITLE 'Released Date') 
released_dt_key, --  (TITLE 'Released Date Key'),
deposit_dt, -- (TITLE 'Deposit Date') AS deposit_dt,
deposit_dt_key, -- (TITLE 'Deposit Date Key'),
adj_dt, -- (TITLE 'Adjustment Date') AS adj_dt,
adj_dt_key, -- (TITLE 'Adjustment Date Key'),
orig_released_dt, -- (TITLE 'Original Released Date') 
orig_released_dt_key, --(TITLE 'Original Released Date Key'),
orig_deposit_dt, --(TITLE 'Original Deposit Date') 
orig_deposit_dt_key, --(TITLE 'Original Deposit Date Key'),
gift_amt, --(TITLE 'Gift Amount'),
totl_gift_amt, --(TITLE 'Total Gift Amount'),
gift_exps_amt, --(TITLE 'GIft Expense Amount'),
intended_gift_amt, --(TITLE 'Intended Gift Amount'),
split_gift_cnt, -- (TITLE 'Split Gift Count'),
active_ind, -- (TITLE 'Active Indicator'),
ack_ind, -- (TITLE 'Acknowledgement Indicator'),
thankyou_ind, -- (TITLE 'Thankyou Indicator'),
do_not_feed_gl_ind, -- (TITLE 'Do Not Feed General Ledger Indicator'),
gift_anon_ind, -- (TITLE 'Gift Anonymous Indicator'),
sc_ind, -- (TITLE 'Soft Credit Indicator'),
split_gift_ind, -- (TITLE 'Split Gift Indicator'),
trbt_gift_ind, -- (TITLE 'Tribute Gift Indicator'),
adj_ind, -- (TITLE 'Adjustment Indicator'),
installment_ind, -- (TITLE 'Installment Indicator'),
gift_in_care_of_ind, -- (TITLE 'Gift In Care Of Indicator'),
dnr_geogrphc_intrst_local_ind, -- (TITLE 'Donor Geographic Interest Local Indicator'),
bdgt_rlvng_ind, -- (TITLE 'Budget Relieving Indicator'),
released_ind, -- (TITLE 'Released Indicator'),
manual_entry_ind, -- (TITLE 'Manual Entry Indicator'),
reject_ind, -- (TITLE 'Reject Indicator'),
misdirected_ind, -- (TITLE 'Misdirected Indicator'),
evnt_benefit_ind, -- (TITLE 'Event Benefit Indicator'),
vsblty_ind, -- (TITLE 'Visibility Indicator'),
fr_credit_ind, -- (TITLE 'Fundraiser Credit Indicator'),
confidence_ind, -- (TITLE 'Confidence Indicator'),
prior_prd_ind, -- (TITLE 'Prior Period Indicator'),
gl_override_ind, -- (TITLE 'General Ledger Override Indicator'),
conv_trans_ind, -- (TITLE 'Converted Transaction Indicator'),
ta_trans_ind, -- (TITLE 'TA Transaction Indicator'),
stock_gift_ind, -- (TITLE 'Stock Gift Indicator'),
inkind_gift_ind, -- (TITLE 'Inkind Gift Indicator'),
dnr_adv_gift_ind, -- (TITLE 'Donor Advised Gift Indicator'),
episodic_gift_ind, -- (TITLE 'Episodic Gift Indicator'),
frc_inctv_prd_clsd_ind, -- (TITLE 'FRC Incentive Period Closed Indicator'),
gift_ask_mult_lnk_ind, -- (TITLE 'Gift Ask Multiple Link Indicator'),
treatment_cd, -- (TITLE 'Treatment Code'),
sub_src_cd, -- (TITLE 'Sub Source Code'),
rev_chan,-- (TITLE 'Revenue Channel'),
gl_credit_acct_string, -- (TITLE 'General Ledger Credit Account String'),
gl_debit_acct_string, -- (TITLE 'General Ledger Debit Account String'),
gmp_gift_locator_key, -- (TITLE 'Gift Management Portal Gift Locator Key'),
dim_gift_trbt_key, -- (TITLE 'Dimension Gift Tribute Key'),
dim_gift_stock_key, -- (TITLE 'Dimension Gift Stock Key'),
dim_gift_inkind_key, -- (TITLE 'Dimension Gift Inkind Key'),
dim_gift_sku_key, -- (TITLE 'Dimension Gift Sku Key'),
dim_gift_premium_key, -- (TITLE 'Dimension Gift Premium Key'),
dim_giftran_key, -- (TITLE 'Dimension Gift Transaction Key'),
rlse_key, -- (TITLE 'Release Key'),
acctng_batch_key, -- (TITLE 'Accounting Batch Key'),
bypass_batch_key, -- (TITLE 'Bypass Batch Key'),
adj_typ_key, -- (TITLE 'Adjustment Type Key'),
gift_stg_key, -- (TITLE 'Gift Stage Key'),
sustnr_typ_key, -- (TITLE 'Sustainer Type Key'),
pmt_mthd_key, -- (TITLE 'Payment Method Key'),
giftran_typ_key, -- (TITLE 'Gift Transaction Type Key'),
dntn_chan_key, -- (TITLE 'Donation Channel Key'),
merchant_key, -- (TITLE 'Merchant Key'),
vendor_key, -- (TITLE 'Vendor Key'),
prog_key, -- (TITLE 'Program Key'),
gl_fcc_key, -- (TITLE 'General Ledger Functional Cost Center Key'),
gl_credit_acct_key, -- (TITLE 'General Ledger Credit Account Key'),
gl_debit_acct_key, -- (TITLE 'General Ledger Debit Account Key'),
lnk_status, -- ( TITLE 'Link Status'),
ask_key, -- (TITLE 'Ask Key'),
fund_key, -- (TITLE 'Fund Key'),
gift_rev_credit_key, -- (TITLE 'Gift Revenue Credit Key'),
gift_rev_credit_rpt_key, -- (TITLE 'Gift Revenue Credit Report Key') ,
sending_lctn_key, -- (TITLE 'Sending Location Key'),
dnr_specified_lctn_key, -- (TITLE 'Donor Specified Location Key'),
sc_affl_key, -- (TITLE 'Soft Credit Affiliation Key'),
src_key, -- (TITLE 'Source Key'),
qlty_assrnc_rslt_key, -- (TITLE 'Quality Assurance Result Key'),
pended_reason_key, -- (TITLE 'Pended Reason Key'),
reject_reason_key, -- (TITLE 'Reject Reason Key'),
gift_amt_tier_key, -- (TITLE 'Gift Amount Tier Key'),
back_out_batch_key, -- (TITLE 'Back Out Batch Key'),
tgt_typ_key, -- (TITLE 'Target Type Key'),
vendor_src_cd, -- (TITLE 'Vendor Source Code'),
srcsys_create_ts, -- (TITLE 'Create Timestamp') AS srcsys_create_ts,
srcsys_update_ts, -- (TITLE 'Update Timestamp') AS srcsys_update_ts,
srcsys_created_by, -- (TITLE 'Record Created By'),
srcsys_modified_by, -- (TITLE 'Record Modified By'),
row_status_cd, -- (TITLE 'Row Status Code'),
dw_trans_ts, -- (TITLE 'Dw Trans Ts') AS dw_trans_ts,
load_id, -- (TITLE 'Load Id'),
appl_src_cd, -- (TITLE 'Appl Src Cd'),
retrieved_trans_ind, -- (TITLE 'Retrieved Transaction Indicator'),
fin_released_dt, -- (TITLE 'Financial Released Date') 
fin_released_dt_key, -- (TITLE 'Financial Released Date Key'),
prvt_ind --(TITLE 'Private Indicator')
FROM eda.ufds_vws.bzfc_fact_giftran
WITH NO SCHEMA BINDING;