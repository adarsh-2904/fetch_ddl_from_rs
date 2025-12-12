CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_phone_campgn_src_cd_xref AS 
-- drop view mktg_ops_vws.bz_dim_phone_campgn_src_cd_xref;

CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_phone_campgn_src_cd_xref AS

/*
Created By: Michael Andrien
Create Date:    09/25/2023
Purpose:    This view serves as a reference table to link the proper source code the the phone campaign.  The reference data
is fed to the MODS team by our Phone Campaign vendor MDS.

Modified By: Michael Andrien
Modified Date: 12/11/2023
Purpose:  Added logic to exclude logically deleted rows (row_stat_cd <> 'L')

Modified By: Michael Andrien
Modified Date: 01/31/2024
Purpose: Added the joins to include the campgn_key and src_key.

Modified By: Michael Andrien
Modified Date: 09/09/2025
Purpose: Add the WHERE condition below to exlude rows from the view where the campaign is not
found in the bz_dim_phone_campgn view.
    AND b.campgn_key is not null
    AND c.src_key is not null
*/
select 
    b.campgn_key, a.campgn_id, a.campgn_cd, c.src_key, a.src_cd, a.fulflmnt_chnl, a.dw_trans_ts, a.row_stat_cd, a.appl_src_cd, a.load_id
    FROM mktg_ops_tbls.dim_phone_campgn_src_cd_xref AS a
    LEFT OUTER JOIN mktg_ops_vws.bz_dim_phone_campgn AS b
        ON a.campgn_id = b.campgn_id
    LEFT OUTER JOIN (
    
    		SELECT
	        src_key, src_cd
	        from(
	        		SELECT
			        src_key, src_cd,
			        row_number() OVER (PARTITION BY src_cd ORDER BY active_ind DESC NULLS LAST, src_key DESC NULLS LAST) as rn
			        FROM mktg_ops_vws.gmpbzal_dim_src AS gmpbzal_dim_src
	        
	        ) as subqry
	
	    	where subqry.rn=1
        ) AS c (src_key, src_cd)
        ON collate(a.src_cd::text,'CI') = collate(c.src_cd::text,'CI')
    WHERE a.row_stat_cd <> 'L' AND b.campgn_key IS NOT NULL AND c.src_key IS NOT NULL
WITH NO SCHEMA BINDING
;