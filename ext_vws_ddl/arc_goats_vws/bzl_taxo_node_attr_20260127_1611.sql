CREATE OR REPLACE VIEW arc_goats_vws.bzl_taxo_node_attr AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 25-Aug-2021
Purpose: This view selects node and corresponding attribute details


Updated by: Manikandan P
Updated date: 08-Jul-2022
Purpose: Included dw_trans_ts field
-----------------------------------------------------------------------------------------------------
*/
SELECT
    tntr.node_key,
    tntr.node_typ_key,
    tntr.node_typ_code,
    tntr.node_typ_name,
    tntr.node_id,
    tntr.node_name,
    tntr.node_name_short,
    tna.node_attr_key,
    tnatr.node_attr_typ_name,
    tna.node_attr_val,
    tna.dw_trans_ts
FROM arc_goats_vws.bz_taxo_node_attr AS tna
INNER JOIN arc_goats_vws.bzl_taxo_node AS tntr
    ON tntr.node_typ_key = tna.node_typ_key AND tntr.node_key = tna.node_key
INNER JOIN arc_goats_vws.bz_taxo_node_attr_typ_ref AS tnatr
ON tnatr.node_attr_key = tna.node_attr_key
WITH NO SCHEMA BINDING;