CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzal_taxo_typ AS

/* --------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records FROM eda.taxo_type table

Modified by: Manikandan P
Modified date: 17-Sep-2020
Purpose: Added taxonomy description column in the view

Modified by: Manikandan P
Modified date: 16-Mar-2021
Purpose: Added data Steward column in the view
----------------------------------------------------------------------------------------------------- */

SELECT
 taxo_typ_key,
 taxo_typ,
 taxo_typ_dsc,
 ln_of_srvc,
 data_steward,
 taxo_status_key,
 taxo_retire_dt,
 trans_key,
 dw_trans_ts,
 row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_typ
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzal_taxo_typ TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzal_taxo_typ TO role ds_mods_reader_vt;
