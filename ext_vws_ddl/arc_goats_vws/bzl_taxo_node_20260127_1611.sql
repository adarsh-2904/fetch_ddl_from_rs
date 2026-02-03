CREATE OR REPLACE VIEW arc_goats_vws.bzl_taxo_node AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view is used to fetch the hierarchy detail of the taxonomy

-----------------------------------------------------------------------------------------------------
*/
SELECT
    a1.node_key,
    a1.node_typ_key,
    a2.node_typ_code,
    a2.node_typ_name,
    a1.node_id,
    a1.node_name,
    a1.node_name_short,
    a1.trans_key,
    a1.dw_trans_ts,
    a1.row_stat_cd
FROM arc_goats_vws.bz_taxo_node AS a1
INNER JOIN arc_goats_vws.bz_taxo_node_typ_ref AS a2
    ON a1.node_typ_key = a2.node_typ_key
WITH NO SCHEMA BINDING;