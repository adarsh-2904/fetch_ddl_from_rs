CREATE OR REPLACE VIEW arc_goats_vws.bzal_taxo_node_attr AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records from taxo_node_attr table

-----------------------------------------------------------------------------------------------------
*/

/* LOCKING TABLE arc_goats_tbls.taxo_node_attr FOR ACCESS MODE */
SELECT
    node_typ_key,
    node_key,
    node_attr_key,
    node_attr_val,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_node_attr
WITH NO SCHEMA BINDING;