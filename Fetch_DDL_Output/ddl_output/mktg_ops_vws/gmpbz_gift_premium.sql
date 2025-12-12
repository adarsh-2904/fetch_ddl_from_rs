create or replace view mktg_ops_vws.gmpbz_gift_premium 
/*
Modified By: 	Michael Andrien
Modified Date:	9/12/2019
Purpose:	This view references the GMS Gift Priemium reference view found in gmpbz_gift_premium.  A gift premium is a product offered to financial donor as an incentive to contribute money to a Red Cross appeal.  Not all gifts have a premium associated with them.
The MODS team needs the view definition in the mktg_ops_vws database, which is the source for the Adobe Campaign application. 
*/
AS

SELECT
gift_premium_key ,
giftran_key ,
gift_cnst_grp_key ,
nk_gift_premium_id ,
gpp_premium_seq ,
premium_cd ,
premium_dsc ,
active_ind ,
backed_out_ind ,
back_out_reason_cd ,
vendor_src_cd ,
CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
srcsys_created_by ,
srcsys_modified_by ,
row_status_cd,
CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
load_id,
appl_src_cd 
FROM eda.ufds_vws.gmpbz_gift_premium
with no schema binding;