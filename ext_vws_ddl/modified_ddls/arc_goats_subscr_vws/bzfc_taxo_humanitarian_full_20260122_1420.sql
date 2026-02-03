CREATE OR REPLACE VIEW mods_bi.arc_goats_subscr_vws.bzfc_taxo_humanitarian_full AS
SELECT
taxo_vers_key,
taxo_typ_key,
taxo_typ,
zipcode_key,
zipcode_cd,
zipcode_name,
chapter_key,
chapter_cd,
chapter_name,
region_key,
region_cd,
region_name,
division_key,
division_cd,
division_name,
valid_start_dt,
valid_end_dt,
dw_trans_ts,
row_stat_cd
FROM hubwork_rep.arc_goats_subscr_tbls.taxo_humanitarian
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.arc_goats_subscr_vws.bzfc_taxo_humanitarian_full TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.arc_goats_subscr_vws.bzfc_taxo_humanitarian_full TO role ds_mods_reader_vt;
