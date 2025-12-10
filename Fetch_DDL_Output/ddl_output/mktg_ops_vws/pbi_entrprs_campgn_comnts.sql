CREATE OR REPLACE VIEW mktg_ops_vws.pbi_entrprs_campgn_comnts
AS
/*
Created By: Michael Andrien
Create Date: 01/10/2023
Purpose:  This view supports the PBI Enterprise Campaign dashaboard and captures the comments referenced within the dashboard.  Currently, the comments are maintained in
an Excel spreadsheet added to the table by manually running insert statements through the database query tool.  The insert statements are generated in the Excel file.
*/

select	
	commnt_dt, 
	dashbrd_nm, 
	commnt_typ, 
	commnt_1, 
	commnt_2, 
	commnt_3,
	commnt_4
from mktg_ops_tbls.pbi_entrprs_campgn_comnts
WITH NO SCHEMA BINDING;