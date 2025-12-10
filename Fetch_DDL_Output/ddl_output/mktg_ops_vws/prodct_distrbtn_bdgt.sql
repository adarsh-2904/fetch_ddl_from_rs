CREATE OR REPLACE VIEW mktg_ops_vws.prodct_distrbtn_bdgt
AS --create view mktg_ops_vws.prodct_distrbtn_bdgt as 
/*
 * Created by : Majeed Mohammad
 * Created on : 10/31/2023
 * Purpose : To read the data from the table mktg_ops_tbls.prodct_distrbtn_bdgt
 */
SELECT	a.mstr_cust_cd, a.product_family, a.bdgt_dt, null as /*b.calendar_key as*/ bdgt_calendar_key, a.bdgt_distrbtns,  a.forcst_distrbtns,
		 a.dw_trans_ts,  a.row_stat_cd,  a.appl_src_cd,  a.load_id
FROM	mktg_ops_tbls.prodct_distrbtn_bdgt a /*inner join dw_common_vws.dim_calendar b on a.bdgt_dt=b.calendar_dt */
with no schema binding;