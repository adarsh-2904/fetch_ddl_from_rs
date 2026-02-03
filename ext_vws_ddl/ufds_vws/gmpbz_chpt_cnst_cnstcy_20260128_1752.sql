CREATE OR REPLACE VIEW ufds_vws.gmpbz_chpt_cnst_cnstcy AS
SELECT
gmp_cnst_key,
chpt_cnstcy_affn_key,
cnstcy_typ_cd,
cnstcy_typ_dsc,
strt_dt,
end_dt,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.chpt_cnst_cnstcy
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;