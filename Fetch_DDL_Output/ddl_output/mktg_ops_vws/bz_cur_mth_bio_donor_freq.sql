CREATE OR REPLACE VIEW mktg_ops_vws.bz_cur_mth_bio_donor_freq
AS

 /*Created by: Majeed Mohammad
Created on: 06/02/2020
Purpose: Created the view to be used in the report for Ken 

Modified by: Majeed Mohammad
Modified on: 07/23/2020
Purpose: Update the date conditions in the case statement to get the correct rolling year measures.  Previously, the -12 was -13 and so on. 

Modified by: Majeed Mohammad
Modified on: 08/05/2020
Purpose: Renamed the view from mktg_ops_vws.bz_bio_donor_freq_snpsht to mktg_ops_vws.bz_cur_mth_bio_donor_freq. Updated the SQL based on Ken's email
 
 Modified by: Majeed Mohammad
Modified on: 08/06/2020
Purpose: Instantiated this view. Updated the view to directly SELECT from the instantiated table 

Modified by: Majeed Mohammad
Modified Date: 08/12/2020
Purpose: Ken added new columns to calculate the REACTIVATED donors in different categgories (Inactive, Lapsed, deeply lapsed ) 

Modified by: Michael Andrien
Modified on: 05/14/2021
Purpose: Added the 4 new KPI listed below to the view.
	ft_prodctv_visit_0_12mth_cnt,
	ft_redcl_prodctv_visit_0_12mth_cnt, 
	ft_plasma_prodctv_visit_0_12mth_cnt,  
	ft_aph_prodctv_visit_0_12mth_cnt

Modified by: Michael Andrien
Modified on: 10/08/2024
Purpose: Added the prodctv_visit_62_mth_cnt, plasma_prodctv_62_mth_cnt, aph_prodctv_62_mth_cnt, redcell_prodctv_62_mth_cnt attributes
for use in calculating reactivated lapsed metrics.

*/
  
SELECT
		donor_id, month_num, year_num, visit_0_12mth_cnt, prodctv_visit_0_12mth_cnt,
		visit_13_24mth_cnt, prodctv_visit_13_24mth_cnt, visit_25_48mth_cnt,
		prodctv_visit_25_48mth_cnt, prodctv_visit_49_60mth_cnt, APH_prodctv_0_12mth_cnt,
		aph_prodctv_13_24mth_cnt, aph_prodctv_25_48mth_cnt, aph_prodctv_49_60mth_cnt,
		plasma_prodctv_0_12mth_cnt, plasma_prodctv_13_24mth_cnt, plasma_prodctv_25_48mth_cnt,
		plasma_prodctv_49_60mth_cnt, redcell_prodctv_0_12mth_cnt, redcell_prodctv_13_24mth_cnt,
		redcell_prodctv_25_48mth_cnt, redcell_prodctv_49_60mth_cnt, aph_visit_0_12mth_cnt,
		aph_visit_13_24mth_cnt, aph_visit_25_48mth_cnt, aph_visit_49_60mth_cnt,
		plasma_visit_0_12mth_cnt, plasma_visit_13_24mth_cnt, plasma_visit_25_48mth_cnt,
		plasma_visit_49_60mth_cnt, redcell_visit_0_12mth_cnt, redcell_visit_13_24mth_cnt,
		redcell_visit_25_48mth_cnt, redcell_visit_49_60mth_cnt, visit_49_60mth_cnt,
		prodctv_visit_62_mth_cnt, plasma_prodctv_62_mth_cnt, aph_prodctv_62_mth_cnt, redcell_prodctv_62_mth_cnt,	
		prodctv_visit_50_61mth_cnt, plasma_prodctv_50_61mth_cnt, aph_prodctv_50_61mth_cnt,
		redcell_prodctv_50_61mth_cnt, prodctv_visit_26_49mth_cnt, plasma_prodctv_26_49mth_cnt,
		aph_prodctv_26_49mth_cnt, redcell_prodctv_26_49mth_cnt, prodctv_visit_14_25mth_cnt,
		plasma_prodctv_14_25mth_cnt, aph_prodctv_14_25mth_cnt, redcell_prodctv_14_25mth_cnt,
		prodctv_visit_1_13mth_cnt, plasma_prodctv_1_13mth_cnt, aph_prodctv_1_13mth_cnt,
		redcell_prodctv_1_13mth_cnt, prodctv_visit_curr_mth_cnt, visit_curr_mth_cnt,
		plasma_prodctv_curr_mth_cnt, aph_prodctv_curr_mth_cnt, redcell_prodctv_curr_mth_cnt,
		ft_prodctv_visit_0_12mth_cnt, ft_redcl_prodctv_visit_0_12mth_cnt, ft_plasma_prodctv_visit_0_12mth_cnt, ft_aph_prodctv_visit_0_12mth_cnt,
		dw_trans_ts, row_stat_cd, appl_src_cd, load_id  
FROM mktg_ops_tbls.bz_cur_mth_bio_donor_freq
WITH NO SCHEMA BINDING;