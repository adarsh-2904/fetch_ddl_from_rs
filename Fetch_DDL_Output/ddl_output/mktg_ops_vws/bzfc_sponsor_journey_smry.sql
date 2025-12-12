CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_sponsor_journey_smry
/*
Created by: Michael Andrien
Created Date: 09/21/2018
Purpose:  This view contains the summary records for the weekly biomed sponsor journal email campaign.  The campaign is launched from Adobe campaign.  
          The MODS Operations team is creating and will run the initial campaign.  Once the Biomed Marketing team has implemented Adobe Campaign they will take ownership
          of the process.  The bzfc_sponsor_journey_detail view provides a historical snapshot of the detailed records that feed the summary table reference by Adobe.  The bzfc_sponsor_journey_smry view
          pivots data from the bzfc_sponsor_journey_smry table into one row per sponsor per drive date, with the customer rows pivoted to columns in the summary table.  
          We''ve included the start and end dates for the time period the list covers and record the list run date for audit purposes.
          
          Campaign Contact Strategy:
            *Touch point to sponsors ~40 days after the blood drive is completed to allow time to capture most of the distributed units (this is different for Donors, who receive the distribution info as soon as the unit has been distributed - could be 7 days, could be 40 days)
            *Distribution will be weekly (so 33-40 days from the drive)
            *Deployment via email only (Donors also receive App and Text, and some donors receive DM)
            *Drive-event triggered campaign
          Limitations:
            *will feature up to 5 hospital facilities - a drive may collect 100 units and have several dozen distribution locations, but we will only feature 1-5 locations to keep message manageable.
            *Only in-Region distributions will be featured, up to 5 hospitals
            *Will not feature distributions to other blood centers and internal transfers
            *Will not deploy to sponsors without an email (DRD can print and share, if DRD email is used)
Modified By: Michael Andrien
Modified Date: 01/16/2019
Purpose: Added join to the unified sponsor view (ubds_vws.bz_dim_sponsor_unf) and added the dr_territory__id, dr_territory_nm and dr_spon_acct_ldr attributes to the summary output.
*/
AS
SELECT
    a.spon_ext_nm, 
    a.nk_spon_ext_id, 
    a.spon_con_full_nm, 
    a.email_address,
    a.customer_nm1, 
    a.customer_nm2, 
    a.customer_nm3,  
    a.customer_nm4, 
    a.customer_nm5, 
    a.drive_start_dt, 
    a.weekly_start_dt, 
    a.weekly_end_dt, 
    b.dr_territory_id, 
    b.dr_territory_nm, 
    b.dr_spon_acct_ldr,
    a.list_run_dt
FROM mktg_ops_tbls.bzfc_sponsor_journey_smry a
LEFT JOIN eda.drms_vws.bz_dim_sponsor b 
    ON a.nk_spon_ext_id = b.nk_spon_ext_id
--LEFT JOIN ubds_vws.bz_dim_sponsor_unf b ON a.nk_spon_ext_id = b.dr_nk_spon_ext_id
with no schema binding;