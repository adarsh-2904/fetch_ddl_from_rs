CREATE OR REPLACE VIEW arc_mdm_vws.bzal_assessmnt AS
/*--------------------------
Created by: Aishvariyaa A
Created date: 29-Jun-2020
Purpose: This view selects all records from arc_mdm_tbls.assessmnt table
-----------------------------*/
SELECT
assessmnt_key,
assessmnt_mthd_key,
assessmnt_cd,
assessmnt_cd_title,
assessmnt_cd_dsc,
assessmnt_ctg,
assessmnt_actn_cd,
assessmnt_strt_ts,
assessmnt_end_ts,
created_by_id,
row_stat_cd
FROM arc_mdm_tbls.assessmnt
WITH NO SCHEMA BINDING;