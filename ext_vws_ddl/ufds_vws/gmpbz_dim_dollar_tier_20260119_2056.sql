CREATE OR REPLACE VIEW ufds_vws.gmpbz_dim_dollar_tier AS
SELECT
dollar_tier_key,
dollar_tier_cd,
dollar_tier_dsc,
high_val,
low_val,
active_ind,
srcsys_created_by,
srcsys_modified_by,
srcsys_create_ts,
srcsys_update_ts,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.dim_dollar_tier
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;