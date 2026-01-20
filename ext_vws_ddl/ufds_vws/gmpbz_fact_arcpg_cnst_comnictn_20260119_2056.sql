CREATE OR REPLACE VIEW ufds_vws.gmpbz_fact_arcpg_cnst_comnictn AS
SELECT
cnst_comnictn_key,
cnst_mstr_id,
nk_tapg_acct_id,
nk_tapg_comnictn_dt ,
nk_tapg_comnictn_seq,
nk_tapg_comnictn_seq_page,
comnictn_dsc,
amt,
amt_typ_key,
chan_typ_key,
src_key,
comnictn_typ_key,
response_typ_key,
lctn_key,
comnictn_note_txt,
active_ind,
srcsys_create_ts,
srcsys_update_ts,
srcsys_created_by,
srcsys_modified_by,
row_status_cd,
dw_trans_ts,
load_id,
appl_src_cd
FROM cdigms_rep.gms_tbls.fact_arcpg_cnst_comnictn
WHERE row_status_cd != 'L'
WITH NO SCHEMA BINDING;