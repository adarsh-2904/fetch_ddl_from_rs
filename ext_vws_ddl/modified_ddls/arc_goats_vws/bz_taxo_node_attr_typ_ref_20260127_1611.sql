CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bz_taxo_node_attr_typ_ref AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects active records FROM eda.taxo_node_attr_typ_ref table

-----------------------------------------------------------------------------------------------------
*/
SELECT
    node_attr_key,
    node_attr_typ_code,
    node_attr_typ_name,
    node_attr_typ_val,
    node_typ_allowed,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM mods_bi.arc_goats_vws.bzal_taxo_node_attr_typ_ref
WHERE row_stat_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bz_taxo_node_attr_typ_ref TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bz_taxo_node_attr_typ_ref TO role ds_mods_reader_vt;
