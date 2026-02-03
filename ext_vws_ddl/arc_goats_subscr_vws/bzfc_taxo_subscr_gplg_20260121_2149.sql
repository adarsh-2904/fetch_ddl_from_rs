CREATE OR REPLACE VIEW arc_goats_subscr_vws.bzfc_taxo_subscr_gplg AS
SELECT DISTINCT
gplg.lvl1_node_cd AS zip_cd,
gplg.lvl1_node_nm AS zip_nm,
gplg.lvl2_node_cd AS gp_terr_cd,
gplg.lvl2_node_nm AS gp_terr_nm,
gplg.lvl3_node_cd AS gp_div_dir_cd,
gplg.lvl3_node_nm AS gp_div_dir_nm,
gplg.lvl4_node_cd AS gp_vp_cd,
gplg.lvl4_node_nm AS gp_vp_nm,
hn.lvl2_node_cd AS chapter_id,
hn.lvl2_node_nm AS chapter_nm,
hn.lvl3_node_cd AS region_id,
hn.lvl3_node_nm AS region_nm,
hn.lvl4_node_cd AS division_id,
hn.lvl4_node_nm AS division_nm,
tna1.node_attr_val AS zipcode_city,
tna2.node_attr_val AS zipcode_state,
tna3.node_attr_val AS gpo_fnm,
tna4.node_attr_val AS gpo_lnm,
tna5.node_attr_val AS gpo_ttl,
tna6.node_attr_val AS gpo_em,
tna7.node_attr_val AS gpo_pn,
tna8.node_attr_val AS gp_div_dir_fnm,
tna9.node_attr_val AS gp_div_dir_lnm,
tna10.node_attr_val AS gp_div_dir_ttl,
tna11.node_attr_val AS gp_div_dir_pn,
tna12.node_attr_val AS gp_div_dir_em,
tna13.node_attr_val AS gp_vp_fnm,
tna14.node_attr_val AS gp_vp_lnm,
tna15.node_attr_val AS gp_vp_ttl,
tna16.node_attr_val AS gp_vp_pn,
tna17.node_attr_val AS gp_vp_em,
tna18.node_attr_val AS region_city_nm,
tna19.node_attr_val AS region_state_cd
FROM (
SELECT DISTINCT
a.lvl1_node_cd,
a.lvl1_node_nm,
a.lvl1_node_key,
a.lvl4_node_cd,
a.lvl4_node_nm,
a.lvl4_node_key,
a.lvl3_node_cd,
a.lvl3_node_nm,
a.lvl3_node_key,
a.lvl2_node_cd,
a.lvl2_node_nm,
a.lvl2_node_key,
vers.taxo_vers_key,
a.taxo_typ_key,
a.taxo_typ,
vers.taxo_ver,
vers.taxo_period_start_dt,
vers.taxo_period_end_dt,
a.valid_start_dt,
a.valid_end_dt,
a.dw_trans_ts AS taxo_dw_trans_ts,
vers.dw_trans_ts AS vers_dw_trans_ts,
a.row_stat_cd AS taxo_row_stat_cd
FROM arc_goats_vws.bzfc_taxo_denorm_curr AS a
INNER JOIN arc_goats_vws.bz_taxo_vers_pub AS vers
ON a.taxo_typ_key = vers.taxo_typ_key
AND vers.taxo_period_start_dt::DATE <= CURRENT_TIMESTAMP(0)::DATE
AND vers.taxo_period_end_dt::DATE >= CURRENT_TIMESTAMP(0)::DATE
WHERE a.taxo_typ_key = 45) AS gplg
LEFT JOIN (
SELECT DISTINCT
lvl4_node_cd,
lvl4_node_nm,
lvl4_node_key,
lvl1_node_cd,
lvl1_node_nm,
lvl1_node_key,
lvl2_node_cd,
lvl2_node_nm,
lvl2_node_key,
lvl3_node_cd,
lvl3_node_nm,
lvl3_node_key
FROM arc_goats_vws.bzfc_taxo_denorm_curr
WHERE taxo_typ_key = 22 ) AS hn
ON gplg.lvl1_node_cd = hn.lvl1_node_cd
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna1
ON tna1.node_typ_key = 101
AND tna1.node_attr_key = 175
AND gplg.lvl1_node_key = tna1.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna2
ON tna2.node_typ_key = 101
AND tna2.node_attr_key = 176
AND gplg.lvl1_node_key = tna2.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna3
ON tna3.node_typ_key = 142
AND tna3.node_attr_key = 230
AND gplg.lvl2_node_key = tna3.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna4
ON tna4.node_typ_key = 142
AND tna4.node_attr_key = 231
AND gplg.lvl2_node_key = tna4.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna5
ON tna5.node_typ_key = 142
AND tna5.node_attr_key = 232
AND gplg.lvl2_node_key = tna5.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna6
ON tna6.node_typ_key = 142
AND tna6.node_attr_key = 233
AND gplg.lvl2_node_key = tna6.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna7
ON tna7.node_typ_key = 142
AND tna7.node_attr_key = 234
AND gplg.lvl2_node_key = tna7.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna8
ON tna8.node_typ_key = 143
AND tna8.node_attr_key = 235
AND gplg.lvl3_node_key = tna8.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna9
ON tna9.node_typ_key = 143
AND tna9.node_attr_key = 236
AND gplg.lvl3_node_key = tna9.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna10
ON tna10.node_typ_key = 143
AND tna10.node_attr_key = 237
AND gplg.lvl3_node_key = tna10.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna11
ON tna11.node_typ_key = 143
AND tna11.node_attr_key = 238
AND gplg.lvl3_node_key = tna11.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna12
ON tna12.node_typ_key = 143
AND tna12.node_attr_key = 239
AND gplg.lvl3_node_key = tna12.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna13
ON tna13.node_typ_key = 144
AND tna13.node_attr_key = 240
AND gplg.lvl4_node_key = tna13.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna14
ON tna14.node_typ_key = 144
AND tna14.node_attr_key = 241
AND gplg.lvl4_node_key = tna14.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna15
ON tna15.node_typ_key = 144
AND tna15.node_attr_key = 242
AND gplg.lvl4_node_key = tna15.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna16
ON tna16.node_typ_key = 144
AND tna16.node_attr_key = 243
AND gplg.lvl4_node_key = tna16.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna17
ON tna17.node_typ_key = 144
AND tna17.node_attr_key = 244
AND gplg.lvl4_node_key = tna17.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna18
ON tna18.node_typ_key = 103
AND tna18.node_attr_key = 135
AND hn.lvl3_node_key = tna18.node_key
LEFT JOIN arc_goats_vws.bzl_taxo_node_attr AS tna19
ON tna19.node_typ_key = 103
AND tna19.node_attr_key = 136
AND hn.lvl3_node_key = tna19.node_key
WITH NO SCHEMA BINDING;