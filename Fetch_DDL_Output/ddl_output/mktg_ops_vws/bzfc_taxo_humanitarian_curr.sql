CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_taxo_humanitarian_curr
/*
Created By: Michael Andrien
Create Date: 10/07/2025
Purpose:	This is a view of the GOAT Humanitarian geographies.  We've added this to 
mkgt_ops_vws to integrate to allow us to add the view to the Adobe Campaign schema definition so the Humanitarian region
details can be included in outbound Cross-Marketing campaigns.
*/

AS
SELECT *
FROM eda.arc_goats_subscr_vws.bzfc_taxo_humanitarian_curr
WITH NO SCHEMA BINDING
;