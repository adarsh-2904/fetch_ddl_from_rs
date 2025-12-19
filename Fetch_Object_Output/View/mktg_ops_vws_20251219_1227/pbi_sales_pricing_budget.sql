CREATE OR REPLACE VIEW mktg_ops_vws.pbi_sales_pricing_budget 
AS --create view mktg_ops_vws.pbi_sales_pricing_budget  as 
/*
 * Created by : Majeed Mohammad
 * Created on : 10/31/2023
 * Purpose : To read the data from the table mktg_ops_tbls.pbi_sales_pricing_budget 
 */
SELECT	cust_id, prodct, buckt, fy_year, fy_mnth,   fy_year_mnth , 
revenue, vol,
		dw_trans_ts, row_stat_cd, appl_src_cd, load_id
FROM	  mktg_ops_tbls.pbi_sales_pricing_budget 
with no schema binding;