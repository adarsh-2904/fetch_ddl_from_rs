CREATE OR REPLACE VIEW arc_goats_vws.bzal_taxo_node_typ_ref AS

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 1020Apr-2020
Purpose: This view selects all the records from taxo_node_typ_ref table

-----------------------------------------------------------------------------------------------------
*/
/* LOCKING TABLE arc_goats_tbls.taxo_node_typ_ref FOR ACCESS MODE */
SELECT
    node_typ_key,
    node_typ_code,
    node_typ_name,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_node_typ_ref
WITH NO SCHEMA BINDING;