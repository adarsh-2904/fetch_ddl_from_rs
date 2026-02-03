CREATE OR REPLACE VIEW arc_goats_vws.bz_taxo_node_typ_ref AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 1020Apr-2020
Purpose: This view selects active records from taxo_node_typ_ref table

-----------------------------------------------------------------------------------------------------
*/
SELECT
    node_typ_key,
    node_typ_code,
    node_typ_name,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM arc_goats_vws.bzal_taxo_node_typ_ref
WHERE row_stat_cd != 'L'
WITH NO SCHEMA BINDING;