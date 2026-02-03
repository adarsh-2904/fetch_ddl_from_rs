CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzal_taxo_node AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records FROM eda.taxo_node table

-----------------------------------------------------------------------------------------------------
*/

/* LOCKING TABLE arc_goats_tbls.taxo_node FOR ACCESS MODE */
SELECT
    node_key,
    node_typ_key,
    node_id,
    node_name,
    node_name_short,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_node
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node TO role ds_mods_reader_vt;
