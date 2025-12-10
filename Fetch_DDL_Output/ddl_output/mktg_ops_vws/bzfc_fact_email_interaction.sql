CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fact_email_interaction
/* Create Date: 01/16/2017
    Created By:  Michael Andrien
    Purpose:  This view provides a provides access to the Adobe email interaction records captured in mktg_ops_tbs.fact_email_interaction.  The Adobe sourc for the 
    email interacations is the NmsBroadLogRcp base table.   The MODS team decided to create a separate interaction fact table for each marketing channel (email, mail, phone
    text, etc).  This view applies to email interactions.

Modified By:  Michael Andrien
Modified Date: 3/8/2017
Purpose: Added Partition statement to the view to eliminate duplicate rows.  This is a temporary fix - Majeed is updating the Informatica mapping to remove the duplicates
				The duplicates are occuring because the delivery status in the broadlog table change change from pending to sent.
				
Modified By:  Majeed Mohammad
Modified Date: 11/27/17
Purpose: Commented out the partition statement. The mapping handles the dupes and does the UPSERT logic.  

Modified By:  Michael Andrien
Modified Date: 6/7/2018
Purpose: Added dim_delivery join to exclude email interaction row associated with deliveries where the exclude from reporting indicator (exclude_rptng_ind) is set to 1.

Modified By: Michael Andrien
Modified Date: 04/16/2020
Purpose:	Added logic to include both the src_key and comnictn_src_key so we can use this table in both the DDCOE CE universe and the GSM version of the CE universe.  The GMS universe
references the src_key and joins to mktg_ops_vws.gmpbzal_dim_src and the DDCOE CE universe referencts the mktg_ops_vws.bz_comnictn_src and join on the comnictn_src_key.

Modified By:  Majeed Mohammad
Modified Date: 06/02/2022
Purpose: Added the columns mktg_unit_key and mktg_nk_ecode 
*/

-- mktg_ops_vws.bzfc_fact_email_interaction source

AS
SELECT
    a.cnst_mstr_id, 
    a.orig_cnst_mstr_id,
    recipient_key, 
    nk_recipient_id, 
    recipient_zip_cd, 
    cnst_hsld_id, 
    nk_intrctn_id, 
    a.delivery_key, 
    a.nk_delivery_id, 
    campaign_key, 
    nk_operation_id, 
    c.src_key, 
    comnictn_src_key, 
    comnictn_typ_key, 
    chan_typ_key, 
    chan_typ_dsc, 
    unit_key, 
    nk_ecode, 
    mktg_unit_key, 
    mktg_nk_ecode, 
    intrctn_status_key, 
    nk_intrctn_status_dsc, 
    a.src_cd,
    a.subsrc_cd, 
    intrctn_dt_key, 
    intrctn_dt, 
    list_run_dt_key, 
    list_run_dt, 
    segmnt_key, 
    nk_segmnt_cd,  
    gen_segmnt_key, 
    fr_last_ta_acct_id, 
    offer_key, 
    email_id,  
    email_addr, 
    email_to_domain, 
    last_dntn_dt, 
    last_dntn_amt, 
    email_intrctn_ind, 
    a.srcsys_trans_ts, 
    a.dw_trans_ts, 
    a.row_stat_cd,
    a.appl_src_cd,
    a.load_id
FROM mktg_ops_tbls.fact_email_interaction a
LEFT JOIN mktg_ops_tbls.dim_delivery b 
    ON a.delivery_key = b.delivery_key
LEFT JOIN (
    SELECT src_key, src_cd
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
        FROM eda.ufds_vws.gmpbzal_dim_src
    ) sub
    WHERE rn = 1
) c 
    ON a.src_cd = c.src_cd
WHERE COALESCE(b.exclude_rptng_ind, 0) = 0
WITH NO SCHEMA BINDING;