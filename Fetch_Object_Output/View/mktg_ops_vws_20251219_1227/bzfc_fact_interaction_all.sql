CREATE OR REPLACE VIEW mktg_ops_vws.bzfc_fact_interaction_all AS
SELECT  
    a.cnst_mstr_id AS orig_cnst_mstr_id,
    a.primary_cnst_mstr_id AS cnst_mstr_id,
    a.cnst_hsld_id,
    a.cnst_comnictn_key,
    src.src_key,
    a.comnictn_src_key,
    a.comnictn_typ_key,
    a.chan_typ_key,
    a.unit_key,
    a.amt_typ_key,
    a.nk_tapg_comnictn_dt,
    a.nk_tapg_comnictn_seq,
    a.nk_tapg_comnictn_seq_page,
    a.comnictn_dsc,
    rc.rpt_cell_cd_key,
    a.cell_id AS rpt_cell_cd_id,
    a.cell_src_cd,
    a.cell_subsrc_cd,
    b.file_cd,
    a.motivtn_cd,
    a.fr_last_ta_acct_id,
    a.finder_num,
    a.offer_id,
    a.treatment_id,
    a.activity_id,
    a.segementation_id,
    a.segment_id,
    a.outbnd_id,
    a.email_id,
    a.email_sent_dt,
    a.to_domain,
    a.drop_dt,
    COALESCE(a.drop_dt, a.email_sent_dt, a.nk_tapg_comnictn_dt) AS interaction_dt,
    a.update_dt,
    a.last_dntn_dt,
    a.last_dntn_amt,
    a.chpt_affl,
    a.submitter_nm,
    a.chpt_id,
    a.cntct_dt,
    a.run_dt,
    a.run_id,
    CASE WHEN a.drop_dt IS NOT NULL THEN 1 ELSE 0 END AS dm_list_ind,
    CASE WHEN a.email_sent_dt IS NOT NULL THEN 1 ELSE 0 END AS em_list_ind,
    CASE WHEN a.email_sent_dt IS NOT NULL THEN 1 ELSE 0 END AS em_interaction_ind,
    CASE WHEN a.email_sent_dt IS NOT NULL OR a.mailed_ind = 1 THEN 1 ELSE 0 END AS tot_interaction_ind,
    a.mailed_ind,
    a.supressed_ind,
    a.mail_drop_cnt,
    a.src_seq_num,
    a.sub_src_seq_num,
    a.appl_src_cd,
    a.load_id,
    a.dw_trans_ts
FROM mktg_ops_tbls.bzfc_fact_interaction_all a
LEFT JOIN (
    SELECT DISTINCT src_cd AS cell_src_cd, segmnt_cd, file_cd
    FROM mktg_ops_tbls.rr_rqq_rql_file_xref
) b
    ON a.cell_src_cd = b.cell_src_cd
    AND SUBSTRING(a.motivtn_cd, 10, 3) = b.segmnt_cd
LEFT JOIN mktg_ops_vws.bz_dim_rpt_cell_cd rc
    ON a.cell_id = rc.rpt_cell_cd_id
LEFT JOIN (
    SELECT src_key, src_cd
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY src_cd ORDER BY active_ind DESC, src_key DESC) AS rn
        FROM eda.ufds_vws.gmpbzal_dim_src
    ) t
    WHERE rn = 1
) src
    ON a.cell_src_cd = src.src_cd
    with no schema binding 
;