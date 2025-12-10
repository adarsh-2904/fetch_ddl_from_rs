CREATE OR REPLACE VIEW mods_bi.mktg_ops_vws.bz_dim_fund_cd AS
SELECT
  dfc.fund_cd_key AS fund_code_key,
  dfc.fund_cd AS fund_code,
  gmpdfc.fund_dsc AS fund_code_description,
  dfc.row_stat_cd,
  CAST (dfc.dw_trans_ts AS TIMESTAMP WITHOUT TIME ZONE) AS dw_trans_ts,
  dfc.appl_src_cd,
  dfc.load_id
FROM hubwork_rep.rco_tbls.dim_fund_cd AS dfc
LEFT OUTER JOIN eda.ufds_vws.gmpbz_dim_fund AS gmpdfc
ON dfc.fund_cd = gmpdfc.fund_cd
WITH NO SCHEMA BINDING;