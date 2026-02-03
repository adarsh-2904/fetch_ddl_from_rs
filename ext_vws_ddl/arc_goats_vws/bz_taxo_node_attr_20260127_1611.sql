CREATE OR REPLACE VIEW arc_goats_vws.bz_taxo_node_attr AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects active records from taxo_node_attr table

-----------------------------------------------------------------------------------------------------
*/
SELECT
    node_typ_key,
    node_key,
    node_attr_key,
    node_attr_val,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM arc_goats_vws.bzal_taxo_node_attr
WHERE row_stat_cd != 'L'
WITH NO SCHEMA BINDING;