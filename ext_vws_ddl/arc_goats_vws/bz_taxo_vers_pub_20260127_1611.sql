CREATE OR REPLACE VIEW arc_goats_vws.bz_taxo_vers_pub AS

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects published versions from taxo_vers table

Modified by: Manikandan P
Modified date: 08-Mar-2021
Purpose: Added taxonomy version field

Modified by: Manikandan P
Modified date: 14-Jan-2022
Purpose: Added taxonomy type field
-----------------------------------------------------------------------------------------------------
*/
SELECT
    vers.taxo_vers_key,
    vers.taxo_typ_key,
    typ.taxo_typ,
    typ.taxo_retire_dt,
    typ.taxo_status_key,
    vers.taxo_ver,
    vers.taxo_ver_dsc,
    vers.taxo_period_start_dt,
    vers.taxo_period_label,
    vers.taxo_period_end_dt,
    vers.efft_start_dt,
    vers.efft_end_dt,
    vers.allow_chg_flg,
    vers.status,
    vers.taxo_vers_notes,
    vers.trans_key,
    vers.dw_trans_ts,
    vers.row_stat_cd
FROM arc_goats_vws.bzal_taxo_vers AS vers
INNER JOIN arc_goats_vws.bzal_taxo_typ AS typ
    ON typ.taxo_typ_key = vers.taxo_typ_key
WHERE vers.status = 'Published' AND vers.row_stat_cd != 'L'
WITH NO SCHEMA BINDING;