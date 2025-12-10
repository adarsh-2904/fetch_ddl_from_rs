CREATE OR REPLACE VIEW mktg_ops_vws.bz_arc_fr_smry_rco_smry AS 
----------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------		bz_arc_fr_smry_rco_smry	--------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR
REPLACE VIEW mktg_ops_vws.bz_arc_fr_smry_rco_smry 
/*
Created by: Michael Andrien
Created on:  03/25/2020
Purpose: This view combines the RCO first time donor and last donation views to provied and RCO summary donation view to support Adobe Campaign communitications to the online donors.  This view was created to enable the Adobe Mktg Ops team
to send 'Thank You'' and 'Welcome Series' emails to donors through Adobe Campaign sooner than pulling it throug the ARC FR Smry profile because the gift can take 3-5 days to get processed in the official gift processing system.

Updated by: Michael Andrien (Update coded provided by Greg Seaberg)
Update: 05/14/2020
Purpose: Added columns for last sustaining RCO transaction

Updated by:			Greg Seaberg
Implemented by:	Michael Andrien
Updated date:		06/03/2024
Purpose: 				Added columns for subscription status as well as one-click sustainer upgrade public code, active status indicator, associated email, 
								and expiration date

Updated by:			Greg Seaberg
Implemented by:	Majeed Mohammad
Updated date:		12/10/2024
Purpose: 				Added columns for subscription last upgraded and magic link last created timestamps from rco_vws.bz_dim_subscription

Modified by: Majeed Mohammad
Modified on: 1/6/2025
Purpose: Added alias with suffix _TS to the columns subscription_last_upgraded & magic_link_last_created 

*/
AS
SELECT 
                cdi.cnst_mstr_id, 
                a.trans_id AS ft_trans_id, 
                a.rco_dntn_id AS ft_rco_dntn_id, 
                a.first_time_trans_dt AS ft_trans_dt, 
                a.billing_email AS ft_billing_email, 
                a.billing_f_nm AS ft_filling_f_nm, 
                a.billing_l_nm AS ft_billing_l_nm, 
                a.em_cnst_data_src_cd AS ft_em_cnst_data_src_cd, 
                a.em_cnst_email AS ft_em_cnst_email, 
                a.cnst_mstr_id_cnt AS ft_cnst_mstr_id_cnt, 
                a.first_cnst_mstr_id AS ft_first_cnst_mstr_id, 
                a.last_cnst_mstr_id AS ft_last_cnst_mstr_id,
                b.trans_id AS last_trans_id, 
                b.rco_dntn_id AS last_rco_dntn_id, 
                b.last_dntn_regis_dt AS last_trans_dt, 
                b.billing_email AS last_billing_email, 
                b.billing_f_nm AS last_billing_f_nm, 
                b.billing_l_nm AS last_billing_l_nm, 
                b.em_cnst_data_src_cd AS last_em_cnst_data_src_cd, 
                b.em_cnst_email AS last_em_cnst_email,
                CASE WHEN ft_trans_dt = b.last_dntn_regis_dt OR b.last_dntn_regis_dt IS NULL THEN 1 ELSE 0 end AS first_time_donat_ind,
                c.trans_id AS last_sustnr_trans_id, 
                c.rco_dntn_id AS last_sustnr_rco_dntn_id, 
                c.last_dntn_regis_dt AS last_sustnr_trans_dt, 
                c.billing_email AS last_sustnr_billing_email, 
                c.billing_f_nm AS last_sustnr_billing_f_nm, 
                c.billing_l_nm AS last_sustnr_billing_l_nm, 
                c.em_cnst_data_src_cd AS last_sustnr_em_cnst_data_src_cd, 
                c.em_cnst_email AS last_sustnr_em_cnst_email,
                c.rco_subscription_id AS last_sustnr_rco_subscription_id,
				c.subscription_stat AS last_sustnr_subscription_stat,
                c.online_channel_cd AS last_sustnr_online_channel_cd,
				c.nk_public_cd AS ocu_public_cd,
				c.ocu_email,
				c.ocu_active_ind,
				c.ocu_expiry_ts,
				c.subscription_last_upgraded_ts,
				c.magic_link_last_created_ts
FROM  eda.arc_mdm_vws.bz_cnst_mstr cdi
LEFT JOIN 
(               
                SELECT
	                cnst_mstr_id, 
	                trans_id, 
	                rco_dntn_id, 
	                first_time_trans_dt, 
	                billing_email, 
	                billing_f_nm, 
	                billing_l_nm, 
	                em_cnst_data_src_cd, 
	                em_cnst_email, 
	                cnst_mstr_id_cnt, 
	                first_cnst_mstr_id, 
	                last_cnst_mstr_id
                FROM mktg_ops_vws.bz_arc_fr_smry_rco_first_tm--exists
) a ON a.cnst_mstr_id = cdi.cnst_mstr_id
LEFT JOIN 
(
                SELECT 
	                cnst_mstr_id,
	                trans_id, 
	                rco_dntn_id, 
	                last_dntn_regis_dt, 
	                billing_email, 
	                billing_f_nm, 
	                billing_l_nm, 
	                em_cnst_data_src_cd, 
	                em_cnst_email
                FROM mktg_ops_vws.bz_arc_fr_smry_rco_last_donat b 
) b ON cdi.cnst_mstr_id = b.cnst_mstr_id
LEFT JOIN 
(
                SELECT 
					cnst_mstr_id,
					trans_id,
					rco_dntn_id,
					last_dntn_regis_dt,
					billing_email,
					billing_f_nm, 
					billing_l_nm,
					em_cnst_data_src_cd,
					em_cnst_email,
					rco_subscription_id,
					subscription_stat,
					online_channel_cd,
					nk_public_cd,
					ocu_email,
					ocu_active_ind,
					ocu_expiry_ts,
					subscription_last_upgraded_ts,
					magic_link_last_created_ts
                FROM mktg_ops_vws.bz_arc_fr_smry_rco_last_sustnr_donat
) c ON cdi.cnst_mstr_id = c.cnst_mstr_id                
WHERE a.cnst_mstr_id IS NOT NULL OR  b.cnst_mstr_id IS NOT NULL OR c.cnst_mstr_id IS NOT NULL with no schema binding;