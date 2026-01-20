CREATE OR REPLACE VIEW ufds_vws.gmpbza_dim_fund AS
SELECT
fund_key,
row_eff_from_ts,
row_eff_to_ts,
fund_cd,
fund_dsc,
fund_long_dsc,
fund_catg_dsc,
gl_company_fund_cd,
gl_company_fund_dsc,
gl_action_prog_cd,
gl_action_prog_dsc,
gl_prog_srcv_cd,
gl_prog_srcv_dsc,
non_bdgt_rlvng_ind,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts ,
load_id,
appl_src_cd,
CASE WHEN row_eff_to_ts = TIMESTAMP '9999-12-31 00:00:00' OR row_eff_to_ts = TIMESTAMP '9999-12-31 00:00:00' THEN 1 ELSE 0 END AS bzd_curr_ind,
spanish_fund_dsc
FROM cdigms_rep.gms_tbls.dim_fund
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;