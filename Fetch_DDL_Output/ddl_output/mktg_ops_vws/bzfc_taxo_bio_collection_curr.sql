CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_taxo_bio_collection_curr
/*
Created By: Michael Andrien
Create Date: 07/16/2024
Purpose:	This view contains is a view of the GOAT Biomedical Collection Operation geographies.  We've added this to 
mkgt_ops_vws to integrate the biomed collection operation details into the blood donor survey reporting model.
*/

AS
SELECT *
FROM eda.arc_goats_subscr_vws.bzfc_taxo_bio_collection_curr
WITH NO SCHEMA BINDING;