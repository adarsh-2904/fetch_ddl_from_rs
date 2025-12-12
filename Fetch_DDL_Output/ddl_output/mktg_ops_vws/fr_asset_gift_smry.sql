CREATE OR REPLACE VIEW mktg_ops_vws.fr_asset_gift_smry 
/*
Created by: Majeed Mohammad
Created on: 11/03/2022
Purpose: View requested by Greg to create the attibution view using the tables mktg_ops_tbls.adobe_dwb_intrctn & mktg_ops_tbls.adobe_dwb_txn
summary of investment asset gifts - stock / DAF / IRA
*/
AS  
select
  txn.cnst_mstr_id,
  sum(txn.stock_gift_ind) stock_gift_cnt,
  sum(txn.dnr_adv_gift_ind) daf_gift_cnt,
  count(case when chan.dntn_chan_cd = 'IRA' then txn.giftran_key end) as ira_gift_cnt
from mktg_ops_vws.gms_arc_fr_txn txn
left join mktg_ops_vws.gmpbz_dim_dntn_chan chan on txn.dntn_chan_key = chan.dntn_chan_key
where txn.stock_gift_ind = 1
  or txn.dnr_adv_gift_ind = 1
  or chan.dntn_chan_cd = 'IRA'
group by 1
having (coalesce(stock_gift_cnt, 0) + coalesce(daf_gift_cnt,0) + coalesce(ira_gift_cnt,0)) > 0
WITH NO SCHEMA BINDING
;