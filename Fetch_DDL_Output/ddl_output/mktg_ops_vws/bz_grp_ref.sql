CREATE OR REPLACE VIEW mktg_ops_vws.bz_grp_ref AS 
-- mktg_ops_vws.bz_grp_ref source

create or REPLACE VIEW
/* ---------------------------------------------------------------------------------------------------------------------------
Created by: Majeed Mohammad
Created date:  9/30/2016
Purpose: This view selects records from the view dw_stuart_vws.bz_grp_ref

Modified By: Michael Andrien
Modified Date: 7/11/2017
Purpose: Change view to select from arc_cmm_vws.grp_ref rather than dw_stuart_vws.bz_grp_ref and 
				and added sub_grp_typ to the view.  Commented out the LOCK Table line since the view references a view.
---------------------------------------------------------------------------------------------------------------------------- */
mktg_ops_vws.bz_grp_ref
AS

SELECT
      grp_key,
      grp_cd,
      grp_nm,
      grp_typ ,
      sub_grp_typ,
      grp_assgnmnt_mthd,
      grp_owner,
      trans_key ,
      user_id,
   CAST(dw_srcsys_trans_ts AS TIMESTAMP(0)) AS dw_srcsys_trans_ts,
   row_stat_cd ,
   appl_src_cd,
   load_id 
FROM eda.arc_cmm_vws.grp_ref
WHERE row_stat_cd <> 'L'
with no schema binding;