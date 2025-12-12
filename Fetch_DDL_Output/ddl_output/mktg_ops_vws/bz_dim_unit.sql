CREATE OR REPLACE VIEW mktg_ops_vws.bz_dim_unit AS 
/*-----------------------------mktg_ops_vws.dim_unit View----------------------------------------------------------*/
/* Created By Micael Andrien - Original Create date - unknown
Modified 07/17/14 - Added 'TR' to the Unit Type constraint to include Regional Unit Type Records.  Requested by Alex Fulton
to support Crossroads Newletter.

Modified By: Michael Andrien
Modified Date: 12/17/2024
Purpose:	Added unit type 'R' to the view definition to inclde ecode 30140, 
which appears to be miscoded.

Modified By: Michael Andrien
Modified Date: 03/13/2025
Purpose:  Created the view in Redshift and converted format to run properly in Redshift
*/
  CREATE or REPLACE VIEW mktg_ops_vws.bz_dim_unit
   AS 
 --  LOCKING TABLE dw_common_vws.dim_unit FOR ACCESS
 --  LOCKING TABLE mktg_ops_vws.nhqmktg_cdrp_enrllmnt_sts FOR ACCESS
SELECT
    A.*,
    B.cdrp_enrollment_sts,
    B.cdrp_enrollment_sts_desc,
    B.chapter_supp_flg
FROM eda.dw_common_vws.dim_unit as A
LEFT JOIN mods_bi.mktg_ops_vws.nhqmktg_cdrp_enrllmnt_sts AS B
ON COLLATE(A.nk_ecode, 'case_insensitive')   = COLLATE(B.chapter_cd, 'case_insensitive')
AND A.appl_src_cd = 'FOCS'  
AND A.unit_typ_cd = 'C'
WHERE
    A.appl_src_cd = 'FOCS'
AND A.unit_typ_cd IN ('C', 'TR', 'R')
with no schema binding;