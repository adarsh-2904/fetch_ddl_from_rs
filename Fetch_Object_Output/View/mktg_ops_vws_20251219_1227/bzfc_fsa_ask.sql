create or replace VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Michael Andrien
Created date: 09-Feb-2015
Purpose: This view links the CDI Master ID to the DDCOE FSA Ask Summary table.  This view is different
                from the similarly named ddcoe_vws view.  We created this in mktg_ops_vws to support Campaign Effectiveness reporting.
                We have the same veiw built on the MKTG 2580, but it points to aprimo_lndng_tbls database. 
               The view is needed to support Planned Giving Lead/Ask analysis in the Campaign Effecitiveness universe.
               
Modified By:  Michael Andrien
Modified Date: 09-March-2015
Purpose: 	Added the derived source code, which is derived from the gift_src column.  The 
				Planned Giving team plans on including the TA source code in the SalesForce gift source column description.
				
Modified By:  Sowmya
Modified Date: 17-Aug-2016
Purpose: Renamed bzd_solicit_amt field to orig_solicit_amt.

Modified By:  Michael Andrien
Modified Date: 05/05/2017
Purpose:  Added the columns below for Greg Seaberg
				nk_sf_acct_id (TITLE 'SalesForce Acct Id'),
				nk_sf_cntct_id (TITLE 'SalesForce Contact Id'),
				nk_ta_acct_id (TITLE 'Team Approach Acct Id'),
				nk_ta_nm_id (TITLE 'Team Approach Name Id'),

Modified By:  Michael Andrien
Modified Date: 06/26/2018
Purpose: Modified the join strategy to leverage the new mktg_ops_vws.bzl_cnst_mstr_fsa_acct_cntct view, which links the SF account to the SF contact ids. 
			NOTE: We added the b.cntct_bzd_SFID, b.cntct_bzd_SFID_2, b.ag_bzd_SFID and b.ag_bzd_SFID_2 attributes, which are the values visible in the SF application.
			
Modified By:  Michael Andrien
Modified Date: 05/22/2019
Purpose: Added the FSA Ask Sequence Number (fsa_ask_seqnc_num) to enable us to eliminate duplicate ask records in Campaign Effectiveness reports.  Adding the cntct_cnst_mstr_id to the view creates
duplicate ask records when the SalesForce account has more than one contact in the account.  The view has one row per acount contact.  To avoid over counting gifts and gift/ask amounts we'll leverage the 
fsa_ask_seqnc_num attribute in reports to limit our selection to fsa_ask_seqnc_num = 1.
---------------------------------------------------------------------------------------------------------------------------- */
mktg_ops_vws.bzfc_fsa_ask
AS

SELECT
    b.cntct_cnst_mstr_id,
    a.cnst_cultstrat_key,
    a.ask_acct_cnst_fsa_key,
    a.sf_ask_id,
    ROW_NUMBER() OVER (PARTITION BY a.sf_ask_id ORDER BY b.cntct_nk_sf_cntct_id) AS ask_seqnc_num,
    b.cntct_nk_sf_acct_id,
    b.cntct_nk_sf_cntct_id,
    b.cntct_bzd_SFID,
    b.cntct_bzd_SFID_2,
    b.ag_nk_ta_acct_id,
    b.ag_nk_ta_nm_id,
    b.ag_bzd_SFID,
    b.ag_bzd_SFID_2,
    a.ask_acct_nm,
    a.nk_sf_cultstrat_id,
    a.bzd_ask_children_cnt,
    a.bzd_orig_ask_ind,
    a.rec_typ,
    a.strat_nm,
    a.acct_ctg,
    a.sf_gift_typ,
    a.sf_gift_vehicle,
    a.gift_src, -- FSA Patch 62
    CASE  
        WHEN POSITION('- AP' IN gift_src) = 0 THEN NULL
        ELSE SUBSTRING(gift_src FROM POSITION('- AP' IN gift_src) + 2 FOR 12)
    END AS bzd_src_cd,
    a.gift_honor_roll, -- FSA Patch 62
    a.stage,
    a.next_step,
    a.cultstrat_dt,
    a.prblty_pct,
    a.amt,
    a.bzd_expected_ask_amt,
    a.orig_solicit_amt,
    a.bzd_pledged_amt,
    a.bzd_rcvd_amt,
    a.bzd_prspctng_amt,
    a.in_kind_ind,
    a.parent_cultstrat_id,
    a.bzd_fr_dashboard_exclude_ind,
    a.created_dt,
    a.clse_dt,
    a.bzd_original_clse_dt,
    a.bzd_ask_clse_dt_chng_ind,
    a.solicit_dt,
    a.pledged_dt,
    a.rcvd_dt,
    a.expected_ask_dt,
    a.bzd_ask_rcvd_2dy_ind,
    a.bzd_mngd_gift_ind,
    a.bzd_mngd_gift_rcvd_20wk_ind,
    a.bzd_spot_gift_ind,
    a.bzd_unmngd_gift_dt_ind,
    a.unit_key,
    a.solicitn_typ,
    a.solicitn_strat,
    a.fundrsng_pckge,
    a.fundrsng_prog,
    a.ask_strat,
    a.appl_src_cd,
    a.ask_ownr_cnst_fsa_key,
    a.ask_ownr_unit_key,
    a.dnr_cnst_fsa_key,
    a.chptr_stff_cnst_fsa_key,
    a.inflncr_cnst_fsa_key,
    a.bzd_exp_gft_dt,
    a.bzd_exp_gft_amt,
    a.bzd_unit_key,
    a.bzd_ownr_cnst_fsa_key,
    a.bzd_gft_dt,
    a.bzd_gft_amt
FROM ddcoe_vws.bzfc_fsa_ask a
LEFT JOIN mktg_ops_vws.bzl_cnst_mstr_fsa_acct_cntct b 
    ON a.ask_acct_cnst_fsa_key = 
        CASE 
            WHEN b.cntct_cnst_typ_cd = 'or' THEN b.cntct_bzd_cnst_fsa_key 
            ELSE b.cntct_bzd_acct_fsa_key 
        END
    AND b.cntct_cnst_typ_cd IN ('or', 'in')
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY b.cntct_cnst_mstr_id, a.cnst_cultstrat_key 
    ORDER BY a.created_dt DESC
) = 1 with no schema binding;