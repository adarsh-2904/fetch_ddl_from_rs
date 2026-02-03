CREATE OR REPLACE VIEW arc_goats_vws.bzal_taxo_vers AS

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records from taxo_vers table

Modified by: Manikandan P
Modified date: 08-Mar-2021
Purpose: Added taxonomy version field
-----------------------------------------------------------------------------------------------------
*/
SELECT
    taxo_vers_key,
    taxo_typ_key,
    taxo_ver,
    taxo_ver_dsc,
    taxo_period_start_dt,
    taxo_period_label,
    taxo_period_end_dt,
    efft_start_dt,
    efft_end_dt,
    allow_chg_flg,
    status,
    taxo_vers_notes,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_vers
WITH NO SCHEMA BINDING;