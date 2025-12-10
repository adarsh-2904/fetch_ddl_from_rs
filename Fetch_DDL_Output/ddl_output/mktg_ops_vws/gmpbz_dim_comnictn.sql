CREATE OR REPLACE VIEW mktg_ops_vws.gmpbz_dim_comnictn AS
SELECT
    comnictn_key,
    comnictn_cd,
    comnictn_dsc,
    prpse_cd,
    prpse_dsc,
    comnictn_criteria,
    comnictn_priority_seq,
    active_ind,
    srcsys_create_ts,
    srcsys_update_ts,
    srcsys_created_by,
    srcsys_modified_by,
    row_status_cd,
    dw_trans_ts,
    load_id,
    appl_src_cd
FROM eda.ufds_vws.gmpbz_dim_comnictn
with no schema binding
;