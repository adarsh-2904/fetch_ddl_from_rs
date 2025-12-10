CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_phone_campgn AS 
-- mktg_ops_vws.bz_dim_phone_campgn source

CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_phone_campgn  AS

/*
Created By: Michael Andrien
Create Date: 06/27/2023
Purpose: This dimension joins to the mktg_ops_vws.bzfc_fact_phone_interaction table and captures descriptive campaign details for phone campaign Marketing campaigns.

Modified By: Michael Andrien
Modified Date: 08/14/2023
Purpose: Added the row_number function to include the dimension key.

Modified By: Greg Seaberg
Implemented By: Michael Andrien
Modified Date: 08/15/2023
Purpose: Added additional columns from physical table.

Modified By: Michael Hall
Implemented By: Michael Hall
Modified Date: 12/10/2024
Purpose: View updated to incorporate the following ten fields added by MDS into the source file:
RecordCount, Completes, PledgedGifts, PledgedRevenue, FulfilledGifts, FulfilledRevenue, ElectronicGifts, ElectronicGiftRevenue,
PledgedRecurringGifts, and PledgedRecurringGiftRevenue.
*/
SELECT
    row_number() OVER (ORDER BY campgn_id NULLS FIRST) AS campgn_key,
    campgn_cd,
    campgn_id,
    campgn_typ,
    campgn_dsc,
    program_typ,
    fyr,
    qtr,
    start_dt,
    end_dt,
    billing_typ,
    bill_rate,
    cmpltd_cnt,
    pldgd_gift_cnt,
    pldgd_rev_amt,
    flfld_gift_cnt,
    flfld_rev_amt,
    elctrnc_gift_cnt,
    elctrnc_gift_rev_amt,
    pldgd_rcrng_gift_cnt,
    pldgd_rcrng_gift_rev_amt,
    dw_trans_ts
FROM mods_bi_rep.mktg_ops_tbls.dim_phone_campgn
with no schema binding;