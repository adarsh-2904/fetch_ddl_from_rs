create or replace view mktg_ops_vws.gmpbz_gift_sku
/*
Modified By: 	Michael Andrien
Modified Date:	9/12/2019
Purpose:	This view references the GMS Gift SKU dimension view found in gms_tbls.gift_sku.  The MODS team needs the view 
definition in the mktg_ops_vws database, which is the source for the Adobe Campaign application.  The SKU identifies the product purchased through the Red Cross catalogue program.
*/
AS
SELECT
gift_sku_key,
giftran_key,
gift_cnst_grp_key,
nk_gift_sku_id,
gpp_sku_seq,
sku_cd,
sku_dsc,
sku_qty,
active_ind,
backed_out_ind,
back_out_reason_cd,
vendor_src_cd,
CAST(srcsys_create_ts AS TIMESTAMP) AS srcsys_create_ts,
CAST(srcsys_update_ts AS TIMESTAMP) AS srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
CAST(dw_trans_ts AS TIMESTAMP) AS dw_trans_ts,
load_id,
appl_src_cd
FROM eda.ufds_vws.gmpbz_gift_sku
with no schema binding;