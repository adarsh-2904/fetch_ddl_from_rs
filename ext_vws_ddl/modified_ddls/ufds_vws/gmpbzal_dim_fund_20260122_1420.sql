CREATE OR REPLACE VIEW mods_bi.ufds_vws.gmpbzal_dim_fund AS
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
(CASE WHEN fund_cd IN ( '4905', '4904' , '3406' , '4900' , '4900-dm' , '4960' , '4900-DM' , '4999' , '2099' , '2947' , '2574-24' , '2575-24' , '4908' )
THEN 'Blue Sky' ELSE
(CASE WHEN gl_company_fund_cd IN ( '052' , '062' ) THEN 'Gray Sky' ELSE 'Blue Sky' END)END) AS fundraising_period,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd,
spanish_fund_dsc
FROM cdigms_rep.gms_tbls.dim_fund
WITH NO SCHEMA BINDING;
GRANT ALL ON TABLE mods_bi.ufds_vws.gmpbzal_dim_fund TO role ds_mods_writer;
GRANT SELECT ON TABLE mods_bi.ufds_vws.gmpbzal_dim_fund TO role ds_mods_reader_vt;
