CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_giftran AS 
-- mktg_ops_vws.gmpbz_dim_giftran source

--------------------------------------------------------------------------------

 
create or replace view mktg_ops_vws.gmpbz_dim_giftran 
/*
Created by Michael Andrien
Create Date 9/18/2019
Purpose: This view was created for the GMS conversion system.  The dim giftran table did not exist in DDCOE.  The GMS team created this to redirect several descriptive attributes associated with the gift into a dimension to keep the width of the fact table down.
The Marketing Operations wing of the MODS team references this view to apply suppressions and various segment criteria in direct mail and email compaigns for the Consumer Fundraisng team (CFR).
*/
AS
SELECT
dim_giftran_key ,
nk_giftran_id ,
nk_gift_id ,
nk_gpp_id ,
nk_batch_id,
nk_basket_id,
gift_grp_id ,
adj_seq,
alt_trans_id ,
gift_img_id ,
gift_bundle_img_id ,
merchant_id ,
ask_id ,
sf_case_id,
vendor_batch_id ,
related_gift_id ,
finder_num ,
ask_src,
gift_org_facil_num ,
third_prty ,
dnr_adv_fund ,
inkind_dro_lctn ,
credit_card_num ,
credit_card_exp_dt  AS credit_card_exp_dt,
check_num,
shpmt_tracking_num ,
gift_note_txt ,
CAST(vendor_src_trans_ts AS TIMESTAMP) AS vendor_src_trans_ts,
backed_out_ind ,
back_out_reason_cd ,
vendor_src_cd ,
CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
srcsys_created_by ,
srcsys_modified_by ,
row_status_cd ,
CAST(dw_trans_ts AS TIMESTAMP)  AS dw_trans_ts,
load_id ,
appl_src_cd 
FROM eda.ufds_vws.gmpbz_dim_giftran
WHERE row_status_cd <> 'L'
WITH NO SCHEMA BINDING;