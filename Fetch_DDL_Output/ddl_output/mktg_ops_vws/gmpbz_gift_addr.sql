CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_gift_addr AS 
-- mktg_ops_vws.gmpbz_gift_addr source

create or replace view mktg_ops_vws.gmpbz_gift_addr 
/*
Created By:	Michael Andrien
Create Date: 09/18/2020
Purpose: We are referecnce the ufds_vws view and exposing it in the mktg_ops_vws to includ in both the Adobe Campaign schema and in the GMS Mktg Campaign Effectiveness universe.  The gift address 
view is needed for the Premium gift report.  The address associated with the gift premium communication record is not master and is only found in this view.
*/
AS
SELECT	gift_addr_key, giftran_key, gift_cnst_grp_key, row_eff_from_ts,
		row_eff_to_ts, nk_gmp_addr_id, nk_gpp_addr_seq, nk_ta_acct_id,
		nk_ta_addr_id, gift_in_care_of, locator_addr_key, addr_typ_cd,
		addr_typ_dsc, addr_line1, addr_line2, city, state_cd, state_dsc,
		zipcode, zipcode_extsn, country_cd, country_dsc, cln_addr_line1,
		cln_addr_line2, cln_city, cln_zipcode, cln_state_cd, cln_state_dsc,
		cln_country_cd, cln_country_dsc, dpv_cd, seasnl_ind, seasnl_from_mth,
		seasnl_to_mth, seasnl_from_dt, seasnl_to_dt, addr_on_gift_ind,
		prefd_ind, active_ind, backed_out_ind, back_out_reason_cd, vendor_src_cd,
		srcsys_create_ts, srcsys_update_ts, srcsys_created_by, srcsys_modified_by,
		row_status_cd, dw_trans_ts, load_id, appl_src_cd
FROM eda.ufds_vws.gmpbz_gift_addr
with no schema binding;