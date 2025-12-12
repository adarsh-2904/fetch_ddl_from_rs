CREATE OR REPLACE VIEW mktg_ops_vws.dim_gl_acct AS 
CREATE OR REPLACE  VIEW  mktg_ops_vws.dim_gl_acct  AS
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Created By:  Michael Andrien
Create Date: 3/13/2020
Purpose:  The view exposes the common view for the CFS Dim GL Account table found in  dw_common_vws.dim_gl_acct..  The view is required in mktg_ops_vws to expose the view the the
Adobe Campaign schema.

Modified By: Michael Andrien
Modified Date: 09/18/2025
Purpose: Changed the database reference from dw_common_vws to bio_snp_vws when the view was recreated in the EDW 2.0 Redshift environment.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
SELECT * 
FROM eda.bio_snp_vws.dim_gl_acct
WITH NO SCHEMA BINDING;