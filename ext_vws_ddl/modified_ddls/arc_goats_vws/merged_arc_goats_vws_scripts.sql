CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzal_taxo_node AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records FROM eda.taxo_node table

-----------------------------------------------------------------------------------------------------
*/

/* LOCKING TABLE arc_goats_tbls.taxo_node FOR ACCESS MODE */
SELECT
    node_key,
    node_typ_key,
    node_id,
    node_name,
    node_name_short,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_node
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzal_taxo_node_attr AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records FROM eda.taxo_node_attr table

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
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node_attr TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node_attr TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzal_taxo_node_attr_typ_ref AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records FROM eda.taxo_node_attr_typ_ref table

-----------------------------------------------------------------------------------------------------
*/

/* LOCKING TABLE arc_goats_tbls.taxo_node_attr_typ_ref FOR ACCESS MODE */
SELECT
    node_attr_key,
    node_attr_typ_code,
    node_attr_typ_name,
    node_attr_typ_val,
    node_typ_allowed,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_node_attr_typ_ref
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node_attr_typ_ref TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node_attr_typ_ref TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzal_taxo_node_typ_ref AS

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 1020Apr-2020
Purpose: This view selects all the records FROM eda.taxo_node_typ_ref table

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
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node_typ_ref TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzal_taxo_node_typ_ref TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzal_taxo_typ AS

/* --------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records FROM eda.taxo_type table

Modified by: Manikandan P
Modified date: 17-Sep-2020
Purpose: Added taxonomy description column in the view

Modified by: Manikandan P
Modified date: 16-Mar-2021
Purpose: Added data Steward column in the view
----------------------------------------------------------------------------------------------------- */

SELECT
 taxo_typ_key,
 taxo_typ,
 taxo_typ_dsc,
 ln_of_srvc,
 data_steward,
 taxo_status_key,
 taxo_retire_dt,
 trans_key,
 dw_trans_ts,
 row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_typ
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzal_taxo_typ TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzal_taxo_typ TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzal_taxo_vers AS

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records FROM eda.taxo_vers table

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
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzal_taxo_vers TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzal_taxo_vers TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzfc_taxo_denorm_curr AS
SELECT
    taxo_vers_key,
    taxo_ver_dsc,
    taxo_typ_key,
    taxo_typ,
    lvl1_node_typ,
    lvl1_node_key,
    lvl1_node_cd,
    lvl1_node_nm,
    lvl2_node_typ,
    lvl2_node_key,
    lvl2_node_cd,
    lvl2_node_nm,
    lvl3_node_typ,
    lvl3_node_key,
    lvl3_node_cd,
    lvl3_node_nm,
    lvl4_node_typ,
    lvl4_node_key,
    lvl4_node_cd,
    lvl4_node_nm,
    lvl5_node_typ,
    lvl5_node_key,
    lvl5_node_cd,
    lvl5_node_nm,
    lvl6_node_typ,
    lvl6_node_key,
    lvl6_node_cd,
    lvl6_node_nm,
    lvl7_node_typ,
    lvl7_node_key,
    lvl7_node_cd,
    lvl7_node_nm,
    lvl8_node_typ,
    lvl8_node_key,
    lvl8_node_cd,
    lvl8_node_nm,
    lvl9_node_typ,
    lvl9_node_key,
    lvl9_node_cd,
    lvl9_node_nm,
    lvl10_node_typ,
    lvl10_node_key,
    lvl10_node_cd,
    lvl10_node_nm,
    valid_start_dt,
    valid_end_dt,
    dw_trans_ts,
    row_stat_cd
FROM mods_bi.arc_goats_vws.bzfc_taxo_denorm_full
WHERE trunc(valid_start_dt) <= current_date AND trunc(valid_end_dt) >= current_date
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzfc_taxo_denorm_curr TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzfc_taxo_denorm_curr TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzfc_taxo_denorm_full AS

/* LOCKING TABLE arc_goats_tbls.taxo_denorm FOR ACCESS MODE */
SELECT
    taxo_vers_key,
    taxo_ver_dsc,
    taxo_typ_key,
    taxo_typ,
    lvl1_node_typ,
    lvl1_node_key,
    lvl1_node_cd,
    lvl1_node_nm,
    lvl2_node_typ,
    lvl2_node_key,
    lvl2_node_cd,
    lvl2_node_nm,
    lvl3_node_typ,
    lvl3_node_key,
    lvl3_node_cd,
    lvl3_node_nm,
    lvl4_node_typ,
    lvl4_node_key,
    lvl4_node_cd,
    lvl4_node_nm,
    lvl5_node_typ,
    lvl5_node_key,
    lvl5_node_cd,
    lvl5_node_nm,
    lvl6_node_typ,
    lvl6_node_key,
    lvl6_node_cd,
    lvl6_node_nm,
    lvl7_node_typ,
    lvl7_node_key,
    lvl7_node_cd,
    lvl7_node_nm,
    lvl8_node_typ,
    lvl8_node_key,
    lvl8_node_cd,
    lvl8_node_nm,
    lvl9_node_typ,
    lvl9_node_key,
    lvl9_node_cd,
    lvl9_node_nm,
    lvl10_node_typ,
    lvl10_node_key,
    lvl10_node_cd,
    lvl10_node_nm,
    valid_start_dt,
    valid_end_dt,
    dw_trans_ts,
    row_stat_cd
FROM hubwork_rep.arc_goats_tbls.taxo_denorm
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzfc_taxo_denorm_full TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzfc_taxo_denorm_full TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzl_taxo_node AS

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
FROM mods_bi.arc_goats_vws.bz_taxo_node AS a1
INNER JOIN mods_bi.arc_goats_vws.bz_taxo_node_typ_ref AS a2
    ON a1.node_typ_key = a2.node_typ_key
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzl_taxo_node TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzl_taxo_node TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bzl_taxo_node_attr AS

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
FROM mods_bi.arc_goats_vws.bz_taxo_node_attr AS tna
INNER JOIN mods_bi.arc_goats_vws.bzl_taxo_node AS tntr
    ON tntr.node_typ_key = tna.node_typ_key AND tntr.node_key = tna.node_key
INNER JOIN mods_bi.arc_goats_vws.bz_taxo_node_attr_typ_ref AS tnatr
ON tnatr.node_attr_key = tna.node_attr_key
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bzl_taxo_node_attr TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bzl_taxo_node_attr TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bz_taxo_node AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects all the records FROM eda.taxo_node table

-----------------------------------------------------------------------------------------------------
*/
SELECT
    node_key,
    node_typ_key,
    node_id,
    node_name,
    node_name_short,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM mods_bi.arc_goats_vws.bzal_taxo_node
WHERE row_stat_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bz_taxo_node TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bz_taxo_node TO role ds_mods_reader_vt;

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

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bz_taxo_node_typ_ref AS

/* ----------------------------------------------------------------------------- */

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 1020Apr-2020
Purpose: This view selects active records FROM eda.taxo_node_typ_ref table

-----------------------------------------------------------------------------------------------------
*/
SELECT
    node_typ_key,
    node_typ_code,
    node_typ_name,
    trans_key,
    dw_trans_ts,
    row_stat_cd
FROM mods_bi.arc_goats_vws.bzal_taxo_node_typ_ref
WHERE row_stat_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bz_taxo_node_typ_ref TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bz_taxo_node_typ_ref TO role ds_mods_reader_vt;

CREATE OR REPLACE VIEW mods_bi.arc_goats_vws.bz_taxo_vers_pub AS

/*
--------------------------------------------------------------------------------------------------
Created by: Manikandan P
Created date: 20-Apr-2020
Purpose: This view selects published versions FROM eda.taxo_vers table

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
FROM mods_bi.arc_goats_vws.bzal_taxo_vers AS vers
INNER JOIN mods_bi.arc_goats_vws.bzal_taxo_typ AS typ
    ON typ.taxo_typ_key = vers.taxo_typ_key
WHERE vers.status = 'Published' AND vers.row_stat_cd != 'L'
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_vws.bz_taxo_vers_pub TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_vws.bz_taxo_vers_pub TO role ds_mods_reader_vt;
