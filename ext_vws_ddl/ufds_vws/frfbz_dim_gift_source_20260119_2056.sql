CREATE OR REPLACE VIEW ufds_vws.frfbz_dim_gift_source AS
SELECT
gift_source_key,
nk_sf_gift_source_guid,
ownr_key,
gift_source_name,
gift_source_status,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
load_id,
row_status_cd,
dw_trans_ts,
appl_src_cd
FROM cdigms_rep.frf_sf_tbls.dim_gift_source
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;