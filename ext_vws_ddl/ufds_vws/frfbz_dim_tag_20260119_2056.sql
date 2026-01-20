CREATE OR REPLACE VIEW ufds_vws.frfbz_dim_tag AS
/*
Created BY: ufds PBI Team
Created Date:04/20/2022
Purpose :This view contains Tags data of Salesforce Contacts
*/
SELECT
frf_tag_key,
frf_cnst_key,
tag_nm,
strt_dt,
end_dt,
comments,
grp,
nk_sf_acct_guid ,
nk_sf_cntct_guid,
nk_sf_tag_guid,
nk_sf_tag_label_guid,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.frf_sf_tbls.dim_tag
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;