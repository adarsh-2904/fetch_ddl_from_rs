CREATE OR REPLACE VIEW arc_goats_subscr_vws.bzfc_taxo_bio_collection_curr AS
SELECT
taxo_vers_key,
taxo_typ_key,
taxo_typ,
zipcode_key,
zipcode_cd,
zipcode_name,
collection_operation_key,
collection_operation_cd,
collection_operation_name,
district_key,
district_cd,
district_name,
ds_region_key,
ds_region_cd,
ds_region_name,
division_key,
division_cd,
division_name,
valid_start_dt,
valid_end_dt,
dw_trans_ts,
row_stat_cd
FROM arc_goats_subscr_vws.bzfc_taxo_bio_collection_full
WHERE valid_start_dt::DATE <= CURRENT_TIMESTAMP(0)::DATE
AND valid_end_dt::DATE >= CURRENT_TIMESTAMP(0)::DATE
WITH NO SCHEMA BINDING;