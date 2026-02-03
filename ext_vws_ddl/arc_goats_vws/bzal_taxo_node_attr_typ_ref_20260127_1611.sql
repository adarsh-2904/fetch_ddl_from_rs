CREATE OR REPLACE VIEW arc_goats_vws.bzal_taxo_node_attr_typ_ref AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records from taxo_node_attr_typ_ref table

-----------------------------------------------------------------------------------------------------
*/

/* LOCKING TABLE arc_goats_tbls.taxo_node_attr_typ_ref FOR ACCESS MODE */
SELECT
    node_attr_key,
    node_attr_typ_code,
    node_attr_typ_name,
    node_attr_typ_val,
    node_typ_allowed,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_node_attr_typ_ref
WITH NO SCHEMA BINDING;