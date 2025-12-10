CREATE OR REPLACE VIEW mktg_ops_vws.dv_active_segmnt_snapsht
AS
/*
Created By Michael Andrien
Create Date 8/28/2017
Purpose:  This view provides access to the active constituent snapshot metrics to the dv_active_segmnt_snapsht table.  These metrics	
				are used to track and assess our progress in growing our active cnst base by line of business (LOB) and to assess whether we are growing our multi-LOB cnst base.
				The snapshot table allows us to view the historical metrics.  A macro is run daily to insert the metrics at a daily grain.

Modified By Michael Andrien
Modified Date 8/31/2017
Purpose:  Added 9 new columns to capture the constituent type and LOB only and and LOB plus other or mult lob counts 
				(cnst_typ_cd, active_all_trans_fr_only_cnt, active_all_trans_fr_othr_cnt, active_all_trans_bio_only_cnt, active_all_trans_bio_othr_cnt, active_phss_rcs_only_cnt,active_phss_rcs_othr_cnt, active_vms_only_cnt, active_vms_othr_cnt)

Modified By:  Mike Andrien
Modified Date: 03/02/2018
Purpose: Added lapsed and new counts by LOB

Modified By:  Mike Andrien
Modified Date: 03/08/2018
Purpose: Added Reactivated counts for FR, Bio and PHSS

Modified By:  Mike Andrien
Modified Date: 03/13/2018
Purpose:  Added - add total lapsed, new and reactivated attributes (total_month_lapsed_cnt, total_month_new_active_cnt, total_month_reactivated_cnt)

Modified By:  Mike Andrien
Modified Date: 05/28/2018
Purpose:  Added DemandWare (DMW) attributes and segrated them from RCS, PHSS and PHSS RCS attributes

Modified By:  Mike Andrien
Modified Date: 07/06/2018
Purpose:  Added  DemandWare (DMW)  new, lapsed and reactivated metrics.  

Modified By:  Mike Andrien
Modified Date: 07/30/2018
Purpose:   Added the Multi-LOB 4,3,and 2 count attributes and the 2-LOB combination counts.

Modified By:  Mike Andrien
Modified Date: 03/28/2023
Purpose:  Added the new DemandWare course and store metrics below
	active_dmw_course_cnt (TITLE 'Active DMW Course Count'), 
	active_dmw_course_only_cnt  (TITLE  'Active DMW Course Only Count'),
	active_dmw_course_othr_cnt (TITLE  'Active DMW Course & Other Count'), 
	active_dmw_store_cnt (TITLE  'Active DMW Store Count'),
	active_dmw_store_only_cnt (TITLE  'Active DMW Store Only Count'), 
	active_dmw_store_othr_cnt (TITLE  'Active DMW Store & Other Count'), 
	active_dmw_course_nostore_cnt (TITLE  'Active DMW Course No Store Count'), 
	active_dmw_store_nocourse_cnt (TITLE  'Active DMW Store No Course Count'),	  

Modified By:  Michael Andrien
Modified Date: 07/20/2023
Purpose: Added the active_multi_ever_cnt attribute and renamed active_multi_ever_ind to active_multi_ever_cnt.
*/

SELECT
    snapsht_dt, --(TITLE 'Snapshot Date')
    cnst_typ_cd, -- (TITLE 'Constituent Type Code'),
	active_all_trans_fr_cnt, -- (TITLE 'Active FR Count All Trans'),
    active_all_trans_fr_only_cnt, -- (TITLE 'Active FR Only Count All Trans'),
    active_all_trans_fr_othr_cnt, -- (TITLE 'Active FR & Other Count All Trans'),
    fr_month_lapsed_cnt, -- (TITLE 'FR Monlthly Lapsed Count'),
    fr_month_new_active_cnt, -- (TITLE 'FR Monthly New Active Count'),
    fr_month_reactivated_cnt, -- (TITLE 'FR Monthly Reactived Count'),
	active_all_trans_bio_cnt, -- (TITLE 'Active Bio Count All Trans'),
    active_all_trans_bio_only_cnt, -- (TITLE 'Active Bio Only Count All Trans'),
    active_all_trans_bio_othr_cnt, -- (TITLE 'Active Bio & Other Count All Trans'),
    bio_month_lapsed_cnt, -- (TITLE 'Bio Monlthly Lapsed Count'),
    bio_month_new_active_cnt, -- (TITLE 'Bio Monthly New Active Count'),
    bio_month_reactivated_cnt, -- (TITLE 'Bio Monthly Reactived Count'),
    active_dmw_cnt, --  (TITLE 'Active DMW Count - All Trans'), 
    active_dmw_only_cnt, -- (TITLE 'Active DMW Only Count - All Trans'), 
    active_dmw_othr_cnt, -- (TITLE 'Active DMW & Other Count - All Trans'), 
	active_dmw_course_cnt, -- (TITLE 'Active DMW Course Count'), 
	active_dmw_course_only_cnt, --  (TITLE  'Active DMW Course Only Count'),
	active_dmw_course_othr_cnt, -- (TITLE  'Active DMW Course & Other Count'), 
	active_dmw_store_cnt, -- (TITLE  'Active DMW Store Count'),
	active_dmw_store_only_cnt, -- (TITLE  'Active DMW Store Only Count'), 
	active_dmw_store_othr_cnt, -- (TITLE  'Active DMW Store & Other Count'), 
	active_dmw_course_nostore_cnt, -- (TITLE  'Active DMW Course No Store Count'), 
	active_dmw_store_nocourse_cnt, -- (TITLE  'Active DMW Store No Course Count'),	  
    active_rcs_cnt, -- (TITLE 'Active RCS Count - All Trans'), 
    active_rcs_only_cnt, -- (TITLE 'Active RCS Only Count - All Trans'), 
    active_rcs_othr_cnt, -- (TITLE 'Active RCS & Other Count - All Trans'), 
    active_phss_cnt, --(TITLE 'Active PHSS Count - All Trans'),
    active_phss_only_cnt, -- (TITLE 'Active PHSS Only Count - All Trans'), 
    active_phss_othr_cnt, -- (TITLE 'Active PHSS & Other Count - All Trans'), 
    active_phss_rcs_cnt, -- (TITLE 'Active PHSS RCS Count - All Trans'),
    active_phss_rcs_only_cnt, -- (TITLE 'Active PHSS RCS Only Count - All Trans'),
    active_phss_rcs_othr_cnt, -- (TITLE 'Active PHSS RCS & Other Count - All Trans'),
    rcs_month_lapsed_cnt, -- (TITLE 'RCS Monlthly Lapsed Count'),
    rcs_month_new_active_cnt, -- (TITLE 'RCS Monthly New Active Count'),
    phss_month_lapsed_cnt, -- (TITLE 'PHSS Monlthly Lapsed Count'),
    phss_month_new_active_cnt, -- (TITLE 'PHSS Monthly New Active Count'),
    phss_month_reactivated_cnt, -- (TITLE 'PHSS Monthly Reactived Count'),
    dmw_month_lapsed_cnt, -- (TITLE 'DemandWare Monlthly Lapsed Count'),
    dmw_month_new_active_cnt, -- (TITLE 'DemandWare Monthly New Active Count'),
    dmw_month_reactivated_cnt, -- (TITLE 'DemandWare Monthly Reactived Count'),
    total_month_lapsed_cnt, --  (TITLE 'Total Monlthly Lapsed Count'),
    total_month_new_active_cnt, --  (TITLE 'Total Monthly New Active Count'),
    total_month_reactivated_cnt, --  (TITLE 'Total Monthly Reactivated Count'),
	active_vms_cnt, -- (TITLE 'Active Vol Count - All Transt'),
    active_vms_only_cnt, -- (TITLE 'Active Vol Only Count - All Transt'),
    active_vms_othr_cnt, -- (TITLE 'Active Vol & Other Count - All Transt'),
	active_cnst_cnt, -- (TITLE 'Active Cnst Count'),
	active_all_trans_cnst_cnt, -- (TITLE 'Active Cnst Count - All Trans'),
	multi_lob_cnt, -- (TITLE 'Multi LOB Count'),
	multi_lob_all_trans_cnt, -- (TITLE 'Multi LOB Count - All Trans'),
	active_multi_ever_cnt, -- (TITLE 'Active Mult Ever Count'),
	four_lob_cnt, -- (TITLE 'Four Active LOB Count'), 
	three_lob_cnt, --  (TITLE 'Three Active LOB Count'), 
	two_lob_cnt, -- (TITLE 'Two Active LOB Count'), 
	fr_bio_cnt, --  (TITLE 'FR-BIO Active Count'),
	fr_phss_cnt, -- (TITLE 'FR-PHSS Active Count'), 
	fr_vms_cnt, -- (TITLE 'FR-VOL Active Count'), 
	bio_phss_cnt, -- (TITLE 'BIO-PHSS Active Count'), 
	bio_vms_cnt, --  (TITLE 'BIO-VOL Active Count'), 
	vol_phss_cnt --  (TITLE 'PHSS-VOL Active Count')
FROM mktg_ops_tbls.dv_active_segmnt_snapsht
WITH NO SCHEMA BINDING;