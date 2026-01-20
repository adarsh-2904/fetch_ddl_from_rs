CREATE OR REPLACE VIEW mods_bi.arc_mdm_vws.bzal_assessmnt AS
/*--------------------------
Created by: Aishvariyaa A
Created date: 29-Jun-2020
Purpose: This view selects all records FROM eda.arc_mdm_vws.bzal_assessmnt table
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
FROM eda.arc_mdm_vws.bzal_assessmnt
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_mdm_vws.bzal_assessmnt TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_mdm_vws.bzal_assessmnt TO role ds_mods_reader_vt;
