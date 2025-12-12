CREATE OR REPLACE VIEW mktg_ops_vws.dim_calendar 
AS
/*
Created By: Michael Andrien
Create Date: 10/17/2019
Purpose:  Created the Mktg version of the dim_calendar view 

Modified By: Majeed Mohammad
Modified Date: 12/01/2021
Purpose: Updates made based on Teamwork ticket#8108751. 
					Added the custom columns(monday_calendar_woy, monday_calendar_dow, monday_calendar_eow_cd, monday_calendar_eow_dt) to calculate the week as Mon-Sun instead of Sun-Sat. 

*/

SELECT calendar_key, calendar_dt, calendar_yr, calendar_mth, calendar_dy, calendar_doy, calendar_mth_abbr, calendar_woy, 
		case when EXTRACT(DOW FROM DATE_TRUNC('year', calendar_dt))=1 and calendar_dow = 'SUN' then calendar_woy
					when EXTRACT(DOW FROM DATE_TRUNC('year', calendar_dt))=1 and calendar_dow <> 'SUN' then calendar_woy +1 
 					when calendar_dow = 'SUN' then calendar_woy - 1 else calendar_woy 
 			end as monday_calendar_woy, 
		calendar_dow,
		case when calendar_dow = 'SUN' then calendar_dy_cd + 6 else calendar_dy_cd - 1 end as monday_calendar_dow, 
		calendar_dy_cd, calendar_eom_cd, calendar_eow_cd, 
		case when calendar_dow = 'SUN' then 'W' else NULL end as monday_calendar_eow_cd, 
		case when calendar_dow = 'SUN' then calendar_dt else calendar_dt+(8-calendar_dy_cd) end as monday_calendar_eow_dt, 
		calendar_hldy_cd,
		calendar_qtr, fiscal_yr, fiscal_mth, fiscal_dy, fiscal_doy, fiscal_mth_abbr,
		fiscal_woy, fiscal_dow, fiscal_dy_cd, fiscal_eom_cd, fiscal_eow_cd,
		fiscal_hldy_cd, fiscal_qtr, row_stat_cd, dw_trans_ts 
FROM  eda.dw_common_vws.dim_calendar
where  calendar_yr<9999 
WITH NO SCHEMA BINDING;