CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bz_taxo_node_attr AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects active records FROM eda.taxo_node_attr table

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
FROM mods_bi.arc_goats_vws.bzal_taxo_node_attr
WHERE row_stat_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bz_taxo_node_attr TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bz_taxo_node_attr TO role ds_mods_reader_vt;
